# 源码和个人远程仓库

## 固定的官方起点

| 项目 | 内容 |
| --- | --- |
| 官方仓库 | `https://github.com/LubanCat/kernel.git` |
| 官方标签 | `rk356x-4.19.232-24` |
| 起点提交 | `c66bf3fcb4610d4444648496e7893c64af84ec64` |
| 个人公开 Fork | [orbits-yiyi/lubancat-kernel](https://github.com/orbits-yiyi/lubancat-kernel) |
| 个人开发分支 | `main` |

Fork 在 GitHub 上保留官方仓库的分支、标签和历史。个人开发从上述版本创建的 `main` 开始；官方标签用于查阅固定起点，之后的学习文档和实验可以继续形成个人提交。

## 已完成的迁移

2026-11-15 建仓时，本地完整源码包含 78,880 个受版本控制的文件，并已核对 43 个符号链接。选定分支已补全历史，共 870,486 个提交，通过 Git 连通性检查。

建仓时本地 `main`、远程 `origin/main` 与官方 -24 标签指向同一提交，个人仓库默认分支已设为 `main`，推送预检通过。后续 `main` 会随着文档和实验提交前进，官方标签继续标识原始版本。

前期 -23 构建中使用的本地修复没有加入本次 -24 源码。之前的构建和 TF 卡探索说明保存在[历史记录](archive/README.md)。

## 两个远程名称

| 名称 | 地址 | 用途 |
| --- | --- | --- |
| `origin` | `https://github.com/orbits-yiyi/lubancat-kernel.git` | 保存个人开发成果 |
| `upstream` | `https://github.com/LubanCat/kernel.git` | 查阅和获取官方更新 |

`origin` 和 `upstream` 是本地为远程地址起的名字。`main` 是可继续提交的分支；`rk356x-4.19.232-24` 是用于标识官方版本的标签。本地 `main` 跟踪个人仓库的 `origin/main`。

## 先熟悉三个命令

在本仓库根目录执行：

```bash
git status
git remote -v
git branch -vv
```

依次观察工作区是否有修改、两个远程地址，以及 `main` 的跟踪关系。

之后使用：

```bash
git log --oneline -5
git show rk356x-4.19.232-24
```

第一条查看最近提交，第二条查看官方版本标记。阅读驱动时，可以进一步学习 `git log -- 文件路径` 和 `git blame 文件路径`。

## 在新环境获取源码

在另一台机器上需要获取个人仓库时，可以执行：

```bash
git clone https://github.com/orbits-yiyi/lubancat-kernel.git
cd lubancat-kernel
git remote add upstream https://github.com/LubanCat/kernel.git
```

内核历史较大，首次克隆需要等待。当前开发机已有完成迁移的本地副本，直接进入该副本开展学习即可。

## 下一阶段

接下来先认识源码目录与“芯片启动逻辑 → U-Boot → 内核和设备树 → 根文件系统”，再逐步准备构建环境和 eMMC 启动验证，见[项目方案](01-project-plan.md)。
