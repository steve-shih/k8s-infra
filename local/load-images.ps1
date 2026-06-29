<#
==============================================================================
檔案名稱 (File): local/load-images.ps1
負責元件 (Component): 開發工具腳本 (Development Scripts)
檔案用途 (Purpose): 將本地端剛編譯好的 Docker Image 直接匯入至 k8s 本地節點中 (如 Kind 或 Minikube)，省去推播至 Registry 的時間。
使用方式 (Usage): 直接執行 `./load-images.ps1`
==============================================================================
#>
$ErrorActionPreference = "Stop"

Write-Host "Fetching nodes..."
$nodes = (kubectl get nodes -o jsonpath='{.items[*].metadata.name}') -split ' '

$images = @("daynote-frontend:local", "daynote-backend:local", "tire-erp:local", "feeding:local", "pet-adoption:local")

foreach ($img in $images) {
    $tar = $img.Replace(":", "-") + ".tar"
    Write-Host "Saving $img to $tar..."
    docker save -o $tar $img
    
    foreach ($node in $nodes) {
        Write-Host "Importing $tar to $node..."
        docker cp $tar "$node`:/$tar"
        docker exec $node ctr -n k8s.io images import /$tar
    }
    Remove-Item $tar
}

Write-Host "All images loaded successfully!"
