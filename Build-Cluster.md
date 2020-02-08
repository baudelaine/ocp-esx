# Build cluster

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

> :warning: Run this on DNS

	export OCP=ocp3
	export MASTER_IP_HEAD=172.16.187.3
	export MASTER_NFS_IP=172.16.187.48
	export MASTER_CTL_IP=172.16.187.49
	export REVERSE_IP_TAIL=.187.16.172
	export REVERSE_IP_HEAD=3
	export REVERSE_NFS_IP=48.187.16.172
	export REVERSE_CTL_IP=49.187.16.172

### Add records to master zone

> :warning: Run this on DNS

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

> :warning: Run this on DNS

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

### Restart DNS service

> :warning: Run this on DNS

```
service bind9 restart
```

### Test master zone

> :warning: Run this on DNS

	dig @localhost +short lb-$OCP.iicparis.fr.ibm.com

### Test reverse zone

> :warning: Run this on DNS

	LB_IP=$(dig @localhost +short lb-$OCP.iicparis.fr.ibm.com)
	dig @localhost +short -x $LB_IP


### Test alias

> :warning: Run this on DNS

	dig @localhost +short *.apps-$OCP.iicparis.fr.ibm.com


## On ESX

### Set ESX environment variables

> :warning: Allowed characters for OCP are [A-Z] [a-z] [0-9] [-]

- **OCP** for cluster-name.
- **DATASTORE** for path where vms will be created.
- **VMDK** for full path of minimal and prepared RHEL7 vmdk file.
- **WORKDIR** for path where bundle was extracted.

e.g.

> :warning: Run this on ESX

	export OCP=ocp3
	export DATASTORE="/vmfs/volumes/V7000F-Volume-10TB"
	export VMDK="/vmfs/volumes/datastore1/vmdk/rhel.vmdk"
	export WORKDIR="/vmfs/volumes/datastore1/ocp-esx-master"

### Create VMs

> :warning: Run this on ESX

	cd $WORKDIR && ./createVMs.sh $OCP

### Start controller vm

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-'$OCP'" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Get controller dhcp address

> :warning: Wait for ctl vm to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

> :warning: Run this on ESX

	$WORKDIR/getVMAddress.sh | grep ctl



## On Controller

### Set environment variables

> :warning: Allowed characters for OCP are [A-Z] [a-z] [0-9] [-]

- **OCP** for cluster-name.
- **SSHPASS** for root password of cluster vms.

e.g.

> :warning: Run this on Controller

```
echo "" >> ~/.bashrc
echo "export OCP=ocp3" >> ~/.bashrc
echo "export SSHPASS=spcspc" >> ~/.bashrc
source ~/.bashrc

```

### Get tools to manage storage and setup hostname and ip address from DNS

> :warning: Run this on Controller

```
curl -LO http://github.com/bpshparis/ocp-esx/archive/master.zip
[ ! -z $(command -v unzip) ] && echo unzip installed || yum install zip unzip -y
unzip master.zip
echo "export WORKDIR=$PWD/ocp-esx-master" >> ~/.bashrc
source ~/.bashrc
rm -f master.zip

```

### Extend root logical volume

> :warning: Run this on Controller

>:warning: Set **DISK**, **PART**, **VG** and **LV** variables accordingly in **$WORKDIR/extendRootLV.sh** before proceeding

	$WORKDIR/extendRootLV.sh && lvs

### Setup hostname and ip address from DNS

> :warning: Run this on Controller

	$WORKDIR/setHostAndIP.sh ctl-$OCP

### Reboot for change to take effect

> :warning: Run this on Controller

	reboot

## On ESX

> :warning: If session is new, please [set-esx-environment-variables](#set-esx-environment-variables) first.

### Start other vms

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 !~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Get cluster vms DHCP ip address

> :warning: Run this on ESX

> :warning: Wait for all cluster vms to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

	$WORKDIR/getVMAddress.sh | sed '/ctl-ocp/d' | tee $WORK_DIR/vms

###  Copy all cluster vms DHCP ip address to  controller

> :warning: Run this on ESX

	scp $WORK_DIR/vms root@ctl-$OCP:/root


## On  Controller

### Copy extendRootLV.sh and setHostAndIP.sh to cluster nodes

> :warning: Run this on Controller

	for ip in $(awk -F ";" '{print $3}' /root/vms); do echo "copy to" $ip; sshpass -e scp -o StrictHostKeyChecking=no $WORKDIR/extendRootLV.sh $WORKDIR/setHostAndIP.sh root@$ip:/root; done

### Set cluster nodes with ip address and hostname known in DNS

> :warning: Run this on Controller

	for LINE in $(awk -F ";" '{print $0}' vms); do  HOSTNAME=$(echo $LINE | cut -d ";" -f2); IPADDR=$(echo $LINE | cut -d ";" -f3); echo $HOSTNAME; echo $IPADDR; sshpass -e ssh -o StrictHostKeyChecking=no root@$IPADDR '/root/setHostAndIP.sh '$HOSTNAME; done

### Reboot cluster nodes

> :warning: Run this on Controller

	for ip in $(awk -F ";" '{print $3}' vms); do sshpass -e ssh -o StrictHostKeyChecking=no root@$ip 'reboot'; done


## On ESX

### Wait for all cluster vms to be up with static ip address

> :warning: Run this on ESX

> :warning: Wait for all cluster vms to be up and display its DHCP address in the **3rd column**
> You may need to run script several times.

	$WORKDIR/getVMAddress.sh

## On  Controller

### Exchange ssh public key with cluster nodes

#### Clean cluster nodes ssh environment

> :warning: Run this on Controller

	for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do sshpass -e ssh -o StrictHostKeyChecking=no root@$node-$OCP 'hostname -f; rm -f /root/.ssh/known_hosts; rm -f /root/.ssh/authorized_keys'; done

#### Generate ssh key pair and copy public key on cluster nodes

> :warning: Run this on Controller

	yes y | ssh-keygen -b 4096 -f ~/.ssh/id_rsa -N ""


	for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do sshpass -e ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$node-$OCP; done

#### Check  controller can access cluster nodes without being prompt for a password

> :warning: Run this on Controller

	for node in lb m1 m2 m3 n1 i1 n2 i2 n3 i3 nfs; do ssh root@$node-$OCP 'hostname -f; date; timedatectl | grep "Local time"'; done
