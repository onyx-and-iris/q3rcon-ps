class Base {
    [string]$hostname
    [int]$port
    [string]$passwd
    [Object]$request
    [Object]$response
    hidden [System.Net.Sockets.Socket] $_socket

    Base ([string]$hostname, [int]$port, [string]$passwd) {
        $this.hostname = $hostname
        $this.port = $port
        $this.passwd = $passwd

        $this.request = New-RequestPacket($this.passwd)
        $this.response = New-ResponsePacket

        $ip = [system.net.IPAddress]::Parse([System.Net.Dns]::GetHostAddresses($this.hostname)[0].IPAddressToString)
        
        $endpoint = New-Object System.Net.IPEndPoint $ip, $this.port 
        try {
            $this._socket = [System.Net.Sockets.Socket]::New(
                [System.Net.Sockets.AddressFamily]::InterNetwork,
                [System.Net.Sockets.SocketType]::Dgram,
                [System.Net.Sockets.ProtocolType]::UDP
            )
            $this._socket.Connect($endpoint)
            $this._socket.ReceiveTimeout = 100
        }
        catch [System.Net.Sockets.SocketException] {
            throw "Failed to create UDP connection to server."          
        }
    }

    [string] ToString () {
        return "Rcon connection {0}:{1} with pass {2}" -f $this.hostname, $this.port, $this.passwd
    }

    [string] _send([string]$msg) {
        $this._socket.Send($this.request.Payload($msg))

        [string[]]$data = @()
        $sw = [Diagnostics.Stopwatch]::StartNew()
        While ($sw.ElapsedMilliseconds -lt 50) {
            try {
                $buf = New-Object System.Byte[] 4096
                $this._socket.Receive($buf)
                $data += [System.Text.Encoding]::ASCII.GetString($($buf | Select-Object -Skip $($this.response.Header().Length - 1)))
            }
            catch [System.Net.Sockets.SocketException] {
                if ( $_.Exception.SocketErrorCode -eq 'TimedOut' ) {
                    "finished waiting for fragment" | Write-Debug
                }
            }
        }
        $sw.Stop()
        return [string]::Join("", $data)
    }

    [string] _send([string]$msg, [int]$timeout) {
        $this._socket.Send($this.request.Payload($msg))

        [string[]]$data = @()
        $sw = [Diagnostics.Stopwatch]::StartNew()
        While ($sw.ElapsedMilliseconds -lt $timeout) {
            try {
                $buf = New-Object System.Byte[] 4096
                $this._socket.Receive($buf)
                $data += [System.Text.Encoding]::ASCII.GetString($($buf | Select-Object -Skip $($this.response.Header().Length - 1)))
            }
            catch [System.Net.Sockets.SocketException] {
                if ( $_.Exception.SocketErrorCode -eq 'TimedOut' ) {
                    "finished waiting for fragment" | Write-Debug
                }
            }
        }
        return [string]::Join("", $data)
    }

    [void] _close() {
        $this._socket.Close()
    }
}

Function New-Base {
    param([string]$hostname, [int]$port, [string]$passwd)

    [Base]::new($hostname, $port, $passwd)
}
