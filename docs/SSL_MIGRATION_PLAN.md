# 🚀 Kubernetes SSL 憑證 (HTTPS) 與 Ingress 升級計畫 (待續)

> **紀錄時間**：2026-06-17
> **目前狀態**：已敲定架構方向，準備等待 DNS 設定後開始施工。

## 1. 確定的架構目標
目前的架構是透過 `shared-nginx` LoadBalancer 使用不同的 Port 進行分流。為了支援 HTTPS (強制走 443 Port)，我們決定改採 **「子網域 + 路徑」** 混合分流模式。

指定的網域規則如下：
- **Tire ERP**: `https://erp.wheel.petpa.tw`
- **DayNote**: `https://area.petpa.tw/daynote`
- **Feeding**: `https://area.petpa.tw/feeding`
- **Pet Adoption**: `https://area.petpa.tw/petlive`

## 2. ⚠️ 下次開工前：您必須完成的 DNS 設定
在我們下次見面、準備讓系統自動發放 SSL 憑證 (Let's Encrypt) 之前，您必須先去您的網域供應商 (例如 GoDaddy) 設定好以下兩筆 **A Record**，並指向我們 GCP 叢集的對外 IP：

- **目標 IP 地址**：`35.221.153.58`
- **需要設定的 Record**：
  1. 主機名稱 (Name): `erp.wheel` ➡️ 指向 `35.221.153.58`
  2. 主機名稱 (Name): `area` ➡️ 指向 `35.221.153.58`

*(請注意：DNS 設定後通常需要幾分鐘到幾小時生效)*

## 3. ⚠️ 重大技術影響提醒：前端路徑修改
因為 DayNote、Feeding 等專案改為**「子資料夾路徑 (/daynote)」**分流，這會導致 React / Next.js 等前端框架在打包時，找不到原本的根目錄 (`/`) 靜態檔案。

**下次升級完基礎設施後，您必須修改各個前端專案：**
- **Next.js**: 在 `next.config.js` 中新增 `basePath: '/daynote'`
- **React (Vite)**: 在 `vite.config.js` 設定 `base: '/daynote/'`
- **React (CRA)**: 在 `package.json` 加入 `"homepage": "/daynote"`

## 4. 下次見面時，我們預計要執行的技術細節
當您明後天準備好時，請告訴我：「DNS 設好了，請開始升級 SSL！」，我將會為您執行：
1. **移除舊架構**：從 `k8s-prod.yaml` 中刪除舊版的 `shared-nginx` (ConfigMap, Deployment, Service)。
2. **安裝 Nginx Ingress**：在 K8s 叢集上安裝官方的 `ingress-nginx` 控制器。
3. **安裝 Cert-Manager**：在 K8s 叢集上安裝憑證自動派發機器人。
4. **撰寫新版 Ingress Yaml**：為四個專案編寫具有 `cert-manager.io/cluster-issuer` 標籤的正式 Ingress 設定檔，推送到 `k8s-infra` 給 ArgoCD 同步。
