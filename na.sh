#!/bin/bash
hyygV="22.8.29 V 3.3"
remoteV=`wget -qO- https://gitlab.com/rwkgyg/hysteria-yg/raw/main/hysteria.sh | sed  -n 2p | cut -d '"' -f 2`

red='\033[0;31m'
bblue='\033[0;34m'
plain='\033[0m'
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
readp(){ read -p "$(yellow "$1")" $2;}
[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit 1
yellow " 请稍等3秒……正在扫描vps类型及参数中……"
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "不支持你当前系统，请选择使用Ubuntu,Debian,Centos系统。" && exit 1
fi
vsid=`grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1`
sys(){
[ -f /etc/os-release ] && grep -i pretty_name /etc/os-release | cut -d \" -f2 && return
[ -f /etc/lsb-release ] && grep -i description /etc/lsb-release | cut -d \" -f2 && return
[ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return;}
op=`sys`
version=`uname -r | awk -F "-" '{print $1}'`
main=`uname  -r | awk -F . '{print $1}'`
minor=`uname -r | awk -F . '{print $2}'`

bit=`uname -m`
if [[ $bit = x86_64 ]]; then
cpu=amd64
elif [[ $bit = aarch64 ]]; then
cpu=arm64
else
red "VPS的CPU架构为$bit 不支持当前系统的CPU架构，请使用amd64或arm64架构的CPU运行脚本" && exit 1

vi=`systemd-detect-virt`
rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

wgcfgo(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
sureipadress
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
sureipadress
systemctl start wg-quick@wgcf >/dev/null 2>&1
fi
}

if [[ $vi = openvz ]]; then
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
red "检测到未开启TUN，现尝试添加TUN支持" && sleep 2
cd /dev
mkdir net
mknod net/tun c 10 200
chmod 0666 net/tun
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
green "添加TUN支持失败，建议与VPS厂商沟通或后台设置开启" && exit 0
else
green "恭喜，添加TUN支持成功，现添加TUN守护功能" && sleep 4
cat>/root/tun.sh<<-\EOF
#!/bin/bash
cd /dev
mkdir net
mknod net/tun c 10 200
chmod 0666 net/tun
EOF
chmod +x /root/tun.sh
grep -qE "^ *@reboot root bash /root/tun.sh >/dev/null 2>&1" /etc/crontab || echo "@reboot root bash /root/tun.sh >/dev/null 2>&1" >> /etc/crontab
green "TUN守护功能已启动"
fi
fi
fi
[[ $(type -P yum) ]] && yumapt='yum -y' || yumapt='apt -y'
[[ $(type -P curl) ]] || (yellow "检测到curl未安装，升级安装中" && $yumapt update;$yumapt install curl)
[[ $(type -P lsof) ]] || (yellow "检测到lsof未安装，升级安装中" && $yumapt update;$yumapt install lsof)
[[ ! $(type -P qrencode) ]] && ($yumapt update;$yumapt install qrencode)
if [[ -z $(grep 'DiG 9' /etc/hosts) ]]; then
v4=$(curl -s4m5 https://ip.gs -k)
if [ -z $v4 ]; then
echo -e nameserver 2a01:4f8:c2c:123f::1 > /etc/resolv.conf
fi
fi
systemctl stop firewalld.service >/dev/null 2>&1
systemctl disable firewalld.service >/dev/null 2>&1
setenforce 0 >/dev/null 2>&1
ufw disable >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -t nat -F >/dev/null 2>&1
iptables -t mangle -F >/dev/null 2>&1
iptables -F >/dev/null 2>&1
iptables -X >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
if [[ -n $(apachectl -v 2>/dev/null) ]]; then
systemctl stop httpd.service >/dev/null 2>&1
systemctl disable httpd.service >/dev/null 2>&1
service apache2 stop >/dev/null 2>&1
systemctl disable apache2 >/dev/null 2>&1
fi


if [[ $release = Centos ]]; then
if [[ ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
fi
yum install epel-release -y
else
$yumapt update
fi

rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum install golang

apt install software-properties-common
add-apt-repository ppa:longsleep/golang-backports 
apt update 
apt install golang-go

go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive


rm /usr/bin/caddy
wget -N https://github.com/rkygogo/na/raw/main/caddy2-naive-linux-${cpu}.tar.gz
tar zxvf caddy2-naive-linux-${cpu}.tar.gz
rm caddy2-naive-linux-${cpu}.tar.gz -f
chmod +x caddy
mv caddy /usr/bin/
mkdir /etc/caddy


inscertificate(){
green "hysteria协议证书申请方式选择如下:"
readp "1. acme一键申请证书（支持常规80端口模式与dns api模式），已有证书则自动识别（回车默认）\n2. 自定义证书路径\n请选择：" certificate
if [ -z "${certificate}" ] || [ $certificate == "1" ]; then
if [[ -f /root/cert.crt && -f /root/private.key ]] && [[ -s /root/cert.crt && -s /root/private.key ]]; then
blue "经检测，之前已申请过acme证书"
readp "1. 直接使用原来的证书，默认root路径（回车默认）\n2. 删除原来的证书，重新申请acme证书\n请选择：" certacme
if [ -z "${certacme}" ] || [ $certacme == "1" ]; then
readp "请输入已申请过的acme证书域名:" ym
echo ${ym} > /etc/hysteria/ca.log
blue "输入的域名：$ym ，已直接引用\n"
elif [ $certacme == "2" ]; then
rm -rf /root/cert.crt /root/private.key
wget -N https://gitlab.com/rwkgyg/acme-script/raw/main/acme.sh && bash acme.sh
ym=$(cat /etc/hysteria/ca.log)
if [[ ! -f /root/cert.crt && ! -f /root/private.key ]] && [[ ! -s /root/cert.crt && ! -s /root/private.key ]]; then
red "证书申请失败，脚本退出" && exit
fi
fi
else
wget -N https://gitlab.com/rwkgyg/acme-script/raw/main/acme.sh && bash acme.sh
ym=$(cat /etc/hysteria/ca.log)
if [[ ! -f /root/cert.crt && ! -f /root/private.key ]] && [[ ! -s /root/cert.crt && ! -s /root/private.key ]]; then
red "域名申请失败，脚本退出" && exit
fi
fi
certificatec='/root/cert.crt'
certificatep='/root/private.key'

elif [ $certificate == "2" ]; then
readp "请输入已放置好证书的路径（/a/b/……/cert.crt）：" cerroad
readp "请输入已放置好证书的路径（/a/b/……/private.key）：" keyroad
certificatec=$cerroad
certificatep=$keyroad


else 
red "输入错误，请重新选择" && inscertificate
fi
}


insport(){
readp "hysteria端口设置[1-65535]（回车跳过为443端口）：" port
if [[ -z $port ]]; then
port=443
until [[ -z $(ss -ntlp | awk '{print $4}' | grep -w "$port") ]]
do
[[ -n $(ss -ntlp | awk '{print $4}' | grep -w "$port") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义hysteria端口:" port
done
else
until [[ -z $(ss -ntlp | awk '{print $4}' | grep -w "$port") ]]
do
[[ -n $(ss -ntlp | awk '{print $4}' | grep -w "$port") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义hysteria端口:" port
done
fi
blue "已确认端口：$port\n"
}

insuser(){
readp "hysteria设置用户名（回车跳过为随机6位字符）：" user
if [[ -z ${user} ]]; then
pswd=`date +%s%N |md5sum | cut -c 1-6`
fi
blue "已确认用户名：${user}\n"
}

inspswd(){
readp "hysteria设置密码（回车跳过为随机10位字符）：" pswd
if [[ -z ${pswd} ]]; then
pswd=`date +%s%N |md5sum | cut -c 1-10`
fi
blue "已确认密码：${pswd}\n"
}



green "设置配置文件中……，稍等5秒"

    
cat << EOF >/etc/caddy/Caddyfile
{
https_port $port
}
:$port, $ym
tls admin@seewo.com
route {
 forward_proxy {
   basic_auth ${user} ${pswd}
   hide_ip
   hide_via
   probe_resistance
  }
 reverse_proxy  https://ygkkk.blogspot.com  {
   header_up  Host  {upstream_hostport}
   header_up  X-Forwarded-Host  {host}
  }
}
EOF

cat << EOF >/etc/caddy/caddy_server.json
{
 "apps": {
   "http": {
     "servers": {
       "srv0": {
         "listen": [
           ":8964"   
         ],
         "routes": [
           {
             "handle": [
               {
                 "auth_user_deprecated": "${user}",   
                 "auth_pass_deprecated": "${pswd}", 
                 "handler": "forward_proxy",
                 "hide_ip": true,
                 "hide_via": true,
                 "probe_resistance": {}
               }
             ]
           },
           {
             "handle": [
               {
                 "handler": "reverse_proxy",
                 "headers": {
                   "request": {
                     "set": {
                       "Host": [
                         "{http.reverse_proxy.upstream.hostport}"
                       ],
                       "X-Forwarded-Host": [
                         "{http.request.host}"
                       ]
                     }
                   }
                 },
                 "transport": {
                   "protocol": "http",
                   "tls": {}
                 },
                 "upstreams": [
                   {
                     "dial": "ygkkk.blogspot.com" 
                   }
                 ]
               }
             ]
           }
         ],
         "tls_connection_policies": [
           {
             "match": {
               "sni": [
                 "$ym"  
               ]
             },
             "certificate_selection": {
               "any_tag": [
                 "cert0"
               ]
             }
           }
         ],
         "automatic_https": {
           "disable": true
         }
       }
     }
   },
   "tls": {
     "certificates": {
       "load_files": [
         {
           "certificate": "${certificatec}", 
           "key": "${certificatep}",  
           "tags": [
             "cert0"
           ]
         }
       ]
     }
   }
 }
}
EOF


cat << EOF >/etc/systemd/system/caddy.service
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target
[Service]
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
PrivateTmp=true
ProtectSystem=full
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable caddy
systemctl start caddy


kba(){
start_menu(){
hysteriastatus
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
white "甬哥Gitlab项目  ：gitlab.com/rwkgyg"
white "甬哥blogger博客 ：ygkkk.blogspot.com"
white "甬哥YouTube频道 ：www.youtube.com/c/甬哥侃侃侃kkkyg"
green "naiveproxy-yg脚本安装成功后，再次进入脚本的快捷方式为 na"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green " 1. 安装naiveproxy（必选）" 
green " 2. 卸载naiveproxy"
white "----------------------------------------------------------------------------------"
green " 3. 四大配置变更（证书、用户名、密码、端口）" 
green " 4. 关闭、开启、重启naiveproxy"   
green " 5. 更新naiveproxy-yg安装脚本"  
green " 6. 更新naiveproxy内核"
white "----------------------------------------------------------------------------------"
green " 7. 显示当前naiveproxy分享链接、V2rayN配置文件、二维码"
green " 8. 安装warp（可选）"
green " 8. 安装bbr加速（可选）"
green " 0. 退出脚本"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [[ -n $(systemctl status hysteria-server 2>/dev/null | grep -w active) && -f '/etc/hysteria/config.json' ]]; then
if [ "${hyygV}" = "${remoteV}" ]; then
green "当前naiveproxy-yg安装脚本版本号：${hyygV} ，已是最新版本\n"
else
green "当前naiveproxy-yg安装脚本版本号：${hyygV}"
yellow "检测到最新hysteria-yg安装脚本版本号：${remoteV} ，可选择5进行更新\n"
fi
loVERSION="$(/usr/local/bin/hysteria -v | awk 'NR==1 {print $3}')"
hyVERSION="v$(curl -Ls "https://data.jsdelivr.com/v1/package/resolve/gh/HyNetwork/Hysteria" | grep '"version":' | sed -E 's/.*"([^"]+)".*/\1/')"
if [ "${loVERSION}" = "${hyVERSION}" ]; then
green "当前hysteria内核版本号：${loVERSION} ，已是最新版本\n"
else
green "当前hysteria内核版本号：${loVERSION}"
yellow "检测到最新hysteria内核版本号：${hyVERSION} ，可选择6进行更新\n"
fi
fi
white "VPS系统信息如下："
white "操作系统:     $(blue "$op")" && white "内核版本:     $(blue "$version")" && white "CPU架构 :     $(blue "$cpu")" && white "虚拟化类型:   $(blue "$vi")"
white "$status"
echo
readp "请输入数字:" Input
case "$Input" in     
 1 ) inshysteria;;
 2 ) unins;;
 3 ) changeserv;;
 4 ) stclre;;
 5 ) uphyyg;; 
 6 ) uphysteriacore;;
 7 ) hysteriashare;;
 8 ) cfwarp;;
 * ) exit 
esac
}
if [ $# == 0 ]; then
start
start_menu
fi
}
