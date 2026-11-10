# 比對新舊兩個 publish 資料夾，產出正式機異動清單 CSV（可直接用 Excel 開啟）
# 用法：.\產生異動清單.ps1                       （使用下方預設路徑）
#       .\產生異動清單.ps1 -Old "D:\舊版" -New "D:\新版"
#       .\產生異動清單.ps1 -All                  （改為列出新版全部檔案，不比對）
# 注意：本檔需存成 UTF-8 with BOM，否則 Windows PowerShell 5.1 會把中文解錯
param(
  [string] $Old = "C:\Users\User\Desktop\old_IMap",
  [string] $New = "C:\Users\User\Desktop\New_IMap",
  # 預設輸出到腳本所在資料夾
  [string] $Out,
  [switch] $All,
  # 正式機執行期間產生的日誌資料夾，不屬於部署內容
  [string[]] $ExcludeDirs = @("BootstrapLog", "Runtime", "SerilogSelfLog", "Log", "logs")
)

# 任何錯誤（例如資料夾不存在）立即中止，避免產出不完整的清單
$ErrorActionPreference = 'Stop'

function Get-FileMap($root) {
  $root = (Resolve-Path $root).Path.TrimEnd('\')
  Get-ChildItem $root -Recurse -File | Where-Object {
    $ExcludeDirs -notcontains $_.FullName.Substring($root.Length + 1).Split('\')[0]
  } | ForEach-Object {
    [pscustomobject]@{ Path = $_.FullName.Substring($root.Length + 1); Hash = (Get-FileHash $_.FullName).Hash }
  }
}

$i = 0
if ($All) {
  if (-not $Out) {
    $Out = Join-Path $PSScriptRoot "正式機完整檔案清單.csv"
  }
  $rows = Get-FileMap $New | Sort-Object Path | ForEach-Object {
    $i++
    [pscustomobject]@{ 序號 = $i; 檔案位置與名稱 = "IMap\" + $_.Path }
  }
} else {
  if (-not $Out) {
    $Out = Join-Path $PSScriptRoot "正式機異動清單.csv"
  }
  $rows = Compare-Object (Get-FileMap $Old) (Get-FileMap $New) -Property Path, Hash |
    Group-Object Path | Sort-Object Name | ForEach-Object {
      if ($_.Count -eq 2) {
        $type = '修改'
      } elseif ($_.Group[0].SideIndicator -eq '=>') {
        $type = '新增'
      } else {
        $type = '刪除'
      }
      $i++
      [pscustomobject]@{ 序號 = $i; 檔案位置與名稱 = "IMap\" + $_.Name; 異動類型 = $type }
    }
}

# 寫入 UTF-8 with BOM，Excel 開啟中文才不會亂碼
$csv = $rows | ConvertTo-Csv -NoTypeInformation
[IO.File]::WriteAllLines($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out), $csv, [Text.UTF8Encoding]::new($true))
if ($All) {
  "共 $($rows.Count) 筆"
} else {
  $rows | Group-Object 異動類型 | ForEach-Object { "$($_.Name)：$($_.Count) 筆" }
}
"已輸出：$Out"
