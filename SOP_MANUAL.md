# 🚀 企業級 Kubernetes (GKE) 與 Docker 終極維運與故障排除手冊

這是一份針對您現有系統架構所量身打造的**「極致詳細版」操作手冊**。無論您是要上版、降版、查 Bug 還是擴充伺服器，只要跟著這份手冊的「使用情境」，把指定的指令「複製貼上」到您的終端機 (PowerShell/CMD)，即可完成所有維運操作。

---

## 🔑 零、前置作業：連線到您的伺服器 (最重要！)
在打任何 `kubectl` 指令之前，您的電腦必須先跟 GCP 的 K8s 叢集建立連線。如果您發現打 `kubectl` 出現權限錯誤，請先執行：

```bash
# 1. 登入 Google 帳號 (會彈出瀏覽器讓您點擊)
gcloud auth login

# 2. 獲取您的 K8s 叢集連線憑證 (請把 PROJECT_ID 換成您實際的 GCP 專案 ID)
gcloud container clusters get-credentials steve-k8s-cluster --region asia-east1-a --project=您的專案ID
```
*💡 預期結果：終端機會顯示 `kubeconfig entry generated for steve-k8s-cluster`，代表連線成功。*

---

## 🐳 一、Docker 開發者日常操作
Docker 是用來把您的程式碼包裝成「標準化軟體光碟」的工具。

### 1. 本地端打包與測試 (手動版)
如果您不想等 GitHub Action，想在自己電腦打包看看會不會報錯：
```bash
# 在含有 Dockerfile 的資料夾下執行，-t 後面接的是您想取的名字
docker build -t daynote-backend-test:v1 .
```
*💡 預期結果：會看到 Step 1/10 ... 一步步跑完，最後顯示 `Successfully built`。*

### 2. 查看與清理本地垃圾 (必學，否則 C 槽會爆滿)
當您打包幾十次之後，電腦會塞滿舊的映像檔。
```bash
# 查看現在有哪些映像檔
docker images

# 【危險但好用】一鍵刪除所有沒在執行的容器與沒有名字的廢棄映像檔
docker system prune -a
```
*💡 系統會警告 `WARNING! This will remove: ...`，請大膽輸入 `y` 即可清理。*

---

## ☸️ 二、K8s 日常監控與互動操作
這是平常「巡視」伺服器狀態最常用的指令。

### 1. 查看所有網站 (Pod) 是死是活？
```bash
kubectl get pods
```
*💡 正常情況：`STATUS` 必須是 `Running`，`READY` 必須是 `1/1`。*
*🚨 異常情況：如果看到 `CrashLoopBackOff`、`Error`、`Pending`，請立刻跳到下方的「第四部分：故障排除」。*

### 2. 查看伺服器資源有沒有被吃光？(像 Windows 工作管理員)
```bash
# 查看每台機器的 CPU 與記憶體使用率
kubectl top nodes

# 查看每一個專案現在吃了多少 CPU 與記憶體
kubectl top pods
```
*💡 預期結果：會列出每個 Pod 吃了幾 m (CPU) 與幾 Mi (記憶體)。如果某個 Pod 的記憶體一直狂飆，代表可能有 Memory Leak。*

### 3. 【進階】我想要直接「遠端登入」進去正在跑的網站裡面！
有時候您想檢查 Docker 裡面到底有沒有某個檔案，或是想手動跑 Python 腳本：
```bash
# 語法：kubectl exec -it <Pod名字> -- /bin/bash (或是 /bin/sh)
kubectl exec -it daynote-backend-5c8f8b8f-xyz -- /bin/bash
```
*💡 預期結果：您的終端機會變成 Linux 系統的 `root@daynote-backend-xxx:/app# `，這時候您就可以下 `ls` 或是 `cat` 來看裡面的檔案了。看完輸入 `exit` 退出。*

---

## 📈 三、資源擴充 (升規) 與 節流 (降規) 操作
所有關於硬體的修改，**全部都在 `k8s-infra/prod/k8s-prod.yaml` 裡面修改**。改完存檔，執行 `git add .` -> `git commit -m "update"` -> `git push` 交給 ArgoCD 處理。

### 情境 A：明天要辦活動，流量會爆增 (修改機器數量)
1. 打開 `k8s-prod.yaml`。
2. 找到您要擴充的專案，例如 `daynote-frontend`。
3. 找到 `replicas: 1` 這行。
4. **【升級】** 將 `1` 改成 `3` (代表叫 K8s 複製出 3 台機器來分擔流量)。
5. **【降級】** 活動結束後，將 `3` 改回 `1` 以節省 GCP 帳單費用。

### 情境 B：程式運算太複雜，瘋狂 OutOfMemory (OOM) 崩潰 (修改記憶體上限)
1. 打開 `k8s-prod.yaml`。
2. 找到 `resources:` 區塊 (如果沒有可以自己加上去)：
   ```yaml
           resources:
             requests:
               memory: "128Mi"   # 保底記憶體
               cpu: "100m"       # 保底 CPU (1000m = 1顆CPU)
             limits:
               memory: "512Mi"   # ⬅️ 系統強制上限！把這裡從 256Mi 改成 512Mi 甚至 1Gi
               cpu: "500m"
   ```
3. 推送上 GitHub 後，K8s 會自動把舊的砍掉，換一台配備 512Mi 的新機器上線。

---

## 🚑 四、超詳細故障排除 SOP (網站壞了怎麼辦？)

當發現網站 502 Bad Gateway 或是無法連線時，請冷靜，照著以下 SOP 走：

### 🛑 步驟一：找出犯人
下指令：`kubectl get pods`
查看哪一個專案的狀態不是 `Running`。把它的名字 (例如 `tire-erp-8469dbf-abc`) 複製起來。

### 🛑 步驟二：如果是 `CrashLoopBackOff` (程式啟動後立刻崩潰)
這代表您的程式碼有 Bug (例如語法錯誤、缺少套件、連不上資料庫)。
**👉 解法：看 Log (程式碼的 console.log 或是報錯訊息)**
```bash
# 語法：kubectl logs <Pod名字>
kubectl logs tire-erp-8469dbf-abc
```
*💡 畫面會印出程式崩潰前最後吐出的錯誤訊息。例如：`ModuleNotFoundError: No module named 'flask'`。看到這個就知道是忘了裝套件，去改程式碼重新推上 GitHub 即可。*

如果剛剛的指令沒東西，請加上 `--previous` 看上一次死亡前的遺言：
```bash
kubectl logs tire-erp-8469dbf-abc --previous
```

### 🛑 步驟三：如果是 `ImagePullBackOff` 或 `ErrImagePull` (下載檔案失敗)
這代表 K8s 想要去 GHCR 雲端光碟櫃下載 Image，但是被拒絕了，或是根本找不到那個版本。
**👉 解法：看事件簿**
```bash
# 語法：kubectl describe pod <Pod名字>
kubectl describe pod tire-erp-8469dbf-abc
```
滑到最下面看 `Events`：
* 如果寫 `not found`：代表您在 YAML 裡面寫的版本號 (`image: ...:main`) 拼錯了。
* 如果寫 `unauthorized`：代表您的 K8s 叢集忘記去 GitHub 拿檔案的密碼了 (ImagePullSecrets 設定有誤)。

### 🛑 步驟四：如果是 `Pending` (一直卡住在準備中)
這代表您的 GCP 叢集「整台母機的 CPU 或記憶體已經滿了」，塞不下新的機器了。
**👉 解法：去 GCP 控制台花錢升級母機**
1. 登入 Google Cloud Console。
2. 進入 Kubernetes Engine -> 叢集 -> `steve-k8s-cluster`。
3. 進入「節點 (Nodes)」分頁。
4. 將機器規格升級 (例如從 e2-medium 升級到 e2-standard-2) 或是增加節點數量。

### 🛑 步驟五：如果是 HTTPS 憑證失敗 (瀏覽器顯示不安全)
如果是新網域剛綁上去，Let's Encrypt 發證失敗：
```bash
# 1. 看哪一張憑證有問題 (READY 為 False)
kubectl get certificate

# 2. 查看 Let's Encrypt 的拒絕理由
kubectl describe challenge
```
*💡 最常見原因是 `no such host` (DNS 沒設定好，請去 GoDaddy 檢查 A 紀錄)，或是您在 Ingress YAML 裡面的 `tls: - hosts:` 拼錯網域名稱了。*

---

## ⏪ 五、終極大絕招：災難復原 (時光倒流)
如果您剛剛推了一版有毒的程式碼，導致網站整個大當機，老闆在背後非常生氣，您需要**在 10 秒內恢復網站**！

**👉 解法：手動降版 (Rollback)**
因為我們使用 GitOps 架構，您只需要讓 `k8s-infra` 的 YAML 檔「回到過去」：
1. 打開您的 `k8s-prod.yaml`。
2. 把 `image: ghcr.io/...:最新版` 手動改回上一個正常的標籤名稱。
   *(如果您都是用 `main` 覆蓋，那您必須去 GitHub Packages 後台找出上一個正常的 sha 標籤，例如 `:sha-8a7b6c5`)*
3. 改完後存檔，執行 `git add .` -> `git commit -m "rollback"` -> `git push`。
4. K8s 會在幾秒內瞬間把舊的正常機器開起來，把有毒的新機器殺掉。危機解除！
