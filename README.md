## Prerequisites

Be a [Redhat partner](https://partnercenter.redhat.com/Dashboard_page) and ask for [NEW NFR](https://partnercenter.redhat.com/NFR_Redirect) to get access to Openshift packages.

In your ESX datastore you should have copied:

- A vmdk file which host  a [minimal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-simple-install#sect-simple-install) and  [prepared](https://docs.openshift.com/container-platform/3.11/install/host_preparation.html) RHEL7. 
- A [bundle](https://github.com/bpshparis/ocp-esx/archive/master.zip)  of scripts and configurations files.

> :bulb: Unregister a RHEL with subscription-manager **unregister**

## On ESX

### Set ESX environment variables

> :warning: Allowed characters for values are [A-Z] [a-z] [0-9] [-/.]

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

> It will take several minutes so [lets add records in DNS](#on-dns)



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

	export OCP=ocp3
	export MASTER_IP_HEAD=172.16.187.3
	export MASTER_NFS_IP=172.16.187.48
	export MASTER_CTL_IP=172.16.187.49
	export REVERSE_IP_TAIL=.187.16.172
	export REVERSE_IP_HEAD=3
	export REVERSE_NFS_IP=48.187.16.172
	export REVERSE_CTL_IP=49.187.16.172

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

> :warning: If session is new, please [set ESX environment variables](#set-esx-environment-variables) first.

### Start ctl vm
	vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-'$OCP'" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Get ctl dhcp address

> :bulb: Wait for ctl vm to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

	$WORKDIR/getVMAddress.sh | grep ctl



## On  controller

### Set environment variables

> :warning: Allowed characters for values are [A-Z] [a-z] [0-9] [-/.]


- **OCP** for cluster-name.



```
echo "" >> ~/.bashrc
echo "export OCP=ocp3" >> ~/.bashrc
source ~/.bashrc
```

### Get tools to manage storage, setup hostname and ip address from DNS

```
curl -LO http://github.com/bpshparis/ocp-esx/archive/master.zip
unzip master.zip
echo "export WORKDIR=$PWD/ocp-esx-master" >> ~/.bashrc
source ~/.bashrc
```

### Extend root logical volume

	$WORKDIR/extendRootLV.sh && lvs

### Setup hostname and ip address from DNS

	$WORKDIR/setHostAndIP.sh ctl-$OCP

### Reboot for change to take effect

	reboot

## On ESX

> :warning: If session is new, please [set ESX environment variables](#set-esx-environment-variables) first.

### Start other vms

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

> :bulb: (Optional) In case cluster vms need to be reboot because of dhcp address lost.
> You may reboot cluster vms with the following command.

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh && vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Wait for all cluster vms to be up and get their DHCP ip address

> :bulb: Wait for all cluster vms to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

	$WORKDIR/getVMAddress.sh | sed '/ctl-ocp/d' | tee $WORK_DIR/vms

###  Copy all cluster vms DHCP ip address to  controller

	scp $WORK_DIR/vms root@ctl-$OCP:/root


## On  controller

### Set  controller environment variables

> :warning: Allowed characters are [A-Z] [a-z] [0-9] [-/]

- **OCP** for cluster-name.

- **SSHPASS** for root password of cluster vms.

- **IP_HEAD** for ip head of all cluster vms.

- **FIRST_IP_TAIL** for ip tail of load balancer (lb). 

- **LAST_IP_TAIL** for ip tail of third infra node (i3). 


	echo "export SSHPASS=spcspc" >> ~/.bashrc
	echo "export IP_HEAD=172.16.187." >> ~/.bashrc
	echo "export FIRST_IP_TAIL=30" >> ~/.bashrc
	echo "export LAST_IP_TAIL=39" >> ~/.bashrc
	source ~/.bashrc


### Copy extendRootLV.sh and setHostAndIP.sh to all cluster vms

	for ip in $(awk -F ";" '{print $3}' /root/vms); do echo "copy to" $ip; sshpass -e scp -o StrictHostKeyChecking=no $WORKDIR/extendRootLV.sh $WORKDIR/setHostAndIP.sh root@$ip:/root; done

### Set all cluster vms with ip address and hostname known in DNS

	for LINE in $(awk -F ";" '{print $0}' vms); do  HOSTNAME=$(echo $LINE | cut -d ";" -f2); IPADDR=$(echo $LINE | cut -d ";" -f3); echo $HOSTNAME; echo $IPADDR; sshpass -e ssh -o StrictHostKeyChecking=no root@$IPADDR '/root/setHostAndIP.sh '$HOSTNAME; done

### Reboot all cluster vms

	for ip in $(awk -F ";" '{print $3}' vms); do sshpass -e ssh -o StrictHostKeyChecking=no root@$ip 'reboot'; done


## On esx

### Wait for all cluster vms to be up with static ip address

	$WORK_DIR/getVMAddress.sh

## On  controller


### Exchange ssh public key with all cluster vms

#### Clean ssh env on all cluster vms

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do sshpass -e ssh -o StrictHostKeyChecking=no root@$IP_HEAD$i 'hostname -f; rm -f /root/.ssh/known_hosts; rm -f /root/.ssh/authorized_keys'; done

#### Generate ssh key pair and copy public key on all cluster vms

	yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""


	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done

#### Check  controller can access all cluster vm without being prompt for a password

:bulb: Use this command to sync time among cluster members

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; ntpdate ntp.iicparis.fr.ibm.com; timedatectl | grep "Local time"'; done

### Create key pair and exchange public key between cluster vms

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

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do scp ssh-env root@$IP_HEAD$i:/root/.ssh/environment; done



	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N "" && for i in $(seq $FIRST $LAST); do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$IP_HEAD$i; done'; done


#### Check all vm can access each other without being prompt for a password

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; for i in $(seq $FIRST $LAST); do ssh -o StrictHostKeyChecking=no root@$IP_HEAD$i "hostname -f; date"; done'; done


### Prepare to install OCP

#### Copy inventory file to default ansible file

	sed 's/-ocp./-'$OCP'/g' $WORKDIR/hosts-cluster > /etc/ansible/hosts

#### Check hosts 

	grep -e '-ocp.' /etc/ansible/hosts

#### Extend root Volume Group on all cluster vms

	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; /root/extendRootLV.sh'; done

#### Check ansible can speak with every nodes in the cluster

	ansible OSEv3 -m ping

#### Set Docker storage

	ansible nodes -a 'systemctl stop docker'
	ansible lb -a 'systemctl stop docker'



	for i in $(seq $FIRST_IP_TAIL $LAST_IP_TAIL); do ssh root@$IP_HEAD$i 'hostname -f; rm -rf /var/lib/docker/*'; done


	ansible nodes -a 'du -h /var/lib/docker/'
	ansible lb -a 'du -h /var/lib/docker/'


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
cat > setOCPStorage.sh << EOF
ansible infra-compute -a 'pvcreate /dev/sdd'
ansible infra-compute -a 'vgcreate origin /dev/sdd'
ansible infra-compute -a 'lvcreate -n origin -l 100%VG origin'
ansible infra-compute -a 'mkdir /var/lib/origin'
ansible infra-compute -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/origin/origin'
ansible infra-compute -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/origin-origin  /var/lib/origin  xfs defaults,noatime 1 2"'
ansible infra-compute -a 'mount /var/lib/origin'
ansible infra-compute -a 'df -hT /var/lib/origin'
ansible infra-compute -a 'lvs'
EOF
```

	chmod +x setOCPStorage.sh && ./setOCPStorage.sh

#### set etcd storage

```
cat > setETCDStorage.sh << EOF
ansible etcd -a 'pvcreate /dev/sdd'
ansible etcd -a 'vgcreate etcd /dev/sdd'
ansible etcd -a 'lvcreate -n etcd -l 100%VG etcd'
ansible etcd -a 'mkdir /var/lib/etcd'
ansible etcd -a 'mkfs.xfs -f -n ftype=1 -i size=512 -n size=8192 /dev/etcd/etcd'
ansible etcd -m lineinfile -a 'path=/etc/fstab line="/dev/mapper/etcd-etcd  /var/lib/etcd  xfs defaults,noatime 1 2"'
ansible etcd -a 'mount /var/lib/etcd'
ansible etcd -a 'df -hT /var/lib/etcd'
ansible etcd -a 'lvs'
EOF
```

	chmod +x setETCDStorage.sh && ./setETCDStorage.sh



# On esx

### Make a snapshot

#### Power cluster vms off

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh

#### Make a snapshot called beforeInstallingOCP

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.create " $1 " beforeInstallingOCP"}' | sh

#### Power cluster vms on

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh



# On ctl

### Install OCP

#### Check ansible can speak with every nodes in the cluster

	ansible OSEv3 -m ping

#### Launch OCP installation

:bulb: To avoid network failure, launch installation on ** locale console** or in a **screen**

	screen -mdS ADM && screen -r ADM


	cd /usr/share/ansible/openshift-ansible


	ansible-playbook playbooks/prerequisites.yml


	ansible-playbook playbooks/deploy_cluster.yml

:bulb: Leave screen with **Ctrl + a +d**
:bulb: Come back with

	screen -r ADM


# On first master

## Give admin cluster-admin role

oc login -u system:admin

oc create clusterrolebinding registry-controller --clusterrole=cluster-admin --user=admin



# On ctl

## Install oc Client Tools

Download [oc Client Tools](https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz) and copy **oc** and **kubectl** in your $PATH

	rsync -avg --progress /mnt/iicbackup/produits/ISO/add-ons/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz .
	
	tar xvzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz --strip-components 1 -C /usr/local/sbin

## Check install

	oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
	
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

### Get snapshot id

:bulb: Get snapshot state with

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.get " $1 }' | sh

### Set snapshot id

	SNAPID=1
	
	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.off " $1}' | sh
	
	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/snapshot.revert " $1 " " '$SNAPID' " suppressPowerOn" }' | sh
	
	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

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

chmod +x installNFSServer.sh && ./installNFSServer.sh

# on first master

export OCP=ocp7

## Test nfs access

mkdir /mnt/test && mount -t nfs nfs-$OCP:/exports /mnt/test
touch /mnt/test/a && echo "RC="$? && ls /mnt/test/a && yes | rm /mnt/test/a && echo "RC="$?
umount /mnt/test && rmdir /mnt/test/

## Add storage class managed-nfs-storage for NFS Persistent Volume Claim

mount /mnt/iicbackup/produits/

cd /root
tar xvzf /mnt/iicbackup/produits/ISO/add-ons/icpa/nfs-client.tar.gz


oc login -u admin -p admin
oc new-project storage
cd /root/nfs-client/
NAMESPACE=$(oc project -q)
sed -i -e 's/namespace:.*/namespace: '$NAMESPACE'/g' ./deploy/rbac.yaml
oc create -f deploy/rbac.yaml
oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:$NAMESPACE:nfs-client-provisioner
sed -i -e 's/<NFS_HOSTNAME>/nfs-'$OCP'/g' deploy/deployment.yaml

oc create -f deploy/class.yaml
oc create -f deploy/deployment.yaml

oc get pods
oc logs $(oc get pods | awk 'NR>1 {print $1}')

oc create -f deploy/test-claim.yaml

### should display bound state
oc get pvc

oc create -f deploy/test-pod.yaml

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





https://docs.openshift.com/container-platform/3.11/install_config/registry/securing_and_exposing_registry.html#exposing-the-registry
