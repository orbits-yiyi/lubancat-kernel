> 历史记录：本页保留前期方案及当时的验证结论。当前版本和执行路线见[学习入口](../README.md)。文中本机路径属于旧工作区。

# 以 LubanCat-1N 为实践平台学习驱动

当前优先目标是建立稳定、可恢复的系统与源码基线，再系统学习驱动。AI 网站保留为后续应用实验。

## 固定版本

- 内核：官方标签 `rk356x-4.19.232-23`，提交 `e47983915ec0566ef92d81624cc1cb4b7bfbc9b3`。
- 源码目录：`build/stable-1n/source/`，从官方标签创建独立工作树。
- 工具链：Linaro GCC 6.3.1，官方 SDK 工具链仓库提交 `f96f76d6be89a6e28d4dac1f233f9aca9921f69b`。
- 配置入口：`lubancat2_defconfig`，适用于这份 4.19 源码的 RK3566/RK3568 系列。
- 输出目录：`build/stable-1n/out/`。
- 实验内核标识：`4.19.232-lbc1n`，用于确认板上确实启动了本次构建产物。

“稳定基线”需要由源码版本、配置、工具链、镜像与启动验收共同确定。官方标签提供版本起点，编译通过之后还要在实际板上验证网络、存储和重启。

当前构建采用官方标签加一项 RTL8852BE 平台参数修复。原始标签中该模块缺少大小端和 cfg80211 等平台编译参数，构建时出现 `Must be LITTLE/BIG Endian Host`；原工作区已有对应修复，因此仅引入这一处，补丁保存在 `build/stable-1n/baseline/rtl8852be-platform.patch`。原 `kernel/` 中的全部未提交改动另存于 `build/rebuild-1n/baseline/source-changes.patch`。

对照完整镜像提取出的配置，本次配置除实验版本后缀与版本自动追加设置外，GCC 插件可用性设置不同；其余配置一致。原镜像内核使用同系列 Linaro GCC 6.3.1 工具链。

编译命令：

```bash
cd /home/yiyi/Workspace/lubancat
bash scripts/build-kernel-1n.sh
```

已验证 `Image`、DTB/DTBO、全部已配置模块的构建通过。TF 卡烧录与上板验证见 [构建与 TF 卡启动](04-build-and-flash-tf.md)。

## 学习顺序

| 阶段 | 核心内容 | 板上实验或源码入口 |
| --- | --- | --- |
| 1 | 内核、根文件系统、启动链、交叉编译 | TF 卡启动；检查运行内核、设备树、挂载和日志 |
| 2 | 模块入口、参数、日志、符号、版本匹配 | `examples/drivers/01_hello/` |
| 3 | 字符设备、文件操作、用户与内核数据传输 | 编写最小字符设备及用户态读写程序 |
| 4 | 设备树、platform 总线、匹配与 probe | 1N DTS 的 `compatible`、资源描述和驱动匹配 |
| 5 | GPIO、pinctrl、LED | `drivers/leds/leds-gpio.c`、`drivers/gpio/gpio-rockchip.c`、`drivers/pinctrl/pinctrl-rockchip.c` |
| 6 | 中断、定时器、工作队列、并发 | 按键输入、防抖、延迟处理与同步 |
| 7 | input 子系统、ADC、PWM | `drivers/input/keyboard/adc-keys.c`、SARADC 与 PWM 驱动 |
| 8 | I²C 客户端驱动与控制器 | 小型传感器；`drivers/i2c/busses/i2c-rk3x.c` |
| 9 | SPI、UART | 外设通信；`drivers/spi/spi-rockchip.c`、`drivers/tty/serial/8250/8250_dw.c` |
| 10 | RTC、时钟、复位、regulator、电源管理 | `drivers/rtc/rtc-rk808.c`、运行时电源管理与休眠恢复 |
| 11 | MMC、USB、网络 | `drivers/mmc/host/dw_mmc-rockchip.c`、USB 枚举、`drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c` |
| 12 | DRM、V4L2、ALSA、DMA/IOMMU | 根据实际屏幕、摄像头和音频外设安排专项实验 |

每个阶段都完成“用户态如何访问 → 设备树如何描述 → 内核如何匹配 → 驱动如何操作资源 → 日志如何定位错误”的链路。复杂子系统放在模块、设备模型和并发基础之后学习。

## 第一个硬件入口：板载 LED

当前 1N DTS 中，LED 节点的 `compatible` 是 `gpio-leds`。系统灯位于 `gpio0` 的 `PC5`，低电平有效，默认触发器为 `heartbeat`。需要结合板卡实际硬件版本和启动设备树核对。

可以沿下面的路径阅读当前代码：

1. `arch/arm64/boot/dts/rockchip/rk3566-lubancat-1n.dts` 中的 `leds` 节点。
2. `drivers/leds/leds-gpio.c` 中的设备树匹配与 `probe`。
3. LED 子系统提供给用户态的 `/sys/class/leds/` 接口。
4. GPIO 和 pinctrl 控制器驱动如何处理引脚。

先通过现有驱动理解完整调用过程，再编写自己的小驱动，便于把每次代码变化与硬件行为对应起来。

## 官方资料

- [当前官方内核标签](https://github.com/LubanCat/kernel/releases/tag/rk356x-4.19.232-23)
- [官方 4.19 SDK 清单中的工具链](https://github.com/LubanCat/manifests/blob/linux/rk356x_linux/rk356x_linux4.19_stable.xml)
- [官方驱动开发教程](https://doc.embedfire.com/linux/rk356x/driver/zh/latest/index.html)
