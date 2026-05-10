# data.xlsx -> info.js 변환 스크립트

$xlsxPath = Join-Path $PSScriptRoot "data.xlsx"
$jsPath   = Join-Path $PSScriptRoot "info.js"

if (-not (Test-Path $xlsxPath)) { Write-Host "data.xlsx 없음"; exit 1 }

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Open($xlsxPath)
$ws = $wb.Sheets(1)
$lastRow = $ws.UsedRange.Rows.Count

$uniData = [ordered]@{}

for ($r = 2; $r -le $lastRow; $r++) {
    $uni = $ws.Cells($r,1).Text.Trim()
    if (-not $uni) { continue }

    $dept = [ordered]@{
        suneung  = $ws.Cells($r,2).Text.Trim()
        dept     = $ws.Cells($r,3).Text.Trim()
        method   = $ws.Cells($r,4).Text.Trim()
        minScore = $ws.Cells($r,5).Text.Trim()
        type     = $ws.Cells($r,6).Text.Trim()
        duration = $ws.Cells($r,7).Text.Trim()
    }

    if (-not $uniData.Contains($uni)) {
        $uniData[$uni] = [System.Collections.Generic.List[object]]::new()
    }
    $uniData[$uni].Add($dept)
}

$wb.Close($false); $excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb)    | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[GC]::Collect()

$json     = $uniData | ConvertTo-Json -Depth 5 -Compress
$utf8     = New-Object System.Text.UTF8Encoding $false
$js       = "/* data.xlsx -> info.js (generate-data.bat 으로 갱신) */`nwindow.INFO_DATA = $json;`n"
[System.IO.File]::WriteAllText($jsPath, $js, $utf8)

Write-Host "완료: info.js ($($uniData.Count)개 대학, $lastRow 행)"
