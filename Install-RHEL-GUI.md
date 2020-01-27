# Install RHEL GUI

## On Controller

	poweroff

## On ESX

### Check ctl vm is Powered off

	vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh


### Add VNC connectivity to ctl vm

> :warning: If session is new, please [set-esx-environment-variables](#set-esx-environment-variables) first.

```
VMX=$DATASTORE/$OCP/ctl-$OCP/ctl-$OCP.vmx

cat >> $VMX << EOF
RemoteDisplay.vnc.enabled = "True"
RemoteDisplay.vnc.port = "5901"  	 
RemoteDisplay.vnc.password = "spcspc"
RemoteDisplay.vnc.keymap = "fr"
EOF
```

### Open gdbserver in ESX firewall properties for VNC to work

	esxcli network firewall ruleset set -e true -r gdbserver

### Power ctl vm on

	vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Get ESX ip address

> :warning: Save this address to connect to ESX VNC server

```
SWITCH=vmk0
esxcli network ip interface ipv4 get -i $SWITCH | awk 'END{print $2}'
```

## On Controller from VNC

> :bulb: Connect to ESX VNC server on port 5901 with ip address collected above

> e.g. xtightvncviewer **172.16.161.131**:**5901**

> :bulb: type **spcspc** when prompt for **password**

### Add a new user and grant him administrator (sudo)

```
USERID="userid"
PASSWORD="spcspc"

useradd $USERID

echo "$PASSWORD" | passwd $USERID --stdin

usermod -a -G wheel $USERID
```

### install GUI

	yum groupinstall "Server with GUI" -y

### Set runlevel to graphical.target

	systemctl set-default graphical.target

### Start GUI

	init 5

