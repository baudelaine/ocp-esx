# On DNS

cat >> /var/lib/bind/iicparis.fr.ibm.com.hosts << EOF
lb-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.10
m1-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.11
m2-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.12
m3-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.13
n1-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.14
i1-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.15
n2-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.16
i2-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.17
n3-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.18
i3-ocp1.iicparis.fr.ibm.com.    IN      A       172.16.187.19
nfs-ocp1.iicparis.fr.ibm.com.   IN      A       172.16.187.28
ctl-ocp1.iicparis.fr.ibm.com.   IN      A       172.16.187.29
*.apps-ocp1.iicparis.fr.ibm.com.        IN      CNAME   apps-ocp1.iicparis.fr.ibm.com.
apps-ocp1.iicparis.fr.ibm.com.  IN      A       172.16.187.15
apps-ocp1.iicparis.fr.ibm.com.  IN      A       172.16.187.17
apps-ocp1.iicparis.fr.ibm.com.  IN      A       172.16.187.19
EOF

cat >> /var/lib/bind/172.16.rev << EOF
10.187.16.172.in-addr.arpa.     IN      PTR     lb-ocp1.iicparis.fr.ibm.com.
11.187.16.172.in-addr.arpa.     IN      PTR     m1-ocp1.iicparis.fr.ibm.com.
12.187.16.172.in-addr.arpa.     IN      PTR     m2-ocp1.iicparis.fr.ibm.com.
13.187.16.172.in-addr.arpa.     IN      PTR     m3-ocp1.iicparis.fr.ibm.com.
14.187.16.172.in-addr.arpa.     IN      PTR     n1-ocp1.iicparis.fr.ibm.com.
15.187.16.172.in-addr.arpa.     IN      PTR     i1-ocp1.iicparis.fr.ibm.com.
16.187.16.172.in-addr.arpa.     IN      PTR     n2-ocp1.iicparis.fr.ibm.com.
17.187.16.172.in-addr.arpa.     IN      PTR     i2-ocp1.iicparis.fr.ibm.com.
18.187.16.172.in-addr.arpa.     IN      PTR     n3-ocp1.iicparis.fr.ibm.com.
19.187.16.172.in-addr.arpa.     IN      PTR     i3-ocp1.iicparis.fr.ibm.com.
28.187.16.172.in-addr.arpa.     IN      PTR     nfs-ocp1.iicparis.fr.ibm.com.
29.187.16.172.in-addr.arpa.     IN      PTR     ctl-ocp1.iicparis.fr.ibm.com.
EOF

service bind9 restart

# On a client

dig @172.16.160.100 +short lb-ocp1.iicparis.fr.ibm.com
# 172.16.187.10

dig @172.16.160.100 +short -x 172.16.187.10
# lb-ocp1.iicparis.fr.ibm.com.

dig @172.16.160.100 +short *.apps-ocp1.iicparis.fr.ibm.com
# apps-ocp1.iicparis.fr.ibm.com.
# 172.16.187.17
# 172.16.187.19
# 172.16.187.15

# On the esxi

export OCP=ocp1
export DS_PATH=/vmfs/volumes/V7000F-Volume-10TB
export WORK_DIR=/vmfs/volumes/datastore1/vmdk

mkdir -p $DS_PATH/$OCP

chmod +x $WORK_DIR/*.sh

$WORK_DIR/createVMs.sh $OCP

## start ctl
vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-'$OCP'" {print "vim-cmd vmsvc/power.on " $1}' | sh

## get ctl dhcp address
$WORK_DIR/getVMAddress.sh | grep ctl

# On ctl

export OCP=ocp1
/root/extendRootVG.sh
/root/setHostAndIP.sh ctl-$OCP
reboot

# On esx

## start other vm
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

## In case cluster VM need to reboot e.g. dhcp address lost
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

## get other VM ip address and copy them to ctl
$WORK_DIR/getVMAddress.sh | sed '/ctl-ocp/d' | tee $WORK_DIR/vms
scp $WORK_DIR/vms root@ctl-$OCP:/root

# On ctl

export OCP=ocp1
export SSHPASS=spcspc && export IP_HEAD=172.16.187. && export FIRST=10 && export LAST=19

## set other vm ip address and hostname known in DNS
for LINE in $(awk -F ";" '{print $0}' vms); do  HOSTNAME=$(echo $LINE | cut -d ";" -f2); IPADDR=$(echo $LINE | cut -d ";" -f3); echo $HOSTNAME; echo $IPADDR; sshpass -e ssh -o StrictHostKeyChecking=no root@$IPADDR '/root/setHostAndIP.sh '$HOSTNAME; done

## reboot cluster vms
for ip in $(awk -F ";" '{print $3}' vms); do sshpass -e ssh -o StrictHostKeyChecking=no root@$ip 'reboot'; done

# On esx
## Wait for vm to be up and ready then check cluster vm are static
$WORK_DIR/getVMAddress.sh

# On ctl

##Key exchange

export OCP=ocp1
export SSHPASS=spcspc && export IP_HEAD=172.16.187. && export FIRST=10 && export LAST=19

### Clean ssh env on cluster vm
for i in $(seq $FIRST $LAST); do sshpass -e ssh -o StrictHostKeyChecking=no root@$IP_HEAD$i 'hostname -f; rm -f /root/.ssh/known_hosts; rm -f /root/.ssh/authorized_keys'; done

### Generate key pair on ctl and copy ctl public key on cluster vm
yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""
for i in $(seq $FIRST $LAST); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done

### Check ctl can access cluster vm without being prompt for a password
for i in $(seq $FIRST $LAST); do ssh root@$IP_HEAD$i 'hostname -f; date'; done

### create key pair and exchange public key between cluster vm (PermitUserEnvironment must enabled in target /etc/ssh/sshd_config)

cat > ssh-env << EOF
SSHPASS=spcspc
IP_HEAD=172.16.187.
FIRST=10
LAST=19
EOF

for i in $(seq $FIRST $LAST); do scp ssh-env root@$IP_HEAD$i:/root/.ssh/environment; done

for i in $(seq $FIRST $LAST); do ssh root@$IP_HEAD$i 'hostname -f; yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N "" && for i in $(seq $FIRST $LAST); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done'; done

### Check all vm can access each other without being prompt for a password
for i in $(seq $FIRST $LAST); do ssh root@$IP_HEAD$i 'hostname -f; for i in $(seq $FIRST $LAST); do ssh -o StrictHostKeyChecking=no root@$IP_HEAD$i "hostname -f; date"; done'; done

#ansible & ssh setup

## copy inventory file to default ansible file
sed 's/-ocp./-'$OCP'/g' /root/hosts-cluster > /etc/ansible/hosts

## check
grep -e '-ocp.' /etc/ansible/hosts

## check ansible can speak with every nodes in the cluster
ansible OSEv3 -m ping

## extend root vg
cat > extendRootVG.sh << EOF
ansible nodes -a 'pvcreate /dev/sdb'
ansible nodes -a 'vgextend root /dev/sdb'
ansible nodes -a 'lvextend /dev/root/root -l 100%VG -r /dev/sdb'
ansible nodes -a 'df -hT /'
ansible nodes -a 'lvs'
EOF

chmod +x extendRootVG.sh
./extendRootVG.sh

## set Docker storage
ansible nodes -a 'systemctl stop docker' && ansible nodes -a 'systemctl is-active docker'

for i in $(seq $FIRST $LAST); do ssh root@$IP_HEAD$i 'hostname -f; rm -rf /var/lib/docker/*'; done

ansible nodes -a 'du -h /var/lib/docker/'

cat > setDockerStorage.sh << EOF
ansible nodes -a 'du -h /var/lib/docker'
ansible nodes -a 'pvcreate /dev/sdc'
ansible nodes -a 'vgcreate docker /dev/sdc'
ansible nodes -a 'lvcreate -n docker -l 100%VG docker'
ansible nodes -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/docker/docker'
ansible nodes -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/docker-docker  /var/lib/docker  xfs defaults,noatime 1 2"'
ansible nodes -a 'mount /var/lib/docker'
ansible nodes -a 'df -hT /var/lib/docker'
ansible nodes -a 'lvs'
ansible nodes -a 'systemctl start docker'
ansible nodes -a 'systemctl is-active docker'
EOF

chmod +x setDockerStorage.sh
./setDockerStorage.sh

## set OCP storage
cat > setOCPStorage.sh << EOF
ansible nodes -a 'pvcreate /dev/sdd'
ansible nodes -a 'vgcreate origin /dev/sdd'
ansible nodes -a 'lvcreate -n origin -l 100%VG origin'
ansible nodes -a 'mkdir /var/lib/origin'
ansible nodes -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/origin/origin'
ansible nodes -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/origin-origin  /var/lib/origin  xfs defaults,noatime 1 2"'
ansible nodes -a 'mount /var/lib/origin'
ansible nodes -a 'df -hT /var/lib/origin'
ansible nodes -a 'lvs'
EOF

chmod +x setOCPStorage.sh
./setOCPStorage.sh

screen -mdS ADM
screen -r ADM
cd /usr/share/ansible/openshift-ansible
ansible-playbook playbooks/prerequisites.yml
ansible-playbook playbooks/deploy_cluster.yml

# On first master

## Check install

oc login -u system:admin

oc create clusterrolebinding registry-controller --clusterrole=cluster-admin --user=admin

oc login -u admin -p admin

oc new-project validate

oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git

oc logs -f bc/ruby-ex

oc expose svc/ruby-ex

curl -I -v $(oc get routes | awk 'NR>1 {print $2}')

oc delete project validate

## Check further with instructions here:  Check install https://docs.openshift.com/container-platform/3.11/day_two_guide/environment_health_checks.html


# On esx
## Make a snapshot
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " OCPInstalled"}' | sh
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

## If necessary revert snapshot

#SNAPID=1

#vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh
#vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.revert " $1 " " '$SNAPID' " suppressPowerOn" }' | sh
#vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

# On NFS server

cat > installNFSServer.sh << EOF
pvcreate /dev/sdb
vgcreate exports /dev/sdb
lvcreate -n exports -l 100%VG exports
mkdir /exports
mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/exports/exports
echo "/dev/mapper/exports-exports  /exports  xfs defaults,noatime 1 2" >> /etc/fstab
mount /exports
df -hT /exports
lvs
echo "/exports *(rw,sync,no_root_squash)" >> /etc/exports
systemctl restart nfs
showmount -e
systemctl enable nfs
EOF

chmod +x installNFSServer.sh
./installNFSServer.sh

# on first master

## Test nfs access

export OCP=ocp1

mkdir /mnt/test
mount -t nfs nfs-$OCP:/exports /mnt/test
touch /mnt/test/a && ls /mnt/test/a && rm /mnt/test/a
umount /mnt/test && rmdir /mnt/test/

## Add storage class managed-nfs-storage for NFS Persistent Volume Claim

mount /mnt/iicbackup/produits/

cd /root
tar xvfz /mnt/iicbackup/produits/ISO/add-ons/icpa/nfs-client.tar.gz

oc login -u admin -p admin
oc new-project storage
cd /root/nfs-client/
NAMESPACE=$(oc project -q)
sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/rbac.yaml
oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:$NAMESPACE:nfs-client-provisioner
vi /root/nfs-client/deploy/deployment.yaml
vi /root/nfs-client/deploy/class.yaml

oc create -f deploy/deployment.yaml
oc create -f deploy/class.yaml

oc get pods
oc logs

oc create -f deploy/test-claim.yaml

### should display bound state
oc get pvc

oc create -f test-pod.yaml

# On NFS server

l /exports





vim-cmd vmsvc/getallvms | awk '$2 ~ "-ocp" {print "vim-cmd vmsvc/power.shutdown " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~ "-ocp" {print "vim-cmd vmsvc/power.off " $1}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~"-ocp" {print "vim-cmd vmsvc/snapshot.create " $1 " ocpPrereqCompleted"}' | sh

vim-cmd vmsvc/getallvms | awk '$2 ~"-ocp" {print "vim-cmd vmsvc/snapshot.create " $1 " beforeOcpPrereq"}' | sh


vim-cmd vmsvc/getallvms | awk '$2 ~"-ocp" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh

SNAPID=1

vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh
#vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.remove " $1 " " '$SNAPID'}' | sh
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.revert " $1 " " '$SNAPID' " suppressPowerOn" }' | sh
vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh



Please see https://ibm-cp-applications.apps.ocp76.iicparis.fr.ibm.com to get started and learn more about IBM Cloud Pak for Applications.

The Tekton Dashboard is available at: https://tekton-dashboard-kabanero.apps.ocp76.iicparis.fr.ibm.com.

The IBM Transformation Advisor UI is available at: https://ta.apps.apps.ocp76.iicparis.fr.ibm.com.




export IP_HEAD=172.16.187. && for i in $(seq 50 61); do sshpass -e ssh root@$IP_HEAD$i 'hostname -f; date'; done


for node in ocp5-i1 ocp5-i2; do echo $node; ssh $node 'shutdown -h now'; done

export IP_HEAD=172.16.187.5
#yum install -y sshpass
export SSHPASS=spcspc

for i in $(seq 0 7); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done

for i in $(seq 0 7); do export SSHPASS=spcspc && export IP_HEAD=172.16.187.5 && echo $IP_HEAD$i; ssh root@$IP_HEAD$i 'hostname -f; date'; echo; done

cd /usr/share/ansible/openshift-ansible
ansible-playbook -i /etc/ansible/hosts playbooks/prerequisites.yml
ansible-playbook -i /etc/ansible/hosts playbooks/deploy_cluster.yml

oc login -u system:admin

oc get nodes


dig +short docker-registry.default.svc.cluster.local

docker login -u $(oc whoami) -p $(oc whoami -t) docker-registry.default.svc.cluster.local:5000

docker login -u $(oc whoami) -p $(oc whoami -t) 172.30.50.52:5000

oc create secret generic dockerhub --from-file=.dockerconfigjson=/root/.docker/config.json> --type=kubernetes.io/dockerconfigjson

oc delete pod --all -n openshift-web-console

oc delete pod --all -n openshift-console

https://docs.openshift.com/container-platform/3.11/getting_started/configure_openshift.html#getting-started-configure-openshift

https://docs.okd.io/latest/minishift/getting-started/quickstart.html
