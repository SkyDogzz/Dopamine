param(
	[Parameter(Mandatory = $true)]
	[string] $GodotExecutable,
	[string] $OutputPath = "docs/qa/data/windows_survival_profile.csv"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$projectPath = Join-Path $repositoryRoot "game"
$buildPath = Join-Path $repositoryRoot "build/windows"
$godotExecutableInput = $GodotExecutable.Trim().Trim('"').Trim("'")
if (-not (Test-Path -LiteralPath $godotExecutableInput -PathType Leaf)) {
	throw "Godot executable not found: $godotExecutableInput"
}
$godotPath = (Resolve-Path -LiteralPath $godotExecutableInput).Path
$testProjectName = "Dopamine Survivor Tests $([Guid]::NewGuid().ToString('N'))"
$testWorkspacePath = Join-Path $buildPath "profiling-test-workspace"
$testProjectPath = Join-Path $testWorkspacePath "game"

Write-Host "Building the Windows Debug extension and test executables."
& (Join-Path $repositoryRoot "tools/build_windows.ps1") `
	-GodotExecutable $godotPath -NoLaunch -DebugOnly -SkipProjectChecks -TestProjectPath $testProjectPath
if ($LASTEXITCODE -ne 0) { throw "Windows Debug build failed with exit code $LASTEXITCODE" }

Write-Host "Preparing an isolated Godot project for the test suite."
if (Test-Path -LiteralPath $testWorkspacePath) {
	Remove-Item -LiteralPath $testWorkspacePath -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $testWorkspacePath | Out-Null
$excludedGodotCache = Join-Path $projectPath ".godot"
& robocopy $projectPath $testProjectPath /E /XD $excludedGodotCache /NFL /NDL /NJH /NJS /NP
$copyExitCode = $LASTEXITCODE
if ($copyExitCode -ge 8) { throw "Could not prepare the isolated test project (robocopy exit code $copyExitCode)." }
$testDocsPath = Join-Path $testWorkspacePath "docs"
& robocopy (Join-Path $repositoryRoot "docs") $testDocsPath /E /NFL /NDL /NJH /NJS /NP
$copyExitCode = $LASTEXITCODE
if ($copyExitCode -ge 8) { throw "Could not copy reference docs for the isolated test workspace (robocopy exit code $copyExitCode)." }
$testProjectFile = Join-Path $testProjectPath "project.godot"
$projectConfig = [System.IO.File]::ReadAllText($testProjectFile)
$originalName = 'config/name="Dopamine Survivor"'
if (-not $projectConfig.Contains($originalName)) { throw "Could not set an isolated test profile in $testProjectFile" }
$projectConfig = $projectConfig.Replace($originalName, "config/name=`"$testProjectName`"")
[System.IO.File]::WriteAllText($testProjectFile, $projectConfig)

Write-Host "Running all registered CTest checks sequentially. Test saves use the temporary '$testProjectName' profile."
$testExitCode = 0
try {
	& ctest --test-dir $buildPath -C Debug --output-on-failure -j1
	$testExitCode = $LASTEXITCODE
} finally {
	$testDataPath = Join-Path $buildPath "test_appdata"
	if (Test-Path -LiteralPath $testDataPath) {
		Remove-Item -LiteralPath $testDataPath -Recurse -Force
	}
}
if ($testExitCode -ne 0) { throw "CTest failed with exit code $testExitCode; profiling was not started." }

Write-Host "Importing the game project, then starting the interactive capture."
& $godotPath --headless --editor --path $projectPath --quit
if ($LASTEXITCODE -ne 0) { throw "Godot project import failed with exit code $LASTEXITCODE" }

$outputFile = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
	$OutputPath
} else {
	Join-Path $repositoryRoot $OutputPath
}
$outputFile = [System.IO.Path]::GetFullPath($outputFile)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputFile) | Out-Null

Write-Host "Starting Dopamine Survivor. The CSV will be written to: $outputFile"
Write-Host "Play a temporary no-save Survival run at speed x1, then close the game to finish the capture."
$profileArgument = "--profile-output=$outputFile"
& $godotPath --path $projectPath -- $profileArgument
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
	throw "Godot did not create the profiling output. Confirm that the project started successfully."
}
Write-Host "All tests passed; profiling complete: $outputFile"
