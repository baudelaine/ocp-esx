#!/bin/sh

ME=${0##*/}
RED="\e[31m"
YELLOW="\e[33m"
LBLUE="\e[34m"
GREEN="\e[32m"
NC="\e[0m"

OCP=""

[ -z "$OCP" ] && { echo -e "$RED ERROR: OCP is empty. Exiting... $NC"; exit 1; }

DATASTORE="/vmfs/volumes/V7000F-Volume-10TB"
VMS_PATH="$DATASTORE/$OCP"

[ ! -d "$DATASTORE/$OCP" ] && { echo -e "$RED ERROR: $DATASTORE/$OCP directory not found. Exiting... $NC"; exit 1; }

RHEL_VMDK="/vmfs/volumes/datastore1/vmdk/rhel.vmdk"

[ ! -f "$RHEL_VMDK" ] && { echo -e "$RED ERROR: $CRHEL_VMDK not found. Exiting... $NC"; exit 1; }

CENTOS_VMDK="/vmfs/volumes/datastore1/vmdk/centos.vmdk"

[ ! -f "$CENTOS_VMDK" ] && { echo -e "$RED ERROR: $CENTOS_VMDK not found. Exiting... $NC"; exit 1; }

VMX="/vmfs/volumes/datastore1/vmdk/rhel.vmx"

[ ! -f "$VMX" ] && { echo -e "$RED ERROR: $VMX not found. Exiting... $NC"; exit 1; }

CTL_VM="ctl-$OCP"
LB_VM="lb-$OCP"
NFS_VM="nfs-$OCP"
CTL_STORAGE="100G"
CTL_VCPU="4"
CTL_RAM="16384"
LB_STORAGE=""
LB_VCPU="2"
LB_RAM="2048"
NFS_STORAGE="500G"
NFS_VCPU="2"
NFS_RAM="2048"
CTL_VNC_PORT="5919"
LB_VNC_PORT="5900"
NFS_VNC_PORT="5918"

createCtlVm (){

for VM_NAME in $CTL_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$CTL_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$CTL_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$CTL_VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createCtlVmdk (){

for VM_NAME in $CTL_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $RHEL_VMDK $VMS_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c $CTL_STORAGE $VMS_PATH/$VM_NAME/root1.vmdk
	fi
done

}

addCtlVmdk (){

for VM_NAME in $CTL_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root1.vmdk 0 1
	fi;
done

}

createLbVm (){

for VM_NAME in $LB_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$LB_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$LB_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$LB_VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createLbVmdk (){

for VM_NAME in $LB_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $RHEL_VMDK $VMS_PATH/$VM_NAME/root0.vmdk
	fi
done

}

addLbVmdk (){

for VM_NAME in $LB_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root0.vmdk 0 0
	fi;
done

}


createNfsVm (){

for VM_NAME in $NFS_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$NFS_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$NFS_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$NFS_VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createNfsVmdk (){

for VM_NAME in $NFS_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $CENTOS_VMDK $VMS_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c $NFS_STORAGE $VMS_PATH/$VM_NAME/root1.vmdk
	fi
done

}

addNfsVmdk (){

for VM_NAME in $NFS_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root1.vmdk 0 1
	fi;
done

}

case $1 in

	ctl)
		echo "Create $OCP controler..."
		createCtlVm
		createCtlVmdk
		addCtlVmdk
		;;

	lb)
		echo "Create $OCP load balancer..."
		createLbVm
		createLbVmdk
		addLbVmdk
		;;

	nfs)
		echo "Create $OCP NFS server..."
		createNfsVm
		createNfsVmdk
		addNfsVmdk
		;;

	*)
		echo "Create $OCP controler, load balancer and NFS server..."
		createCtlVm
		createCtlVmdk
		addCtlVmdk
		createLbVm
		createLbVmdk
		addLbVmdk
		createNfsVm
		createNfsVmdk
		addNfsVmdk
		;;

esac

exit 0;
