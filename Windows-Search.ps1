function Service-Stop {
    Stop-Service WSearch -Force
    Write-Host "Search service stopped"
}

function Service-Start {
    Start-Service WSearch
    Write-Host "Search service started"
}

function Get-Root-Guid {
    $roots = Get-ChildItem -Path $searchRoots -ErrorAction SilentlyContinue
    foreach ($root in $roots) {
        $props = Get-ItemProperty -Path $root.PSPath -ErrorAction SilentlyContinue
        if ($props.URL -match "file:///$volumeLetter\\[([0-9a-fA-F\-]{36})\]\\") {
            return $matches[1]
        }
    }
    Write-Host "Warning: using default GUID" -ForegroundColor Yellow
    return $defaultGuid
}

function Clean-Init {
    $subKeys = Get-ChildItem -Path $registryBase
    foreach ($subKey in $subKeys) {
        Remove-Item -Path $subKey.PSPath -Recurse -Force
    }
    Write-Host "Exclusions reset"
}

function Default-Search {
    param (
        [String]$path,
        [String]$url,
        [Int]$isDefault
    )
    $subKeyPath = Join-Path $registryBase $counter
    New-Item -Path $subKeyPath -Force | Out-Null
    New-ItemProperty -Path $subKeyPath -Name "Container" -PropertyType DWord -Value 0 -Force | Out-Null
    New-ItemProperty -Path $subKeyPath -Name "Default"   -PropertyType DWord -Value $isDefault -Force | Out-Null
    New-ItemProperty -Path $subKeyPath -Name "Include"   -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $subKeyPath -Name "NoContent" -PropertyType DWord -Value 0 -Force | Out-Null
    New-ItemProperty -Path $subKeyPath -Name "Policy"    -PropertyType DWord -Value 0 -Force | Out-Null
    New-ItemProperty -Path $subKeyPath -Name "Suppress"  -PropertyType DWord -Value 0 -Force | Out-Null
    New-ItemProperty -Path $subKeyPath -Name "URL"       -PropertyType String -Value $url -Force | Out-Null
    $global:counter++
    Set-ItemProperty -Path $registryBase -Name "ItemCount" -Value $global:counter -Force | Out-Null
    Write-Host "Included folder $counter : $path" -ForegroundColor Green
}

function Recur-Search {
    param (
        [String]$path
    )
    $folders = Get-ChildItem -Path $path -Directory -Force -ErrorAction SilentlyContinue
    foreach ($folder in $folders) {
        if ($folder.Name.StartsWith(".")) {
            $subKeyPath = Join-Path $registryBase $counter
            $relativePath = $folder.FullName.Substring(3)
            $url = "file:///$volumeLetter[$guid]\$relativePath\"
            New-Item -Path $subKeyPath -Force | Out-Null
            New-ItemProperty -Path $subKeyPath -Name "Container" -PropertyType DWord -Value 0 -Force | Out-Null
            New-ItemProperty -Path $subKeyPath -Name "Default"   -PropertyType DWord -Value 0 -Force | Out-Null
            New-ItemProperty -Path $subKeyPath -Name "Include"   -PropertyType DWord -Value 0 -Force | Out-Null
            New-ItemProperty -Path $subKeyPath -Name "NoContent" -PropertyType DWord -Value 0 -Force | Out-Null
            New-ItemProperty -Path $subKeyPath -Name "Policy"    -PropertyType DWord -Value 0 -Force | Out-Null
            New-ItemProperty -Path $subKeyPath -Name "Suppress"  -PropertyType DWord -Value 0 -Force | Out-Null
            New-ItemProperty -Path $subKeyPath -Name "URL"       -PropertyType String -Value $url -Force | Out-Null
            $global:counter++
            Set-ItemProperty -Path $registryBase -Name "ItemCount" -Value $global:counter -Force | Out-Null
            Write-Host "Excluded folder $counter : $($folder.FullName)" -ForegroundColor Green
        } else {
            Recur-Search -path $folder.FullName
        }
    }
}

$registryBase = "HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSetRules"
$searchRoots = "HKLM:\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\SearchRoots"
$volumeLetter = "E:\"
$defaultGuid = "98da7f83-099d-4591-afed-be354bdaf82b"
$guid = Get-Root-Guid
$global:counter = 0

Service-Stop
Clean-Init
#Default-Search -path "Microsoft Outlook" -url "csc://{S-1-5-21-2626148534-851844826-3743222949-1001}/" -isDefault 1
#Default-Search -path "Microsoft Outlook" -url "mapi16://{S-1-5-21-2626148534-851844826-3743222949-1001}/" -isDefault 0
Default-Search -path "$volumeLetter" -url "file:///$volumeLetter[$guid]\" -isDefault 0
Recur-Search -path "$volumeLetter"
Service-Start
