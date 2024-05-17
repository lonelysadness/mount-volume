function Write-Log {
    param (
        [string]$message
    )
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    $logEntry | Out-File -FilePath $logFilePath -Append
}

$logFilePath = Join-Path $env:USERPROFILE "mount_shares.log"

function Mount-Folder {
    param (
        [string]$folderPath
    )

    $existingDrive = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -eq $folderPath }
    if ($existingDrive) {
        Write-Log "Le dossier $folderPath est déjà monté sur $($existingDrive.Name):"
        return
    }
    if (Test-Path $folderPath) {
        $driveLetter = $null
        90..69 | ForEach-Object {
            $letter = [char]$_
            if (!(Get-PSDrive -Name $letter -ErrorAction SilentlyContinue)) {
                $driveLetter = $letter
                return
            }
        }
        if ($driveLetter) {
            try {
                New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $folderPath -Persist -Scope Global
                Write-Log "Dossier monté : $folderPath sur $driveLetter"
            } catch {
                Write-Log "Erreur lors du montage de $folderPath sur $driveLetter $_"
            }
        } else {
            Write-Log "Aucune lettre de lecteur disponible pour monter $folderPath"
        }
    } else {
        Write-Log "Le chemin $folderPath n'existe pas ou est inaccessible."
    }
}


$isAdmin = $(whoami /groups | Select-String "Admins du domaine") -ne $null

$userFolder = "\\SRV-INF-001\rep_base_users$\$env:USERNAME"
Mount-Folder -folderPath $userFolder

if ($isAdmin) {
    $infraFolder = "\\SRV-INF-001\rep_base_communs$\Infrastructure"
    Mount-Folder -folderPath $infraFolder
}
else {
    $communsFolder = "\\SRV-INF-001\rep_base_communs$"
    $subFolders = Get-ChildItem -Path $communsFolder -Directory -ErrorAction SilentlyContinue

    foreach ($subFolder in $subFolders) {
        Mount-Folder -folderPath $subFolder.FullName
    }
}
