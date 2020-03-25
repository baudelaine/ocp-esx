# Prerequisites for installing Watson Assistant and Watson Speech Services for Cloud Pak for Data 2.5 on Openshift 3.11


## Redhat requirements

:bulb: NFR request could take several days to be validate.

Be a [Redhat partner](https://partnercenter.redhat.com/Dashboard_page) and ask for [NEW NFR](https://partnercenter.redhat.com/NFR_Redirect) to get access to Openshift packages.

## Hardware requirements

One Lenovo **X3550M5** or similar to host **9** virtual machines:

| role                  | vcpus ( Intel with AVX2 ) | ram (GB) | storage (GB) | ethernet (10GB) |
| --------------------- | ------------------------- | -------- | ------------ | --------------- |
| load balancer         | 2                         | 2        | 5            | 1               |
| master + infra + etcd | 4                         | 16       | 120          | 1               |
| master + infra + etcd | 4                         | 16       | 120          | 1               |
| master + infra + etcd | 4                         | 16       | 120          | 1               |
| worker                | 10                        | 64       | 500          | 1               |
| worker                | 10                        | 64       | 500          | 1               |
| worker                | 10                        | 64       | 500          | 1               |
| nfs server            | 2                         | 2        | 500          | 1               |
| installer             | 4                         | 16       | 200          | 1               |
| **TOTAL**             | **50**                    | **260**  | **2565**     | **9**           |


## System requirements

- One **vmdk** file which host  a [minimal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-simple-install#sect-simple-install) and  [prepared](https://docs.openshift.com/container-platform/3.11/install/host_preparation.html) RHEL7 **booting in DHCP**, **running VMware Tools** with **localhost.localdomain** as hostname. 

- One **DNS server**.

- One **DHCP server**.

## Software requirements

### For Cloud Pak for Data

#### Obtain installation file

> :information_source: Run this on installer

Download **IBM Cloud Pak for Data Enterprise Edition V2.5 - Installer Linux x86 Multilingual** part number **CC3Y1ML** from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/pao_customer.html).

#### Run installer to download cloudpak4data-ee-v2.5.0.0.tgz

> :information_source: Run this on installer

```
chmod +x CP4D_EE_Installer_V2.5.bin && ./CP4D_EE_Installer_V2.5.bin
```

#### Untar cloudpak4data-ee-v2.5.0.0.tgz in cpd directory

> :information_source: Run this on installer

```
mkdir cpd && cd cpd && tar xvzf ../cloudpak4data-ee-v2.5.0.0.tgz
```

#### Get entitlement key

Get the key from [My IBM](https://myibm.ibm.com/products-services/containerlibrary)

#### Save the apikey and username

> :information_source: Run this on installer

```
export USERNAME="cp"
export APIKEY="myEntitlementKey"
```

#### Test your entitlement key against cp.icr.io registry

##### Login registry

> :information_source: Run this on installer

```
docker login -u $USERNAME -p $APIKEY cp.icr.io
```

##### Try to pull something

> :information_source: Run this on installer

```
docker pull cp.icr.io/cp/cpd/zen-meta-couchdb:v2.5.0.0-210
```

### For Watson Assistant

> :information_source: Run this on installer

Download **IBM Watson Assistant for IBM Cloud Pak for Data 1.4.1 Linux English**  part number **CC5GBEN** from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/pao_customer.html).



### For Watson Speech Services

> :information_source: Run this on installer

Download **IBM Watson Speech Services 1.1.1 Linux English**  part number **CC5F7EN**  from [IBM Passport Advantage](https://www.ibm.com/software/passportadvantage/pao_customer.html).




> :information_source: Run this on installer

Download **IBM Watson Speech Services Language Pack 1.1.1 Linux English**  part number **CC5F8EN** from [IBM Passport Advantage] (https://www.ibm.com/software/passportadvantage/pao_customer.html).

