$response = Invoke-RestMethod -Uri 'http://localhost:4096/provider'
$connected = $response.connected
Write-Host "Connected providers: $($connected -join ', ')"

foreach ($p in $response.all) {
    if ($connected -contains $p.id) {
        $modelNames = $p.models.PSObject.Properties.Name
        Write-Host "Provider: $($p.id) - $($modelNames.Count) models"
        # Show first 5 model names
        $modelNames | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" }
        if ($modelNames.Count -gt 5) {
            Write-Host "  ... and $($modelNames.Count - 5) more"
        }
    }
}
