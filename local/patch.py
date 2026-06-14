# -*- coding: utf-8 -*-
import re

with open('k8s-full-stack.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

failover_block = '''
            proxy_intercept_errors on;
            error_page 502 504 =200 /failover.html;
            location = /failover.html {
                default_type text/html;
                return 200 "<!DOCTYPE html><html><head><meta charset='utf-8'><title>環境切換中</title></head><body style='text-align:center; padding: 50px; font-family: sans-serif; background: #222; color: #fff;'><h1>🚧 環境 1 (本地) 忙碌中或斷線</h1><h2>系統將於 3 秒後自動切換至【備用正式環境】...</h2><p>如果沒有自動跳轉，請點擊 <a href='#' id='failover-link' style='color: #00ffcc;'>這裡</a>。</p><script>var target = 'http://35.221.153.58' + (window.location.port ? ':' + window.location.port : '') + window.location.pathname; document.getElementById('failover-link').href = target; setTimeout(function(){ window.location.href = target; }, 3000);</script></body></html>";
            }
'''

# Add to Tire ERP Server block
content = content.replace('server_name  zhqy.ngrok.pro;', 'server_name  zhqy.ngrok.pro;' + failover_block)

# Add to Other Apps Server block
content = content.replace('server_name  meowlab.ngrok.app;', 'server_name  meowlab.ngrok.app;' + failover_block)

with open('k8s-full-stack.yaml', 'w', encoding='utf-8') as f:
    f.write(content)
