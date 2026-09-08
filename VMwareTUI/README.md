# VMwareTUI

A terminal management console for VMware **vCenter Server** and **standalone ESXi
hosts**, written in pure PowerShell. Connect by IP, log in once, and manage your
VMs from the keyboard instead of the web client.

No PowerCLI. No modules to install. Runs on the PowerShell that ships with
Windows.

```
 VMware Console  |  192.168.1.50  |  vCenter 8.0.2
 user root   |  health CRITICAL   |  refreshed 17:42:10  |  6 VMs
----------------------------------------------------------------------------------
  [ 1 VMs ]   2 Health    3 Datastores    4 Log
----------------------------------------------------------------------------------
     # NAME                          POWER    vCPU  MEM GB  IP ADDRESS     TOOLS
     1 DC01                          * On        4      16  10.0.0.10       ok
 >   2 FILE01                        o Off       2       8  10.0.0.11       ok
     3 TEST-VM                       = Susp      2       4                  -
----------------------------------------------------------------------------------
 DC01  |  Windows Server 2022  |  4 vCPU / 16 GB  |  on esxi01  |  tools: toolsOk
----------------------------------------------------------------------------------
 O on  S shutdown  R restart  P power-off  E reset  U suspend  / filter  F5  Q quit
```

## Requirements

- Windows PowerShell **5.1** or PowerShell **7+**
- Network access to TCP 443 on the vCenter or ESXi host
- An account with permission to view inventory and change VM power state

## Quick start

```powershell
cd D:\VMwareTUI
.\Start-VMwareTUI.ps1 -Server 192.168.1.50 -SkipCertificateCheck
```

You will be prompted for credentials:

- **ESXi host** — usually `root`
- **vCenter** — usually `administrator@vsphere.local`

Run it with no arguments and it asks for the address too:

```powershell
.\Start-VMwareTUI.ps1
```

If PowerShell blocks the script, unblock it for the current session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## Keys

| Key | Action | | Key | View |
|---|---|---|---|---|
| `↑` `↓` | Move selection | | `1` | Virtual machines |
| `PgUp` `PgDn` | Page | | `2` | Health |
| `Home` `End` | Jump to first / last | | `3` | Datastores |
| `O` | Power on | | `4` | Activity log |
| `S` | Shut down guest (graceful) | | `/` | Filter |
| `R` | Restart guest (graceful) | | `Esc` | Clear filter |
| `U` | Suspend | | `F5` | Refresh now |
| `P` | **Force power off** (confirm) | | `Q` | Quit |
| `E` | **Hard reset** (confirm) | | | |

`S` and `R` ask VMware Tools inside the guest to shut down cleanly. `P` and `E`
act on virtual hardware — the equivalent of pulling the power cord or pressing
reset — so both require a confirmation.

## Certificates

vCenter and ESXi ship with self-signed certificates, so a first connection needs
a decision. Three options, in order of preference:

```powershell
# 1. Best: pin the certificate you expect
.\Start-VMwareTUI.ps1 -Server 192.168.1.50 -CertificateThumbprint AABBCC...

# 2. Convenient: skip validation. Prints the thumbprint so you can switch to (1).
.\Start-VMwareTUI.ps1 -Server 192.168.1.50 -SkipCertificateCheck

# 3. Nothing to do if the host has a certificate your machine already trusts.
.\Start-VMwareTUI.ps1 -Server vcenter.lab.local
```

To read a thumbprint before connecting:

```powershell
Import-Module .\VMwareTUI.psd1
Get-VMwareServerCertificate -ComputerName 192.168.1.50
```

Passwords are held as `SecureString`, converted to plain text only for the
moment it takes to build the login request, and never written to disk or logged.

## Scripting without the TUI

Every capability is a normal cmdlet, so the module is useful in scheduled tasks
too.

```powershell
Import-Module .\VMwareTUI.psd1

$c = Connect-VMwareServer -Server 192.168.1.50 -SkipCertificateCheck

# What is wrong right now?
$report = Get-VMwareHealthReport -Connection $c
if ($report.Verdict -ne 'Ok') { $report.Findings | Format-Table Severity, Subject, Message }

# Inventory
Get-VMwareVM -Connection $c | Where-Object PowerState -eq 'poweredOn' | Format-Table Name, IPAddress, MemoryGB
Get-VMwareHost -Connection $c | Format-Table Name, CpuPercent, MemoryPercent, UptimeText
Get-VMwareDatastore -Connection $c | Sort-Object UsedPercent -Descending

# Restart one VM and wait for it
Get-VMwareVM -Connection $c -Name 'TEST-VM' |
    Invoke-VMwareVMPower -Connection $c -Action Restart

Disconnect-VMwareServer -Connection $c
```

### Cmdlets

| Cmdlet | Purpose |
|---|---|
| `Connect-VMwareServer` | Log in to vCenter or ESXi |
| `Disconnect-VMwareServer` | Log out and release the session |
| `Test-VMwareConnection` | Is the session still valid? |
| `Get-VMwareVM` | List VMs with power state, sizing, guest IP, Tools |
| `Get-VMwareHost` | List hosts with CPU/memory/uptime/status |
| `Get-VMwareDatastore` | List datastores with capacity and free space |
| `Get-VMwareHealthReport` | Evaluate everything and return a verdict |
| `Invoke-VMwareVMPower` | On / Off / Reset / Suspend / Shutdown / Restart |
| `Wait-VMwareTask` | Block until a vSphere task finishes |
| `Show-VMwareConsole` | Launch the TUI against an existing connection |
| `Get-VMwareServerCertificate` | Inspect a host's TLS certificate |

## How it talks to vSphere

It uses the **vSphere Web Services API** (SOAP, at `https://host/sdk`).

That choice is deliberate. The newer vSphere Automation REST API
(`/api/vcenter/...`) is only served by vCenter — a standalone ESXi host does not
have it. The SOAP API is present on *both*, so one code path covers vCenter and
free ESXi alike. The module reports which one answered via
`about.apiType`, and the TUI adapts (the host column only appears under vCenter).

## Health rules

| Check | Warning | Critical |
|---|---|---|
| Host CPU | ≥ 75% | ≥ 90% |
| Host memory | ≥ 85% | ≥ 95% |
| Datastore used | ≥ 85% | ≥ 95% |
| Host overall status | `yellow` | `red` |
| Host connection state | — | not `connected` |
| Datastore accessible | — | inaccessible |
| Maintenance mode | on | — |
| VMware Tools missing on a running VM | yes | — |

The worst finding becomes the overall verdict.

## Tests

108 unit tests, no external dependencies:

```powershell
pwsh -File .\tests\Run-Tests.ps1
# or on Windows PowerShell
powershell -File .\tests\Run-Tests.ps1
```

They cover the SOAP envelope construction and response parsing (against captured
vSphere payloads), the health rules, and the layout maths — scrolling, column
fitting, bar drawing — which is where off-by-one bugs hide. Exits non-zero on
failure, so it can gate CI.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `Cannot complete login due to an incorrect user name or password` | Wrong credentials. vCenter usually wants the full UPN, e.g. `administrator@vsphere.local`. |
| `The underlying connection was closed` on 5.1 | Old TLS default. The module raises TLS 1.2 automatically; if it persists, the host may only offer TLS 1.3. |
| Escape sequences printed as text | Legacy console without VT support. Run with `-Ascii`, or use Windows Terminal. |
| `VMware Tools is not running ... so a graceful restart is not possible` | Install VMware Tools in the guest, or use `-Force` / the `P`/`E` keys to act on virtual hardware. |
| Boxes render as `?` or garbage | Code page issue. Run with `-Ascii`. |
| Certificate thumbprint mismatch | The host certificate changed — or something is intercepting. Verify before overriding. |
