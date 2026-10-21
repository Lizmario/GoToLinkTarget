# 跳到软链接/联接点的源文件夹
# 用法：GoToLinkTarget.ps1 -Mode Item|Background -Path <路径> [-Print]
#   Item       右键某个文件夹：解析该文件夹（自身或任一上级是链接即可）
#   Background 在文件夹空白处右键：解析当前所在文件夹
#   -Print     只输出解析结果，不打开窗口（调试用）
param(
    [ValidateSet('Item', 'Background')][string]$Mode = 'Item',
    [switch]$Print,
    [Parameter(Mandatory)][string]$Path
)

$ErrorActionPreference = 'Stop'

function Show-Message([string]$text) {
    if ($Print) { Write-Output $text; return }
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show($text, '跳到链接源文件夹')
}

# 目录是链接时返回其目标的绝对路径，否则返回 $null
function Get-LinkTarget([IO.DirectoryInfo]$dir) {
    if (-not ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $null }
    $target = @((Get-Item -LiteralPath $dir.FullName -Force).Target)[0]
    if (-not $target) { return $null }
    $target = $target -replace '^\\\?\?\\', ''
    if (-not [IO.Path]::IsPathRooted($target)) { $target = Join-Path $dir.Parent.FullName $target }
    [IO.Path]::GetFullPath($target)
}

# 从路径自身逐级向上找链接，替换后保留子路径；目标若仍含链接则继续解析
function Resolve-RealPath([string]$p) {
    for ($i = 0; $i -lt 32; $i++) {
        $dir = [IO.DirectoryInfo]$p
        $rest = @()
        $hit = $null
        while ($dir) {
            $hit = Get-LinkTarget $dir
            if ($hit) { break }
            $rest = @($dir.Name) + $rest
            $dir = $dir.Parent
        }
        if (-not $hit) { return $p }
        $p = $hit
        foreach ($r in $rest) { $p = Join-Path $p $r }
    }
    throw '链接层级过深或存在循环'
}

try {
    $src = [IO.Path]::GetFullPath($Path.Trim().Trim('"'))
    $real = Resolve-RealPath $src

    if ($real -eq $src) { Show-Message "该路径不在软链接/联接点内：`n$src"; return }
    if (-not (Test-Path -LiteralPath $real)) { Show-Message "链接目标不存在：`n$real"; return }
    if ($Print) { Write-Output $real; return }

    # 优先在发起右键的资源管理器窗口内跳转，找不到再新开窗口
    $windowPath = if ($Mode -eq 'Background') { $src } else { Split-Path $src -Parent }
    $shell = New-Object -ComObject Shell.Application
    foreach ($w in @($shell.Windows())) {
        try { $wp = $w.Document.Folder.Self.Path } catch { continue }
        if ($wp -and $wp.TrimEnd('\') -eq $windowPath.TrimEnd('\')) {
            $w.Navigate2($real)
            return
        }
    }
    Start-Process explorer.exe -ArgumentList "`"$real`""
}
catch {
    Show-Message "解析失败：$($_.Exception.Message)"
}
