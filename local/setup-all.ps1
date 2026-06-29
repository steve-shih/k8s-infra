<#
==============================================================================
檔案名稱 (File): local/setup-all.ps1
負責元件 (Component): 開發工具腳本 (Development Scripts)
檔案用途 (Purpose): 一鍵編譯所有微服務的 Docker Image 並自動載入至本地 K8s 環境，然後重啟 Pod 以套用新程式碼。
使用方式 (Usage): 直接執行 `./setup-all.ps1`
==============================================================================
#>
Write-Host "Building daynote-frontend..."
cd C:\Users\beaut\.gemini\antigravity-ide\scratch\dayNoteApp\frontend
docker build -t daynote-frontend:local .

Write-Host "Building daynote-backend..."
cd C:\Users\beaut\.gemini\antigravity-ide\scratch\dayNoteApp\backend
docker build -t daynote-backend:local .

Write-Host "Loading images to Kind..."
cd C:\Users\beaut\.gemini\antigravity-ide\scratch
powershell.exe -ExecutionPolicy Bypass -File .\load-images.ps1

Write-Host "Restarting failed pods to force image pull..."
kubectl delete pods -l app=daynote-backend
kubectl delete pods -l app=daynote-frontend
Write-Host "All done! Check your pods."
