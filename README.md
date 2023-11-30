# Q3 Rcon client for Powershell

Send Rcon commands to your Quake-3 Engine server from Powershell!

## Tested against

Currently only tested on COD servers (2, 4 and 5).

## Requirements

- Powershell 7.2+

## Installation

`Install-Module -Name Q3Rcon -Scope CurrentUser`

## Use

```powershell
Import-Module Q3Rcon

try {
    $rcon = Connect-Rcon -hostname "hostname.server" -port 28960 -passwd "strongrconpassword"

    $rcon.Map()

    "Rotating the map..."
    $rcon.MapRotate()

    Start-Sleep -Milliseconds 3000 # wait for map to rotate

    $rcon.Map()
}
finally {
    Disconnect-Rcon -rcon $rcon
}
```

## Rcon Class

### `Send($cmd) | Send($cmd, $timeout)`

Send a RCON command as a string. For example:

```powershell
$rcon.Send("mapname")

$rcon.Send("g_gametype dm")

$rcon.Send("map_rotate", 2000)
```

If the command returns a response it will be printed to the console.

Pass an optional timeout (ms) for commands that return responses in fragments. (status, map_rotate etc...)
