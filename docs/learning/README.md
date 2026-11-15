# 学习文档入口

当前目标是在 LubanCat-1N 上系统学习 Linux 驱动，采用“理解原理 → 少量操作 → 检查结果”的方式逐步推进。板上本地小模型和局域网聊天网页已跑通，后续加入服务管理、DuckDNS/Dynu 公网接入与个人文档检索。

当前约定：

- 源码基线：官方 `rk356x-4.19.232-24`。
- 个人仓库：[orbits-yiyi/lubancat-kernel](https://github.com/orbits-yiyi/lubancat-kernel)，开发分支为 `main`。
- 后续烧录方案：Windows RKDevTool，通过 USB-OTG 写入板载 eMMC。
- 实测开发板：4GB 内存、ARM64、Ubuntu 20.04.6 LTS。
- 当前阶段：源码和远程仓库已就绪；llama.cpp b5046 完成本地推理和局域网页面验证。
- 服务自启脚本与 systemd 单元已准备，仍需在开发板安装并验收；公网连通和知识库检索尚未完成。
- `-24` 的构建、烧录与驱动上板验证尚未在本次协作中执行。

## 阅读顺序

| 顺序 | 内容 | 状态 |
| --- | --- | --- |
| 1 | [项目方案与学习方式](01-project-plan.md) | 当前方案 |
| 2 | [源码和远程仓库](05-source-migration.md) | 已建立，可从这里学习 Git |
| 3 | [驱动学习路线](03-driver-roadmap.md) | 按阶段开展实验 |
| 4 | [启动链与 eMMC 方案](04-boot-and-emmc.md) | 先理解启动，再安排构建和烧录 |
| 5 | [板上模型与聊天网站](02-local-chat.md) | 本地推理与局域网页面已验证 |
| 6 | [AI、知识库、DDNS 与开机自启完整方案](06-ai-knowledge-base-deployment.md) | 含复现步骤、实测数据、DuckDNS/Dynu 路线和服务安装说明 |
| 参考 | [前期探索记录](archive/README.md) | -23、TF 卡和最小模块的历史记录 |

在仓库根目录执行以下三个命令，先观察当前工作区、远程地址和分支跟踪关系：

```bash
git status
git remote -v
git branch -vv
```

需要采集机器信息时，可使用已有的[只读环境检查脚本](tools/inspect-linux.sh)：

```bash
sh docs/learning/tools/inspect-linux.sh
```

脚本显示的是运行它的那台机器的信息；开发机与开发板分别记录。
