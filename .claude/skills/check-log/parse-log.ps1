<#
.SYNOPSIS
    Parse a Project Zomboid console log for Warehouse Operator [WHO] markers and Lua errors.
.DESCRIPTION
    Reads the PZ console log, groups [WHO] lines into load markers / state
    transitions / collapsed Quest-Check spam, and extracts any Lua error blocks.
    Read-only. Prints a compact report to stdout for /check-log to summarize.
.PARAMETER Path
    Log file to read. Defaults to %USERPROFILE%\Zomboid\console.txt.
.PARAMETER Tail
    Lines of context to keep around an error line. Default 8.
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path $env:USERPROFILE 'Zomboid\console.txt'),
    [int]$Tail = 8
)

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Output "ERROR: log not found at $Path"
    Write-Output "Hint: archived sessions live under $env:USERPROFILE\Zomboid\Logs\."
    exit 0
}

$lines = Get-Content -LiteralPath $Path
Write-Output "=== console: $Path ($($lines.Count) lines) ==="
Write-Output ""

# --- [WHO] markers, classified ---------------------------------------------
$who = $lines | Where-Object { $_ -match '\[WHO\]' }

# Strip the "LOG  : Lua  f:NNNN>" prefix for readability, keep the frame number.
function Clean([string]$l) {
    if ($l -match 'f:(\d+)>\s*(\[WHO\].*)$') { return ("f:{0,-6} {1}" -f $Matches[1], $Matches[2].TrimEnd()) }
    return $l.TrimEnd()
}

$loadMarkers = @()
$transitions = @()
$questChecks = @()

foreach ($l in $who) {
    if ($l -match 'Quest-Check:') { $questChecks += (Clean $l); continue }
    if ($l -match 'loaded|module loaded|Mod version|Build target|boot complete|Terminal UI module') {
        $loadMarkers += (Clean $l); continue
    }
    # everything else = a state transition / action worth seeing
    $transitions += (Clean $l)
}

Write-Output "--- LOAD MARKERS ($($loadMarkers.Count)) ---"
if ($loadMarkers) { $loadMarkers | ForEach-Object { Write-Output $_ } } else { Write-Output "(none - file may not have loaded)" }
Write-Output ""

Write-Output "--- STATE / ACTIONS ($($transitions.Count)) ---"
if ($transitions) { $transitions | ForEach-Object { Write-Output $_ } } else { Write-Output "(none)" }
Write-Output ""

Write-Output "--- QUEST-CHECK (collapsed, $($questChecks.Count) total) ---"
if ($questChecks.Count -gt 0) {
    Write-Output ("first: " + $questChecks[0])
    if ($questChecks.Count -gt 1) { Write-Output ("last:  " + $questChecks[-1]) }
} else { Write-Output "(none)" }
Write-Output ""

# --- Lua errors / stack traces ---------------------------------------------
# Real errors only: an ERROR-severity line, a thrown exception, a Java frame, or
# a Lua stack traceback. Deliberately NOT matching WARN / "at X.Y" info lines --
# PZ emits hundreds of benign vanilla warnings that would drown a real mod crash.
$errPattern = '(^|>\s*|:\s*)ERROR\b|Exception|stack traceback|java\.lang|caused by'
# Lines that tie an error to THIS mod (vs. vanilla/engine noise). Intentionally
# specific -- a bare "\.lua" would match vanilla map paths (e.g. objects.lua).
# PZ tags mod Lua errors as Lua(WarehouseOperator) and traces reference WHO_*.lua.
$modPattern = 'WHO_|WarehouseOperator|InventoryItemFactory|setAlcoholPower'

$errIdx = for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match $errPattern) { $i } }

Write-Output "--- ERRORS / STACK TRACES ---"
if (-not $errIdx) {
    Write-Output "(none - clean run, no ERROR/Exception lines)"
} else {
    $modIdx   = @($errIdx | Where-Object { $lines[$_] -match $modPattern })
    $otherIdx = @($errIdx | Where-Object { $lines[$_] -notmatch $modPattern })

    Write-Output "MOD-RELATED ($($modIdx.Count)):"
    if (-not $modIdx) {
        Write-Output "  (none referencing WHO_ / WarehouseOperator / item factory)"
    } else {
        # Print each with a context window so a stack trace reads in full.
        $printed = New-Object System.Collections.Generic.HashSet[int]
        foreach ($i in $modIdx) {
            $start = [Math]::Max(0, $i - 2)
            $end   = [Math]::Min($lines.Count - 1, $i + $Tail)
            $block = $false
            for ($j = $start; $j -le $end; $j++) {
                if ($printed.Add($j)) {
                    if (-not $block) { Write-Output "  ----"; $block = $true }
                    Write-Output ("  " + $lines[$j].TrimEnd())
                }
            }
        }
    }

    Write-Output ""
    Write-Output "OTHER / ENGINE ($($otherIdx.Count), likely unrelated to this mod):"
    if (-not $otherIdx) {
        Write-Output "  (none)"
    } else {
        # Compact: one line each, no context window.
        foreach ($i in $otherIdx) { Write-Output ("  " + $lines[$i].TrimEnd()) }
    }
}
