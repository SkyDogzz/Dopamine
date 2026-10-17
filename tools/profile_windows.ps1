param(
	[Parameter(Mandatory = $true)]
	[string] $GodotExecutable,
	[string] $OutputPath = "docs/qa/data/windows_survival_profile.csv"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$projectPath = Join-Path $repositoryRoot "game"
$godotExecutableInput = $GodotExecutable.Trim().Trim('"').Trim("'")
if (-not (Test-Path -LiteralPath $godotExecutableInput -PathType Leaf)) {
	throw "Godot executable not found: $godotExecutableInput"
}
$godotPath = (Resolve-Path -LiteralPath $godotExecutableInput).Path
$extensionPath = Join-Path $projectPath "bin/windows/libdopamine.windows.template_debug.x86_64.dll"
if (-not (Test-Path -LiteralPath $extensionPath -PathType Leaf)) {
	Write-Host "Windows debug extension is missing; building the project first."
	& (Join-Path $repositoryRoot "tools/build_windows.ps1") -GodotExecutable $godotPath -NoLaunch
	if ($LASTEXITCODE -ne 0) { throw "Windows build failed with exit code $LASTEXITCODE" }
}

$outputFile = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
	$OutputPath
} else {
	Join-Path $repositoryRoot $OutputPath
}
$outputFile = [System.IO.Path]::GetFullPath($outputFile)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputFile) | Out-Null

Write-Host "Starting Dopamine Survivor. The CSV will be written to: $outputFile"
Write-Host "Play a normal Survival run at speed x1, then close the game to finish the capture."
$profileArgument = "--profile-output=$outputFile"
& $godotPath --path $projectPath -- $profileArgument
if ($LASTEXITCODE -ne 0) { throw "Godot exited with code $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
	throw "Godot did not create the profiling output. Confirm that the project started successfully."
}
Write-Host "Profiling complete: $outputFile"
