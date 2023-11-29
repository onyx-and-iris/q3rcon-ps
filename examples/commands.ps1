[cmdletbinding()]
param()

Import-Module ../lib/Q3Rcon.psm1

Function Get-ConnFromPSD1 {
    $configpath = Join-Path $PSScriptRoot "config.psd1"
    return Import-PowerShellDataFile -Path $configpath
}

try {
    $conn = Get-ConnFromPSD1
    $rcon = Connect-Rcon -hostname $conn.host -port $conn.port -passwd $conn.passwd
    
    $rcon.Map()

    "Rotating the map..."
    $rcon.MapRotate()

    Start-Sleep -Milliseconds 3000 # wait for map to rotate

    $rcon.Map()
}
finally {
    Disconnect-Rcon -rcon $rcon
}
