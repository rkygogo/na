mkdir /etc/naive
chmod +x caddy
    
    mv /root/caddy /etc/naive/caddy    
    
    cat << EOF >/etc/naive/Caddyfile
{
  servers {
    protocol {
      experimental_http3  # 启用 HTTP/3
    }
  }
}
:443, 域名
tls admin@seewo.com
route {
 forward_proxy {
   basic_auth 用户名 密码
   hide_ip
   hide_via
   probe_resistance
  }
 reverse_proxy  反代地址  {
   header_up  Host  {upstream_hostport}
   header_up  X-Forwarded-Host  {host}
  }
}
EOF
    cat <<EOF > /root/naive-cl.json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://用户名:密码@域名",
  "log": ""
}
EOF
    qvurl="naive+https://用户名:密码@域名:443?padding=false#Naive"
    echo $qvurl > /root/naive-qvurl.txt
    
    cd /opt/naive
    /opt/naive/caddy start
