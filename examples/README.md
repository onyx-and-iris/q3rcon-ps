# Use

These examples load connection info from a file `config.psd1` placed next to the script files.

```psd1
@{
    host   = "hostname.server"
    port   = 28960
    passwd = "strongrconpassword"
}
```

Run them with -Debug flag for debug output.

For example: `pwsh.exe .\cli.ps1 -Debug`
