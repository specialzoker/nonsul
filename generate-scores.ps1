# scores.xlsx -> scores.js 변환 스크립트 (대학별 시트 → 학과별 논술점수)
# 각 시트 = 대학 1곳, A열 학과명 / B열 논술점수 / C열 100점 환산(선택)

$xlsxPath = Join-Path $PSScriptRoot "scores.xlsx"
$jsPath   = Join-Path $PSScriptRoot "scores.js"

if (-not (Test-Path $xlsxPath)) { Write-Host "scores.xlsx 없음"; exit 1 }

# 앱(info.js) 대학명으로 정규화
$NAME_MAP = @{ '한국기술교육대' = '한국기술교대' }

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Open($xlsxPath)

$uniData = [ordered]@{}

foreach ($ws in $wb.Sheets) {
    $uni = $ws.Name.Trim()
    if ($NAME_MAP.ContainsKey($uni)) { $uni = $NAME_MAP[$uni] }
    $lastRow = $ws.UsedRange.Rows.Count

    $list = [System.Collections.Generic.List[object]]::new()
    for ($r = 2; $r -le $lastRow; $r++) {
        $dept = $ws.Cells($r,1).Text.Trim()
        if (-not $dept) { continue }
        $rawTxt = $ws.Cells($r,2).Value2
        if ($null -eq $rawTxt -or "$rawTxt" -eq "") { continue }
        $raw  = [math]::Round([double]$rawTxt, 2)
        $cTxt = $ws.Cells($r,3).Value2
        if ($null -ne $cTxt -and "$cTxt" -ne "") {
            $conv = [math]::Round([double]$cTxt, 2)
        } else {
            $conv = $null
        }
        # [학과명, 논술점수, 100점환산(없으면 null)]
        $list.Add(@($dept, $raw, $conv))
    }
    if ($list.Count -gt 0) { $uniData[$uni] = $list }
}

$wb.Close($false); $excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb)    | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[GC]::Collect()

$json = $uniData | ConvertTo-Json -Depth 5 -Compress
$utf8 = New-Object System.Text.UTF8Encoding $false
$js   = "/* scores.xlsx -> scores.js (generate-scores.ps1 로 갱신) */`nwindow.SCORE_DATA = $json;`n"
[System.IO.File]::WriteAllText($jsPath, $js, $utf8)

$total = ($uniData.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
Write-Host "완료: scores.js ($($uniData.Count)개 대학, $total 개 학과)"
