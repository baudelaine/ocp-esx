# Prerequisites

Be a [Redhat partner](https://partnercenter.redhat.com/Dashboard_page) and ask for [NEW NFR](https://partnercenter.redhat.com/NFR_Redirect) to get access to Openshift packages.

One **ESXi server** in which datastore you should have copied:

- A vmdk file which host  a [minimal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-simple-install#sect-simple-install) and  [prepared](https://docs.openshift.com/container-platform/3.11/install/host_preparation.html) RHEL7 **booting in DHCP** and **running VMware Tools**. 
- A [bundle](https://github.com/bpshparis/ocp-esx/archive/master.zip)  of scripts and configurations files.

One **DNS server**.

One **DHCP server**.



<!--

#awk '/!container-selinux/{if (NR!=1)print "";next}{printf "%s ",$0}END{print "";}' b

yum install atomic -y

yum install container-selinux container-storage-setup containers-common criu gomtree libnet ostree protobuf-c python-docker python-docker-pycreds python-requests python-websocket-client python2-pysocks python2-urllib3 runc skopeo -y

yum install atomic-openshift atomic-openshift-clients atomic-openshift-hyperkube atomic-openshift-node bind ceph-common dnsmasq flannel iscsi-initiator-utils pyparted atomic-openshift:3.11 atomic-openshift-master:3.11 atomic-openshift-node:3.11 -y



yum install ose-control-plane ose-deployer ose-docker-registry ose-haproxy-router ose-pod registry-console etcd -y



yum install atomic-openshift-excluder atomic-openshift-docker-excluder -y



echo "OPTIONS='--insecure-registry=172.30.0.0/16 --selinux-enabled --log-opt max-size=1M --log-opt max-file=3'" >> 	/etc/sysconfig/docker 



cat >> /etc/sysctl.conf << EOF

net.ipv4.ip_local_port_range = 2048 65000
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.wmem_max = 33554432
net.core.rmem_max = 33554432
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_rmem = 4096 16777216 33554432
net.ipv4.tcp_wmem = 4096 16777216 33554432
net.core.optmem_max = 40960
vm.max_map_count=262144
kernel.sem = 250 1024000 32 4096

EOF

sysctl -p



swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab



-->


# Target 


> Target is to bluid an Openshift cluster that we'll call **ocp3**



| Hostname                     | IP Address    | Role                 |
| ---------------------------- | ------------- | -------------------- |
| lb-ocp3.iicparis.fr.ibm.com  | 172.16.187.30 | Load Balancer        |
| m1-ocp3.iicparis.fr.ibm.com  | 172.16.187.31 | Master + etcd        |
| m2-ocp3.iicparis.fr.ibm.com  | 172.16.187.32 | Master + etcd        |
| m3-ocp3.iicparis.fr.ibm.com  | 172.16.187.33 | Master + etcd        |
| n1-ocp3.iicparis.fr.ibm.com  | 172.16.187.34 | Computer             |
| i1-ocp3.iicparis.fr.ibm.com  | 172.16.187.35 | Infra                |
| n2-ocp3.iicparis.fr.ibm.com  | 172.16.187.36 | Computer             |
| i2-ocp3.iicparis.fr.ibm.com  | 172.16.187.37 | Infra                |
| n3-ocp3.iicparis.fr.ibm.com  | 172.16.187.38 | Computer             |
| i3-ocp3.iicparis.fr.ibm.com  | 172.16.187.39 | Infra                |
| nfs-ocp3.iicparis.fr.ibm.com | 172.16.187.48 | Persistent Storage   |
| ctl-ocp3.iicparis.fr.ibm.com | 172.16.187.49 | Controller + ansible |


# Start building cluster

## On DNS

### Set DNS environment variables

> :warning: Allowed characters for values are [A-Z] [a-z] [0-9] [-/.]

- **OCP** for cluster-name.
- **MASTER_IP_HEAD** for cluster ip head in master zone.
- **MASTER_NFS_IP** for nfs server ip in master zone.
- **MASTER_CTL_IP** for  controller ip in master zone.
- **REVERSE_IP_HEAD** for cluster ip head in reverse zone.
- **REVERSE_IP_TAIL** for cluster ip tail in reverse zone.
- **REVERSE_NFS_IP** for nfs server ip in reverse zone.
- **REVERSE_CTL_IP** for  controller ip in reverse zone.


e.g.

	export OCP=ocp19
	export MASTER_IP_HEAD=172.16.187.19
	export MASTER_NFS_IP=172.16.187.208
	export MASTER_CTL_IP=172.16.187.209
	export REVERSE_IP_TAIL=.187.16.172
	export REVERSE_IP_HEAD=19
	export REVERSE_NFS_IP=208.187.16.172
	export REVERSE_CTL_IP=209.187.16.172

### Add records to master zone

```
cat >> /var/lib/bind/iicparis.fr.ibm.com.hosts << EOF
lb-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}0
m1-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}1
m2-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}2
m3-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}3
n1-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}4
i1-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}5
n2-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}6
i2-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}7
n3-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}8
i3-$OCP.iicparis.fr.ibm.com.    IN      A       ${MASTER_IP_HEAD}9
nfs-$OCP.iicparis.fr.ibm.com.   IN      A       ${MASTER_NFS_IP}
ctl-$OCP.iicparis.fr.ibm.com.   IN      A       ${MASTER_CTL_IP}
*.apps-$OCP.iicparis.fr.ibm.com.        IN      CNAME   apps-$OCP.iicparis.fr.ibm.com.
apps-$OCP.iicparis.fr.ibm.com.  IN      A       ${MASTER_IP_HEAD}5
apps-$OCP.iicparis.fr.ibm.com.  IN      A       ${MASTER_IP_HEAD}7
apps-$OCP.iicparis.fr.ibm.com.  IN      A       ${MASTER_IP_HEAD}9
EOF
```

### Add records to reverse zone

```
cat >> /var/lib/bind/172.16.rev << EOF
${REVERSE_IP_HEAD}0${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     lb-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}1${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     m1-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}2${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     m2-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}3${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     m3-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}4${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     n1-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}5${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     i1-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}6${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     n2-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}7${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     i2-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}8${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     n3-$OCP.iicparis.fr.ibm.com.
${REVERSE_IP_HEAD}9${REVERSE_IP_TAIL}.in-addr.arpa.     IN      PTR     i3-$OCP.iicparis.fr.ibm.com.
${REVERSE_NFS_IP}.in-addr.arpa.     IN      PTR     nfs-$OCP.iicparis.fr.ibm.com.
${REVERSE_CTL_IP}.in-addr.arpa.     IN      PTR     ctl-$OCP.iicparis.fr.ibm.com.
EOF
```

### Restart DNS

```
service bind9 restart
```

### Test master zone

	dig @localhost +short lb-$OCP.iicparis.fr.ibm.com

### Test reverse zone

	LB_IP=$(dig @localhost +short lb-$OCP.iicparis.fr.ibm.com)
	dig @localhost +short -x $LB_IP


### Test alias

	dig @localhost +short *.apps-$OCP.iicparis.fr.ibm.com



## On ESX

### Set ESX environment variables

> :warning: Allowed characters for OCP are [A-Z] [a-z] [0-9] [-]

- **OCP** for cluster-name.
- **DATASTORE** for path where vms will be created.
- **VMDK** for full path of minimal and prepared RHEL7 vmdk file.
- **WORKDIR** for path where bundle was extracted.

e.g.

	export OCP=ocp3
	export DATASTORE="/vmfs/volumes/V7000F-Volume-10TB"
	export VMDK="/vmfs/volumes/datastore1/vmdk/rhel.vmdk"
	export WORKDIR="/vmfs/volumes/datastore1/ocp-esx-master"

### Create VMs

	cd $WORKDIR && ./createVMs.sh $OCP

### Start controller vm
	vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-'$OCP'" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Get controller dhcp address

> :bulb: Wait for ctl vm to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

	$WORKDIR/getVMAddress.sh | grep ctl



## On Controller

### Set environment variables

> :warning: Allowed characters for OCP are [A-Z] [a-z] [0-9] [-]

- **OCP** for cluster-name.
- **SSHPASS** for root password of cluster vms.

e.g.

```
echo "" >> ~/.bashrc
echo "export OCP=ocp3" >> ~/.bashrc
echo "export SSHPASS=spcspc" >> ~/.bashrc
source ~/.bashrc

```

### Get tools to manage storage and setup hostname and ip address from DNS

```
curl -LO http://github.com/bpshparis/ocp-esx/archive/master.zip
[ ! -z $(command -v unzip) ] && echo unzip installed || yum install zip unzip -y
unzip master.zip
echo "export WORKDIR=$PWD/ocp-esx-master" >> ~/.bashrc
source ~/.bashrc
rm -f master.zip 

```

### Extend root logical volume

>:warning: Set **DISK**, **PART**, **VG** and **LV** variables accordingly in **$WORKDIR/extendRootLV.sh** before proceeding 

	$WORKDIR/extendRootLV.sh && lvs

### Setup hostname and ip address from DNS

	$WORKDIR/setHostAndIP.sh ctl-$OCP

### Reboot for change to take effect

	reboot

## On ESX

> :warning: If session is new, please [set ESX environment variables](#set-esx-environment-variables) first.

### Start other vms

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Get cluster vms DHCP ip address

> :bulb: Wait for all cluster vms to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

	$WORKDIR/getVMAddress.sh | sed '/ctl-ocp/d' | tee $WORK_DIR/vms

###  Copy all cluster vms DHCP ip address to  controller

	scp $WORK_DIR/vms root@ctl-$OCP:/root


## On  Controller

### Copy extendRootLV.sh and setHostAndIP.sh to cluster nodes

	for ip in $(awk -F ";" '{print $3}' /root/vms); do echo "copy to" $ip; sshpass -e scp -o StrictHostKeyChecking=no $WORKDIR/extendRootLV.sh $WORKDIR/setHostAndIP.sh root@$ip:/root; done

### Set cluster nodes with ip address and hostname known in DNS

	for LINE in $(awk -F ";" '{print $0}' vms); do  HOSTNAME=$(echo $LINE | cut -d ";" -f2); IPADDR=$(echo $LINE | cut -d ";" -f3); echo $HOSTNAME; echo $IPADDR; sshpass -e ssh -o StrictHostKeyChecking=no root@$IPADDR '/root/setHostAndIP.sh '$HOSTNAME; done

### Reboot cluster nodes

	for ip in $(awk -F ";" '{print $3}' vms); do sshpass -e ssh -o StrictHostKeyChecking=no root@$ip 'reboot'; done


## On ESX

### Wait for all cluster vms to be up with static ip address

> :bulb: Wait for all cluster vms to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

	$WORKDIR/getVMAddress.sh

## On  Controller

### Exchange ssh public key with cluster nodes

#### Clean cluster nodes ssh environment 

	for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do sshpass -e ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; rm -f /root/.ssh/known_hosts; rm -f /root/.ssh/authorized_keys'; done

#### Generate ssh key pair and copy public key on cluster nodes

	yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""


	for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$node-$OCP; done

#### Check  controller can access cluster nodes without being prompt for a password

	for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do ssh root@$node-$OCP 'hostname -f; date; timedatectl | grep "Local time"'; done


# Prepare to install OCP

#### Copy inventory file to default ansible file

	sed 's/-ocp./-'$OCP'/g' $WORKDIR/hosts-cluster > /etc/ansible/hosts

> :warning: Don't forget to set **oreg_auth_user** and **oreg_auth_password** in **/etc/ansible/hosts** .
> :warning: Escape **'$'** character in your password if necessary.
> e.g. OREG_PWD="mypa\$sword"


```
OREG_USER="iicparis"
OREG_PWD="********"

sed -i 's/\(oreg_auth_user=\).*$/\1'$OREG_USER'/' /etc/ansible/hosts
sed -i 's/\(oreg_auth_password=\).*$/\1'$OREG_PWD'/' /etc/ansible/hosts


```


#### Check hosts 

	grep -e 'ocp[0-9]\{1,\}' /etc/ansible/hosts



#### Extend root Volume Group on all cluster nodes

>:warning: Set **DISK**, **PART**, **VG** and **LV** variables accordingly in **$WORKDIR/extendRootLV.sh** before proceeding 

	for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; /root/extendRootLV.sh'; done

#### Check root Volume Group on all cluster nodes

	for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; lvs'; done

#### Check ansible can speak with every nodes in the cluster

	ansible OSEv3 -m ping

#### Set Docker storage

```
ansible nodes -a 'systemctl stop docker' 
```


```
for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; [ -d /var/lib/docker ] && rm -rf /var/lib/docker/* || mkdir /var/lib/docker; du -h /var/lib/docker'; done
```


```
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
```


	chmod +x setDockerStorage.sh && ./setDockerStorage.sh

#### Set OCP storage

```
for node in m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; [ -d /var/lib/origin ] && rm -rf /var/lib/origin/* || mkdir /var/lib/origin; du -h /var/lib/origin'; done
```


```
cat > setOCPStorage.sh << EOF
ansible nodes -a 'pvcreate /dev/sdd'
ansible nodes -a 'vgcreate origin /dev/sdd'
ansible nodes -a 'lvcreate -n origin -l 100%VG origin'
ansible nodes -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/origin/origin'
ansible nodes -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/origin-origin  /var/lib/origin  xfs defaults,noatime 1 2"'
ansible nodes -a 'mount /var/lib/origin'
ansible nodes -a 'df -hT /var/lib/origin'
ansible nodes -a 'lvs'
EOF
```


	chmod +x setOCPStorage.sh && ./setOCPStorage.sh


#### Set ETCD storage

```
for node in m1 m2 m3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; [ -d /var/lib/etcd ] && rm -rf /var/lib/etcd/* || mkdir /var/lib/etcd; du -h /var/lib/etcd'; done
```


```
cat > setETCDStorage.sh << EOF
ansible etcd -a 'pvcreate /dev/sde'
ansible etcd -a 'vgcreate etcd /dev/sde'
ansible etcd -a 'lvcreate -n etcd -l 100%VG etcd'
ansible etcd -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/etcd/etcd'
ansible etcd -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/etcd-etcd  /var/lib/etcd  xfs defaults,noatime 1 2"'
ansible etcd -a 'mount /var/lib/etcd'
ansible etcd -a 'df -hT /var/lib/etcd'
ansible etcd -a 'lvs'
EOF
```


	chmod +x setETCDStorage.sh && ./setETCDStorage.sh

#### Check nodes logical volume

	ansible nodes -a 'lvs'



# Make a ReadyForOCP snapshot

## On Controller

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; poweroff'; done
```

## On ESX

#### Check all vms are Powered off

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh

#### Make a snapshot called ReadyForOCP

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " ReadyForOCP"}' | sh

#### Power cluster vms on

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh



# Install Openshift

## On Controller

#### Check ansible can speak with every nodes in the cluster

	ansible OSEv3 -m ping

#### Check every nodes in the cluster can speak to registry.redhat.io

	ansible nodes -a 'ping -c 2 registry.redhat.io'

#### Check OpenShift Health

> :warning:  Set **oreg_auth_user** and **oreg_auth_password** accordingly


	[ ! -z $(command -v skopeo) ] && echo skopeo installed || yum install skopeo -y
	skopeo inspect --tls-verify=false --creds='$oreg_auth_user:$oreg_auth_password' docker://registry.redhat.io/openshift3/ose-docker-registry:v3.11.161



#### Launch OCP installation

> :bulb: To avoid network failure, launch installation on **locale console** or in a **screen**

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y
screen -mdS ADM && screen -r ADM

```

```
cd /usr/share/ansible/openshift-ansible
```



```
ansible-playbook playbooks/prerequisites.yml
```

```
ansible-playbook playbooks/deploy_cluster.yml
```

>:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

> :bulb: If something went wrong have a look at **~/openshift-ansible.log**

>:checkered_flag::checkered_flag::checkered_flag:


# Check Openshift Installation

## On first master

#### Give admin cluster-admin role

```
oc login -u system:admin
```

```
oc create clusterrolebinding registry-controller --clusterrole=cluster-admin --user=admin
```


## On Controller

<!--

#### Install oc Client Tools

Download [oc Client Tools](https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz) and copy **oc** and **kubectl** in your $PATH

	wget -c https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz

rsync -avg --progress /mnt/iicbackup/produits/ISO/add-ons/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz .

	tar xvzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz --strip-components 1 -C /usr/local/sbin

-->

### Check install

#### Login to cluster

	oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true

### Check Environment health

#### Checking complete environment health

Proceed as describe [here](https://docs.openshift.com/container-platform/3.11/day_two_guide/environment_health_checks.html#day-two-guide-complete-deployment-health-check)

#### Checking Hosts Router Registry and Network connectivity

Proceed as describe [here](https://docs.openshift.com/container-platform/3.11/day_two_guide/environment_health_checks.html#day-two-guide-host-health)


# Make a OCPinstalled snapshot

## On Controller

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; poweroff'; done
```

## On ESX

### Make a snapshot

#### Make a snapshot called OCPInstalled

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $2 !~ "nfs-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " OCPinstalled"}' | sh

#### Power cluster vms on

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $2 !~ "nfs-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

### If necessary revert snapshot

#### Get last snapshot id from first master

	export SNAPID=$(vim-cmd vmsvc/getallvms | awk '$2 ~ "m1-ocp" && $2 !~ "nfs-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh | awk -F' : ' '$1 ~ "--Snapshot Id " {print $2}')

#### Revert to latest snapshot

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $2 !~ "nfs-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.revert " $1 " " '$SNAPID' " suppressPowerOn" }' | sh

#### Power cluster vms on

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $2 !~ "nfs-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

<!--

# On NFS server

```
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
[ ! -z $(rpm -qa nfs-utils) ] && echo nfs-utils installed || { echo nfs-utils not installed; yum install -y nfs-utils rpcbind; }
systemctl restart nfs
showmount -e
systemctl enable nfs
systemctl stop firewalld
systemctl disable firewalld
EOF
```

```
chmod +x installNFSServer.sh && ./installNFSServer.sh
```

# On Controller

## Test nfs access

```
[ ! -z $(rpm -qa nfs-utils) ] && echo nfs-utils installed \
|| { echo nfs-utils not installed; yum install -y nfs-utils rpcbind; }

[ ! -d /mnt/test ] && mkdir /mnt/test && mount -t nfs nfs-$OCP:/exports /mnt/test
touch /mnt/test/a && echo "RC="$?

sshpass -e ssh -o StrictHostKeyChecking=no nfs-$OCP ls /exports/ 
```

```
rm -f /mnt/test/a && echo "RC="$?
sshpass -e ssh -o StrictHostKeyChecking=no nfs-$OCP ls /exports/
umount /mnt/test && rmdir /mnt/test/ 
```

## Add storage class managed-nfs-storage for NFS Persistent Volume Claim

```
oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
```

```
unzip $WORKDIR/nfs-client.zip -d $WORKDIR
```



```
cd $WORKDIR/nfs-client/

oc new-project storage

NAMESPACE=$(oc project -q)

sed -i -e 's/namespace:.*/namespace: '$NAMESPACE'/g' ./deploy/rbac.yaml

oc create -f deploy/rbac.yaml

oc adm policy add-scc-to-user \
hostmount-anyuid system:serviceaccount:$NAMESPACE:nfs-client-provisioner

sed -i -e 's/<NFS_HOSTNAME>/nfs-'$OCP'/g' deploy/deployment.yaml

oc create -f deploy/class.yaml

oc create -f deploy/deployment.yaml

oc get pods

oc logs $(oc get pods | awk 'NR>1 {print $1}')

oc create -f deploy/test-claim.yaml

oc create -f deploy/test-pod.yaml

VOLUME=$(oc get pvc | awk '$1 ~ "test-claim" {print $3}')
```

> :bulb: Next command shoud display **SUCCESS**

```
sshpass -e ssh -o StrictHostKeyChecking=no \
nfs-$OCP ls /exports/$(oc project -q)-test-claim-$VOLUME

cd ~
```



# Exposing openshift Registry

## On Controller

```
oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true -n default

[ -z $(command -v jq) ] && { wget -c https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x jq-linux64 && mv jq-linux64 /usr/local/sbin/jq } || echo jq installed
```

> :warning: Termination should display **passthrough** if not proceed as describe [here](https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry)

```
oc get route/docker-registry -o json | jq -r .spec.tls.termination
```

```
REG_HOST=$(oc get route/docker-registry -o json | jq -r .spec.host)

mkdir -p /etc/docker/certs.d/$REG_HOST

scp m1-$OCP:/etc/origin/master/ca.crt /etc/docker/certs.d/$REG_HOST

docker login -u $(oc whoami) -p $(oc whoami -t) $REG_HOST

docker pull busybox

docker tag docker.io/busybox $REG_HOST/$(oc project -q)/busybox

docker push $REG_HOST/$(oc project -q)/busybox
```



# Install Cloud Pak for Data

cp -v  /mnt/iicbackup/produits/ISO/add-ons/icp4d/cpd/cloudpak4data-ee-v2.5.0.0.tgz .

mkdir cpd && cd cpd && tar xvzf ../cloudpak4data-ee-v2.5.0.0.tgz

//Must be connected to IBM network

```
APIKEY=$(curl http://icpfs1.svl.ibm.com/zen/cp4d-builds/2.5.0.0/production/internal/repo.yaml | awk -F ": " ' $1 ~ "apikey" {print $2}')
```


```
cat > repo.yaml << EOF
registry:
  - url: cp.icr.io/cp/cpd
    username: iamapikey
    apikey: $APIKEY
    name: base-registry
fileservers:
  - url: https://raw.github.com/IBM/cloud-pak/master/repo/cpd
EOF
```



oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true

chmod +x bin/cpd-linux

// Prepare installation

// Dry run

bin/cpd-linux adm --repo repo.yaml --assembly lite --namespace cpd

// Apply

bin/cpd-linux adm --repo repo.yaml --assembly lite --namespace cpd --apply

// Grant `cpd-admin-role` to the project administration user

oc adm policy add-role-to-user cpd-admin-role admin --role-namespace=cpd -n cpd

// Install OCP4D

screen -mdS ADM

screen -r ADM

bin/cpd-linux \
--repo ./repo.yaml \
--assembly lite \
--namespace cpd \
--storageclass managed-nfs-storage \
--transfer-image-to docker-registry-default.apps-$OCP.iicparis.fr.ibm.com/cpd \
--target-registry-password $(oc whoami -t) \
--target-registry-username $(oc whoami) \
--cluster-pull-prefix docker-registry.default.svc:5000/cpd



# Install Cloud Pak for Application

[Instructions](https://github.ibm.com/IBMCloudPak4Apps/icpa-install#other-ibmers)

```
export INSTALLER_TAG=3.0.0.0
export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=ekey
export ENTITLED_REGISTRY_KEY=
```

	docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY"
	
	docker pull "$ENTITLED_REGISTRY/cp/icpa/icpa-installer:$INSTALLER_TAG"

> :bulb: Optional: save installer and restore it in another environment

>```
>docker save cp.icr.io/cp/icpa/icpa-installer | gzip -c > cp.icr.io-cp-icpa-icpa-installer.tar.gz
>```

>```
>docker load < cp.icr.io-cp-icpa-icpa-installer.tar.gz
>```


```
mkdir data
docker run -v $PWD/data:/data:z -u 0 \
-e LICENSE=accept \
"$ENTITLED_REGISTRY/cp/icpa/icpa-installer:$INSTALLER_TAG" cp -r "data/*" /data
```

// add subdomain to data/config.yaml
e.g. apps-ocp3.iicparis.fr.ibm.com

// add existing PVC to transadv.yaml

```
oc login https://lb-$OCP:8443 -u admin -p admin \
--insecure-skip-tls-verify=true
```

```
oc new-project ta
```

```
cp -v $WORKDIR/nfs-client/deploy/test-claim.yaml \
$WORKDIR/nfs-client/deploy/tapvc.yaml
```

```
sed -i '/  name: / s/test-claim/tapvc/' \
$WORKDIR/nfs-client/deploy/tapvc.yaml
```

```
oc create -f $WORKDIR/nfs-client/deploy/tapvc.yaml
```



//Add tapvc as existingClaim in data/transadv.yaml

vi data/transadv.yaml

```
docker run -v ~/.kube:/root/.kube:z -u 0 -t \
-v $PWD/data:/installer/data:z \
-e LICENSE=accept \
-e ENTITLED_REGISTRY -e ENTITLED_REGISTRY_USER -e ENTITLED_REGISTRY_KEY \
"$ENTITLED_REGISTRY/cp/icpa/icpa-installer:$INSTALLER_TAG" install
```





# Install Cloud Pak for Multicloud Management

## On First Master Node

### Add the following to your /etc/origin/master/master-config.yaml

```
admissionConfig:
  pluginConfig:
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
```

### Restart your apiserver and controllers

```
/usr/local/bin/master-restart api
/usr/local/bin/master-restart controllers
```

## On Controller

### Elasticsearch

> :warning: **vm.max_map_count** has to be set to **262144** to all nodes

#### Check

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; sysctl -n vm.max_map_count'; done
```

#### Update if necessary

```
for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3; do ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; sysctl -w vm.max_map_count=262144; echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf'; done
```

### Install the IBM Cloud Pak for Multicloud Management

> :bulb: Download partnumber CC4L8EN

#### Load the container images into the local registry

> :warning: Check registry file system has 50G free.

	tar xf ibm-cp4mcm-core-1.2-x86_64.tar.gz -O | sudo docker load

#### Create an installation directory on the boot node

```
mkdir /opt/ibm-multicloud-manager-1.2 \ 
&& cd /opt/ibm-multicloud-manager-1.2
```























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

https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry



https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry







-->

<!--
# Annexes

## On Controller

#### Create key pair and exchange public key between cluster vms

> PermitUserEnvironment must enabled in target /etc/ssh/sshd_config

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; sed -i "s/^#PermitUserEnvironment no/PermitUserEnvironment yes/g" /etc/ssh/sshd_config; systemctl restart sshd'; done


:warning: Set **FIRST** and **LAST** variables acordingly

```
cat > ssh-env << EOF
SSHPASS=spcspc
IP_HEAD=172.16.187.
FIRST=30
LAST=39
EOF
```


```
for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do scp ssh-env root@$IP_HEAD$i:/root/.ssh/environment; done
```


```
for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N "" && for i in $(seq $FIRST $LAST); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done'; done
```

#### Check all vm can access each other without being prompt for a password

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; for i in $(seq $FIRST $LAST); do ssh -o StrictHostKeyChecking=no root@$IP_HEAD$i "hostname -f; date"; done'; done


```

```

```

```
-->