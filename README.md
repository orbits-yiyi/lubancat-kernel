# LubanCat-1N Linux 驱动学习

基于野火鲁班猫官方内核 `rk356x-4.19.232-24`，在 LubanCat-1N 上逐步学习 Linux、启动流程和设备驱动。个人开发分支为 `main`，官方历史和版本标签均已保留。

**从 [学习文档入口](docs/learning/README.md) 开始。**

| 内容 | 文档 |
| --- | --- |
| 当前目标、进度与学习方式 | [项目方案](docs/learning/01-project-plan.md) |
| GPIO、设备树、总线与驱动子系统 | [驱动学习路线](docs/learning/03-driver-roadmap.md) |
| 启动链与 USB-OTG 烧录 eMMC 的方案 | [启动与 eMMC](docs/learning/04-boot-and-emmc.md) |
| 个人 Fork、版本标签、origin 与 upstream | [源码和远程仓库](docs/learning/05-source-migration.md) |
| 后续板上小模型与聊天网站 | [本地 AI 计划](docs/learning/02-local-chat.md) |
| 之前的 -23 构建、TF 卡探索与教学模块记录 | [历史记录](docs/learning/archive/README.md) |

当前重点是源码管理和驱动基础，后续以小实验逐步推进构建、上板验证及应用开发。目标板内存暂按 2GB 规划，实际规格待上板核对。

代码基线来自 [LubanCat/kernel](https://github.com/LubanCat/kernel)，标签起点为 `c66bf3fcb4610d4444648496e7893c64af84ec64`。本仓库提供 Linux 内核源码；引导程序和完整系统构建涉及的其他 SDK 组件在对应阶段单独准备。

上游内核说明见 [README](README)，许可证见 [COPYING](COPYING)。
