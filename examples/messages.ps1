[cmdletbinding()]
param()

Import-Module ../lib/Q3Rcon.psm1

function Get-ConnFromPSD1 {
    $configpath = Join-Path $PSScriptRoot 'config.psd1'
    return Import-PowerShellDataFile -Path $configpath
}

function Get-DadJoke {
    Invoke-WebRequest -Uri 'https://icanhazdadjoke.com' -Headers @{accept = 'application/json' } | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty Joke
}

function Send-Message {
    param($rcon)

    $msg = Get-DadJoke
    Write-Debug "Sending message: $msg"
    $rcon.Say($msg)
}


try {
    $conn = Get-ConnFromPSD1
    $rcon = Connect-Rcon -hostname $conn.host -port $conn.port -passwd $conn.passwd

    Send-Message -rcon $rcon
}
finally {
    Disconnect-Rcon -rcon $rcon
}
