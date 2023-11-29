. $PSScriptRoot\packet.ps1
. $PSScriptRoot\base.ps1    


class Rcon {
    [Object]$base

    Rcon ([string]$hostname, [int]$port, [string]$passwd) {
        $this.base = New-Base -hostname $hostname -port $port -passwd $passwd
    }

    [Rcon] Login() {
        $resp = $this.base._send("login")
        if ($resp -in @("Bad rcon", "Bad rconpassword.", "Invalid password.")) {
            throw "invalid rcon password"
        }
        $this.base.ToString() | Write-Debug
        return $this
    }

    [string] Send($msg) {
        return $this.base._send($msg)
    }

    [void] Say($msg) {
        $this.base._send($msg)
    }

    [void] FastRestart() {
        $this.base._send("fast_restart", 2000)
    }

    [void] MapRotate() {
        $this.base._send("map_rotate", 2000)
    }

    [void] MapRestart() {
        $this.base._send("map_restart", 2000)
    }

    [string] Map() {
        return $this.base._send("mapname")
    }

    [void] SetMap($mapname) {
        $this.base._send("map mp_$mapname")
    }

    [string] Gametype() {
        return $this.base._send("g_gametype")
    }

    [void] SetGametype($gametype) {
        $this.base._send("g_gametype $gametype")
    }

    [string] HostName() {
        return $this.base._send("sv_hostname")
    }

    [void] SetHostName($hostname) {
        $this.base._send("sv_hostname $hostname")
    }
}

Function Connect-Rcon {
    param([string]$hostname, [int]$port, [string]$passwd)

    [Rcon]::new($hostname, $port, $passwd).Login()
}

Function Disconnect-Rcon {
    param([Rcon]$rcon)

    $rcon.base._close()
    "Disconnected from {0}:{1}" -f $rcon.base.hostname, $rcon.base.port | Write-Debug
}

Export-ModuleMember -Function Connect-Rcon, Disconnect-Rcon
