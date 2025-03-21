# Verifica se il script è in esecuzione come amministratore
function Ensure-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Output "WIMToolkit necessita di essere lanciato come Amministratore. Riavvio."
        Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "-Command irm -Uri 'https://raw.githubusercontent.com/ItaliaDevHub/WIMToolkit/main/WIMtoolkitDowload.ps1' | iex"
        return $false
    }
    return $true
}

# Assicurati che lo script venga eseguito come amministratore
if (-not (Ensure-Admin)) {
    return
}

# Rimuovi eventuali directory precedenti
$wimToolkitPath = "C:\WIMToolkit"
if (Test-Path $wimToolkitPath) {
    Write-Host "Rimuovendo la directory esistente di WIMToolkit..." -ForegroundColor Yellow
    Remove-Item -Path $wimToolkitPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Cambia la directory a C:\
Set-Location -Path "C:\"

# Scarica il file ZIP da ItaliaDevHub
$zipUrl = "https://github.com/ItaliaDevHub/WIMToolkit/archive/refs/heads/main.zip"
$zipFile = "WIMToolkit-main.zip"
Write-Host "Scaricando WIMToolkit da ItaliaDevHub..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile

# Estrai l'archivio ZIP
Write-Host "Estraendo l'archivio..." -ForegroundColor Cyan
Expand-Archive -Path $zipFile -DestinationPath "." -Force

# Rinomina la cartella estratta
Write-Host "Rinomina la cartella estratta in WIMToolkit..." -ForegroundColor Cyan
Move-Item -Path "WIMToolkit-main" -Destination $wimToolkitPath -Force

# Rimuovi l'archivio ZIP
Remove-Item -Path $zipFile -Force

# Avvia WIMToolkit
Write-Host "Avvio WIMToolkit..." -ForegroundColor Cyan
Start-Process -FilePath "$wimToolkitPath\WIMToolkit.bat"
