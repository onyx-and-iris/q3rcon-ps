class Packet {
    [System.Byte[]]$MAGIC = @(, 0xFF * 4)

    [string] Header() {
        throw 'method not implemented'
    }
}

class RequestPacket : Packet {
    [string]$passwd

    RequestPacket([string]$passwd) {
        $this.passwd = $passwd
    }

    [System.Byte[]] Header() {
        return $this.MAGIC + [System.Text.Encoding]::ASCII.GetBytes('rcon')
    }

    [System.Byte[]] Payload([string]$msg) {
        return $this.Header() + [System.Text.Encoding]::ASCII.GetBytes($(' {0} {1}' -f $this.passwd, $msg))
    }
}

class ResponsePacket : Packet {
    [System.Byte[]] Header() {
        return $this.MAGIC + [System.Text.Encoding]::ASCII.GetBytes('print\n')
    }
}

function New-RequestPacket([string]$passwd) {
    [RequestPacket]::new($passwd)
}

function New-ResponsePacket {
    [ResponsePacket]::new()
}
