# 包清单与对账

本机显式安装的包，按**迁移优先级**分组记录。换机时按组安装，日常靠对账防止清单腐烂。

## 文件构成

| 文件 | 内容 | 入 git |
| --- | --- | --- |
| `00-local.txt` | **本机专属**：微码、显卡驱动栈、固件、引导、专属外设 + 本机的历史包袱 | ✗ |
| `00-local.example.txt` | 上面那份的模板，新机器照着抄 | ✓ |
| `10-base.txt` | 包管理、网络、文件系统、归档、打印 —— 装机第一步 | ✓ |
| `20-desktop.txt` | Hyprland、KDE 应用、音频、输入法 —— 装完有可用图形界面 | ✓ |
| `25-fonts.txt` | CJK / 兜底字形 / emoji / 等宽 / UI 字体 | ✓ |
| `30-cli.txt` | 日常 CLI，交互习惯全在这 | ✓ |
| `40-dev.txt` | 语言链、容器、数据库、性能剖析、AI agent | ✓ |
| `50-apps.txt` | GUI 应用、代理 VPN、抓包、游戏、32 位运行时 | ✓ |
| `90-optional.txt` | 备选方案 / 一次性尝试 / 玩具，**迁移时整组跳过** | ✓ |
| `../scripts/pkg-sync` | 对账 + 安装（在 PATH 里，可直接敲 `pkg-sync`）| ✓ |

清单只收 `pacman -Qqe`（显式安装）的包，依赖由 pacman 自动拉齐，不入库。

### `00-local.txt` 为什么不入 git

它收两类东西，共同点是**不该跟着仓库复制到别的机器上**：

1. **硬件绑定** —— 微码认 CPU 厂商，显卡驱动认 GPU 厂商，固件和引导认主板。抄错了轻则
   驱动不加载，重则开不了机。
2. **本机的历史包袱** —— 入库清单描述的是"这套 dotfiles 想要的系统"，桌面只有
   **Hyprland 一系**。某台机器上多出来的东西（装机时留下的另一个桌面环境、给一次性项目装的
   服务端）属于那台机器的情况，写进入库清单会让新机器按仓库装完莫名其妙多出一堆东西。
   本机的实例：整套 `plasma-meta`（55 个包 / ~274 MiB），和 Hyprland 并存着，只是为了
   随时能切回去登另一个会话。

所以它被 `.gitignore` 排除，每台机器自己维护一份，版本库里只留 `00-local.example.txt`
当模板（AMD 那一套写在里面，注释掉了）。

注意第 2 类和 `90-optional.txt` 的区别：`90-optional` 是"**任何机器**都可留可不留"，会入库；
`00-local` 是"**只有这台机器**才有"，不入库。KDE *应用*（dolphin/okular/gwenview）两者都不属于
—— 它们不依赖 Plasma 会话，而且 `mimeapps.list`、`vars.lua`、`windowrules.lua` 直接点名了
它们，所以留在 `20-desktop.txt` 入库。

新机器上第一步：

```bash
cp pacman/00-local.example.txt pacman/00-local.txt   # 然后按自己的硬件删改
```

不做这一步的话，`pkg-sync` 会把本机的微码和显卡驱动全报成「系统里有、清单里没有」——
它检测到缺文件时会直接提示。

### `90-optional.txt` 是单向对账

这一组里的包**装了不报「未记录」，没装也不报「缺包」**。所以它既能停放"装着但随时能删"的
包（被更好方案取代的旧工具），也能停放"记着但暂时不装"的包（要 license 的、依赖特定硬件的、
上游构建坏掉的）。其余组是双向对账：写进去就意味着"这台机器应该装它"。

格式是每行一个包名，`#` 之后为注释，`[AUR]` 标记的包必须用 paru 装。行尾注释初版是 pacman
自带的包描述，**逐步替换成"我为什么需要它"更有价值** —— `20-desktop.txt` 里那批中文注释是范例。

## 日常用法

```bash
pkg-sync              # 三向对账
pkg-sync repos        # 只检查前置仓库
pkg-sync orphans      # 列出全部孤儿包(按体积排序)
pkg-sync install      # 装 00~50 组(跳过 90-optional)
pkg-sync install 40-dev 50-apps   # 只装指定组
```

装了新包之后随手跑一次对账，它会报出「系统里有、清单里没有」，把包补进对应分组即可。
反方向的「清单里有、系统没装」有三种情况，别一律当腐烂处理：

1. **包其实装着，只是被标成了 dependency** —— `pacman -Qqe` 收不到它。这是最常见的一种，
   也正是下面坑 1、坑 2 说的定时炸弹。修法是 `sudo pacman -D --asexplicit <pkg>`，不是重装。
   先分类再动手：

   ```bash
   pkg-sync | sed -n '/清单里有/,/^$/p' | sed -n 's/^  - //p' |
     while read -r p; do pacman -Qq "$p" >/dev/null 2>&1 &&
       echo "已装,改标记: $p" || echo "真的没装: $p"; done
   ```

2. **真的没装** —— 要么装上，要么想清楚不装、挪进 `90-optional.txt`。
3. **清单腐烂**（包被弃用、改名、或从仓库下架）—— 删掉对应行，换成继任者。

### 第三个方向：孤儿层

前两个方向对的都是**显式包**（`pacman -Qqe`）。任何以「依赖」身份装进来的东西不在这个
视野里 —— 不管是 AUR 的 makedepends 残留，还是一个 717 MiB 的 GUI 程序，对账都会一路
报「一致」。2026-08-30 那次盘点就是这么发现的：`wechat-bin`、`sing-box` 装在机器上、
清单里查无此人，而 `pkg-sync` 从没提过一句。

所以 `pkg-sync` 现在会同时报孤儿层（`pacman -Qdt`：没人依赖它、当初又是当依赖装的），
默认只摘体积最大的 5 个，完整列表走 `pkg-sync orphans`。

**这一层不要一键清理。** 构建残留和真应用在 `-Qdt` 的输出里长得完全一样：

- 要留的 → `sudo pacman -D --asexplicit <包名>`，再补进对应清单。不转显式的话，
  下次孤儿清理照样扫掉。
- 大批 `gcc*` / `llvm*` / `electron*` / `qt5-doc` 堆在这里 → 是 paru 没清 makedepends，
  在 `/etc/paru.conf` 的 `[options]` 下加 `RemoveMake` 和 `CleanAfter` 堵源头，
  否则清完过几个月原样长回来。

顺带一提，占地大头往往不是包而是**缓存**：`/var/cache/pacman/pkg` 和 `~/.cache/paru`
都不受任何对账约束。`paccache -dk3` 先 dry-run 看看能省多少，
`systemctl enable --now paccache.timer` 挂上定期清理。

## 迁移到新机器

1. 先启用 `multilib` 和 `archlinuxcn` 仓库（见下方第 5 条坑），装好 `paru`
2. `cp 00-local.example.txt 00-local.txt`，按新机器的 CPU/GPU 改（`lscpu`、`lspci -k`）
3. `pkg-sync install 00-local 10-base` → 能开机联网
4. `pkg-sync install 20-desktop 25-fonts` → 有图形界面且不满屏方框
5. 剩下的按需装，`90-optional` 想清楚再单独挑

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

> 已知无害的残留：`localsend :: libdartjni.so 缺 libjvm.so` —— Dart 的 Java 互操作桥，
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

### 13. `.pacnew` 会无声堆积，而且 diff 要用 sudo

包升级时若配置文件被本地改过，pacman 不会覆盖，而是把新版本写成 `<file>.pacnew` 放旁边。
**不会有任何提示**，于是你的配置一直停在旧版，错过上游的新选项和安全默认值。本机曾一次性
攒下 14 个，最老的来自 2025-10。

```bash
sudo find /etc -name '*.pacnew' -o -name '*.pacsave'
```

**坑**:`/etc/sudoers` 是 0440,不加 sudo 的 `diff` 会静默失败、输出为空。如果你拿
`diff a b | grep -c '^[<>]'` 数差异行,会得到 0,误判成"没差异可以直接删"——而 sudoers
恰恰是这批里最不能出错的。**整个扫描循环都要在 root 下跑**。

合并的判断顺序:

1. 先看**双方各自的生效行**(`grep -vE '^\s*#|^\s*$'`),而不是通读整个 diff ——
   `.pacnew` 大部分改动是注释和文档,生效行往往只有几条
2. 你的生效行 = 本地定制,默认全部保留。特别当心承重的:`sshd_config` 的
   `AllowTcpForwarding`(wayvnc 隧道靠它)、`/etc/default/v2raya` 的 shim 路径、
   `pacman.conf` 的 `[multilib]`/`[archlinuxcn]`(清单安装依赖)
3. pacnew 的生效行 = 上游新默认值,逐条决定是否采纳
4. 改完**立刻用该配置自己的校验器验证**:`visudo -c -f`、`sshd -t`、`bash -n /etc/profile`、
   `pacman -Sy`。sudoers 写错会让 sudo 完全不可用,必须先 `visudo -c` 通过再落盘

`pacman -Qkk <pkg>` 报 backup file 校验不匹配时,未必是你改过——也可能是包已更新而
`/etc` 里还是旧版(即存在未处理的 .pacnew)。采纳 pacnew 反而能消除这个不匹配。

### 14. 缓存比孤儿包大一个数量级

清了 3 GiB 孤儿之后才发现 `/var/cache/pacman/pkg` 有 93 GiB、`~/.cache/paru` 有 46 GiB。

```bash
sudo paccache -rk2      # 每个包保留最近 2 个版本(本机一次释放 79.67 GiB)
sudo paccache -ruk0     # 再清已卸载包的缓存;刚做过大批卸载时先别清,这是回滚保险
```

`/var/cache/pacman/pkg/download-*` 是中断下载留下的暂存目录(root 0700,`du` 会报权限
拒绝),`paccache` 不管它们,需要手工删。本机攒了 6 个共 292 MiB。

### 15. 官方仓库里有的包，不要为了"快"去用 AUR 的 `-bin`

`-bin` 的意义是**免掉本地编译**。但 `core`/`extra`/`multilib`/`archlinuxcn` 里的包本来就是
别人编译好的二进制，同样不用本地编译，而且有签名、跟着仓库一起升级、不会像 AUR 包那样因为
系统库 SONAME 变了就静默失效（坑 11）。所以取舍顺序是：

**官方仓库 → archlinuxcn → AUR 的 `-bin` → AUR 源码包**

只有仓库里根本没有的，才轮得到 `-bin`。本机的 `vicinae-bin` / `herdr-bin` / `tensaku-bin`
属于这一类。

**这条最初写错了举例**：曾把 `ast-grep-bin` / `localsend-bin` / `telegram-desktop-bin`
也列进"仓库里没有"，实际三个都有（`extra/ast-grep`、`archlinuxcn/localsend`、
`extra/telegram-desktop`，`telegram-desktop` 甚至与 AUR 同版本），`nali-go-bin` 同理。
2026-08-31 已全部换成仓库版。所以判断不能凭印象，装 `-bin` 前先实际搜一遍：

```bash
# 对每个 pacman -Qm 的外部包，查同名及去掉 -bin/-git 后缀的名字
for p in $(pacman -Qmq); do
  b=${p%-bin}; b=${b%-git}
  for c in "$p" "$b"; do
    pacman -Si "$c" &>/dev/null && { echo "$p -> $(pacman -Si "$c" | awk -F': +' '/^Repository/{print $2;exit}')/$c"; break; }
  done
done
```

换过去要留意命令名可能不一致：`extra/ast-grep` 不装 `sg` 短名（与 util-linux 的 `sg`
冲突），`telegram-desktop` 的二进制叫 `Telegram`。

反过来，清单从别的机器抄过来时，`-bin` 这一栏最容易过期：

- `jnv-bin` 已从 AUR 下架，`extra` 里的 `jnv` 就是它的继任者
- `bpftool-bin` 同样下架，bpftool 现在由 `extra/bpf` 提供

`pkg-sync` 报「清单里有、系统没装」而 `paru -Si <pkg>` 又查不到时，先去仓库里搜同名/近名的包，
多半是这种"AUR 包被官方收编"的迁移，而不是清单写错了。

### 16. AUR 包会因为上游而不是你而构建失败，要分清

本机有两个 32 位运行时包卡在这上面（已挪进 `90-optional.txt` 并写明原因）：

- `lib32-libcanberra`：源码在 `git.0pointer.net`，该站 TLS 证书域名不匹配，`git clone` 直接失败
- `lib32-openal`：PKGBUILD 拿 64 位的 `/usr/lib/libmysofa.so` 去链 32 位目标，
  `ld` 报 `file in wrong format`，而 multilib 里并没有 `lib32-libmysofa`

这两种都不是坑 12 那种"本地 PATH 污染"，重建、清缓存、换干净 PATH 都没用。判断方法：
报错发生在 **download/prepare 阶段**（拉不到源码）或指向 **PKGBUILD 自己的依赖声明**
（链错架构的库、缺一个仓库里不存在的 lib32-*），就是上游的问题；报错发生在编译阶段、
且报的是版本不兼容，才先怀疑本地环境。

另外 `check()` 失败（跑上游测试用例挂了）不影响产物可用，`paru -S --nocheck <pkg>` 可以跳过 ——
`grpcurl` 现在就得这么装。

### 17. 本地构建的包会因为 pkgrel 更高而永久压住仓库版

`pacman -Syu` 只在**仓库版本更高**时才替换。所以一个本地 `makepkg` 出来的包，只要 `pkgrel`
比仓库那份大，就会**永远**留在系统里 —— 不报冲突、不报错、`-Syu` 天天跑也纹丝不动。

实例：`isd` 启动即 `ModuleNotFoundError: No module named 'pfzy'`，但 `pacman -Qq python-pfzy`
明明有，而且它就是 `isd` 声明的依赖。原因是本地那份 `python-pfzy 0.3.4-3` 是 2025-02 手工构建的，
文件落在 `/usr/lib/python3.13/site-packages/`；系统 Python 早已升到 3.14，`isd` 也是按 3.14 打的包。
仓库里的 `0.3.4-2` 才是正确的 3.14 构建，但 `-3 > -2`，pacman 认为本地更新，于是一直不换。

**这和坑 11 是同一类"依赖关系满足、运行时却是坏的"，只是换成了 Python 侧**：SONAME 那套对
Python 不适用，Python 认的是 `site-packages` 的版本号目录，大版本一跳，旧目录里的模块就再也
`import` 不到了。

判断一个包是不是本地构建的残留，看两个字段：

```bash
pacman -Qi python-pfzy | grep -E 'Packager|Validated|Build Date'
# Packager : Unknown Packager    ← 官方包这里是维护者邮箱
# Validated By : None            ← 官方包这里是 Signature
```

修法是显式指定仓库来源，把它降回去：

```bash
sudo pacman -S extra/python-pfzy
```

全库体检 —— 列出所有"本地版本高于仓库版本"的包（`expac` 批量查，逐个 `expac` 会慢到超时）：

```bash
export LC_ALL=C   # 不设的话 join 会因排序规则不一致而漏配
expac -Q '%n %v' | sort -k1,1 > /tmp/lv
expac -S '%n %v' | sort -u -k1,1 > /tmp/sv
join /tmp/lv /tmp/sv | while read -r n lv sv; do
  [[ $(vercmp "$lv" "$sv") -gt 0 ]] &&
    printf '%-30s 本地 %-16s 仓库 %-16s %s\n' "$n" "$lv" "$sv" \
      "$(pacman -Qi "$n" | sed -n 's/^Packager *: //p')"
done
```

顺带查还有哪些包卡在旧 Python 目录里（Python 大版本升级后值得跑一次）：

```bash
for d in /usr/lib/python3.1[0-9]/site-packages/*/; do
  [[ $d == /usr/lib/python$(python3 -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")')/* ]] && continue
  pacman -Qoq "$d" 2>/dev/null
done | sort -u
```

> 本机 2026-08-30 复核结果：`python-pfzy` 已修（降回 `extra` 版，isd 正常）。
> 剩下 `python-pptx 1.0.2-6` 同样是本地构建、pkgrel 高于仓库，但文件在 3.14 里、能 import，
> 暂时没坏 —— 下次 Python 大版本跳的时候它会以同样的方式静默失效，届时同法处理。
> `python-textual-autocomplete 4.0.6-1`（本地构建、卡在 3.13、`import` 失败）和
> `python-backports-zstd`（官方包，落在 3.13 是它的本职）两个都是 `Required By: None` 的孤儿，
> 按坑 3 逐个 review 后再清。

### 18. 入库清单不是"这台机器装了什么"，是"这套 dotfiles 需要什么"

这两者的差距会在**第二台机器**上一次性结账。本仓库的实例：把一台机器的 130 个未记录包
补进入库清单之后，另一台机器跑 `pkg-sync` 报出 **99 个缺包** —— 绝大多数不是那台机器缺东西，
而是清单里混进了第一台机器的偶然状态（自建服务、裸 k8s 控制面、一整套代理栈、几十个
一次性装的 Python 库）。

判据 —— 一个包该进**入库**清单，当且仅当满足以下之一：

1. **tracked 的配置或脚本直接调用它**，能 grep 出证据（`git`、`brightnessctl`、`wlogout`、
   `xclip`、`playerctl` 属于这类）
2. **没有它，某个 tracked 配置会静默降级** —— 字体、编解码器、输入法词库、GTK 主题。
   不报错，只是变难看或缺字
3. **它是 Arch 系统本身的底座** —— `base`、`networkmanager`、`btrfs-progs`

不满足的去处：跟硬件/本机绑定的进 `00-local.txt`，其余进 `90-optional.txt`。

第 1 条要用证据，不能靠印象。包名和命令名经常对不上（`bpf` 提供 `bpftool`），
而且短包名 grep 会大量误报 —— 实测 `tiny` 命中的是 SVG 里的英文单词、`xray` 命中的是
Hyprland 的 `debug:xray` 选项、`imagemagick` 命中的是 `convert`/`display`/`stream`
这些常见词。所以要**限定文件类型**并逐条复核：

```bash
grep -rIlw --exclude-dir=.git --exclude-dir=pacman \
  --include='*.sh' --include='*.lua' --include='*.zsh' --include='*.toml' \
  --include='*.kdl' --include='*.jsonc' --include='*.qml' --include='*.list' \
  "$pkg" .
```

**换机是唯一能验证清单的时机。** 第二台机器的 `pkg-sync` 输出不是"那台机器缺东西"的清单，
而是"第一台机器污染了多少"的账单 —— 拿它来反向修剪入库清单，比在单机上凭空判断准得多。
