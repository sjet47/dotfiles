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

修法：`sudo pacman -D --asexplicit ddcutil`（换成实际包名），然后补进清单。

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

`pacman -Rns --print plasma-meta` 会报 `invalid option: '--nosave' and '--print' may not be used together`。
如果你把 stderr 混进了 stdout 再数行数，会看到"只删 1 个包"这种假象，实际那 1 行是错误信息。
dry-run 用 `pacman -Rs --print --print-format '%n' plasma-meta`。

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

### 11. AUR 包会因系统库 SONAME 升级静默失效，而且重装无效

AUR 包是**在你机器上编译**的，链接的是当时的系统库。之后 pacman 升级了那个库、SONAME 变了，
旧二进制就加载不了 —— 但 pacman 不会告诉你，因为包依赖关系（`protobuf>=2.4.0` 这种）依然满足。

实例：`openvpn3` 构建于 7 月，链接 `libabsl_*.so.2605`；abseil-cpp 升到 `20260817.0-1` 之后
只提供 `.2608`，后端进程直接起不来。

**症状极具误导性** —— 主程序 `/usr/bin/openvpn3` 是好的，配置能正常加载，只有真正建隧道时
后端才崩，报错是 `New tunnel did not respond`，看着完全像网络问题。真正的原因得去 journal 里找：

```bash
journalctl -b | grep -i openvpn3 | grep 'error while loading shared libraries'
```

**重装解决不了**。paru 会复用 `~/.cache/paru/clone/<pkg>/` 里已构建的 `.pkg.tar.zst`，
装完 `pacman -Qi` 的 `Build Date` 纹丝不动。必须强制重建：

```bash
paru -S --rebuild openvpn3    # 换成实际包名
```

判断是否中招，看 `Build Date` 和缺库：

```bash
pacman -Qi openvpn3 | grep 'Build Date'
ldd /usr/lib/openvpn3-linux/openvpn3-service-client | grep 'not found'
```

体检全部 AUR 包（换机后、大版本升级后值得跑一次）：

```bash
for p in $(pacman -Qqem); do
  pacman -Ql "$p" | awk '{print $2}' | grep -E '/(bin|lib)/' | while read -r f; do
    [[ -f $f ]] || continue
    ldd "$f" 2>/dev/null | awk '/not found/{print $1}' | while read -r lib; do
      # Flutter/Electron 等自带库的应用把依赖放在同目录,单独 ldd 解析不到,属误报
      [[ -e "$(dirname "$f")/$lib" ]] && continue
      echo "[!] $p :: $(basename "$f") 缺 $lib"
    done
  done
done
```

> 已知无害的残留：`localsend-bin :: libdartjni.so 缺 libjvm.so` —— Dart 的 Java 互操作桥，
> LocalSend 在 Linux 上不使用，没装 JDK 就会报，可忽略。

### 12. PATH 里的项目工具链会污染 AUR 构建

`makepkg` 继承你当前 shell 的 PATH。如果 PATH 前面挂着项目级或语言管理器的 bin 目录
（opam / ghcup / bun / 各种 `.toolset/bin`），里面的旧版工具会**盖住系统版本**，
构建时用它生成代码、却对着系统头文件编译，于是炸在完全无关的地方。

实例：`openvpn3` 重建时报

```
/usr/include/google/protobuf/arena.h: error: invalid new-expression of
abstract class type 'openvpn::DcoKeyConfig_KeyDirection'
```

看着像"上游代码跟 protobuf 35 不兼容，这个包在 Arch 上坏了"。实际是
`~/heybox/repo/heybox-go/.zeus-toolset/bin/protoc`（libprotoc **26.1**）盖住了
`/usr/bin/protoc`（libprotoc **35.1**），差 9 个大版本，生成的 C++ 代码带的虚函数集
跟新运行时的抽象基类对不上。

排查 —— 比对同名工具的所有副本：

```bash
which -a protoc     # 换成构建报错涉及的工具:protoc / cmake / go / node ...
```

修法是用干净 PATH 构建：

```bash
PATH="/usr/bin:$PATH" paru -S --rebuild openvpn3
```

**一个上游包在标准 Arch 环境编译不过，先怀疑本地构建环境被污染，再怀疑上游。**
本机 PATH 前面常年挂着 5 个这类目录，中招概率不低。
