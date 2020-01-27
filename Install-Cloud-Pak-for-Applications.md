# Install Cloud Pak for Applications

## On Controller

### Pre-installation tasks

#### Get entitlement key

Look for [Cloud Paks in IBM Cloud catalog](https://cloud.ibm.com/catalog?search=cloud%20pak%20for%20app#software) and assign the license when clicking on the Cloud Pak for Application tile.

##### Install IBM Cloud CLI

	curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

##### Login to IBM Cloud

	ibmcloud login --sso --no-region

##### Set APIKEY with entitlement key

###### Install jq 

> :bulb: jq is a json parser for command line

```
[ -z $(command -v jq) ] && { wget -c https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x jq-linux64 && mv jq-linux64 /usr/local/sbin/jq; } || echo jq installed
```

###### Set APIKEY

```
BEARER=$(ibmcloud iam oauth-tokens | awk '{print $4;}')

APIKEY=$(curl -s https://billing.cloud.ibm.com/v1/licensing/entitlements -H "Authorization: Bearer $BEARER" -H 'Content-Type: application/json' -H 'cache-control: no-cache' | jq -r '.resources[] | select(.name | contains("Cloud Pak for Applications")) | .apikey') && echo $APIKEY
```

### Pull installer

> :bulb: Following instructions came from [here](https://github.ibm.com/IBMCloudPak4Apps/icpa-install#other-ibmers)

> :bulb: Tag starting with 3 seems to suit for Openshift 3.11

> :bulb: Tag starting with 4 seems to suit for Openshift 4.2

```
export INSTALLER_TAG=3.0.0.0
export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=ekey
export ENTITLED_REGISTRY_KEY=$APIKEY
```

	docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY"
	
	docker pull "$ENTITLED_REGISTRY/cp/icpa/icpa-installer:$INSTALLER_TAG"

> :bulb: Optional: To save installer

>```
>docker save cp.icr.io/cp/icpa/icpa-installer | gzip -c > cp.icr.io-cp-icpa-icpa-installer.tar.gz
>```

>  and restore it **later** in another environment.

>```
>docker load < cp.icr.io-cp-icpa-icpa-installer.tar.gz
>```

### Setup installer

#### Extract configuration files

```
mkdir data

docker run -v $PWD/data:/data:z -u 0 \
-e LICENSE=accept \
"$ENTITLED_REGISTRY/cp/icpa/icpa-installer:$INSTALLER_TAG" cp -r "data/*" /data
```

#### Set subdomain in data/config.yaml

```
SUBDOMAIN=apps-$OCP.iicparis.fr.ibm.com

sed -i -e 's/\(^\s\{4\}subdomain: \).*$/\1"'$SUBDOMAIN'"/'  data/config.yaml
```

#### Set PVC in data/transadv.yaml

##### Log in cluster

```
oc login https://lb-$OCP:8443 -u admin -p admin \
--insecure-skip-tls-verify=true
```

##### Create project ta for Transformation Advisor service

```
oc new-project ta
```

##### Create PVC

```
PVC_NAME=tapvc

cp -v $WORKDIR/nfs-client/deploy/test-claim.yaml \
$WORKDIR/nfs-client/deploy/$PVC_NAME.yaml

sed -i '/  name: / s/test-claim/'$PVC_NAME'/' \
$WORKDIR/nfs-client/deploy/$PVC_NAME.yaml

oc create -f $WORKDIR/nfs-client/deploy/$PVC_NAME.yaml
```

##### Add PVC as existingClaim in data/transadv.yaml

```
sed -i -e 's/\(^\s\{6\}existingClaim: \).*$/\1"'$PVC'"/'  data/transadv.yaml
```

### Install Cloud Pak for Applications on a Red Hat OpenShift cluster

> :warning: To avoid network failure, launch installation on locale console or in a screen

```
[ ! -z $(command -v screen) ] && echo screen installed || yum install screen -y

screen -mdS ADM && screen -r ADM
```

```
docker run -v ~/.kube:/root/.kube:z -u 0 -t \
-v $PWD/data:/installer/data:z \
-e LICENSE=accept \
-e ENTITLED_REGISTRY -e ENTITLED_REGISTRY_USER -e ENTITLED_REGISTRY_KEY \
"$ENTITLED_REGISTRY/cp/icpa/icpa-installer:$INSTALLER_TAG" install
```


> :bulb: If something went wrong check logs in **data/logs** directory.

>:checkered_flag::checkered_flag::checkered_flag:
