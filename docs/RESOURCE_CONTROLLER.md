# 叢集資源切換控制器使用說明 (Resource Toggle Controller)

這份文件說明了如何透過自訂的 PowerShell 控制器腳本，來快速開啟或關閉 Kubernetes 中的服務。
由於本叢集使用 **ArgoCD (GitOps)** 管理，因此控制器會透過修改本地設定並自動推送到 Git 的方式來讓 ArgoCD 觸發縮減 (Scale Down)。

## 1. 檔案位置與結構

所有與控制器相關的檔案皆位於 `local/controller/` 資料夾中：

- **`Toggle-Resources.ps1`**: 實際執行的 PowerShell 腳本。
- **`config.json`**: 控制器設定檔，用來決定哪些服務會受到控制。

## 2. 如何操作控制器

請打開一個 PowerShell 終端機，並確保當前目錄位於 `k8s-infra` 的根目錄下，接著可以根據需求執行以下指令：

### 切換為節能模式 (Lite Mode)

若您平常只需要使用 `daynoteapp`，可以將其他服務暫時關閉以節省資源，請執行：

```powershell
.\local\controller\Toggle-Resources.ps1 -Mode Lite
```

**這個指令會做什麼事？**
1. 將 `config.json` 中指定的 Deployment (如 `pet-adoption.yaml`, `tire-erp.yaml` 等) 的 `replicas` 改為 `0`。
2. 將 `config.json` 中指定的 CronJob 加上 `suspend: true` 以暫停排程。
3. 自動執行 `git commit` 以及 `git push` 推送至 GitHub。
4. ArgoCD 發現變更後，會自動幫您將不需使用的 Pod 關閉。

### 切換為全開模式 (Full Mode)

當您需要展示或開發其他模組時，請執行此模式來恢復所有服務的運作：

```powershell
.\local\controller\Toggle-Resources.ps1 -Mode Full
```

**這個指令會做什麼事？**
1. 將所有受到控制的 Deployment 的 `replicas` 恢復為 `1`。
2. 取消 CronJob 的暫停狀態 (`suspend: false`)。
3. 同樣自動推送至 GitHub，觸發 ArgoCD 自動還原並啟動所有 Pod。

## 3. 如何新增或移除受控服務？

控制器完全由 `config.json` 來驅動。
如果您有新的服務要納入「節能模式」的關閉範圍中，請開啟 `local/controller/config.json`：

```json
{
  "targetFiles": [
    "prod/feeding.yaml",
    "prod/pet-adoption.yaml",
    "prod/tire-erp.yaml",
    "prod/k8s-petbar.yaml"
  ],
  "cronjobFiles": [
    "prod/k8s-petbar-cronjob.yaml"
  ]
}
```

將您新的 YAML 檔案路徑加入到對應的陣列中即可。下次執行控制器腳本時，就會一併處理您新增的設定檔。
