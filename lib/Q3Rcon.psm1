try {
    . (Join-Path $PSScriptRoot packet.ps1)
    . (Join-Path $PSScriptRoot base.ps1)     
}
catch {
    throw "unable to dot source module files"
}


class Rcon {
    [Object]$base

    Rcon ([string]$hostname, [int]$port, [string]$passwd) {
        $this.base = New-Base -hostname $hostname -port $port -passwd $passwd
    }

    [Rcon] _login() {
        $resp = $this.Send("login")
        if ($resp -in @("Bad rcon", "Bad rconpassword.", "Invalid password.")) {
            throw "invalid rcon password"
        }
        $this.base.ToString() | Write-Debug
        return $this
    }

    [string] Send([string]$msg) {
        return $this.base._send($msg)
    }

    [string] Send([string]$msg, [int]$timeout) {
        return $this.base._send($msg, $timeout)
    }

    [void] Say($msg) {
        $this.Send("say $msg")
    }

    [void] FastRestart() {
        $this.Send("fast_restart", 2000)
    }

    [void] MapRotate() {
        $this.Send("map_rotate", 2000)
    }

    [void] MapRestart() {
        $this.Send("map_restart", 2000)
    }

    [string] Map() {
        return $this.Send("mapname")
    }

    [void] SetMap($mapname) {
        $this.Send("map mp_" + $mapname.TrimStart("mp_"), 2000)
    }

    [string] Gametype() {
        return $this.Send("g_gametype")
    }

    [void] SetGametype($gametype) {
        $this.Send("g_gametype $gametype")
    }

    [string] HostName() {
        return $this.Send("sv_hostname")
    }

    [void] SetHostName($hostname) {
        $this.Send("sv_hostname $hostname")
    }
}

Function Connect-Rcon {
    param([string]$hostname, [int]$port, [string]$passwd)

    [Rcon]::new($hostname, $port, $passwd)._login()
}

Function Disconnect-Rcon {
    param([Rcon]$rcon)

    $rcon.base._close()
    "Disconnected from {0}:{1}" -f $rcon.base.hostname, $rcon.base.port | Write-Debug
}

Export-ModuleMember -Function Connect-Rcon, Disconnect-Rcon
