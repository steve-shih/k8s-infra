<#
==============================================================================
檔案名稱 (File): local/update-daynote.ps1
負責元件 (Component): 開發工具腳本 (Development Scripts)
檔案用途 (Purpose): 專為 DayNote 專案設計，一鍵編譯前後端 Image、匯入叢集並重啟 Pod。
使用方式 (Usage): 直接執行 `./update-daynote.ps1`
==============================================================================
#>
Write-Host "Building frontend..."
cd C:\Users\beaut\.gemini\antigravity-ide\scratch\dayNoteApp\frontend
docker build -t daynote-frontend:local .

Write-Host "Building backend..."
cd C:\Users\beaut\.gemini\antigravity-ide\scratch\dayNoteApp\backend
docker build -t daynote-backend:local .

Write-Host "Loading to kind..."
cd C:\Users\beaut\.gemini\antigravity-ide\scratch
powershell.exe -ExecutionPolicy Bypass -File .\load-images.ps1

Write-Host "Restarting pods..."
kubectl delete pods -l app=daynote-frontend
kubectl delete pods -l app=daynote-backend
Write-Host "Done!"
