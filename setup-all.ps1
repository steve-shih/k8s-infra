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
