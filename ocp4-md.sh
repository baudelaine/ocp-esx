### Run on DNS

```
export DOMAIN="iicparis.fr.ibm.com"
export IP_HEAD="172.16"
export OCP=ocp5
export LB_IP=$IP_HEAD.187.50
export M1_IP=$IP_HEAD.187.51
export M2_IP=$IP_HEAD.187.52
export M3_IP=$IP_HEAD.187.53
export W1_IP=$IP_HEAD.187.54
export W2_IP=$IP_HEAD.187.55
export W3_IP=$IP_HEAD.187.56
export W4_IP=$IP_HEAD.187.57
export W5_IP=$IP_HEAD.187.58
export BS_IP=$IP_HEAD.187.67
export NFS_IP=$IP_HEAD.187.68
export CTL_IP=$IP_HEAD.187.69
```


```
cat >> /var/lib/bind/$DOMAIN.hosts << EOF
lb-$OCP.$DOMAIN.   IN      A       $LB_IP
m1-$OCP.$DOMAIN.   IN      A       $M1_IP
m2-$OCP.$DOMAIN.   IN      A       $M2_IP
m3-$OCP.$DOMAIN.   IN      A       $M3_IP
w1-$OCP.$DOMAIN.   IN      A       $W1_IP
w2-$OCP.$DOMAIN.   IN      A       $W2_IP
w3-$OCP.$DOMAIN.   IN      A       $W3_IP
w4-$OCP.$DOMAIN.   IN      A       $W4_IP
w5-$OCP.$DOMAIN.   IN      A       $W5_IP
bs-$OCP.$DOMAIN.   IN      A       $BS_IP
nfs-$OCP.$DOMAIN.   IN      A       $NFS_IP
ctl-$OCP.$DOMAIN.  IN      A       $CTL_IP
api.$OCP.$DOMAIN.  IN      A       $LB_IP
api-int.$OCP.$DOMAIN.      IN      A       $LB_IP
apps.$OCP.$DOMAIN. IN      A       $LB_IP
etcd-0.$OCP.$DOMAIN.       IN      A       $M1_IP
etcd-1.$OCP.$DOMAIN.       IN      A       $M2_IP
etcd-2.$OCP.$DOMAIN.       IN      A       $M3_IP
*.apps.$OCP.$DOMAIN.       IN      CNAME   apps.$OCP.$DOMAIN.
_etcd-server-ssl._tcp.$OCP.$DOMAIN.        86400   IN      SRV     0 10 2380 etcd-0.$OCP.$DOMAIN.
_etcd-server-ssl._tcp.$OCP.$DOMAIN.        86400   IN      SRV     0 10 2380 etcd-1.$OCP.$DOMAIN.
_etcd-server-ssl._tcp.$OCP.$DOMAIN.        86400   IN      SRV     0 10 2380 etcd-2.$OCP.$DOMAIN.
EOF
```

```
cat >> /var/lib/bind/$IP_HEAD.rev << EOF
$(echo $LB_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     lb-$OCP.$DOMAIN.
$(echo $M1_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     m1-$OCP.$DOMAIN.
$(echo $M2_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     m2-$OCP.$DOMAIN.
$(echo $M3_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     m3-$OCP.$DOMAIN.
$(echo $W1_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w1-$OCP.$DOMAIN.
$(echo $W2_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w2-$OCP.$DOMAIN.
$(echo $W3_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w3-$OCP.$DOMAIN.
$(echo $W4_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w3-$OCP.$DOMAIN.
$(echo $W5_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     w3-$OCP.$DOMAIN.
$(echo $BS_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     bs-$OCP.$DOMAIN.
$(echo $NFS_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     nfs-$OCP.$DOMAIN.
$(echo $CTL_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     ctl-$OCP.$DOMAIN.
EOF
```

```
service bind9 restart
```

```
for host in lb m1 m2 m3 w1 w2 w3 w4 w5 bs nfs ctl; do echo -n $host-$OCP "->"; dig @localhost +short $host-$OCP.$DOMAIN; done
dig @localhost +short *.apps.$OCP.$DOMAIN
dig @localhost +short _etcd-server-ssl._tcp.$OCP.$DOMAIN SRV
```


### Run on LB

```
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i -e 's/^SELINUX=\w*/SELINUX=disabled/' /etc/selinux/config
```

```
yum install haproxy -y
```

```
export DOMAIN="iicparis.fr.ibm.com"
export OCP=ocp5
```

```
cat >> /etc/haproxy/haproxy.cfg << EOF

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend ingress-http
    bind *:80
    default_backend ingress-http
    mode tcp
    option tcplog

backend ingress-http
    balance source
    mode tcp
    server w1-$OCP $(dig +short w1-$OCP.$DOMAIN):80 check
    server w2-$OCP $(dig +short w2-$OCP.$DOMAIN):80 check
    server w3-$OCP $(dig +short w3-$OCP.$DOMAIN):80 check
    server w4-$OCP $(dig +short w4-$OCP.$DOMAIN):80 check
    server w5-$OCP $(dig +short w5-$OCP.$DOMAIN):80 check

frontend ingress-https
    bind *:443
    default_backend ingress-https
    mode tcp
    option tcplog

backend ingress-https
    balance source
    mode tcp
    server w1-$OCP $(dig +short w1-$OCP.$DOMAIN):443 check
    server w2-$OCP $(dig +short w2-$OCP.$DOMAIN):443 check
    server w3-$OCP $(dig +short w3-$OCP.$DOMAIN):443 check
    server w4-$OCP $(dig +short w4-$OCP.$DOMAIN):443 check
    server w5-$OCP $(dig +short w5-$OCP.$DOMAIN):443 check

frontend openshift-api-server
    bind *:6443
    default_backend openshift-api-server
    mode tcp
    option tcplog

backend openshift-api-server
    balance source
    mode tcp
    server m1-$OCP $(dig +short m1-$OCP.$DOMAIN):6443 check
    server m2-$OCP $(dig +short m2-$OCP.$DOMAIN):6443 check
    server m3-$OCP $(dig +short m3-$OCP.$DOMAIN):6443 check
    server bs-$OCP $(dig +short bs-$OCP.$DOMAIN):6443 check

frontend machine-config-server
    bind *:22623
    default_backend machine-config-server
    mode tcp
    option tcplog

backend machine-config-server
    balance source
    mode tcp
    server m1-$OCP $(dig +short m1-$OCP.$DOMAIN):22623 check
    server m2-$OCP $(dig +short m2-$OCP.$DOMAIN):22623 check
    server m3-$OCP $(dig +short m3-$OCP.$DOMAIN):22623 check
    server bs-$OCP $(dig +short bs-$OCP.$DOMAIN):22623 check

EOF
```

```
systemctl restart haproxy
systemctl enable haproxy
```



