# Shell shared functions

LBP=$HOME/.local/bin
ARCH=$(uname -m)

getbin() {
  wget "$1" -O $LBP/$2
  chmod +x $LBP/$2
}

os_name=$(uname)
if [[ $os_name == "Linux" ]]
then
  disv=$(cat /etc/issue | awk '{print $1}')
elif [[ $os_name == "Darwin" ]]
then
  disv="macOS"
fi
