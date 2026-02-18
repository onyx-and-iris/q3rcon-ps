[cmdletbinding()]
param()

Import-Module ../lib/Q3Rcon.psm1

function Read-HostUntilEmpty {
    param([object]$rcon)

    "Input 'Q' or <Enter> to exit."
    while (($line = Read-Host -Prompt 'Send command') -cne [string]::Empty) {
        if ($line -eq 'Q') {
            break
        }

        $resp = $rcon.Send($line)
        Write-Host (Remove-ColourCodes $resp)
    }
}

function Remove-ColourCodes($str) {
    return $str -replace '\^[0-9]', ''
}

function Get-ConnFromPSD1 {
    $configpath = Join-Path $PSScriptRoot 'config.psd1'
    return Import-PowerShellDataFile -Path $configpath
}


try {
    $conn = Get-ConnFromPSD1
    $rcon = Connect-Rcon -hostname $conn.host -port $conn.port -passwd $conn.passwd
    Read-HostUntilEmpty -rcon $rcon
}
finally {
    Disconnect-Rcon -rcon $rcon
}
