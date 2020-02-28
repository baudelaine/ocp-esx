DNS=172.16.187.35
MASK=255.255.224.0
ROUTER=172.16.186.17
WEB='http:\/\/172.16.187.35:6080'
DOMAIN=iicparis.fr.ibm.com

> /home/ocp42/.ssh/known_hosts


sudo rm -rf master.ign worker.ign metadata.json bootstrap.ign manifests openshift auth .openshift_install.log .openshift_install_state.json
cp ../sav/install-config.yaml-ori install-config.yaml
./openshift-install create manifests --dir=$PWD

sed -i 's/mastersSchedulable: true/mastersSchedulable: false/' manifests/cluster-scheduler-02-config.yml
tar -czf ../sav/manifests.tgz manifests
tar -czf ../sav/openshift.tgz openshift

./openshift-install create ignition-configs --dir=$PWD

cp  bootstrap.ign /var/www/html/ignition/bootstrap/bootstrap.ign
for ho in master421 master422 master423 worker421 worker422 worker423
do
    rm -rf /var/www/html/ignition/$ho
    mkdir /var/www/html/ignition/$ho
    if [ `echo $ho | grep master | wc -c ` -gt 9 ] ;then ori=master ; fi
    if [ `echo $ho | grep worker | wc -c ` -gt 9 ] ;then ori=worker ; fi
    echo "cat ${ori}.ign | sed 's/"storage":{}/"storage":{"files":[{"filesystem":"root","path":"\/etc\/hostname","mode":420,"contents":{"source":"data:,@@@@@"}}]}/' | sed "s/@@@@@/${ho}.${DOMAIN}/" > /var/www/html/ignition/$ho/$ho.ign"

    cat ${ori}.ign | sed 's/"storage":{}/"storage":{"files":[{"filesystem":"root","path":"\/etc\/hostname","mode":420,"contents":{"source":"data:,@@@@@"}}]}/' | sed "s/@@@@@/${ho}.${DOMAIN}/" > /var/www/html/ignition/$ho/$ho.ign
done

rm -f rhcoss-4.2.18-x86_64-*_installer.iso
for ho in bootstrap_172.16.187.37 master421_172.16.187.31 master422_172.16.187.32 master423_172.16.187.33 worker421_172.16.187.34 worker422_172.16.187.36 worker423_172.16.187.38
do
   mkdir mnt
   sudo mount ../rhcos-4.2.18-x86_64-installer.iso mnt/
   mkdir rhcos
   rsync -a mnt/* rhcos/
   hname=`echo $ho | awk -F_ '{ print $1}'`
   hip=`echo $ho | awk -F_ '{ print $2}'`
   cd rhcos
   if [ $hname = "bootstrap" ]; then
       sed -i "s/coreos.inst=yes/coreos.inst=yes ip=$hip::$ROUTER:$MASK:${hname}.${DOMAIN}:ens192:none nameserver=$DNS coreos.inst.install_dev=sda coreos.inst.image_url=${WEB}\/install\/rhcos-4.2.18-x86_64-metal-bios.raw.gz coreos.inst.ignition_url=${WEB}\/ignition\/append-bootstrap.ign/" isolinux/isolinux.cfg
   else
      sed -i "s/coreos.inst=yes/coreos.inst=yes ip=$hip::${ROUTER}:${MASK}:${hname}.${DOMAIN}:ens192:none nameserver=$DNS coreos.inst.install_dev=sda coreos.inst.image_url=${WEB}\/install\/rhcos-4.2.18-x86_64-metal-bios.raw.gz coreos.inst.ignition_url=${WEB}\/ignition\/${hname}\/${hname}.ign/" isolinux/isolinux.cfg
   fi

   sudo mkisofs -U -A "RHCOS-x86_64" -V "RHCOS-x86_64" -volset "RHCOS-x86_64" -J -joliet-long -r -v -T -x ./lost+found -o ../rhcoss-4.2.18-x86_64-${hname}_installer.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot .
   cd ..
   pwd
   rm -rf rhcos/
   sudo umount $PWD/mnt/
   rm -rf mnt
   ssh  root@172.16.161.131 "rm /vmfs/volumes/V7000F-Volume-10TB/iso/rhcoss-4.2.18-x86_64-${hname}_installer.iso"
   scp rhcoss-4.2.18-x86_64-${hname}_installer.iso root@172.16.161.131:/vmfs/volumes/V7000F-Volume-10TB/iso
done




   

