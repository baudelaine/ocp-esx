#!/bin/sh

ME=${0##*/}
RED="\e[31m"
YELLOW="\e[33m"
LBLUE="\e[34m"
GREEN="\e[32m"
NC="\e[0m"

OCP="ocp5"
WEB_SRV_URL="http://172.16.160.150/ocp43"
RAW_IMG_URL="$WEB_SRV_URL/rhcos-4.3.0-x86_64-metal.raw.gz"
BS_IGN_URL="$WEB_SRV_URL/bootstrap.ign"
M_IGN_URL="$WEB_SRV_URL/master.ign"
W_IGN_URL="$WEB_SRV_URL/worker.ign"
DNS="172.16.160.100"
DOMAIN="iicparis.fr.ibm.com"
IF="ens192"
MASK="255.255.224.0"
GATEWAY="172.16.186.17"
ISO_PATH="/media/iso"
RW_ISO_PATH="/media/isorw"
ISO_CFG=$RW_ISO_PATH/isolinux/isolinux.cfg


BS_VM="bs-$OCP"
MASTERS_VM="m1-$OCP m2-$OCP m3-$OCP"
WORKERS_VM="w1-$OCP w2-$OCP w3-$OCP w4-$OCP w5-$OCP"
KERNEL_CMD_LINE="coreos.inst=yes"
DEVICE="sda"
NEW_KERNEL_CMD_LINE="$KERNEL_CMD_LINE coreos.inst.install_dev=$DEVICE coreos.inst.image_url=$RAW_IMG_URL"
MKISOFS_ARGS="-U -A \"RHCOS-x86_64\" -V \"RHCOS-x86_64\" -volset \"RHCOS-x86_64\" -J -joliet-long -r -v -T -x ./lost+found -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot"

[ -z $(command -v mkisofs) ] && yum install -y genisoimage || echo -e mkisofs installed

activateTimeout (){
    sed -i -e 's/^timeout.*$/timeout 100/' $ISO_CFG
    [ $(grep -c '  menu default' $ISO_CFG ) -eq 0 ] && sed -i -e '/  menu label \^Install RHEL CoreOS/a\  menu default\' $ISO_CFG
}

reloadRWIsoPath (){
    [ -d $RW_ISO_PATH ] && rm -rf $RW_ISO_PATH/* || mkdir $RW_ISO_PATH
    [ -d $ISO_PATH ] && rsync -avg --progress $ISO_PATH/ $RW_ISO_PATH
}

initNewKernelCmdLine (){
    NEW_KERNEL_CMD_LINE="$KERNEL_CMD_LINE coreos.inst.install_dev=$DEVICE coreos.inst.image_url=$RAW_IMG_URL"
}

init (){
    reloadRWIsoPath
    activateTimeout
    initNewKernelCmdLine
}

createBSIso (){

for VM_NAME in $BS_VM; do
	echo $VM_NAME
    init
    IP=$(dig +short $VM_NAME.$DOMAIN)
    HOST=$VM_NAME-$OCP.$DOMAIN
    IGN=$BS_IGN_URL
    NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE coreos.inst.ignition_url=$IGN ip=$IP::$GATEWAY:$MASK:$HOST:$IF:none nameserver=$DNS"
    # echo "KERNEL_CMD_LINE="$KERNEL_CMD_LINE
    # echo "NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE
    sed -i -e "s!$KERNEL_CMD_LINE!$NEW_KERNEL_CMD_LINE!" $ISO_CFG
    mkisofs $MKISOFS_ARGS -o $VM_NAME.iso $RW_ISO_PATH/

done

}

createWorkersIso (){

for VM_NAME in $WORKERS_VM; do
	echo $VM_NAME
    init
    IP=$(dig +short $VM_NAME.$DOMAIN)
    HOST=$VM_NAME-$OCP.$DOMAIN
    IGN=$W_IGN_URL
    NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE coreos.inst.ignition_url=$IGN ip=$IP::$GATEWAY:$MASK:$HOST:$IF:none nameserver=$DNS"
    # echo "KERNEL_CMD_LINE="$KERNEL_CMD_LINE
    # echo "NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE
    sed -i -e "s!$KERNEL_CMD_LINE!$NEW_KERNEL_CMD_LINE!" $ISO_CFG
    mkisofs $MKISOFS_ARGS -o $VM_NAME.iso $RW_ISO_PATH/

done

}

createMastersIso (){

for VM_NAME in $MASTERS_VM; do
	echo $VM_NAME
    init
    IP=$(dig +short $VM_NAME.$DOMAIN)
    HOST=$VM_NAME-$OCP.$DOMAIN
    IGN=$M_IGN_URL
    NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE coreos.inst.ignition_url=$IGN ip=$IP::$GATEWAY:$MASK:$HOST:$IF:none nameserver=$DNS"
    # echo "KERNEL_CMD_LINE="$KERNEL_CMD_LINE
    # echo "NEW_KERNEL_CMD_LINE="$NEW_KERNEL_CMD_LINE
    sed -i -e "s!$KERNEL_CMD_LINE!$NEW_KERNEL_CMD_LINE!" $ISO_CFG
    mkisofs $MKISOFS_ARGS -o $VM_NAME.iso $RW_ISO_PATH/

done

}

case $1 in

	masters)
		echo "Create $OCP masters iso..."
        createMastersIso
		;;

	workers)
		echo "Create $OCP workers iso..."
        createWorkersIso
		;;

	bs)
		echo "Create $OCP bs iso..."
        createBSIso
		;;

	*)
		echo "Create $OCP cluster..."
        createBSIso
        createMastersIso
        createWorkersIso
		;;

esac

exit 0;
