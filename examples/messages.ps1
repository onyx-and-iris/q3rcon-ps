[cmdletbinding()]
param()

Import-Module ../lib/Q3Rcon.psm1

Function Get-ConnFromPSD1 {
    $configpath = Join-Path $PSScriptRoot "config.psd1"
    return Import-PowerShellDataFile -Path $configpath
}

Function Get-DadJoke {
    Invoke-WebRequest -Uri "https://icanhazdadjoke.com" -Headers @{accept = "application/json" } | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty Joke
}

Function Send-Message {
    param($rcon)

    $msg = Get-DadJoke
    $msg | Write-Debug
    $rcon.Say($msg)
}


try {
    $conn = Get-ConnFromPSD1
    $rcon = Connect-Rcon -hostname $conn.host -port $conn.port -passwd $conn.passwd

    $stopWatch = [system.diagnostics.stopwatch]::StartNew()
    $timeSpan = New-TimeSpan -Seconds 30
    do {
        Send-Message -rcon $rcon
        Start-Sleep -Seconds 10
    } until ($stopWatch.Elapsed -ge $timeSpan)

}
finally {
    Disconnect-Rcon -rcon $rcon
}
