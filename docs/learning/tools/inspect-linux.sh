#!/bin/sh
# Read-only inventory. Run on the board to inspect the board itself.
set -u

show_command() {
    inspect_label=$1
    shift
    printf '\n[%s]\n' "$inspect_label"
    if command -v "$1" >/dev/null 2>&1; then
        if ! "$@" 2>&1; then
            printf '无法读取此项，可继续检查其他项目。\n'
        fi
    else
        printf '未安装命令：%s\n' "$1"
    fi
}

printf 'Linux 学习环境检查（只读，无需 sudo）\n'
printf '以下信息属于运行此脚本的机器；开发板信息需在开发板上采集。\n'

show_command '运行中的内核版本' uname -r
show_command '运行中的 CPU 架构' uname -m
show_command '用户空间位数' getconf LONG_BIT
show_command 'C 库版本（glibc 系统）' getconf GNU_LIBC_VERSION

printf '\n[系统发行版]\n'
if [ -r /etc/os-release ]; then
    sed -n '/^PRETTY_NAME=/p; /^ID=/p; /^VERSION_ID=/p' /etc/os-release
else
    printf '没有可读的 /etc/os-release。\n'
fi

printf '\n[设备树报告的板卡型号]\n'
if [ -r /proc/device-tree/model ]; then
    tr '\000' '\n' < /proc/device-tree/model
    printf '\n'
else
    printf '没有可读的设备树型号；普通 PC 通常没有此项。\n'
fi

printf '\n[设备树 compatible]\n'
if [ -r /proc/device-tree/compatible ]; then
    tr '\000' '\n' < /proc/device-tree/compatible
    printf '\n'
else
    printf '没有可读的 compatible。\n'
fi

printf '\n[内存，单位 kB]\n'
if [ -r /proc/meminfo ]; then
    awk '/^(MemTotal|MemAvailable|SwapTotal):/ { print }' /proc/meminfo
else
    printf '没有可读的 /proc/meminfo。\n'
fi

show_command '根文件系统容量' df -h /
show_command '根文件系统来源与类型' findmnt -n -o SOURCE,FSTYPE /
show_command '本机 IP 地址' hostname -I
show_command 'Python 版本' python3 --version

printf '\n[开发工具路径]\n'
for inspect_tool in git make gcc g++ cmake aarch64-linux-gnu-gcc ssh scp curl; do
    if command -v "$inspect_tool" >/dev/null 2>&1; then
        printf '%s: %s\n' "$inspect_tool" "$(command -v "$inspect_tool")"
    else
        printf '%s: 未安装或不在 PATH 中\n' "$inspect_tool"
    fi
done

printf '\n[PID 1：系统启动后的第一个进程]\n'
if [ -r /proc/1/comm ]; then
    cat /proc/1/comm
else
    printf '无法读取 /proc/1/comm。\n'
fi

printf '\n[CPU 指令集（首个 CPU）]\n'
if [ -r /proc/cpuinfo ]; then
    awk '/^(Features|flags)[[:space:]]*:/ { print; exit }' /proc/cpuinfo
else
    printf '无法读取 /proc/cpuinfo。\n'
fi

printf '\n检查结束。开发板不需要具备上面列出的全部开发工具。\n'
