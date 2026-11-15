# 本地 AI 服务部署文件

完整环境、DDNS 路线和安装流程见[技术方案](../../06-ai-knowledge-base-deployment.md)。

默认对应板上用户 `cat`、项目 `/home/cat/workspace/ai/llama.cpp`，4 线程、4096 tokens 上下文、1024 tokens 回复上限、单路生成，局域网 IPv4 8080 端口。长回复参数尚需在板上验收。

在开发板上，先停止此前占用 8080 端口的前台模型服务，再执行：

```bash
bash start-ai-server.sh --check
sudo bash install-ai-service.sh --enable
sudo systemctl status lubancat-ai.service --no-pager
curl --fail --max-time 10 http://127.0.0.1:8080/health
```

`--check` 是路径与参数预检，健康检查需等权重加载完成。安装器不带 `--enable` 时只安装文件并重载 systemd。

安装位置：

- `/usr/local/bin/lubancat-ai-start`：启动程序。
- `/etc/default/lubancat-ai`：运行参数，重复安装保留。
- `/etc/systemd/system/lubancat-ai.service`：开机自启和进程管理。

原先 `-n 128` 用于短问答实验，生成较长代码时会触发长度限制。已有参数文件会保留；更新脚本或重新安装不会替用户改掉旧值。已安装时请编辑：

```bash
sudo nano /etc/default/lubancat-ai
```

把对应两项改为 `AI_CONTEXT=4096`、`AI_PREDICT=1024`，再执行：

```bash
sudo systemctl restart lubancat-ai.service
```

网页请求若另设了更低的生成上限，也需要调整。长度上限仍存在，超长代码可分模块生成；按实测约 4.87 tokens/s，长回复可能需要数分钟。参见[输出截断排查](../../06-ai-knowledge-base-deployment.md#61-回复没有结束就停止)。

开发机可以检查安装布局，不修改正在运行的服务：

```bash
bash install-ai-service.sh --destdir /tmp/lubancat-ai-stage
python3 tests/test_service.py
```

测试使用临时目录和替代程序验证启动参数、主进程 PID、预检与配置保留，不代表开发板模型推理或重启验收。
