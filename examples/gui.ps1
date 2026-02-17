[cmdletbinding()]
param()

Import-Module ../lib/Q3Rcon.psm1

[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')

$OKB = New-Object System.Windows.Forms.Button
$OTB = New-Object System.Windows.Forms.TextBox
$CAB = New-Object System.Windows.Forms.Button
$Lbl = New-Object System.Windows.Forms.Label
$RLbl = New-Object System.Windows.Forms.Label

function New-Form {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Q3Rcon Client'
    $form.Size = New-Object System.Drawing.Size(275, 200)
    $form.StartPosition = 'CenterScreen'
    return $form  
}

function Add-OkButton {
    param($form, $rcon)

    $OKB.Location = New-Object System.Drawing.Size(65, 100)
    $OKB.Size = New-Object System.Drawing.Size(65, 23)
    $OKB.Text = 'Send'
    $OKB.Add_Click({ Send-RconCommand -rcon $rcon })
    $form.Controls.Add($OKB)
}

function Add-CloseButton($form) {
    $CAB.Location = New-Object System.Drawing.Size(140, 100)
    $CAB.Size = New-Object System.Drawing.Size(65, 23)
    $CAB.Text = 'Close'
    $CAB.Add_Click({ Write-Host 'Disconnecting from Rcon' -ForegroundColor Green; $form.Close() })
    $form.Controls.Add($CAB)    
}

function Add-Label($form) {
    $Lbl.Location = New-Object System.Drawing.Size(10, 20)
    $Lbl.Size = New-Object System.Drawing.Size(260, 20)
    $Lbl.Text = 'Input Rcon Command:'
    $form.Controls.Add($Lbl)    
}

function Add-TextBox {
    param($form, $rcon)

    $OTB.Location = New-Object System.Drawing.Size(10, 50)
    $OTB.Size = New-Object System.Drawing.Size(240, 20)
    $OTB.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                Send-RconCommand -rcon $rcon
            }
        })
    $form.Controls.Add($OTB)    
}

function Add-ResponseLabel($form) {
    $RLbl.Location = New-Object System.Drawing.Size(10, 75)
    $RLbl.Size = New-Object System.Drawing.Size(260, 20)
    $RLbl.Text = ''
    $form.Controls.Add($RLbl) 
}

function Start-Form($form) {
    $form.Topmost = $true
    $form.Add_Shown({ $form.Activate() })
    [void] $form.ShowDialog()
}

function Send-RconCommand() {
    param($rcon)

    $line = $OTB.Text
    $line | Write-Debug
    if ($line -in @('fast_restart', 'map_rotate', 'map_restart')) {
        $RLbl.Text = ''
        $cmd = $line -replace '(?:^|_)(\p{L})', { $_.Groups[1].Value.ToUpper() }
        $rcon.$cmd()
    }
    elseif ($line.StartsWith('map mp_')) {
        $RLbl.Text = ''
        $mapname = $line.Split()[1]
        $rcon.SetMap($mapname)
    }
    else {
        $resp = $rcon.Send($line)
    }

    if ($resp -match '^["](?<name>[a-z_]+)["]\sis[:]\s["](?<value>.*?)\^7["]\s') {
        $RLbl.Text = $Matches.name + ': ' + $Matches.value
    }
    $OTB.Text = ''
}


function Get-ConnFromPSD1 {
    $configpath = Join-Path $PSScriptRoot 'config.psd1'
    return Import-PowerShellDataFile -Path $configpath
}

function Main {
    begin {
        $conn = Get-ConnFromPSD1
        $rcon = Connect-Rcon -hostname $conn.host -port $conn.port -passwd $conn.passwd
        Write-Host $rcon.base.ToString() -ForegroundColor Green

        $form = New-Form
        Add-OkButton -form $form -rcon $rcon
        Add-CloseButton($form)
        Add-Label($form)
        Add-ResponseLabel($form)
        Add-TextBox -form $form -rcon $rcon
    }
    process {
        Start-Form($form)
    }
    end {
        Disconnect-Rcon -rcon $rcon
    }    
}


if ($MyInvocation.InvocationName -ne '.') {
    Main
}