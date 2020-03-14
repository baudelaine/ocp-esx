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

VMDK="/vmfs/volumes/datastore1/vmdk/rhel.vmdk"

[ ! -f "$VMDK" ] && { echo -e "$RED ERROR: $VMDK not found. Exiting... $NC"; exit 1; }

VMX="/vmfs/volumes/datastore1/vmdk/rhel.vmx"

[ ! -f "$VMX" ] && { echo -e "$RED ERROR: $VMX not found. Exiting... $NC"; exit 1; }

MASTERS_VM="m1-$OCP m2-$OCP m3-$OCP"
WORKERS_VM="w1-$OCP w2-$OCP w3-$OCP"
MASTER_STORAGE="120G"
MASTER_VCPU="4"
MASTER_RAM="16384"
WORKER_STORAGE="500G"
WORKER_VCPU="8"
WORKER_RAM="65536"
MASTER_1ST_VNC_PORT="5901"
WORKER_1ST_VNC_PORT="5904"

createWorkersVm (){

VNC_PORT=$WORKER_1ST_VNC_PORT

for VM_NAME in $WORKERS_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$WORKER_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$WORKER_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createWorkersVmdk (){

for VM_NAME in $WORKERS_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $VMDK $VMS_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c $WORKER_STORAGE $VMS_PATH/$VM_NAME/root1.vmdk
	fi
done

}

addWorkersVmdk (){

for VM_NAME in $WORKERS_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root1.vmdk 0 1
	fi;
done

}


createMastersVm (){

VNC_PORT=$MASTER_1ST_VNC_PORT

for VM_NAME in $MASTERS_VM; do
	echo $VM_NAME
	[ ! -d $VMS_PATH/$VM_NAME ] && mkdir $VMS_PATH/$VM_NAME
	cp -v $VMX $VMS_PATH/$VM_NAME/$VM_NAME.vmx
	if [ $? -eq 0 ]; then
		sed -i -e 's/displayName = "[^"]*"/displayName = "'$VM_NAME'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/numvcpus = "[^"]*"/numvcpus = "'$MASTER_VCPU'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/memSize = "[^"]*"/memSize = "'$MASTER_RAM'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		sed -i -e 's/RemoteDisplay.vnc.port = "[^"]*"/RemoteDisplay.vnc.port = "'$VNC_PORT'"/' $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		vim-cmd solo/registervm $VMS_PATH/$VM_NAME/$VM_NAME.vmx
		let "VNC_PORT++"
	fi
done

}

createMastersVmdk (){

for VM_NAME in $MASTERS_VM; do
	echo $VM_NAME
	if [ $? -eq 0 ]; then
		vmkfstools -i $VMDK $VMS_PATH/$VM_NAME/root0.vmdk
		vmkfstools -c $MASTER_STORAGE $VMS_PATH/$VM_NAME/root1.vmdk
	fi
done

}

addMastersVmdk (){

for VM_NAME in $MASTERS_VM; do
    echo $VM_NAME
	VMID=$(vim-cmd vmsvc/getallvms | awk '{if (NR > 1) print $1 " " $2 }' | grep $VM_NAME | awk '{print $1}')

	if [ ! -z "$VMID" ]; then
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root0.vmdk 0 0
		vim-cmd vmsvc/device.diskaddexisting $VMID $VMS_PATH/$VM_NAME/root1.vmdk 0 1
	fi;
done

}

case $1 in

	masters)
		echo "Create $OCP masters..."
		createMastersVm
		createMastersVmdk
		addMastersVmdk
		;;

	workers)
		echo "Create $OCP workers..."
		createWorkersVm
		createWorkersVmdk
		addWorkersVmdk
		;;

	*)
		echo "Create $OCP cluster..."
		createMastersVm
		createWorkersVm
		createMastersVmdk
		createWorkersVmdk
		addMastersVmdk
		addWorkersVmdk
		;;

esac

exit 0;
