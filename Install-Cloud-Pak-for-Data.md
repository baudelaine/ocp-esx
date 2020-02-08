# Install Cloud Pak for Data

## On Controller

### Pre-installation tasks

#### Obtain the installation file

Download part number **CC3Y1ML** either from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/pao_customer.html) or from [XL](https://w3-03.ibm.com/software/xl/download/ticket.wss).

<!--
```
mount /mnt/iicbackup/produits
rsync  /mnt/iicbackup/produits/ISO/add-ons/icp4d/cpd/cloudpak4data-ee-v2.5.0.0.tgz ~
```
-->

#### Run installer to download cloudpak4data-ee-v2.5.0.0.tgz

> :warning: Run this on Controller

```
chmod +x CP4D_EE_Installer_V2.5.bin && ./CP4D_EE_Installer_V2.5.bin
```

#### Untar cloudpak4data-ee-v2.5.0.0.tgz in cpd directory

> :warning: Run this on Controller

```
mkdir cpd && cd cpd && tar xvzf ../cloudpak4data-ee-v2.5.0.0.tgz
```

#### Get entitlement key

Get the key from [My IBM](https://myibm.ibm.com/products-services/containerlibrary)

#### Save the apikey and username

> :warning: Run this on Controller

```
export USERNAME="cp"
export APIKEY="myEntitlementKey"
```

#### Test your entitlement key against cp.icr.io registry

> :warning: Run this on Controller

```
docker login -u $USERNAME -p $APIKEY cp.icr.io
```

##### Try to pull something

> :warning: Run this on Controller

```
docker pull cp.icr.io/cp/cpd/zen-meta-couchdb:v2.5.0.0-210
```

> :warning: If pull failed with **repository cp.icr.io/cp/cpd/zen-meta-couchdb not found: does not exist or no pull access** then connect to IBM intranet and get username and apikey this way :

> :warning: Run this on Controller with **IBM intranet connection**

>```
>USERNAME=$(curl http://icpfs1.svl.ibm.com/zen/cp4d-builds/2.5.0.0/production/internal/repo.yaml | awk -F ": " ' $1 ~ "username" {print $2}') && echo $USERNAME
>```
> :bulb: username should be something like **iamapikey**

>```
>APIKEY=$(curl http://icpfs1.svl.ibm.com/zen/cp4d-builds/2.5.0.0/production/internal/repo.yaml | awk -F ": " ' $1 ~ "apikey" {print $2}') && echo $APIKEY
>```

#### Add username and apikey to repo.yaml

> :warning: Run this on Controller

```
sed -i -e 's/\(^\s\{4\}username: \).*$/\1'$USERNAME'/' repo.yaml

sed -i -e 's/\(^\s\{4\}apikey: \).*$/\1'$APIKEY'/' repo.yaml
```

### Setting up your Cloud Pak for Data environment

#### Log in cluster

> :warning: Run this on Controller

```
oc login https://lb-$OCP:8443 -u admin -p admin --insecure-skip-tls-verify=true
```

#### Set Cloud Pak for Data project name

> :warning: Run this on Controller

	export PROJECT="cpd"

#### Preview the list of resources that must be created on the cluster

##### Dry run

> :warning: Run this on Controller

```
chmod +x bin/cpd-linux
bin/cpd-linux adm --repo repo.yaml --assembly lite --namespace $PROJECT
```

##### Apply

> :warning: Run this on Controller

```
bin/cpd-linux adm --repo repo.yaml --assembly lite --namespace $PROJECT --apply
```

#### Grant cpd-admin-role to the project administration user

> :warning: Run this on Controller

```
export PROJECT_ADMIN="admin"

oc adm policy add-role-to-user cpd-admin-role $PROJECT_ADMIN --role-namespace=$PROJECT -n $PROJECT
```

### Install Cloud Pak for Data on a Redhat OpenShift cluster

> :warning: To avoid network failure, launch installation on locale console or in a screen

> :warning: Run this on Controller

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

screen -mdS ADM && screen -r ADM
```

```
bin/cpd-linux \
--repo ./repo.yaml \
--assembly lite \
--namespace $PROJECT \
--storageclass managed-nfs-storage \
--transfer-image-to docker-registry-default.apps-$OCP.iicparis.fr.ibm.com/$PROJECT \
--target-registry-password $(oc whoami -t) \
--target-registry-username $(oc whoami) \
--cluster-pull-prefix docker-registry.default.svc:5000/$PROJECT
```

> :bulb: If something went wrong check logs in **cpd/bin/cpd-linux-workspace/Logs/** directory and revert to [last snapshot](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#If-necessary-revert-to-last-snapshot).


>:checkered_flag::checkered_flag::checkered_flag:

[Make a snapshot](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#If-necessary-revert-to-last-snapshot)
