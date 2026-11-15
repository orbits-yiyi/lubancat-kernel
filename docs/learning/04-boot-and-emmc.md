# 启动链与 eMMC 方案

当前选择是通过 **USB-OTG + Windows RKDevTool** 将系统写入 LubanCat-1N 的板载 eMMC。此处先说明各部分的作用，具体构建、接线、设备识别和烧录在后续课程逐项执行。

## 系统如何启动

按当前厂商平台简化表示：

```mermaid
flowchart LR
    rom[片内 BootROM] --> loader[Loader / DRAM 初始化]
    loader --> uboot[U-Boot]
    uboot --> kernel[Linux 内核和设备树]
    kernel --> rootfs[挂载根文件系统]
    rootfs --> init[启动 init 与系统服务]
```

| 部分 | 作用 | 与学习工程的关系 |
| --- | --- | --- |
| BootROM 与启动介质 | 芯片启动逻辑读取下一阶段程序 | 结合芯片、板卡与启动模式理解 |
| Loader、U-Boot | 初始化硬件、选择并加载启动文件 | 需要配套 SDK 中的组件和配置 |
| Linux 内核 | 管理进程、内存、设备与网络 | 本仓库提供源码；`.config` 选择功能与驱动 |
| 设备树 | 描述板级硬件和资源 | 1N 的 DTS 在 `arch/arm64/boot/dts/rockchip/` |
| 根文件系统 | 提供用户、命令、库、配置和服务 | 完整系统的一部分，账户密码也保存在这里 |

理解“从哪里启动”和“启用哪些驱动”时，需要分别查看启动逻辑、U-Boot 配置、启动文件及内核配置。更换内核与重建根文件系统涉及的内容不同。

## 烧录方式

| 方式 | 用途 | 本项目安排 |
| --- | --- | --- |
| USB-OTG + RKDevTool | Windows 下开发阶段的镜像烧录，支持完整镜像及相应的分区操作 | 后续采用 |
| Linux_Upgrade_Tool | Linux 下的对应烧录工具 | 可供后续比较 |
| FactoryTool | 面向批量生产的镜像烧录 | 当前学习阶段不采用 |
| SD 升级卡或 TF 卡启动 | SD 升级卡用于向 eMMC 写镜像；TF 启动用于从卡运行系统 | 前期探索见归档 |

SD 升级卡、TF 卡启动与 USB 直接写 eMMC 的目标和操作过程要分别理解。当前已经确定使用 USB 路线。

## 后续需要逐项核对

先核对完整镜像、源码标签、配置和工具链的对应关系，再准备 RKDevTool、驱动程序与 USB 数据线。连接后确认设备处于预期模式，再确定写入内容。写入 eMMC 会覆盖相应存储内容，具体目标在烧录课程中识别。

启动后的验收包括：运行内核、板卡型号、根文件系统与 boot 挂载、登录、网络、内存、存储和重启恢复。内核模块实验需要使用与运行内核匹配的构建结果。

完整镜像包含引导程序、内核、设备树和根文件系统等；内核的 `Image` 与 `.ko` 属于其中的组成部分。

## 参考资料

- [野火：系统镜像烧录](https://doc.embedfire.com/linux/rk356x/quick_start/zh/latest/quick_start/flash_img/flash_img.html)
- [野火：启动系统与系统登录](https://doc.embedfire.com/linux/rk356x/quick_start/zh/latest/quick_start/board_startup/board_startup.html)
- [前期完整镜像与 TF 卡探索记录](archive/04-build-and-flash-tf.md)
