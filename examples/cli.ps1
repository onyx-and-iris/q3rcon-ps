[cmdletbinding()]
param()

Import-Module ../lib/Q3Rcon.psm1

Function Read-HostUntilEmpty {
    param([object]$rcon)

    "Input 'Q' or <Enter> to exit."
    while (($line = Read-Host -Prompt "Send command") -cne [string]::Empty) {
        if ($line -eq "Q") {
            break
        }

        if ($line -in @("fast_restart", "map_rotate", "map_restart")) {
            $cmd = $line -replace '(?:^|_)(\p{L})', { $_.Groups[1].Value.ToUpper() }
            $rcon.$cmd()
        }
        elseif ($line.StartsWith("map mp_")) {
            $mapname = $line.Split()[1]
            $rcon.SetMap($mapname)
        }
        else {
            $rcon.Send($line)
        }
    }
}

Function Get-ConnFromPSD1 {
    $configpath = Join-Path $PSScriptRoot "config.psd1"
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
