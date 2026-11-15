> 历史记录：该说明对应旧 -23 构建环境中的教学模块，仅完成主机端编译。当前 -24 的示例和上板实验在后续课程准备，见[驱动路线](../03-driver-roadmap.md)。

# 第一份内核模块

目标：理解 `.ko` 的编译、加载、参数、日志和卸载。此模块加载时打印一句话，卸载时打印另一句话。

在开发机执行：

```bash
cd /home/yiyi/Workspace/lubancat/examples/drivers/01_hello
make
modinfo lbc_hello.ko
```

Makefile 使用 `build/stable-1n/out` 中的内核配置和符号表，以及固定的 Linaro 工具链。`M=` 表示外部模块目录，`obj-m` 表示编译成可加载模块。

开发板启动我们构建的内核后，将 `.ko` 传到板上。先检查 `uname -r` 与 `modinfo -F vermagic lbc_hello.ko` 的内核版本部分一致，再执行：

```bash
sudo insmod ./lbc_hello.ko student=Linux
sudo dmesg | tail -n 15
cat /sys/module/lbc_hello/parameters/student
sudo rmmod lbc_hello
sudo dmesg | tail -n 15
```

验收：日志中出现 `hello, Linux` 和 `goodbye, Linux`，参数文件显示 `Linux`。

`module_init` 和 `module_exit` 注册入口与退出函数；`module_param` 提供模块参数；`pr_info` 写入内核日志。这里的权限 `0444` 表示参数在 sysfs 中只读。下一课将把这些入口与设备树匹配和 `probe` 联系起来。
