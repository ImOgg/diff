# 產生異動清單

比對新舊兩個 publish 資料夾，產出正式機部署用的異動清單 CSV，可以直接用 Excel 開啟。

判斷方式是比對檔案內容的 SHA256 雜湊，不看修改時間。所以重新 publish 但內容沒變的檔案，不會被列為異動。

## 需求

- Windows PowerShell 5.1 以上（Windows 內建）

## 用法

```powershell
# 使用腳本內的預設路徑
.\產生異動清單.ps1

# 指定新舊版資料夾
.\產生異動清單.ps1 -Old "D:\publish\v1.2" -New "D:\publish\v1.3"

# 不比對，列出新版的全部檔案（首次部署用）
.\產生異動清單.ps1 -All -New "D:\publish\v1.3"

# 指定輸出位置
.\產生異動清單.ps1 -Old "D:\舊版" -New "D:\新版" -Out "D:\清單\異動.csv"
```

如果出現「已停用指令碼執行」，請改用：

```powershell
powershell -ExecutionPolicy Bypass -File .\產生異動清單.ps1 -Old "D:\舊版" -New "D:\新版"
```

## 參數

| 參數 | 說明 | 預設值 |
|------|------|--------|
| `-Old` | 舊版（目前正式機）的 publish 資料夾 | `C:\Users\User\Desktop\old_IMap` |
| `-New` | 新版的 publish 資料夾 | `C:\Users\User\Desktop\New_IMap` |
| `-Out` | 輸出的 CSV 路徑 | 腳本所在的資料夾 |
| `-All` | 不比對，改為列出新版的全部檔案 | 關閉 |
| `-ExcludeDirs` | 要排除的**第一層**資料夾名稱 | `BootstrapLog, Runtime, SerilogSelfLog, Log, logs` |

預設路徑是作者本機的路徑，其他人使用時請一律帶上 `-Old`、`-New`。

## 輸出

**比對模式** → `正式機異動清單.csv`

| 序號 | 檔案位置與名稱 | 異動類型 |
|------|----------------|----------|
| 1 | IMap\appsettings.json | 修改 |
| 2 | IMap\wwwroot\js\new.js | 新增 |
| 3 | IMap\Old.dll | 刪除 |

**`-All` 模式** → `正式機完整檔案清單.csv`（只有「序號」與「檔案位置與名稱」兩欄）

執行完成後，畫面會顯示各異動類型的筆數。

## 注意事項

- 檔案路徑的前綴 `IMap\` 目前寫死在腳本裡，用於其他專案時需要自行修改。
- `-ExcludeDirs` 只比對第一層資料夾。例如 `logs` 會排除 `logs\...`，但不會排除 `wwwroot\logs\...`。
- 輸出的 CSV 是 UTF-8 with BOM 編碼，Excel 開啟時中文不會亂碼。
- 腳本本身也必須存成 **UTF-8 with BOM**，否則 PowerShell 5.1 會把中文讀錯。用 VS Code 編輯後，請確認右下角的編碼顯示為 `UTF-8 with BOM`。
