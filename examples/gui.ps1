[cmdletbinding()]
param()

Import-Module ../lib/Q3Rcon.psm1

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$OKB = New-Object System.Windows.Forms.Button
$OTB = New-Object System.Windows.Forms.TextBox
$CAB = New-Object System.Windows.Forms.Button
$Lbl = New-Object System.Windows.Forms.Label

Function InitForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Q3Rcon Client"
    $form.Size = New-Object System.Drawing.Size(275, 200)
    $form.StartPosition = "CenterScreen"
    return $form  
}

Function AddOkButton {
    param($form, $rcon)

    $OKB.Location = New-Object System.Drawing.Size(65, 100)
    $OKB.Size = New-Object System.Drawing.Size(65, 23)
    $OKB.Text = "Send"
    $OKB.Add_Click({ SendRconCommand -rcon $rcon })
    $form.Controls.Add($OKB)
}

Function AddCloseButton($form) {
    $CAB.Location = New-Object System.Drawing.Size(140, 100)
    $CAB.Size = New-Object System.Drawing.Size(65, 23)
    $CAB.Text = "Close"
    $CAB.Add_Click({ Write-Host "Disconnecting from Rcon" -ForegroundColor Green; $form.Close() })
    $form.Controls.Add($CAB)    
}

Function AddLabel($form) {
    $Lbl.Location = New-Object System.Drawing.Size(10, 20)
    $Lbl.Size = New-Object System.Drawing.Size(260, 20)
    $Lbl.Text = "Input Rcon Command:"
    $form.Controls.Add($Lbl)    
}

Function AddTextBox {
    param($form, $rcon)

    $OTB.Location = New-Object System.Drawing.Size(10, 50)
    $OTB.Size = New-Object System.Drawing.Size(240, 20)
    $OTB.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                SendRconCommand -rcon $rcon
            }
        })
    $form.Controls.Add($OTB)    
}

Function FinalizeForm($form) {
    $form.Topmost = $true
    $form.Add_Shown({ $form.Activate() })    
}

Function SendRconCommand() {
    param($rcon)

    $rcon.Send($OTB.Text)
    $OTB.Text = ""
}


Function Get-ConnFromPSD1 {
    $configpath = Join-Path $PSScriptRoot "config.psd1"
    return Import-PowerShellDataFile -Path $configpath
}

try {
    $conn = Get-ConnFromPSD1
    $rcon = Connect-Rcon -hostname $conn.host -port $conn.port -passwd $conn.passwd
    Write-Host $rcon.base.ToString() -ForegroundColor Green

    $form = InitForm
    AddOkButton -form $form -rcon $rcon
    AddCloseButton($form)
    AddLabel($form)
    AddTextBox -form $form -rcon $rcon
    FinalizeForm($form)

    [void] $form.ShowDialog()
}
finally {
    Disconnect-Rcon -rcon $rcon
}
