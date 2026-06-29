# 🏢 企業級 Kubernetes 基礎架構 (GitOps 專案庫)

本專案庫 (`k8s-infra`) 是整個系統架構的**核心命脈**。我們採用了現代化的 **GitOps** 管理模式，這意味著：
> 💡 **「GitHub 上的程式碼長怎樣，線上的 K8s 伺服器就長怎樣！」**

線上環境已經安裝了 **ArgoCD** (自動部署機器人)。它會 24 小時不間斷地監聽這個專案庫的 `prod/` 資料夾，只要你把任何修改 Push 到 GitHub，ArgoCD 就會自動把線上的 K8s 狀態同步成跟這裡一模一樣，完全不需要手動連進伺服器下指令！

---

## 📂 專案目錄結構總覽

為了讓團隊成員快速上手，我們將所有設定檔進行了嚴格的分類：

### 1. `cluster-setup/` (叢集底層基礎建設)
這裡存放的是 K8s 最底層的共用設定。這些設定通常只需要在開新叢集時套用一次，**不會透過 ArgoCD 自動同步**，必須由管理者手動 `kubectl apply`。
* `deploy-ingress.yaml`：安裝官方 NGINX Ingress Controller (網路守門員，負責接收外部流量)。
* `cluster-issuer.yaml`：設定 Cert-Manager (自動向 Let's Encrypt 申請免費 HTTPS SSL 憑證的機器人)。
* `secrets.yaml.example`：安全憑證範本（因為真實密碼不能進版控，請複製此檔並填入真實密碼後手動套用）。
* `cors.json` / `cors_new.json`：GCP Cloud Storage 的 CORS 權限設定檔。

### 2. `prod/` (正式環境微服務 - 🤖 ArgoCD 自動同步區)
這裡是**系統的心臟**。ArgoCD 隨時都在監控這個資料夾，裡面的每一個 YAML 檔代表一個獨立運作的系統模組。
* `monitoring-argocd.yaml`：地表最強的 PLG 監控系統 (Prometheus + Loki + Grafana)。
* `daynote.yaml`：DayNote 筆記系統 (包含前端、後端與本地硬碟)。
* `feeding.yaml`：餵食系統。
* `tire-erp.yaml`：Tire ERP 企業資源規劃系統。
* `pet-adoption.yaml`：寵物領養平台。
* `k8s-petbar.yaml`：PetLive 寵物直播平台 (包含前後端與 WebRTC 伺服器)。
* `k8s-petbar-cronjob.yaml`：PetLive 的排程任務 (自動清理過期影片檔)。

### 3. `local/` (本地開發輔助工具)
供開發者在自己的電腦上 (如 Docker Desktop, Kind, Minikube) 快速架設與除錯用的腳本。
* `k8s-full-stack.yaml`：一鍵啟動所有微服務的本地測試版。
* `load-images.ps1`：將本地剛 Build 好的 Docker Image 直接塞進本地 K8s 節點。
* `setup-all.ps1` / `update-daynote.ps1`：一鍵自動化腳本，包含編譯、匯入與重啟 Pod。
* `patch.py`：用於本地網路備援測試的輔助腳本。

### 4. `docs/` (架構文件與 SOP)
* `BACKUP_STRATEGY.md`：系統備份策略與災難復原計畫。
* `SSL_MIGRATION_PLAN.md`：HTTPS 憑證轉移計畫。
* `SOP_MANUAL.md`：基礎運維標準作業流程。

### 5. `argocd-app.yaml` (GitOps 啟動樞紐)
這是最頂層的「App of Apps」宣告檔。線上 K8s 只要套用這個檔案，ArgoCD 就會順藤摸瓜，自動把整個 `prod/` 裡的所有微服務都抓起來部署。

---

## 🚀 線上環境如何運作 (GitOps 流程)

1. **開發階段**：工程師在本地端修改程式碼，發布新的 Docker Image。
2. **設定變更**：工程師回到此專案庫 (`k8s-infra`)，修改 `prod/` 資料夾下對應的 YAML 檔 (例如更改 Image Tag 或是修改環境變數)。
3. **推播 (Push)**：將修改 Commit 並 Push 到 GitHub 的 `main` 分支。
4. **自動同步 (Sync)**：線上的 ArgoCD 發現 GitHub 有異動，自動下載最新設定，並在 3 分鐘內將線上的 K8s Pod 進行零停機 (Rolling Update) 滾動更新。

⚠️ **注意**：絕對禁止手動進入線上 K8s 叢集去修改 `prod` 相關的 Deployment 或 Service，因為你的手動修改會在幾分鐘內被 ArgoCD 強制覆蓋回 GitHub 上記載的狀態 (Self-Heal 機制)。
