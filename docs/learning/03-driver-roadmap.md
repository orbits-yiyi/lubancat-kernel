# Linux 驱动学习路线

从官方 `rk356x-4.19.232-24` 学习，先建立源码、配置、工具链和运行内核的对应关系，再逐步完成驱动实验。

源码位于本仓库；RK3566/RK3568 的该版本配置入口为 `arch/arm64/configs/lubancat2_defconfig`。工具链与输出目录将在 -24 构建课程中确定并记录。旧 -23 的补丁和构建结果见[历史记录](archive/03-driver-roadmap.md)。

## 实验顺序

以下路径均相对于仓库根目录。

| 阶段 | 核心内容 | 小实验或源码入口 |
| --- | --- | --- |
| 1 | Git、源码目录、启动链、交叉编译 | 解释运行内核与源码版本，记录设备树、挂载和日志 |
| 2 | 模块入口、参数、日志、符号、版本匹配 | 编写最小模块，编译后核对 vermagic，再上板加载与卸载 |
| 3 | 字符设备、文件操作、用户与内核数据传输 | 编写字符设备及用户态读写程序 |
| 4 | 设备树、platform 总线、匹配与 probe | 沿 `compatible` 查找驱动，读取设备资源 |
| 5 | GPIO、pinctrl、LED | `drivers/leds/leds-gpio.c`、`drivers/gpio/gpio-rockchip.c`、`drivers/pinctrl/pinctrl-rockchip.c` |
| 6 | 中断、定时器、工作队列、并发 | 按键、防抖、延迟处理与同步 |
| 7 | input、ADC、PWM | `drivers/input/keyboard/adc-keys.c`、SARADC 与 PWM 驱动 |
| 8 | I²C 客户端与控制器 | 小型传感器；`drivers/i2c/busses/i2c-rk3x.c` |
| 9 | SPI、UART | 外设通信；`drivers/spi/spi-rockchip.c`、`drivers/tty/serial/8250/8250_dw.c` |
| 10 | RTC、时钟、复位、regulator、电源管理 | `drivers/rtc/rtc-rk808.c`、运行时电源管理与休眠恢复 |
| 11 | MMC、USB、网络 | `drivers/mmc/host/dw_mmc-rockchip.c`、USB 枚举、`drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c` |
| 12 | DRM、V4L2、ALSA、DMA/IOMMU | 按实际屏幕、摄像头和音频外设安排专项实验 |

每个阶段都完成“用户态如何访问 → 设备树如何描述 → 内核如何匹配 → 驱动如何使用资源 → 日志如何定位问题”的链路。

## 第一个硬件入口：板载 LED

从 [1N 设备树](../../arch/arm64/boot/dts/rockchip/rk3566-lubancat-1n.dts) 的 `leds` 节点开始。源码中 `compatible` 为 `gpio-leds`，系统灯位于 `gpio0` 的 `PC5`，低电平有效，默认触发器为 `heartbeat`。实验前结合板卡实际硬件版本及启动设备树核对。

阅读顺序：

1. 找到设备树节点中的 GPIO 与 pinctrl 描述。
2. 在 [leds-gpio.c](../../drivers/leds/leds-gpio.c) 中找匹配表与 `probe`。
3. 查阅 LED 子系统提供的 `/sys/class/leds/` 接口。
4. 继续追踪 GPIO 与 pinctrl 控制器如何操作引脚。

先通过已有驱动观察调用过程，再编写自己的小驱动。最小模块的旧实验说明可用于理解接口，见[归档](archive/01-hello-module.md)；后续需要使用 -24 对应环境重新编译和验证。

## 官方资料

- [官方 -24 标签](https://github.com/LubanCat/kernel/releases/tag/rk356x-4.19.232-24)
- [野火驱动开发教程](https://doc.embedfire.com/linux/rk356x/driver/zh/latest/index.html)
- [内核自带文档](../../Documentation/)
