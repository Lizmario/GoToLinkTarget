# 移除右键菜单
'HKCU:\Software\Classes\Directory\shell\GoToLinkTarget',
'HKCU:\Software\Classes\Directory\Background\shell\GoToLinkTarget' | ForEach-Object {
    if (Test-Path -LiteralPath $_) { Remove-Item -LiteralPath $_ -Recurse -Force }
}
Write-Host '已卸载右键菜单'
