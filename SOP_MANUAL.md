# 🚀 K8s 與 Docker 維運與故障排除手冊 (SOP)

這份手冊是專為您的專案架構所撰寫的「白話文版」維運指南。
當您遇到網站掛掉、需要升級主機、或是想查看錯誤日誌時，請打開這個檔案，按照裡面的指令一步步操作。

---

## 🐋 第一部分：基礎 Docker 操作
**在哪裡打指令？** 您自己電腦的 PowerShell 或 cmd (需在專案資料夾下，例如 `dayNoteApp`)

Docker 是我們用來「打包軟體」的工具。以下是您在本地開發時最常用的指令：

1. **查看本機目前有哪些打包好的映像檔 (Images)**
   ```bash
   docker images
   ```
2. **查看本機有哪些正在跑的容器 (Containers)**
   ```bash
   docker ps
   ```
3. **手動在本機打包 Docker Image (通常交給 GitHub Action 做就好)**
   ```bash
   docker build -t my-app:latest .
   ```
4. **清理本機不要的垃圾 (釋放硬碟空間，很久沒清會吃滿 C 槽)**
   ```bash
   docker system prune -a
   ```
   *(系統會問您 Y/N，輸入 `y` 即可清理所有沒在用的 Docker 快取)*

---

## ☸️ 第二部分：基礎 K8s 操作
**在哪裡打指令？** 您自己電腦的 PowerShell (前提是您已經安裝好 gcloud 並連線到您的 GKE 叢集)

1. **看現在有哪些網站 (Pod) 正在跑？**
   ```bash
   kubectl get pods
   ```
   *預期結果：會列出所有專案，例如 `daynote-backend-xxx`，狀態必須是 `Running`。*

2. **看有沒有分配到對外的 IP (看 Ingress 與 Service)？**
   ```bash
   kubectl get ingress
   ```
   *預期結果：會看到您的網域 (`erp.wheel.petpa.tw` 等) 對應到 `35.221.153.58`。*

3. **強迫某個專案重新啟動 (如果它卡住了)**
   ```bash
   # 把 deployment/ 後面的名字換成您的專案名稱
   kubectl rollout restart deployment/daynote-backend
   ```

---

## 📈 第三部分：常見設定 (升規與降規 Scale Up / Down)
**在哪裡修改？** 修改本資料夾下的 `prod/k8s-prod.yaml` 檔案，改完後 `git push` 交給 ArgoCD 處理。

### 1. 調整機器數量 (流量變大，需要多台機器支援)
打開 `k8s-prod.yaml`，找到 `replicas:` (副本數) 的設定：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: daynote-backend
spec:
  replicas: 2   # ⬅️ 將 1 改成 2，K8s 就會開兩台機器幫您分散流量
```

### 2. 調整硬體規格 (程式吃太多記憶體，一直崩潰閃退)
找到 `resources:` 的區塊，修改給予的記憶體 (memory) 或 CPU：
```yaml
        resources:
          requests:
            memory: "128Mi"  # 程式啟動時最少需要的記憶體
            cpu: "100m"
          limits:
            memory: "512Mi"  # ⬅️ 升規：把最大限制從 256Mi 提高到 512Mi (防止 OutOfMemory 崩潰)
            cpu: "500m"      # ⬅️ 升規：提高 CPU 算力限制
```
**🚨 注意**：改完 YAML 記得 `git add .` -> `git commit` -> `git push`！

---

## 🕵️ 第四部分：故障排除步驟 (Troubleshooting)

網站連不上的時候怎麼辦？請按照以下順序在 PowerShell 輸入指令排查：

### 狀況一：網站完全連不上 (網頁一直轉圈圈或顯示找不到主機)
1. **檢查 DNS 與 Ingress 是否活著**
   ```bash
   kubectl get ingress
   ```
   *👉 檢查 ADDRESS 欄位有沒有顯示您的 IP `35.221.153.58`。如果沒有，代表 Ingress 控制器壞了。*

### 狀況二：網站跳出 502 Bad Gateway 或是 503 Service Unavailable
這代表您的「網域」是對的，但是背後的「程式 (Pod)」死掉了！

1. **先抓出兇手是誰 (看誰的狀態不是 Running)**
   ```bash
   kubectl get pods
   ```
   *👉 找看看有沒有狀態是 `CrashLoopBackOff` 或 `Error` 的。把那串名字複製起來 (例如 `daynote-backend-5c8f8b8f-xyz`)。*

2. **查看死因 (查看詳細事件)**
   ```bash
   # 請把下面的名字換成您剛剛複製的名字
   kubectl describe pod daynote-backend-5c8f8b8f-xyz
   ```
   *👉 滑到最下面看 `Events:` 區塊。如果是 `OOMKilled`，代表記憶體不足，請去 YAML「升規」。如果是 `ImagePullBackOff`，代表 Docker 名字打錯或是 GitHub 權限有問題，K8s 載不到檔案。*

3. **查看程式日誌 (看看是不是 Python/Node.js 噴 Error 了)**
   ```bash
   # 請把下面的名字換成您的 Pod 名字
   kubectl logs daynote-backend-5c8f8b8f-xyz
   ```
   *👉 這會印出程式裡面的 `console.log` 或是 Python 的錯誤追蹤 (Traceback)，您可以直接看這裡找出哪一行程式碼寫錯。*

### 狀況三：瀏覽器顯示憑證不安全 (HTTPS 憑證發放失敗)
1. **檢查憑證狀態**
   ```bash
   kubectl get certificate
   ```
   *👉 如果 `READY` 顯示 `False`，代表憑證沒發下來。*
2. **看 Let's Encrypt 為什麼拒絕發憑證**
   ```bash
   kubectl describe challenge
   ```
   *👉 通常最下方的訊息會說 `no such host` 或 `DNS problem`，這代表您的 GoDaddy DNS 設定還沒生效，或是設錯 IP 了。*
