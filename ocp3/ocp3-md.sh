### Run on DNS

```
export DOMAIN="iicparis.fr.ibm.com"
export IP_HEAD="172.16"
export OCP=ocp1
export LB_IP=$IP_HEAD.187.10
export M1_IP=$IP_HEAD.187.11
export M2_IP=$IP_HEAD.187.12
export M3_IP=$IP_HEAD.187.13
export W1_IP=$IP_HEAD.187.14
export W2_IP=$IP_HEAD.187.15
export W3_IP=$IP_HEAD.187.16
export W4_IP=$IP_HEAD.187.17
export W5_IP=$IP_HEAD.187.18
export NFS_IP=$IP_HEAD.187.28
export CTL_IP=$IP_HEAD.187.29
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
nfs-$OCP.$DOMAIN.   IN      A       $NFS_IP
ctl-$OCP.$DOMAIN.  IN      A       $CTL_IP
apps.$OCP.$DOMAIN. IN      A       $LB_IP
*.apps.$OCP.$DOMAIN.       IN      CNAME   apps.$OCP.$DOMAIN.
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
$(echo $NFS_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     nfs-$OCP.$DOMAIN.
$(echo $CTL_IP | awk -F. '{print $4 "." $3 "." $2 "." $1}').in-addr.arpa.    IN      PTR     ctl-$OCP.$DOMAIN.
EOF
```

```
service bind9 restart
```

```
for host in lb m1 m2 m3 w1 w2 w3 w4 w5 nfs ctl; do echo -n $host-$OCP "-> "; dig @localhost +short $host-$OCP.$DOMAIN; done
dig @localhost +short *.apps.$OCP.$DOMAIN
```

### On ESX

```
wget -c http://web/ocp1/createCtlLbAndNfs.sh
chmod +x createCtlLbAndNfs.sh
./createCtlLbAndNfs.sh

wget -c http://web/ocp1/createVm.sh
chmod +x createVm.sh
./createVm.sh
```


### Run on LB

```
export OCP=ocp1
export DOMAIN="iicparis.fr.ibm.com"

cd ~
wget -c http://web/$OCP/setHostAndIP.sh

chmod +x setHostAndIP.sh
./setHostAndIP.sh lb-$OCP
systemctl restart network
```

```
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i -e 's/^SELINUX=\w*/SELINUX=disabled/' /etc/selinux/config
```

```
yum install haproxy -y
```

:warning: Remove everything after "maxconn                 3000"

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
    bind *:8443
    default_backend openshift-api-server
    mode tcp
    option tcplog

backend openshift-api-server
    balance source
    mode tcp
    server m1-$OCP $(dig +short m1-$OCP.$DOMAIN):6443 check
    server m2-$OCP $(dig +short m2-$OCP.$DOMAIN):6443 check
    server m3-$OCP $(dig +short m3-$OCP.$DOMAIN):6443 check
EOF
```

```
systemctl restart haproxy
systemctl enable haproxy
```

### Run on CTL

```
export OCP=ocp1
echo "" >> ~/.bashrc
echo "export OCP=$OCP" >> ~/.bashrc
echo "export SSHPASS=spcspc" >> ~/.bashrc
echo "export WORKDIR=~" >> ~/.bashrc
source ~/.bashrc

cd ~
wget -c http://web/$OCP/setHostAndIP.sh

chmod +x setHostAndIP.sh
./setHostAndIP.sh ctl-$OCP
systemctl restart network

wget -c http://web/$OCP/extendRootLV.sh
chmod +x extendRootLV.sh
./extendRootLV.sh

[ -z $(command -v sshpass) ] && yum install -y sshpass || echo sshpass installed

```

### Run on ESX

```
export OCP="ocp1"

vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh
vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

wget -c http://web/$OCP/getVMAddress.sh
chmod +x getVMAddress.sh
./getVMAddress.sh | grep -e '[mw][1-5]' | tee vms
scp vms root@ctl-$OCP:/root
```

### Run on CTL

```
for ip in $(awk -F ";" '{print $3}' /root/vms); do echo "copy to" $ip; sshpass -e scp -o StrictHostKeyChecking=no $WORKDIR/extendRootLV.sh $WORKDIR/setHostAndIP.sh root@$ip:/root; done

for LINE in $(awk -F ";" '{print $0}' vms); do  HOSTNAME=$(echo $LINE | cut -d ";" -f2); IPADDR=$(echo $LINE | cut -d ";" -f3); echo $HOSTNAME; echo $IPADDR; sshpass -e ssh -o StrictHostKeyChecking=no root@$IPADDR '/root/setHostAndIP.sh '$HOSTNAME; done

for ip in $(awk -F ";" '{print $3}' vms); do sshpass -e ssh -o StrictHostKeyChecking=no root@$ip 'reboot'; done

```

### Run on ESX

```
find /vmfs/volumes/ -type f -name getVM* -exec '{}' grep -e '[mw][1-5]' \;
```

### Run on CTL

```
for node in lb m1 m2 m3 w1 w2 w3; do sshpass -e ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; rm -f /root/.ssh/known_hosts; rm -f /root/.ssh/authorized_keys'; done

yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""

for node in lb m1 m2 m3 w1 w2 w3; do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$node-$OCP; done

for node in lb m1 m2 m3 w1 w2 w3; do ssh root@$node-$OCP 'hostname -f; date; timedatectl | grep "Local time"'; done

```

```
wget -c http://web/ocp1/hosts-cluster

sed 's/\([\.-]\)ocp./\1'$OCP'/g' $WORKDIR/hosts-cluster > /etc/ansible/hosts

grep -e 'ocp[0-9]\{1,\}' /etc/ansible/hosts

for node in m1 m2 m3 w1 w2 w3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; /root/extendRootLV.sh'; done

for node in m1 m2 m3 w1 w2 w3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; lvs'; done

ansible OSEv3 -m ping



```



### Run on ESX

```
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

export SNAPNAME=ReadyForOCP
vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-5]|lb" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh
```


```
yum install docker -y
systemctl start docker
docker run hello-world
systemctl enable docker
```

https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md
