Describe 'Format-VMwareCell' {

    It 'pads short text to the requested width' {
        Assert-Equal 'ab   ' (Format-VMwareCell 'ab' 5)
    }

    It 'right-aligns when asked' {
        Assert-Equal '   ab' (Format-VMwareCell 'ab' 5 -Align Right)
    }

    It 'truncates long text and marks it with a tilde' {
        Assert-Equal 'abcd~' (Format-VMwareCell 'abcdefghij' 5)
    }

    It 'returns text of exactly the target width untouched' {
        Assert-Equal 'abcde' (Format-VMwareCell 'abcde' 5)
    }

    It 'treats null as empty padding' {
        Assert-Equal '   ' (Format-VMwareCell $null 3)
    }

    It 'returns empty string for a non-positive width' {
        Assert-Equal '' (Format-VMwareCell 'abc' 0)
    }

    It 'handles a width of one without an out-of-range error' {
        Assert-Equal 'a' (Format-VMwareCell 'abcdef' 1)
    }
}

Describe 'Get-VMwareViewportWindow' {

    It 'shows the whole list when it fits' {
        $w = Get-VMwareViewportWindow -ItemCount 5 -SelectedIndex 0 -Height 10
        Assert-Equal 0 $w.StartIndex
        Assert-Equal 5 $w.Count
    }

    It 'starts at zero while the selection is near the top' {
        $w = Get-VMwareViewportWindow -ItemCount 100 -SelectedIndex 2 -Height 10
        Assert-Equal 0 $w.StartIndex
        Assert-Equal 10 $w.Count
    }

    It 'centres the selection in the middle of a long list' {
        $w = Get-VMwareViewportWindow -ItemCount 100 -SelectedIndex 50 -Height 10
        Assert-Equal 45 $w.StartIndex
    }

    It 'clamps to the end rather than scrolling past it' {
        $w = Get-VMwareViewportWindow -ItemCount 100 -SelectedIndex 99 -Height 10
        Assert-Equal 90 $w.StartIndex
        Assert-Equal 10 $w.Count
    }

    It 'keeps the last item visible at the end of the list' {
        $w = Get-VMwareViewportWindow -ItemCount 100 -SelectedIndex 99 -Height 10
        Assert-True (99 -ge $w.StartIndex -and 99 -lt ($w.StartIndex + $w.Count)) 'selection must be inside the window'
    }

    It 'returns an empty window for an empty list' {
        $w = Get-VMwareViewportWindow -ItemCount 0 -SelectedIndex 0 -Height 10
        Assert-Equal 0 $w.Count
    }

    It 'survives a selection index below zero' {
        $w = Get-VMwareViewportWindow -ItemCount 50 -SelectedIndex -5 -Height 10
        Assert-Equal 0 $w.StartIndex
    }

    It 'survives a selection index past the end' {
        $w = Get-VMwareViewportWindow -ItemCount 50 -SelectedIndex 999 -Height 10
        Assert-Equal 40 $w.StartIndex
    }

    It 'never produces a negative start index' {
        foreach ($i in 0..20) {
            $w = Get-VMwareViewportWindow -ItemCount 21 -SelectedIndex $i -Height 7
            Assert-True ($w.StartIndex -ge 0) "start index negative at selection $i"
            Assert-True (($w.StartIndex + $w.Count) -le 21) "window overruns the list at selection $i"
        }
    }
}

Describe 'New-VMwareBar' {

    It 'draws an empty bar at zero percent' {
        Assert-Equal '..........' (New-VMwareBar -Percent 0 -Width 10)
    }

    It 'draws a full bar at one hundred percent' {
        Assert-Equal '##########' (New-VMwareBar -Percent 100 -Width 10)
    }

    It 'draws a half bar at fifty percent' {
        Assert-Equal '#####.....' (New-VMwareBar -Percent 50 -Width 10)
    }

    It 'clamps values above one hundred' {
        Assert-Equal '##########' (New-VMwareBar -Percent 250 -Width 10)
    }

    It 'clamps negative values' {
        Assert-Equal '..........' (New-VMwareBar -Percent -20 -Width 10)
    }

    It 'always returns exactly the requested width' {
        foreach ($p in 0, 1, 33, 49, 51, 99, 100) {
            Assert-Equal 16 (New-VMwareBar -Percent $p -Width 16).Length "wrong length at $p%"
        }
    }
}

Describe 'Get-VMwarePowerGlyph' {

    It 'reports On for a powered-on VM' {
        Assert-Equal 'On' (Get-VMwarePowerGlyph -PowerState 'poweredOn').Text
    }

    It 'reports Off for a powered-off VM' {
        Assert-Equal 'Off' (Get-VMwarePowerGlyph -PowerState 'poweredOff').Text
    }

    It 'falls back to Unknown for an unrecognised state' {
        Assert-Equal 'Unknown' (Get-VMwarePowerGlyph -PowerState 'banana').Text
    }
}
