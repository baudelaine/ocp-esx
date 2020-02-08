# Install Cloud Pak for Applications

## On Controller

### Pre-installation tasks

#### Get entitlement key

Look for [Cloud Paks in IBM Cloud catalog](https://cloud.ibm.com/catalog?search=cloud%20pak%20for%20app#software) and assign the license when clicking on the Cloud Pak for Application tile.

##### Install IBM Cloud CLI

> :warning: Run this on Controller

	curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

##### Login to IBM Cloud

> :warning: Run this on Controller

	ibmcloud login --sso --no-region

##### Set APIKEY with entitlement key

###### Install jq 

> :bulb: jq is a json parser for command line

> :warning: Run this on Controller

```
[ -z $(command -v jq) ] && { wget -c https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x jq-linux64 && mv jq-linux64 /usr/local/sbin/jq; } || echo jq installed
```

###### Set APIKEY

> :warning: Run this on Controller

```
BEARER=$(ibmcloud iam oauth-tokens | awk '{print $4;}')

APIKEY=$(curl -s https://billing.cloud.ibm.com/v1/licensing/entitlements -H "Authorization: Bearer $BEARER" -H 'Content-Type: application/json' -H 'cache-control: no-cache' | jq -r '.resources[] | select(.name | contains("Cloud Pak for Applications")) | .apikey') && echo $APIKEY
```

### Pull installer

> :bulb: Following instructions came from [here](https://github.ibm.com/IBMCloudPak4Apps/icpa-install#other-ibmers)

> :bulb: Tag starting with 3 seems to suit for Openshift 3.11

> :bulb: Tag starting with 4 seems to suit for Openshift 4.2

> :warning: Run this on Controller

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

> :warning: Run this on Controller

```
mkdir data

docker run -v $PWD/data:/data:z -u 0 \
-e LICENSE=accept \
"$ENTITLED_REGISTRY/cp/icpa/icpa-installer:$INSTALLER_TAG" cp -r "data/*" /data
```

#### Set subdomain in data/config.yaml

> :warning: Run this on Controller

```
SUBDOMAIN=apps-$OCP.iicparis.fr.ibm.com

sed -i -e 's/\(^\s\{4\}subdomain: \).*$/\1"'$SUBDOMAIN'"/'  data/config.yaml
```

#### Set PVC in data/transadv.yaml

##### Log in cluster

> :warning: Run this on Controller

```
oc login https://lb-$OCP:8443 -u admin -p admin \
--insecure-skip-tls-verify=true
```

##### Create project ta for Transformation Advisor service

> :warning: Run this on Controller

```
oc new-project ta
```

##### Create PVC

> :warning: Run this on Controller

```
PVC_NAME=tapvc

cp -v $WORKDIR/nfs-client/deploy/test-claim.yaml \
$WORKDIR/nfs-client/deploy/$PVC_NAME.yaml

sed -i '/  name: / s/test-claim/'$PVC_NAME'/' \
$WORKDIR/nfs-client/deploy/$PVC_NAME.yaml

oc create -f $WORKDIR/nfs-client/deploy/$PVC_NAME.yaml
```

##### Add PVC as existingClaim in data/transadv.yaml

> :warning: Run this on Controller

```
sed -i -e 's/\(^\s\{6\}existingClaim: \).*$/\1"'$PVC'"/'  data/transadv.yaml
```

### Install Cloud Pak for Applications on a Redhat OpenShift cluster

> :warning: To avoid network failure, launch installation on locale console or in a screen

> :warning: Run this on Controller

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

<br>

:hourglass_flowing_sand: :smoking::coffee::smoking::coffee::smoking::coffee::smoking: :coffee: :hourglass_flowing_sand: :beer::beer::beer::pill:  :zzz::zzz: :zzz::zzz: :zzz::zzz::hourglass_flowing_sand: :smoking::coffee: :toilet: :shower: :smoking: :coffee::smoking: :coffee: :smoking: :coffee: :hourglass: 

<br>

>:bulb: Leave screen with **Ctrl + a + d**

>:bulb: Come back with **screen -r ADM**

> :bulb: If something went wrong check logs in **data/logs** directory and revert to [last snapshot](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#If-necessary-revert-to-last-snapshot).

<br>

:checkered_flag::checkered_flag::checkered_flag:

<br>

[Save your work](https://github.com/bpshparis/ocp-esx/blob/master/Install-OCP.md#Make-a-snapshot)

