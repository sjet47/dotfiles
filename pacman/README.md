# 包清单与对账

本机显式安装的包，按**迁移优先级**分组记录。换机时按组安装，日常靠对账防止清单腐烂。

## 文件构成

| 文件 | 内容 |
| --- | --- |
| `00-base.txt` | 内核、固件、显卡驱动、包管理、网络、文件系统、打印 —— 装机第一步 |
| `10-desktop.txt` | Hyprland、KDE 应用、音频、输入法、字体 —— 装完有可用图形界面 |
| `20-cli.txt` | 日常 CLI，交互习惯全在这 |
| `30-dev.txt` | 语言链、容器、数据库、性能剖析、AI agent |
| `40-apps.txt` | GUI 应用、代理 VPN、抓包、游戏 |
| `90-optional.txt` | 备选方案 / 一次性尝试 / 玩具，**迁移时整组跳过** |
| `pkg-sync` | 对账 + 安装 |

清单只收 `pacman -Qqe`（显式安装）的包，依赖由 pacman 自动拉齐，不入库。

格式是每行一个包名，`#` 之后为注释，`[AUR]` 标记的包必须用 paru 装。行尾注释初版是 pacman
自带的包描述，**逐步替换成"我为什么需要它"更有价值** —— `10-desktop.txt` 里那批中文注释是范例。

## 日常用法

```bash
./pacman/pkg-sync              # 双向对账
./pacman/pkg-sync repos        # 只检查前置仓库
./pacman/pkg-sync install      # 装 00~40 组(跳过 90-optional)
./pacman/pkg-sync install 30-dev 40-apps   # 只装指定组
```

装了新包之后随手跑一次对账，它会报出「系统里有、清单里没有」，把包补进对应分组即可。
反方向的「清单里有、系统没装」说明清单腐烂了（包被弃用或改名），删掉对应行。

## 迁移到新机器

1. 先启用 `multilib` 和 `archlinuxcn` 仓库（见下方第 5 条坑），装好 `paru`
2. `./pacman/pkg-sync install 00-base` → 能开机联网
3. `./pacman/pkg-sync install 10-desktop` → 有图形界面
4. 剩下的按需装，`90-optional` 想清楚再单独挑

---

## 坑

### 1. 脚本直接调用的包，必须是显式安装

清单只收显式包。如果某个包当前只是**别人的依赖**，而你的脚本直接调用它，那么新机器按清单
装完之后它可能根本不在，或者哪天它的上游被卸载时它跟着消失 —— 而且是**静默失效**。

实例：`config/hypr/scripts/brightness.sh` 直接调 `ddcutil` 调外接屏亮度，但 `ddcutil` 当时
只是 `powerdevil`（KDE 组件）的依赖。脚本里有 `2>/dev/null` 兜底，坏了都不报错。

排查方法 —— 拿待删包提供的所有可执行文件名，去 grep 自己的配置和脚本：

```bash
pkg=ddcutil    # 换成要查的包名
pacman -Ql "$pkg" | awk '$2 ~ /^\/usr\/bin\/[^\/]+$/ {print $2}' | xargs -n1 basename
```

修法：`sudo pacman -D --asexplicit <pkg>`，然后补进清单。

### 2. enabled 的服务却是非显式安装 = 定时炸弹

服务天天在跑，包却挂在别人的依赖链上，随时可能被当孤儿扫掉。

实例：`sddm`（登录管理器，`sddm.service` enabled）唯一的依赖方是 `sddm-kcm`，而 `sddm-kcm`
自己已经是孤儿 —— 清一次孤儿就连锁删掉 sddm，**下次开机进不了桌面**。
`wireplumber` / `pipewire` / `pipewire-pulse` 同理，依赖方里还有正准备卸载的 `kwin`，
断了就是没声音。

排查方法 —— 遍历 enabled 的 unit，查 `FragmentPath` 归属包的 `Install Reason`：

```bash
systemctl list-unit-files --state=enabled --type=service --no-legend | awk '{print $1}' |
while read -r svc; do
  [[ $svc == *@.service ]] && continue          # 模板单元没有实例,跳过
  unit_path=$(systemctl show -p FragmentPath --value "$svc")
  [[ -f $unit_path ]] || continue
  pkg=$(pacman -Qoq "$unit_path" 2>/dev/null) || continue
  reason=$(pacman -Qi "$pkg" | grep '^Install Reason' | cut -d: -f2-)
  [[ $reason == *dependency* ]] && echo "[!] $pkg <- $svc"
done
```

用户级服务把两处 `systemctl` 都换成 `systemctl --user` 再跑一遍。

> 变量名别用 `path` —— zsh 里它是绑定 `PATH` 的特殊数组，`path=$(...)` 会把整个 `PATH`
> 覆盖成一个字符串，之后所有命令都 `command not found`。bash 没这个行为，所以这类脚本
> 在 bash 下测通、拿到 zsh 里就炸。本仓库默认 shell 是 zsh，写脚本时留意。

### 3. 孤儿包不能盲扫

`pacman -Rns $(pacman -Qdtq)` 是危险操作。孤儿列表是一次性算出来的，删掉一层之后会**露出
新的一层**，多扫几轮就可能吃掉上面两条里那种关键包。清理前逐个 review。

### 4. 装包必须 `-Syu`，不能只 `-S`

对着过期的本地数据库直接 `pacman -S` 装包会造成 **partial upgrade**：新包链接到已升级的库，
系统里却还是旧库，典型症状是装完之后一堆程序 `symbol lookup error`。`pkg-sync install`
已经用 `-Syu`。

### 5. 新机器必须先启用 multilib 和 archlinuxcn

清单里的包分布在 `core` / `extra` / `multilib` / `archlinuxcn`，后两个默认没有 ——
multilib 在 `/etc/pacman.conf` 里是注释掉的，archlinuxcn 要手工添加。

缺了仓库，pacman 只会报一堆 `target not found`，**不会告诉你根因**。所以 `pkg-sync install`
把仓库检查挡在了执行路径上，缺什么、怎么修都会直接打出来。

判断仓库用 `pacman-conf --repo-list`，不要 grep `/etc/pacman.conf` —— 前者能正确处理
`Include` 和注释行，而且 `pacman-conf` 由 pacman 本体提供，新机器上必定存在。

### 6. `-n` 和 `--print` 不能同时用

`pacman -Rns --print <pkg>` 会报 `invalid option: '--nosave' and '--print' may not be used together`。
如果你把 stderr 混进了 stdout 再数行数，会看到"只删 1 个包"这种假象，实际那 1 行是错误信息。
dry-run 用 `pacman -Rs --print --print-format '%n' <pkg>`。

### 7. 管道喂 stdin 时 pacman 需要 tty

`pacman -S -` 从 stdin 读包名（`man pacman` 有明文），但读完之后它要**重开终端**做交互确认。
无 tty 环境下会报 `failed to reopen stdin for reading`。真实终端里正常，
**放进 CI / 非交互脚本必须加 `--noconfirm`**。

### 8. 卸载用 `-Rs`，不要 `-Rsc`

`-s` 只删「不再被需要且非显式安装」的依赖，显式包受保护。`-c`（cascade）是反向的 ——
把所有**依赖它**的包一并删掉，范围会失控。

### 9. 不要引入第三方声明式包管理工具

调研过，生态是荒漠：`pacdef` 已从 AUR 下架、`aconfmgr` 停更在 2021 年、`decman` 只有 2 votes。
而且逻辑上自相矛盾 —— 写迁移方案是为了对抗重装的不确定性，结果方案本身依赖一个随时会消失的
AUR 包。pacman 原生的 `-Qqe` / `-Qqen` / `-Qqem` 加 stdin 安装已经够用。

### 10. 手工维护的清单一定会腐烂

这套东西的前身是三份手写清单，最后的状态是：引用了从没装过的包、同一个包写了两遍、
三份加起来还漏掉 245 个显式包。**清单的价值不在于写下来，而在于能和现实对账。**
所以宁可注释写得糙一点，也要保证 `pkg-sync` 能跑通。
