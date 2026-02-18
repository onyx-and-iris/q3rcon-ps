class Base {
    static [int]$DEFAULT_RECEIVE_TIMEOUT = 100
    static [int]$DEFAULT_BUFFER_SIZE = 4096
    static [int]$DEFAULT_SEND_TIMEOUT = 5000

    [string]$hostname
    [int]$port
    [string]$passwd
    [Object]$request
    [Object]$response
    hidden [System.Net.Sockets.Socket] $_socket
    hidden [bool]$_disposed = $false
    hidden [byte[]]$_receiveBuffer

    Base ([string]$hostname, [int]$port, [string]$passwd) {
        if ([string]::IsNullOrWhiteSpace($hostname)) {
            throw [System.ArgumentException]::new('Hostname cannot be null or empty', 'hostname')
        }
        if ($port -le 0 -or $port -gt 65535) {
            throw [System.ArgumentOutOfRangeException]::new('port', 'Port must be between 1-65535')
        }
        if ([string]::IsNullOrWhiteSpace($passwd)) {
            throw [System.ArgumentException]::new('Password cannot be null or empty', 'passwd')
        }

        $this.hostname = $hostname
        $this.port = $port
        $this.passwd = $passwd

        $this.request = New-RequestPacket($this.passwd)
        $this.response = New-ResponsePacket
        $this._receiveBuffer = [byte[]]::new([Base]::DEFAULT_BUFFER_SIZE)

        $this._InitializeConnection()
    }

    hidden [void] _InitializeConnection() {
        try {
            $hostEntry = [System.Net.Dns]::GetHostEntry($this.hostname)
            if ($hostEntry.AddressList.Length -eq 0) {
                throw [System.Net.Sockets.SocketException]::new([int][System.Net.Sockets.SocketError]::HostNotFound)
            }
            
            $ipv4Address = $hostEntry.AddressList | Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } | Select-Object -First 1
            if (-not $ipv4Address) {
                throw [System.InvalidOperationException]::new("No IPv4 address found for hostname: $($this.hostname)")
            }

            $endpoint = [System.Net.IPEndPoint]::new($ipv4Address, $this.port)
            
            $this._socket = [System.Net.Sockets.Socket]::new(
                [System.Net.Sockets.AddressFamily]::InterNetwork,
                [System.Net.Sockets.SocketType]::Dgram,
                [System.Net.Sockets.ProtocolType]::UDP
            )
            
            $this._socket.Connect($endpoint)
            $this._socket.ReceiveTimeout = [Base]::DEFAULT_RECEIVE_TIMEOUT
            $this._socket.SendTimeout = [Base]::DEFAULT_SEND_TIMEOUT
        }
        catch [System.Net.Sockets.SocketException] {
            $this._Cleanup()
            throw [System.InvalidOperationException]::new(
                "Failed to create UDP connection to $($this.hostname):$($this.port). Error: $($_.Exception.Message)", 
                $_.Exception
            )
        }
        catch {
            $this._Cleanup()
            throw [System.InvalidOperationException]::new(
                "Failed to initialize connection to $($this.hostname):$($this.port). Error: $($_.Exception.Message)", 
                $_.Exception
            )
        }
    }

    hidden [void] _ThrowIfDisposed() {
        if ($this._disposed) {
            throw [System.ObjectDisposedException]::new($this.GetType().Name)
        }
    }

    hidden [bool] _IsConnected() {
        return $this._socket -and -not $this._disposed -and $this._socket.Connected
    }

    [string] ToString () {
        $status = if ($this._IsConnected()) { 'Connected' } else { 'Disconnected' }
        return 'Rcon connection {0}:{1} ({2})' -f $this.hostname, $this.port, $status
    }

    [string] _send([string]$msg) {
        return $this._send($msg, [Base]::DEFAULT_RECEIVE_TIMEOUT)
    }

    [string] _send([string]$msg, [int]$timeout) {
        if ([string]::IsNullOrEmpty($msg)) {
            throw [System.ArgumentException]::new('Message cannot be null or empty', 'msg')
        }
        if ($timeout -le 0) {
            throw [System.ArgumentOutOfRangeException]::new('timeout', 'Timeout must be positive')
        }

        $this._ThrowIfDisposed()
        
        if (-not $this._IsConnected()) {
            throw [System.InvalidOperationException]::new('Socket is not connected')
        }

        try {
            $payload = $this.request.Payload($msg)
            $bytesSent = $this._socket.Send($payload)
            if ($bytesSent -ne $payload.Length) {
                Write-Warning "Not all bytes were sent. Expected: $($payload.Length), Sent: $bytesSent"
            }

            $responseData = [System.Text.StringBuilder]::new()
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $headerLength = $this.response.Header().Length
            
            do {
                try {
                    $bytesReceived = $this._socket.Receive($this._receiveBuffer)
                    if ($bytesReceived -gt 0) {
                        $dataStartIndex = [Math]::Min($headerLength - 1, $bytesReceived)
                        $responseText = [System.Text.Encoding]::ASCII.GetString($this._receiveBuffer, $dataStartIndex, $bytesReceived - $dataStartIndex)
                        $responseData.Append($responseText) | Out-Null
                    }
                }
                catch [System.Net.Sockets.SocketException] {
                    if ($_.Exception.SocketErrorCode -eq 'TimedOut') {
                        Write-Debug 'Socket receive timeout - continuing to wait for more data'
                        continue
                    }
                    else {
                        throw [System.InvalidOperationException]::new(
                            "Socket error during receive: $($_.Exception.Message)", 
                            $_.Exception
                        )
                    }
                }
            } while ($sw.ElapsedMilliseconds -lt $timeout)
            
            $sw.Stop()
            return $responseData.ToString()
        }
        catch [System.Net.Sockets.SocketException] {
            throw [System.InvalidOperationException]::new(
                "Network error during send/receive: $($_.Exception.Message)", 
                $_.Exception
            )
        }
    }

    hidden [void] _Cleanup() {
        if ($this._socket) {
            try {
                if ($this._socket.Connected) {
                    $this._socket.Shutdown([System.Net.Sockets.SocketShutdown]::Both)
                }
            }
            catch {
                Write-Debug "Error during socket shutdown: $($_.Exception.Message)"
            }
            finally {
                $this._socket.Close()
                $this._socket = $null
            }
        }
    }

    [void] _close() {
        $this.Dispose()
    }

    # Dispose implementation (following IDisposable pattern)
    [void] Dispose() {
        $this.Dispose($true)
        [System.GC]::SuppressFinalize($this)
    }

    hidden [void] Dispose([bool]$disposing) {
        if (-not $this._disposed) {
            if ($disposing) {
                $this._Cleanup()
            }
            $this._disposed = $true
        }
    }
}

function New-Base {
    param(
        [Parameter(Mandatory)]
        [string]$hostname,
        
        [Parameter(Mandatory)]
        [ValidateRange(1, 65535)]
        [int]$port,
        
        [Parameter(Mandatory)]
        [string]$passwd
    )

    [Base]::new($hostname, $port, $passwd)
}