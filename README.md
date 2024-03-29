# Infrastructure of the D3I-Pilot

This repository contains the terraform configuration files that have been used to run the D3I pilot study.

In this README you will find a description of the components that make up the infrastructure of the D3I pilot 
and instructions on how to deploy the D3I infrastructure to Azure using Terraform. An Azure subscription is required.

In order to use this repository, you must have:

1. An Azure subscription
2. Basic knowledge about Terraform
2. Basic knowledge about Azure

## How to use the terraform configuration files in this repository

### Preparation

1. Install `terraform`. 
2. Install `azure cli` (called `az` and is used by terraform to interact with Azure)
3. Run 'az login' to authenticate to the azure cli tool and follow instructions

Look at the tutorials below to get the basics of terraform. 

The --use-device-code option below is only required if you don't have a browser on the system (bastion host)

    az login --use-device-code --tenant xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx

### Terraform initialisation

1. cd setup-terraform

```
terraform init
```

Although not required you may want to look at / change variables in backend.conf

The above command creates an exclusive storage environment for terraform state.
Destroying resources of the app will not affect the terraform state.

### Deploy an environment

First deploy the shared resources, these are resources used by all environments (dev, test, prod).

1. Decide if you need to edit the terraform.tfvars file to change variable values.
2. Run the command below

```
cd shared-resources
terraform init -backend-config=backend.conf
time terraform apply -auto-approve
```

Next deploy an environment

1. Decide if you need to edit the terraform.tfvars file to change variable values.
2. Run the command below

```
cd <dev, test or prod>
terraform init -backend-config=backend.conf
time terraform apply -auto-approve
```

## Azure components of the D3I-Pilot

Below is a diagram of the components on Azure that the software of the D3I-pilot is running on.
The components will be described in more detail below.
For the exact configuration of the individual components see the terraform configuration files.

<img title="Azure components" src="/resources/azure_components.svg">

### Azure subscription

The Azure subscription the components will be created in.

### Storage account with the Terraform state files

This storage account will hold Terraform state files. These files will be used by Terraform to keep track of the difference components on Azure.

### Cost monitoring

Cost monitoring is configured for the resource groups that contain the components of the data donation app. If costs exceed a preset limit the administrator will be notified by email.

### Automation account

The automation account holds non-sensitive variables created by the resources in `shared-resources` used by the resources deployed in `<environment>`.

### Container registry

This container registry holds the images that contain the app. Azure app services is configured to pull images from this container registry.
Note that in the current setup the container images for the data donation app are pulled from an external registry, this container registry can be used in the future instead.

The pull credentials are configure with RBAC and managed identities; Azure app services is configured with a system managed identity, and a pull role for this container registry will be assigned to this identity.

Images can be pushed to the registry as follows:

```
# Re-name your locally built image
docker tag <locally-built-image>:<tag> <name-of-registry-on-azure>.azurecr.io/<image-name>:<tag>

# Log in to the registry on azure
az login
az acr login --name <name-of-registry-on-azure>

# Push your image to the registry
docker push <name-of-registry-on-azure>.azurecr.io/<image-name>:<tag>
```

This assumes you already have an image built following these [build instructions](https://github.com/eyra/mono/blob/d3i/latest/PORT.md#release-instructions).

### Azure app service with a web server

This Azure app service runs a minimalist web server that serves the following static content: contact page, support page and instructions in pdf format for the participant. The data donation app contains hard coded references to this web server.

### Azure app service with the data donation app

This Azure app service runs the data donation app. Diagnostics generated by the usage of this app is logged to storage account that the donated data resides in. 
The app service is granted access to the storage account through an Shared Access Signature (SAS) with write only access. Traffic to the storage account is routed internally on Azure.

Azure app services handles the: domain name, DNS, availability, certificates for TLS.

Azure app service assumes that the correct docker image with the correct tag is present in the container registry.

### PostgreSQL database

This database is used by the data donation app.

### Storage account with the donated data

This storage account contains the donated data, and contains diagnostics from the data donation app. This storage account is behind a firewall and only accessible for authorized users.

### Storage account with logging data

This storage account contains the logs of the activity on the storage account containing the donated data. 

## Resources for learning

### Terraform to deploy the cloud infrastructure

Terraform is used to specify our infrastructure as code (IaC).
The reason for using Terraform is as follows:

- We can apply version control to the IaC
- Our infrastructure will be replicable

### Useful links 

- [Tutorial video 1](https://www.youtube.com/watch?v=7xngnjfIlK4)
- [Tutorial video 2](https://www.youtube.com/watch?v=RTEgE2lcyk4)
- [Blog about managed identities](https://pontifex.dev/posts/terraform-azure-managed-identity/)
- [Link to ARM templates documentation](https://docs.microsoft.com/en-au/azure/templates/)

### A logical sequence of commands when using Terraform

These commands outlines the basic flow in Terraform, not all steps are necessary, 

```
terraform init          # Initialize
terraform fmt           # Formats your config files neatly
terraform validate      # Validates your configs
terraform plan          # Checks the tfstate file, what changes need to be apply
terraform apply         # Applies the changes
terraform destroy       # Destroys all resources
```

### Notes

#### Terraform on Linux

On linux a working nameserver needs to be set in /etc/resolv.conf
Even if you do not use /etc/resolv.conf config yourself, terraform needs it
