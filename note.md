## Commandline

- [Explainshell](https://explainshell.com/)
- `less +F` for collect from stream
- `dig` for dns resolve
- `set -o vi` to set vi-style cmdline interface
- `set -o emacs` to revert to default style
- `!n` for the n-th command in `history`
- `cd -` go back to last workdir
- `pstree` display process tree, with `-p` for display pid
- `w` for uptime and who
- `<(command)` to make output of `command` as a file, like for `diff`
- `>file 2>&1` or `&>file` merge `stdout` and `stderr`
- `fzf`
- `fpp` pick files from `stdin`
- `jq` and `jnv` for json
- `shyaml` for yaml
- `csvkit` (`in2csv`, `csvcut`, `csvjoin`, `csvgrep`) for csv
- `uniq` `-u` for unique line only, `-d` for repeat line only, `-c` for count repeat
- `comm` for compare file in sorted order
- `cut`, `join`, `paste` for operate file
- `dateutils` for operate datetime
- `zless`, `zmore`, `zcat`, `zgrep` for operate compress file
- `truncate -s 0 filename` for effectively create empty file
- `mtr` for traceroute
- `tac` print file in reverse
- `last` login history
- `vmstat -awt 1` for monitor system status
- `gdb symbol pid` to attach gdb to a process with symbol from `symbol`
- `strace -c` syscall with counting time
- `/usr/share/bcc/tools/cpudist -O -p <pid>`


Here documents

```shell
cat <<EOF
this
is
a
multiple
line
buffer
EOF
```

The `EOF` can be any unique token not inside the buffer

## Shell script

- `set -x` or `set -v` to debug
- `set -eo pipefail` to print error, `-u` for unset variable
- use `(sub command)` to tmp change workdir
- `${var:?error message}` to display error message when variable `var` not exist
- `$(var:-default}` to set a default value for variable `var`
- `$(expr)` to run expression `expr` like `1+1`
- `${var%suffix}` trim `suffix` from `${var}`
- `${var#prefix}` trim `prefix` from `${var}`
- wrap script with `{}` to avoid incomplete script be executed

