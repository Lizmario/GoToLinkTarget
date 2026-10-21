# 注册右键菜单（仅当前用户，无需管理员）
$script = Join-Path $PSScriptRoot 'GoToLinkTarget.ps1'
$label = '跳到链接源文件夹'
$icon = '%SystemRoot%\System32\shell32.dll,4'
$runner = 'conhost.exe --headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File'

$entries = @{
    'HKCU:\Software\Classes\Directory\shell\GoToLinkTarget'            = 'Item'
    'HKCU:\Software\Classes\Directory\Background\shell\GoToLinkTarget' = 'Background'
}

foreach ($key in $entries.Keys) {
    New-Item -Path "$key\command" -Force | Out-Null
    Set-Item -LiteralPath $key -Value $label
    New-ItemProperty -LiteralPath $key -Name 'Icon' -Value $icon -PropertyType ExpandString -Force | Out-Null
    Set-Item -LiteralPath "$key\command" -Value "$runner `"$script`" -Mode $($entries[$key]) -Path `"%V`""
}

Write-Host "已安装：右键文件夹 / 文件夹空白处 →「$label」"
Write-Host 'Win11 新菜单下需点「显示更多选项」或按 Shift+右键 才能看到'
