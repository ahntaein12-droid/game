$ErrorActionPreference = "Stop"

$scripts = @(
    "scripts\Main.gd",
    "scripts\Horse.gd",
    "scripts\GameState.gd",
    "scripts\SaveSystem.gd",
    "scripts\BreedingSystem.gd",
    "scripts\RacingSystem.gd"
)

$failed = $false

foreach ($script in $scripts) {
    if (-not (Test-Path -LiteralPath $script)) {
        Write-Host "Skipping missing script: $script"
        continue
    }

    $logName = "godot-check-$([System.IO.Path]::GetFileNameWithoutExtension($script).ToLowerInvariant()).log"
    Write-Host "Checking $script"

    & godot_console --headless --path . --log-file $logName --check-only --script $script
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed: $script"
        $failed = $true
    }
}

if ($failed) {
    exit 1
}

Write-Host "Godot script check passed."
