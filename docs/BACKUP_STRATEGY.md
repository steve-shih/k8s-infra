# Kubernetes (K8s) 備份策略總覽

本文件紀錄了目前 K8s 叢集可進行的四種主要備份策略，以及目前的實作狀況。

## 備份策略層級表

| 備份層級 | 備份目標與內容 | 使用工具 / 實作方式 | 目前實作現況 | 災難復原難易度 |
| :--- | :--- | :--- | :--- | :--- |
| **1. 設定檔備份 (GitOps)** | 備份 K8s 叢集的所有設定 (Deployment, Service, Ingress 等 YAML) | GitHub (k8s-infra) + ArgoCD | 🟢 **已完善**。所有基礎架構已獨立為 `k8s-infra` 專案庫。 | **極易**。一鍵套用 Git 即可還原叢集骨架。 |
| **2. 資料/應用層級備份** | 備份核心資料庫 (MongoDB) 與靜態檔案 (圖片、文件) | `mongodump` 腳本、排程 (CronJob)、GCP Cloud Storage | 🟡 **部分實作**。靜態檔案已存放於 GCP。MongoDB 若自建於 K8s，需額外補上 CronJob 備份腳本。 | **容易**。需手動將資料倒回資料庫。 |
| **3. 磁碟層級備份 (CSI)** | 備份 K8s 內部的掛載硬碟 (Persistent Volume Claims, PVC) | 雲端服務商的 CSI Snapshot 功能 (如 GCP PD Snapshot) | ⚪ **尚未設定**。目前雖然有宣告 PVC，但並未設定定時快照。 | **中等**。需透過 K8s VolumeSnapshot API 還原。 |
| **4. 全叢集災難復原** | 結合「設定檔」與「磁碟快照」，一次性整包備份整個 Namespace | **Velero** | ⚪ **尚未安裝**。未安裝 Velero 服務器。 | **極易**。一行指令 `velero restore` 即可全盤復活。 |

## 下一步行動建議
1. **確認 MongoDB 狀態**：釐清目前 MongoDB 是使用雲端託管 (Atlas) 還是 K8s 內部自建。若是自建，建議立即建立針對 MongoDB 的 CronJob 備份任務。
2. **評估 Velero 導入**：若未來業務量增長，建議於叢集中安裝 Velero，將全叢集狀態定時備份至 GCP Bucket，達成最完整的災難復原 (DR) 準備。
