# 板上小模型与聊天网站

截至 2026-11-15，本地推理和局域网聊天网页已跑通。完整复现、性能记录、DuckDNS/Dynu 外网方案及开机自启部署步骤统一维护在：

**[AI、知识库、DDNS 与开机自启技术方案](06-ai-knowledge-base-deployment.md)**

| 部分 | 当前状态 |
| --- | --- |
| 开发板 | LubanCat-1N，实测 4GB / aarch64 |
| 系统 | Ubuntu 20.04.6 LTS |
| 引擎 | llama.cpp b5046，提交 74d4f5b041ad，板上原生编译 |
| 权重 | Qwen2.5-0.5B-Instruct Q4_K_M，官方 SHA256 校验通过 |
| 推理 | CPU 短实验，2 线程 3.12 tokens/s，4 线程 4.87 tokens/s |
| 网页 | llama-server 内置页面，局域网 8080 端口访问已确认 |
| 自启动 | [脚本和 systemd 文件](tools/ai-service)已准备，待板上安装和重启验收 |
| 公网访问 | 限定 DuckDNS / Dynu，需先确认 IPv4/IPv6 入站或自有服务器条件 |
| 知识库 | 文档分块、检索、来源引用尚待实现 |

速度来自输出长度不同的两次短实验，不代表严格基准或长期性能。完整回答质量、内存和温度尚需补充验收。

原始候选调查保留在[前期 AI 方案](archive/02-local-chat.md)，其中 2GB 等规格假设属于历史记录，以本页和完整技术方案的实测数据为准。
