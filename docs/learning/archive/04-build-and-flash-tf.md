> 历史记录：本页保留前期方案及当时的验证结论。当前版本和执行路线见[学习入口](../README.md)。文中本机路径属于旧工作区。

# 当前 4.19 源码构建与 TF 卡启动

## 已核对的文件

完整镜像：

```text
E:\Document\lubancat\linux_image\lubancat-rk3566-ubuntu20.04-xfce-20260418_update\lubancat-rk3566-ubuntu20.04-xfce-20260418_update.img
```

镜像大小 3,841,905,226 字节，MD5 为 `b76aedfeae7f49de4d974b3a99f62168`，与随附 `md5sum.txt` 及官方发布说明一致。已使用官方工具解包确认其中包含 Loader、U-Boot、boot 和 rootfs。它是适用于 RK3566 的完整 RK 格式系统镜像。

源镜像内核版本字符串为 `4.19.232`，使用 Linaro GCC 6.3.1 构建。当前源码基线和构建修复见 [驱动学习路线](03-driver-roadmap.md)。

## 编译输出

在 WSL 的工作区运行：

```bash
cd /home/yiyi/Workspace/lubancat
bash scripts/build-kernel-1n.sh
bash scripts/package-kernel-1n.sh
```

| 产物 | 位置与用途 |
| --- | --- |
| 内核 Image | `build/stable-1n/out/arch/arm64/boot/Image` |
| 1N 设备树 | `build/stable-1n/out/arch/arm64/boot/dts/rockchip/rk3566-lubancat-1n.dtb` |
| 配置与符号表 | `build/stable-1n/out/.config`、`Module.symvers` |
| 内核安装包 | `build/stable-1n/linux-image-4.19.232-lbc1n_4.19.232-lbc1n-1_arm64.deb` |
| 日志 | `build/stable-1n/logs/` |
| 第一份教学模块 | `examples/drivers/01_hello/lbc_hello.ko` |

`Image`、设备树和 `.deb` 都是系统的组成部分；TF 卡初次启动使用上面核对过的完整 `_update.img`。

## 第一阶段：把完整系统写入 TF 卡

Windows 烧录工具已准备在：

```text
E:\Document\lubancat\tools\SDDiskTool_v1.76\SD_Firmware_Tool.exe
```

操作顺序：

1. 将 TF 卡插入读卡器并接到 Windows 电脑。
2. 打开烧录工具，根据读卡器名称和 TF 卡容量选择目标盘。点击开始后，该卡上的现有数据会被覆盖。
3. 功能模式选择 **SD 启动**。
4. 固件文件选择本页开头的完整 `lubancat-rk3566-ubuntu20.04-xfce-20260418_update.img`。
5. 点击“开始创建”，等待工具提示成功。
6. 安全移除读卡器，在开发板断电时插入 TF 卡，再连接网线、显示器等并上电。

若 Windows 提示格式化 Linux 分区，取消该提示；Linux 分区由开发板使用。烧录工具的“SD 启动”模式用于制作 TF 启动卡。

官方启动说明指出有镜像的 SD 卡优先启动。首次启动会初始化系统并可能自动重启，等待初始化完成后登录。

## 第二阶段：验证官方基础系统

默认普通用户为 `cat`，密码为 `temppwd`。在板上终端执行：

```bash
uname -r
uname -m
cat /etc/os-release
tr '\000' '\n' < /proc/device-tree/model
findmnt /
findmnt /boot
ip -br address
free -h
```

记录根文件系统与 boot 的来源、板型、IP、内存和当前内核。确认网络、存储可用，再正常重启一次，验证可以再次启动。用这些信息确认实际从 TF 卡运行。

## 第三阶段：安装本次构建的内核

基础系统验收后，将本次内核安装包复制到板上，安装内核、模块和设备树，并核对 boot 分区中的内核与 initrd 链接。该镜像使用独立 boot 分区，具体切换步骤会依据第二阶段的挂载结果执行。

切换后 `uname -r` 应为 **`4.19.232-lbc1n`**。之后再加载第一份教学模块：它的版本标识与本次构建匹配。

头文件包中保留了交叉编译过程中生成的主机工具；首阶段采用 WSL 上的内核构建目录编译外部模块。板上原生编译驱动时，需要另核对这些主机工具的架构和板上编译环境。

## 官方操作参考

- [系统镜像烧录：SD 卡模式与工具](https://doc.embedfire.com/linux/rk356x/quick_start/zh/latest/quick_start/flash_img/flash_img.html)
- [4.19 镜像发布记录与 MD5](https://doc.embedfire.com/linux/rk356x/quick_start/zh/latest/quick_start/baidu_cloud/update_history_rk356x_kernel4.19.html)
- [系统启动与登录](https://doc.embedfire.com/linux/rk356x/quick_start/zh/latest/quick_start/board_startup/board_startup.html)
