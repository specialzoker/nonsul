# raw.csv -> data.js 변환 스크립트
# 매년 raw.csv 교체 후 generate-data.bat 을 실행하면 data.js 가 갱신됩니다.

$csvPath = Join-Path $PSScriptRoot "raw.csv"
$jsPath  = Join-Path $PSScriptRoot "data.js"

$content = [System.IO.File]::ReadAllText($csvPath, [System.Text.Encoding]::UTF8)

# BOM 제거
if ($content.Length -gt 0 -and [int][char]$content[0] -eq 65279) {
    $content = $content.Substring(1)
}

# 문자 단위 JSON 문자열 이스케이프 (PowerShell ConvertTo-Json 우회)
$sb = New-Object System.Text.StringBuilder($content.Length * 2)
[void]$sb.Append('"')
foreach ($c in $content.ToCharArray()) {
    switch ([int]$c) {
        34  { [void]$sb.Append('\"') }
        92  { [void]$sb.Append('\\') }
        10  { [void]$sb.Append('\n') }
        13  { [void]$sb.Append('\r') }
        9   { [void]$sb.Append('\t') }
        default {
            if ([int]$c -lt 32) { [void]$sb.Append('\u{0:x4}' -f [int]$c) }
            else { [void]$sb.Append($c) }
        }
    }
}
[void]$sb.Append('"')
$json = $sb.ToString()

$header = "/* raw.csv -> data.js (generate-data.bat 실행으로 갱신) */"
$js = "$header`nwindow.RAW_CSV_DATA = $json;`n"

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($jsPath, $js, $utf8NoBom)

$kb = [Math]::Round((Get-Item $jsPath).Length / 1024, 1)
Write-Host "완료: data.js 생성 ($kb KB)"
