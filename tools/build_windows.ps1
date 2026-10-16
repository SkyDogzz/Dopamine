param(
	[Parameter(Mandatory = $true)]
	[string] $GodotExecutable,
	[switch] $NoLaunch,
	[switch] $Export
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$projectPath = Join-Path $repositoryRoot "game"
$buildPath = Join-Path $repositoryRoot "build/windows"
$releaseBuildPath = Join-Path $repositoryRoot "build/windows-release"
$godotPath = (Resolve-Path $GodotExecutable).Path

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
	"-DBUILD_TESTING=ON", "-DGODOTCPP_TARGET=template_debug"
)
Invoke-CMakeConfigure $debugArguments $buildPath

cmake --build $buildPath --config Debug --parallel 4
if ($LASTEXITCODE -ne 0) { throw "Windows extension build failed with exit code $LASTEXITCODE" }

$releaseArguments = @(
	"-S", $repositoryRoot, "-B", $releaseBuildPath, "-A", "x64",
	"-DBUILD_TESTING=OFF", "-DGODOTCPP_TARGET=template_release"
)
Invoke-CMakeConfigure $releaseArguments $releaseBuildPath

cmake --build $releaseBuildPath --config Release --parallel 4
if ($LASTEXITCODE -ne 0) { throw "Windows release extension build failed with exit code $LASTEXITCODE" }

$extensionPath = Join-Path $projectPath "bin/windows/libdopamine.windows.template_debug.x86_64.dll"
if (-not (Test-Path $extensionPath)) { throw "Expected GDExtension DLL was not created: $extensionPath" }
$releaseExtensionPath = Join-Path $projectPath "bin/windows/libdopamine.windows.template_release.x86_64.dll"
if (-not (Test-Path $releaseExtensionPath)) { throw "Expected release GDExtension DLL was not created: $releaseExtensionPath" }

& $godotPath --headless --editor --path $projectPath --quit
if ($LASTEXITCODE -ne 0) { throw "Godot project import failed with exit code $LASTEXITCODE" }

& $godotPath --headless --path $projectPath --script "res://tests/sandbox_smoke.gd"
if ($LASTEXITCODE -ne 0) { throw "GDExtension smoke test failed with exit code $LASTEXITCODE" }

if ($Export) {
	$exportDirectory = Join-Path $buildPath "export"
	New-Item -ItemType Directory -Force -Path $exportDirectory | Out-Null
	$exportPath = Join-Path $exportDirectory "Dopamine Survivor.exe"
	& $godotPath --headless --path $projectPath --export-release "Windows Desktop" $exportPath
	if ($LASTEXITCODE -ne 0) { throw "Windows export failed with exit code $LASTEXITCODE" }
	if (-not (Test-Path $exportPath)) { throw "Godot did not create the exported executable: $exportPath" }
}

if (-not $NoLaunch) {
	if ($Export) {
		& $exportPath
	} else {
		& $godotPath --path $projectPath
	}
}
