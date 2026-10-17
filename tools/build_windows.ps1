param(
	[Parameter(Mandatory = $true)]
	[string] $GodotExecutable,
	[switch] $NoLaunch,
	[switch] $Export,
	[switch] $DebugOnly,
	[switch] $SkipProjectChecks,
	[string] $TestProjectPath
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$projectPath = Join-Path $repositoryRoot "game"
$buildPath = Join-Path $repositoryRoot "build/windows"
$releaseBuildPath = Join-Path $repositoryRoot "build/windows-release"
$godotExecutableInput = $GodotExecutable.Trim()
if ($godotExecutableInput.Length -ge 2 -and (
	($godotExecutableInput.StartsWith('"') -and $godotExecutableInput.EndsWith('"')) -or
	($godotExecutableInput.StartsWith("'") -and $godotExecutableInput.EndsWith("'"))
)) {
	$godotExecutableInput = $godotExecutableInput.Substring(1, $godotExecutableInput.Length - 2)
}
if (-not (Test-Path -LiteralPath $godotExecutableInput -PathType Leaf)) {
	throw "Godot executable not found: $godotExecutableInput. Pass the path with -GodotExecutable, or enter it without surrounding quotes when prompted."
}
$godotPath = (Resolve-Path -LiteralPath $godotExecutableInput).Path

function Invoke-CMakeConfigure([string[]] $Arguments, [string] $BuildDirectory) {
	$output = & cmake @Arguments 2>&1
	$exitCode = $LASTEXITCODE
	$output | ForEach-Object { Write-Host $_ }
	if ($exitCode -eq 0) { return }

	$errorText = $output -join "`n"
	if ($errorText -notmatch "unable to read tree|Failed to checkout tag") {
		throw "CMake configuration failed with exit code $exitCode"
	}

	Write-Host "The godot-cpp checkout is incomplete; removing only its generated FetchContent directories and retrying."
	$dependencyDirectory = Join-Path $BuildDirectory "_deps"
	foreach ($directoryName in @("godot-cpp-src", "godot-cpp-subbuild", "godot-cpp-build")) {
		$directory = Join-Path $dependencyDirectory $directoryName
		if (Test-Path $directory) { Remove-Item -Recurse -Force $directory }
	}
	& cmake @Arguments
	if ($LASTEXITCODE -ne 0) { throw "CMake configuration retry failed with exit code $LASTEXITCODE" }
}

$debugArguments = @(
	"-S", $repositoryRoot, "-B", $buildPath, "-A", "x64",
	"-DBUILD_TESTING=ON", "-DGODOTCPP_TARGET=template_debug",
	"-DDOPAMINE_GODOT_EXECUTABLE=$godotPath"
)
if (-not [string]::IsNullOrWhiteSpace($TestProjectPath)) {
	$debugArguments += "-DDOPAMINE_GAME_PROJECT_DIR=$([System.IO.Path]::GetFullPath($TestProjectPath))"
}
Invoke-CMakeConfigure $debugArguments $buildPath

cmake --build $buildPath --config Debug --parallel 4
if ($LASTEXITCODE -ne 0) { throw "Windows extension build failed with exit code $LASTEXITCODE" }

$extensionPath = Join-Path $projectPath "bin/windows/libdopamine.windows.template_debug.x86_64.dll"
if (-not (Test-Path $extensionPath)) { throw "Expected GDExtension DLL was not created: $extensionPath" }

if (-not $DebugOnly) {
	$releaseArguments = @(
		"-S", $repositoryRoot, "-B", $releaseBuildPath, "-A", "x64",
		"-DBUILD_TESTING=OFF", "-DGODOTCPP_TARGET=template_release",
		"-DDOPAMINE_GODOT_EXECUTABLE=$godotPath"
	)
	Invoke-CMakeConfigure $releaseArguments $releaseBuildPath

	cmake --build $releaseBuildPath --config Release --parallel 4
	if ($LASTEXITCODE -ne 0) { throw "Windows release extension build failed with exit code $LASTEXITCODE" }
	$releaseExtensionPath = Join-Path $projectPath "bin/windows/libdopamine.windows.template_release.x86_64.dll"
	if (-not (Test-Path $releaseExtensionPath)) { throw "Expected release GDExtension DLL was not created: $releaseExtensionPath" }
}

if (-not $SkipProjectChecks) {
	$importOutput = & $godotPath --headless --editor --path $projectPath --import --quit 2>&1
	$importOutput | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "Godot project import failed with exit code $LASTEXITCODE" }
	if ($importOutput -match "(?m)(ERROR:|SCRIPT ERROR:)") { throw "Godot project import reported errors" }

	$smokeOutput = & $godotPath --headless --path $projectPath --script "res://tests/sandbox_smoke.gd" 2>&1
	$smokeOutput | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "GDExtension smoke test failed with exit code $LASTEXITCODE" }
	if ($smokeOutput -match "(?m)(SCRIPT ERROR:|Assertion failed|Cannot get class 'CombatSimulation'|GDExtension.*(failed|unavailable))") {
		throw "GDExtension smoke test reported errors"
	}
}

if ($Export) {
	$exportDirectory = Join-Path $buildPath "export"
	New-Item -ItemType Directory -Force -Path $exportDirectory | Out-Null
	$exportPath = Join-Path $exportDirectory "DopamineSurvivor.exe"
	Write-Host "Export target: $exportPath"
	$exportOutput = & $godotPath --verbose --headless --path $projectPath --export-release "Windows Desktop" $exportPath 2>&1
	$exportOutput | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "Windows export failed with exit code $LASTEXITCODE" }
	if ($exportOutput -match "(?m)(ERROR:|SCRIPT ERROR:)") { throw "Windows export reported errors" }
	if (-not (Test-Path $exportPath)) {
		$exportContents = Get-ChildItem -LiteralPath $exportDirectory -Force | ForEach-Object { $_.FullName }
		throw "Godot returned success without creating the exported executable '$exportPath'. Export directory contains: $($exportContents -join ', ')"
	}
}

if (-not $NoLaunch) {
	if ($Export) {
		& $exportPath
	} else {
		& $godotPath --path $projectPath
	}
}
