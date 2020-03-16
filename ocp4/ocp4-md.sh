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
for host in lb m1 m2 m3 w1 w2 w3 w4 w5 bs nfs ctl; do echo -n $host-$OCP "-> "; dig @localhost +short $host-$OCP.$DOMAIN; done
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
    # server w4-$OCP $(dig +short w4-$OCP.$DOMAIN):80 check
    # server w5-$OCP $(dig +short w5-$OCP.$DOMAIN):80 check

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
    # server w4-$OCP $(dig +short w4-$OCP.$DOMAIN):443 check
    # server w5-$OCP $(dig +short w5-$OCP.$DOMAIN):443 check

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


### Run on ctl

```


```

:warning: Change CN in -subj with $OCP

```
openssl req -x509 -nodes -days 7300 -sha256 -newkey rsa:2048 -keyout /etc/pki/tls/private/$HOSTNAME.key -out /etc/pki/tls/certs/$HOSTNAME.crt -subj "/C=FR/L=Bois-Colombes/O=IIC/OU=IIC Paris/CN=$HOSTNAME/emailAddress=iic_paris@fr.ibm.com"

openssl x509 -noout -text -in   /etc/pki/tls/certs/$HOSTNAME.crt

cp -v /etc/pki/tls/certs/$HOSTNAME.crt /etc/pki/ca-trust/source/anchors/

update-ca-trust

[ ! -f /etc/docker-distribution/registry/config.yml ] && yum install docker-distribution -y
 

sed -i '/^http:/,$d' /etc/docker-distribution/registry/config.yml

cat >> /etc/docker-distribution/registry/config.yml << EOF
http:
    addr: $HOSTNAME:5000
    net: tcp
    host: https://$HOSTNAME:5000
    tls:
         certificate: /etc/pki/tls/certs/$HOSTNAME.crt
         key: /etc/pki/tls/private/$HOSTNAME.key
EOF

systemctl restart docker-distribution

mkdir /etc/docker/certs.d/$HOSTNAME\:5000

yes | cp -v -f /etc/pki/tls/certs/$HOSTNAME.crt /etc/docker/certs.d/$HOSTNAME\:5000

docker login -u admin -p admin $HOSTNAME:5000

wget -c http://web/stuff/nfsclient.tar.gz

docker load < nfsclient.tar.gz

docker tag docker-registry.iicparis.fr.ibm.com:5000/nfsclient:v1 $HOSTNAME:5000/nfsclient:v1

docker push $HOSTNAME:5000/nfsclient:v1

```


```
UBUNTU
$ cp certs/domain.crt /usr/local/share/ca-certificates/myregistrydomain.com.crt
update-ca-certificates
RED HAT ENTERPRISE LINUX
cp certs/domain.crt /etc/pki/ca-trust/source/anchors/myregistrydomain.com.crt
update-ca-trust
```


```
cd ~

rm -f install-config.yaml

wget -c http://web/stuff/install-config.yaml

export DOMAIN="iicparis.fr.ibm.com"

sed -i "s/\(^baseDomain: \).*$/\1$DOMAIN/" install-config.yaml

sed -i -e '12s/^  name:.*$/  name: '$OCP'/' install-config.yaml

rm -f iicparis-pull-secret.txt

wget -c http://web/stuff/iicparis-pull-secret.txt

SECRET=$(cat iicparis-pull-secret.txt)

sed -i "s/^pullSecret:.*$/pullSecret: '$SECRET'/"  install-config.yaml

[ ! -f ~/.ssh/id_rsa ] && yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""

PUB_KEY=$(cat ~/.ssh/id_rsa.pub)

sed -i "s:^sshKey\:.*$:sshKey\: '$PUB_KEY':"  install-config.yaml 

sshpass -e ssh -o StrictHostKeyChecking=no root@web "rm -rf /mnt/iicbackup/produits/ocp/$OCP"

sshpass -e ssh -o StrictHostKeyChecking=no root@web "mkdir /mnt/iicbackup/produits/ocp/$OCP"

sshpass -e scp -o StrictHostKeyChecking=no install-config.yaml root@web:/mnt/iicbackup/produits/ocp/$OCP

sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /mnt/iicbackup/produits/ocp/$OCP"

> ~/.ssh/known_hosts

eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_rsa

<<<<<<< HEAD
wget -c http://web/stuff/openshift-install-linux-4.2.18.tar.gz
# wget -c http://web/stuff/openshift-install-linux-4.3.1.tar.gz

tar xvzf openshift-install-linux-4.2.18.tar.gz
# tar xvzf openshift-install-linux-4.3.1.tar.gz

chmod +x openshift-install
=======
rm -f ~/openshift-install ~/openshift-install-linux-* ~/openshift-client-linux-*

wget -c http://web/stuff/openshift-install-linux-4.2.18.tar.gz
# wget -c http://web/stuff/openshift-install-linux-4.3.1.tar.gz

tar xvzf openshift-install-linux-4.2.18.tar.gz
# tar xvzf openshift-install-linux-4.3.1.tar.gz
>>>>>>> 155c0ad7ce519f33a6a760dd009648ec49a8a344

wget -c http://web/stuff/openshift-client-linux-4.2.18.tar.gz
# wget -c http://web/stuff/openshift-client-linux-4.3.1.tar.gz

<<<<<<< HEAD
=======
rm -f /usr/local/sbin/oc /usr/local/sbin/kubectl
>>>>>>> 155c0ad7ce519f33a6a760dd009648ec49a8a344
tar -xvzf openshift-client-linux-4.2.18.tar.gz -C /usr/local/sbin
# tar -xvzf openshift-client-linux-4.3.1.tar.gz -C /usr/local/sbin

INST_DIR=~/ocpinst

[ -d "$INST_DIR" ] && rm -rf $INST_DIR/* || mkdir $INST_DIR

cd $INST_DIR

cp -v ../install-config.yaml ../openshift-install .

./openshift-install create manifests --dir=$PWD

sed -i 's/mastersSchedulable: true/mastersSchedulable: false/' manifests/cluster-scheduler-02-config.yml

./openshift-install create ignition-configs --dir=$PWD

wget -c http://web/stuff/rhcos-4.2.18-x86_64-installer.iso
# wget -c http://web/stuff/rhcos-4.3.0-x86_64-installer.iso

[ ! -d /media/iso ] && mkdir /media/iso 

<<<<<<< HEAD
=======
[ ! -z "$(ls -A /media/iso)" ] && umount /media/iso

sleep 2

>>>>>>> 155c0ad7ce519f33a6a760dd009648ec49a8a344
mount -o loop rhcos-4.2.18-x86_64-installer.iso /media/iso/
# mount -o loop rhcos-4.3.0-x86_64-installer.iso /media/iso/

[ ! -d /media/isorw ] && mkdir /media/isorw || rm -rf /media/isorw/*

wget -c http://web/stuff/buildIsoAndIgn.sh

chmod +x buildIsoAndIgn.sh

./buildIsoAndIgn.sh

umount /media/iso
```

```


```
[ -z $(command -v jq) ] && { wget -c https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x jq-linux64 && mv jq-linux64 /usr/local/sbin/jq; } || echo jq installed

for ign in $(ls *.ign); do
    echo $ign
    host=$(echo $ign | awk -F. '{print $1}')
    jq -c -r '.storage.files[] | select(.contents.source=="data:,'$host'.iicparis.fr.ibm.com")' $ign 
done

[ ! -d /media/test ] && mkdir /media/test

for iso in $(ls *.iso); do
    echo $iso
    mount -o loop $iso /media/test
    grep 'ip=' /media/test/isolinux/isolinux.cfg
    umount /media/test
done
```


```
sshpass -e scp -o StrictHostKeyChecking=no *.ign root@web:/mnt/iicbackup/produits/ocp/$OCP

sshpass -e ssh -o StrictHostKeyChecking=no root@web "OCP=$OCP; cd /mnt/iicbackup/produits/ocp/; ln -s ../stuff/rhcos-4.2.18-x86_64-metal-bios.raw.gz $OCP/."

# sshpass -e ssh -o StrictHostKeyChecking=no root@web "OCP=ocp5; cd /mnt/iicbackup/produits/ocp/; ln -s ../stuff/rhcos-4.3.0-x86_64-metal.raw.gz $OCP/."

sshpass -e ssh -o StrictHostKeyChecking=no root@web "chmod -R +r /mnt/iicbackup/produits/ocp/$OCP"

ISO_PATH="/vmfs/volumes/datastore1/iso"

<<<<<<< HEAD
```
OCP=ocp5
cd /mnt/iicbackup/produits/ocp/
ln -sf ../stuff/rhcos-4.2.18-x86_64-metal-bios.raw.gz $OCP/.
# ln -sf ../stuff/rhcos-4.3.0-x86_64-metal.raw.gz $OCP/.
chmod -R +r /mnt/iicbackup/produits/ocp/
```
=======
sshpass -e ssh -o StrictHostKeyChecking=no root@$OCP "rm -rf $ISO_PATH/*"

sshpass -e scp -o StrictHostKeyChecking=no *.iso root@$OCP:/$ISO_PATH
>>>>>>> 155c0ad7ce519f33a6a760dd009648ec49a8a344

sshpass -e ssh -o StrictHostKeyChecking=no root@$OCP "chmod -R +r /vmfs/volumes/datastore1/iso/"

# rm -f *.iso *.ign
```

### Run on esx

```
cd /vmfs/volumes/datastore1
rm -f createVm.sh rhcos.vmx
wget -c http://web/stuff/createVm.sh
wget -c http://web/stuff/rhcos.vmx

chmod +x createVm.sh

./createVm.sh

```

### Start cluster vms


```
screen -mdS ADMIN
screen -r ADMIN

INST_DIR=~/ocpinst
cd $INST_DIR
./openshift-install --dir=$PWD wait-for bootstrap-complete --log-level=debug
```

```
for node in bs m1 m2 m3 w1 w2 w3
do
  ssh -o StrictHostKeyChecking=no -l core $node-$OCP "hostname; date"
done
```


```
./openshift-install gather bootstrap --bootstrap 172.16.187.67 --key ~/.ssh/id_rsa --master "172.16.187.51 172.16.187.52 172.16.187.53"
```


:warning: For VNC to work run this on ESX:
>
```
esxcli network firewall ruleset set -e true -r gdbserver
```

```
export OCP=ocp11

xtightvncviewer -compresslevel 9 -passwd ~/.vnc/passwd $OCP:0

xtightvncviewer -compresslevel 9 -passwd ~/.vnc/passwd $OCP:1

xtightvncviewer -compresslevel 9 -passwd ~/.vnc/passwd $OCP:4
```

```
export KUBECONFIG=~/ocpinst/auth/kubeconfig

oc whoami

Error from server (NotFound): the server could not find the requested resource (get users.user.openshift.io ~)

oc whoami
system:admin
```

https://docs.openshift.com/container-platform/4.3/installing/installing_bare_metal/installing-bare-metal.html#installation-approve-csrs_installing-bare-metal


```
./openshift-install --dir=$PWD wait-for install-complete
```

INFO Waiting up to 30m0s for the cluster at https://api.ocp23.iicparis.fr.ibm.com:6443 to initialize... 
INFO Waiting up to 10m0s for the openshift-console route to be created... 
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/root/ocpinst/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.ocp23.iicparis.fr.ibm.com 
INFO Login to the console with user: kubeadmin, password: 2tfrX-x9Lzi-FTtLJ-x6i2B 




```
vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

SNAPNAME="OCPInstalled"

 vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " '$SNAPNAME' "}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[mw][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh


export SNAPIDS=$(vim-cmd vmsvc/getallvms | awk '$2 ~ "m1-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh | awk -F' : ' '$1 ~ "--Snapshot Id " {print $2}') && echo $SNAPIDS

export SNAPID=$(echo $SNAPIDS | awk '{print $NF}') && echo $SNAPID

vim-cmd vmsvc/getallvms | awk '$2 ~ "[wm][1-3]-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.revert " $1 " " '$SNAPID' " suppressPowerOn" }' | sh


oc login https://lb-$OCP:6443 -u admin -p admin --insecure-skip-tls-verify=true

```




INFO Waiting up to 30m0s for the cluster at https://api.ocp5.iicparis.fr.ibm.com:6443 to initialize... 
INFO Waiting up to 10m0s for the openshift-console route to be created... 
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/root/ocpinst/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.ocp5.iicparis.fr.ibm.com 
INFO Login to the console with user: kubeadmin, password: n6fCf-Fmb2z-PLHEk-C9XKB 


for ho in m1 m2 m3 w1 w2 w3 
do
  scp -o StrictHostKeyChecking=no /etc/pki/tls/certs/ctl-$OCP.crt core@$ho-$OCP:/tmp
  ssh -o StrictHostKeyChecking=no -l core $ho-$OCP "sudo cp /tmp/ctl-$OCP.crt /etc/pki/ca-trust/source/anchors/; update-ca-trust"
  ssh -o StrictHostKeyChecking=no -l core $ho-$OCP "sudo mkdir /etc/containers/certs.d/ctl-$OCP.iicparis.fr.ibm.com\:5000; sudo cp /tmp/ctl-$OCP.crt /etc/containers/certs.d/ctl-$OCP.iicparis.fr.ibm.com\:5000"
done


for ho in m1 m2 m3 w1 w2 w3
do
  echo $ho
  ssh -o StrictHostKeyChecking=no -l core $ho-$OCP "ls /etc/containers/certs.d/ctl-$OCP.iicparis.fr.ibm.com\:5000/"
done


oc edit sc managed-nfs-storage

metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"