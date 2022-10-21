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
[[ $bit = x86_64 ]] && cpu=AMD64
[[ $bit = aarch64 ]] && cpu=ARM64
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


chmod +x caddy
mv caddy /usr/bin/
mkdir /etc/caddy

    
cat << EOF >/etc/caddy/Caddyfile
:443, kb.ygkkk.eu.org
tls admin@seewo.com
route {
 forward_proxy {
   basic_auth 123 456
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
           ":443"   //监听端口
         ],
         "routes": [
           {
             "handle": [
               {
                 "auth_user_deprecated": "123",   //用户名
                 "auth_pass_deprecated": "456",  //密码
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
                     "dial": "ygkkk.blogspot.com:443"  //伪装网址
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
                 "kb.ygkkk.eu.org"  //域名
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
           "certificate": "/root/cert.crt",  //公钥路径
           "key": "/root/private.key",   //私钥路径
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
#User=caddy
#Group=caddy
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
#LimitNOFILE=1048576
#LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable caddy
systemctl start caddy

