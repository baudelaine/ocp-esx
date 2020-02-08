# Install RHEL GUI

## On Controller

> :warning: Run this on Controller

	poweroff

## On ESX

### Check ctl vm is Powered off

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.getstate " $1}' | sh


### Add VNC connectivity to ctl vm

> :warning: If session is new, please [set-esx-environment-variables](https://github.com/bpshparis/ocp-esx/blob/master/Build-Cluster.md#set-esx-environment-variables) first.

> :warning: Run this on ESX

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

> :warning: Run this on ESX

	esxcli network firewall ruleset set -e true -r gdbserver

### Power ctl vm on

> :warning: Run this on ESX

	vim-cmd vmsvc/getallvms | awk '$2 ~ "ctl-ocp" && $1 !~ "Vmid" {print "vim-cmd vmsvc/power.on " $1}' | sh

### Get ESX ip address

> :warning: Run this on ESX

> :warning: Save this address to connect to ESX VNC server

```
SWITCH=vmk0
esxcli network ip interface ipv4 get -i $SWITCH | awk 'END{print $2}'
```

## On your local machine

Download [TightVNC](https://www.tightvnc.com/download.php), a Free, Lightweight, Fast and Reliable Remote Control / Remote Desktop Software

> :bulb: Connect to ESX VNC server on port 5901 with ip address collected above

> e.g. xtightvncviewer **172.16.161.131**:**5901**

> :bulb: type **spcspc** when prompt for **password**

### Add a new user and grant him administrator (sudo)

> :warning: Run this from your local machine on Conroller VNC console

```
USERID="userid"
PASSWORD="spcspc"

useradd $USERID

echo "$PASSWORD" | passwd $USERID --stdin

usermod -a -G wheel $USERID
```

### install GUI

> :warning: Run this from your local machine on Conroller VNC console

	yum groupinstall "Server with GUI" -y

### Set runlevel to graphical.target

> :warning: Run this from your local machine on Conroller VNC console

	systemctl set-default graphical.target

### Start GUI

> :warning: Run this from your local machine on Conroller VNC console

	init 5

### Sign in GUI

> :warning: Run this from your local machine on Conroller VNC console

:information_source: When prompted, keep checked locales and keybords, uncheck contribution and skip signing.

#### Open a terminal and copy Openshift cluster Certificate Authority from first Master 

> :warning: Run this from your local machine on Conroller VNC console



#### Add Openshift Certificate Authority to Firefox

> :warning: Run this from your local machine on Conroller VNC console


#### Log to Openshift console

>:bulb: Login to cluster via the load balancer on port 8443 

> :warning: Run this from your local machine on Conroller VNC console



<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>

:bulb: Make a snapshot of the Controller.

<br>
