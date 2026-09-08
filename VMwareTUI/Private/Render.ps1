# Terminal rendering primitives.
#
# The layout maths here (viewport scrolling, cell truncation, bar drawing) is
# deliberately kept as pure functions so it can be unit tested without a
# terminal attached - that is where the off-by-one bugs live.

$script:VMwareAnsiEnabled = $false

$script:VMwareColor = @{
    Reset     = "$([char]27)[0m"
    Bold      = "$([char]27)[1m"
    Dim       = "$([char]27)[2m"
    Reverse   = "$([char]27)[7m"
    Red       = "$([char]27)[91m"
    Green     = "$([char]27)[92m"
    Yellow    = "$([char]27)[93m"
    Blue      = "$([char]27)[94m"
    Magenta   = "$([char]27)[95m"
    Cyan      = "$([char]27)[96m"
    White     = "$([char]27)[97m"
    Grey      = "$([char]27)[90m"
    BgBlue    = "$([char]27)[44m"
    BgRed     = "$([char]27)[41m"
}

$script:VMwareBoxUnicode = @{
    TopLeft = '+'; TopRight = '+'; BottomLeft = '+'; BottomRight = '+'
    Horizontal = '-'; Vertical = '|'; LeftTee = '+'; RightTee = '+'
}

function Test-VMwareWindows {
    $var = Get-Variable -Name 'IsWindows' -ErrorAction SilentlyContinue
    if ($var) { return [bool]$var.Value }
    return $true   # Windows PowerShell 5.1 only exists on Windows.
}

function Enable-VMwareVirtualTerminal {
    <#
        .SYNOPSIS
            Turns on ANSI escape processing in the legacy Windows console.
        .DESCRIPTION
            Windows Terminal and PowerShell 7 handle this already, but
            conhost.exe under Windows PowerShell 5.1 needs
            ENABLE_VIRTUAL_TERMINAL_PROCESSING set explicitly or the screen
            fills with raw escape sequences.
    #>
    [CmdletBinding()]
    param()

    if ($script:VMwareAnsiEnabled) { return $true }

    if (-not (Test-VMwareWindows)) {
        $script:VMwareAnsiEnabled = $true
        return $true
    }

    try {
        if (-not ('VMwareTui.NativeConsole' -as [type])) {
            Add-Type -Namespace 'VMwareTui' -Name 'NativeConsole' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern System.IntPtr GetStdHandle(int nStdHandle);

[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out uint lpMode);

[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, uint dwMode);
'@ -ErrorAction Stop
        }

        $handle = [VMwareTui.NativeConsole]::GetStdHandle(-11)   # STD_OUTPUT_HANDLE
        $mode = 0
        if ([VMwareTui.NativeConsole]::GetConsoleMode($handle, [ref]$mode)) {
            $null = [VMwareTui.NativeConsole]::SetConsoleMode($handle, $mode -bor 0x0004)
            $script:VMwareAnsiEnabled = $true
            return $true
        }
    } catch {
        Write-Verbose "Could not enable virtual terminal processing: $($_.Exception.Message)"
    }

    return $false
}

function Get-VMwareBoxChars {
    <#
        .SYNOPSIS
            Box-drawing glyphs, falling back to ASCII when the console cannot
            render Unicode (raw conhost with a legacy code page).
    #>
    [CmdletBinding()]
    param([switch]$Ascii)

    if ($Ascii) { return $script:VMwareBoxUnicode }

    return @{
        TopLeft     = [char]0x250C   # top-left corner
        TopRight    = [char]0x2510
        BottomLeft  = [char]0x2514
        BottomRight = [char]0x2518
        Horizontal  = [char]0x2500
        Vertical    = [char]0x2502
        LeftTee     = [char]0x251C
        RightTee    = [char]0x2524
    }
}

function Format-VMwareCell {
    <#
        .SYNOPSIS
            Fits text into a fixed-width column, padding or truncating.
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()][AllowEmptyString()]$Text,
        [Parameter(Mandatory)][int]$Width,
        [ValidateSet('Left', 'Right')][string]$Align = 'Left'
    )

    if ($Width -le 0) { return '' }

    $value = if ($null -eq $Text) { '' } else { [string]$Text }

    if ($value.Length -gt $Width) {
        if ($Width -eq 1) { return $value.Substring(0, 1) }
        return $value.Substring(0, $Width - 1) + '~'
    }

    if ($Align -eq 'Right') { return $value.PadLeft($Width) }
    return $value.PadRight($Width)
}

function Get-VMwareViewportWindow {
    <#
        .SYNOPSIS
            Works out which slice of a list to draw so the selected row stays
            visible, keeping it centred where possible.
        .OUTPUTS
            Object with StartIndex and Count.
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$ItemCount,
        [Parameter(Mandatory)][int]$SelectedIndex,
        [Parameter(Mandatory)][int]$Height
    )

    if ($ItemCount -le 0 -or $Height -le 0) {
        return [pscustomobject]@{ StartIndex = 0; Count = 0 }
    }

    if ($ItemCount -le $Height) {
        return [pscustomobject]@{ StartIndex = 0; Count = $ItemCount }
    }

    if ($SelectedIndex -lt 0) { $SelectedIndex = 0 }
    if ($SelectedIndex -ge $ItemCount) { $SelectedIndex = $ItemCount - 1 }

    $start = $SelectedIndex - [math]::Floor($Height / 2)
    if ($start -lt 0) { $start = 0 }

    $maxStart = $ItemCount - $Height
    if ($start -gt $maxStart) { $start = $maxStart }

    return [pscustomobject]@{ StartIndex = [int]$start; Count = $Height }
}

function New-VMwareBar {
    <#
        .SYNOPSIS
            Renders a percentage as a fixed-width text bar.
        .NOTES
            Pure function - covered by the unit tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][double]$Percent,
        [int]$Width = 10,
        [char]$Filled = '#',
        [char]$Empty = '.'
    )

    if ($Width -le 0) { return '' }

    $value = $Percent
    if ($value -lt 0)   { $value = 0 }
    if ($value -gt 100) { $value = 100 }

    $filledCount = [int][math]::Round(($value / 100) * $Width)
    if ($filledCount -gt $Width) { $filledCount = $Width }
    if ($filledCount -lt 0) { $filledCount = 0 }

    return ([string]$Filled * $filledCount) + ([string]$Empty * ($Width - $filledCount))
}

function Get-VMwarePowerGlyph {
    <#
        .SYNOPSIS
            Colour and symbol for a VM power state.
    #>
    [CmdletBinding()]
    param([string]$PowerState, [switch]$Ascii)

    switch ($PowerState) {
        'poweredOn'  { return @{ Text = 'On';      Color = $script:VMwareColor.Green;  Glyph = $(if ($Ascii) { '*' } else { [char]0x25CF }) } }
        'poweredOff' { return @{ Text = 'Off';     Color = $script:VMwareColor.Grey;   Glyph = $(if ($Ascii) { 'o' } else { [char]0x25CB }) } }
        'suspended'  { return @{ Text = 'Susp';    Color = $script:VMwareColor.Yellow; Glyph = $(if ($Ascii) { '=' } else { [char]0x25D0 }) } }
        default      { return @{ Text = 'Unknown'; Color = $script:VMwareColor.Grey;   Glyph = '?' } }
    }
}

function Get-VMwareSeverityColor {
    [CmdletBinding()]
    param([string]$Severity)

    switch ($Severity) {
        'Critical' { return $script:VMwareColor.Red }
        'Warning'  { return $script:VMwareColor.Yellow }
        'Ok'       { return $script:VMwareColor.Green }
        default    { return $script:VMwareColor.Grey }
    }
}
