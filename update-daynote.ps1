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
