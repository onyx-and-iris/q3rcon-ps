try {
    . (Join-Path $PSScriptRoot packet.ps1)
    . (Join-Path $PSScriptRoot base.ps1)     
}
catch {
    throw 'unable to dot source module files'
}


class Rcon {
    static [hashtable]$DefaultTimeouts = @{
        'map'          = 2000
        'map_rotate'   = 2000
        'map_restart'  = 2000
        'fast_restart' = 2000
    }

    [Object]$base
    [hashtable]$timeouts

    Rcon ([string]$hostname, [int]$port, [string]$passwd, [hashtable]$timeouts = $null) {
        $this.base = New-Base -hostname $hostname -port $port -passwd $passwd
        $this.timeouts = $timeouts ?? [Rcon]::DefaultTimeouts
    }

    [Rcon] _login() {
        $resp = $this.Send('login')
        if ($resp -in @('Bad rcon', 'Bad rconpassword.', 'Invalid password.')) {
            throw 'invalid rcon password'
        }
        $this.base.ToString() | Write-Debug
        return $this
    }

    [string] Send([string]$cmd) {
        $key = $cmd.Split()[0]
        if ($this.timeouts.ContainsKey($key)) {
            return $this.base._send($cmd, $this.timeouts[$key])
        }
        return $this.base._send($cmd)
    }

    [void] Say($msg) {
        $this.Send("say $msg")
    }

    [void] FastRestart() {
        $this.Send('fast_restart')
    }

    [void] MapRotate() {
        $this.Send('map_rotate')
    }

    [void] MapRestart() {
        $this.Send('map_restart')
    }

    [string] Map() {
        return $this.Send('mapname')
    }

    [void] SetMap($mapname) {
        $this.Send('map mp_' + $mapname.TrimStart('mp_'))
    }

    [string] Gametype() {
        return $this.Send('g_gametype')
    }

    [void] SetGametype($gametype) {
        $this.Send('g_gametype', $gametype)
    }

    [string] HostName() {
        return $this.Send('sv_hostname')
    }

    [void] SetHostName($hostname) {
        $this.Send('sv_hostname', $hostname)
    }
}

function Connect-Rcon {
    param([string]$hostname, [int]$port, [string]$passwd, [Parameter(Mandatory = $false)][hashtable]$timeouts)

    [Rcon]::new($hostname, $port, $passwd, $timeouts)._login()
}

function Disconnect-Rcon {
    param([Rcon]$rcon)

    if ($rcon -and $rcon.base) {
        $rcon.base.Dispose()
        'Disconnected from {0}:{1}' -f $rcon.base.hostname, $rcon.base.port | Write-Debug
    }
}

Export-ModuleMember -Function Connect-Rcon, Disconnect-Rcon
