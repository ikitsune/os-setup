## grc diff alias
alias diff='grc diff'

## grc dig alias
alias dig='grc dig'

## grc gcc alias
alias gcc='grc gcc'

## grc ifconfig alias
alias ifconfig='grc ifconfig'

## grc mount alias
alias mount='grc mount'

## grc netstat alias
alias netstat='grc netstat'

## grc ping alias
alias ping='grc ping'

## grc ps alias
alias ps='grc ps'

## grc tail alias
alias tail='grc tail'

## grc traceroute alias
alias traceroute='grc traceroute'

## grc wdiff alias
alias wdiff='grc wdiff'

## grc ip alias
alias ip='grc ip'

## Checksums
alias sha1="openssl sha1"
alias md5="openssl md5"

## List open ports
alias ports="netstat -tulanp"

## Get header
alias header="curl -I"

## Get external IP address
alias ipx="curl -s http://ipinfo.io/ip"

## DNS - External IP #1
alias dns1="dig +short @resolver1.opendns.com myip.opendns.com"

## DNS - External IP #2
alias dns2="dig +short @208.67.222.222 myip.opendns.com"

### DNS - Check ("#.abc" is Okay)
alias dns3="dig +short @208.67.220.220 which.opendns.com txt"


## Extract file, example. "ex package.tar.bz2"
ex() {
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2) tar xjf $1 ;;
      *.tar.gz)  tar xzf $1 ;;
      *.bz2)     bunzip2 $1 ;;
      *.rar)     rar x $1 ;;
      *.gz)      gunzip $1  ;;
      *.tar)     tar xf $1  ;;
      *.tbz2)    tar xjf $1 ;;
      *.tgz)     tar xzf $1 ;;
      *.zip)     unzip $1 ;;
      *.Z)       uncompress $1 ;;
      *.7z)      7z x $1 ;;
      *)         echo $1 cannot be extracted ;;
    esac
  else
    echo $1 is not a valid file
  fi
}

