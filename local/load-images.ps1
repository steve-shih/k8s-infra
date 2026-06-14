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
