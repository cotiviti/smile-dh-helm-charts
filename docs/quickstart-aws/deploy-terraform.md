# Deploy Smile CDR with Terraform

Although it's possible to deploy Smile CDR using the Helm Chart, it is advisable to use the provided Terraform module as this will install the required dependencies for you.

## How It Works

To ease configuration of complex environments, the Smile CDR Dependencies Terraform Module will configure the following, non-Kubernetes dependencies.

* RDS database (Optional)
    * Creates separate users & databases for each module
    * Creates DB connection credentials in AWS Secrets Manager, with secure password handling
    * Configure users to use IAM authentication (Optional)
    * Provides Helm Chart configuration values for the above
* Create S3 bucket suitable for staging copied files (Optional)
* Smile CDR IAM role with least-privilege policies for the above resources
* Configures IRSA and Helm Chart configuration values
* AWS Secrets Manager secret for image repository (Optional)
* Creates Route53 DNS entry (optional)

If using the Helm Chart directly, all of the above will need to be configured beforehand. This is not in scope of this quickstart.

## Pre-requisites
It's important to ensure that any pre-requisites are in place before following these steps. If you have not done so already, please review the [Prepare EKS Cluster](./eks-cluster.md) and [Prepare AWS Resources](./aws-resources.md) sections.

### Container Repository
Review the section on [Private Container Registry Credentials](./aws-resources.md#private-container-registry-credentials) and ensure that you either:

* Have already created a suitable AWS Secrets Manager secret

or

* Are preprared to edit the secret that will be created by this Terraform Module.

>**Note:** The Smile CDR pods will not start up unless a container repository is accessible by the cluster.

### DNS configuration
Review the section on [DNS Configuration](./aws-resources.md#dns-configuration) and ensure that you either:

* Have access to add DNS entries in the Route53 Hosted Zone for your chosen parent domain

or

* Have access to add DNS entries to whichever platform hosts your DNS entries

>**Note:*** Your Smile CDR instance will not be accessible until you create a DNS entry using one of the above mechanisms.

## Minimal Configuration

The mimimum required configuration to install Smile CDR using the Terraform module:

```
module "smile_cdr_dependencies" {
  source = "git::https://gitlab.com/smilecdr-public/smile-dh-helm-charts//src/main/terraform/smile-cdr-deps?ref=terraform-module"
  name = "myDeploymentName"
  eks_cluster_name = "myClusterId"

  # If you pre-provisoned a shared Container Registry secret, uncomment this line and add the secret's ARN
  # cdr_regcred_secret_arn = "arn:aws:secretsmanager:<region>:012345678910:secret:shared/regcred/my.registry.com/username"

  prod_mode = false

  ingress_config = {
    public = {
      parent_domain = "example.com"

      # If you are not able to create Route53 DNS entries, then uncomment this line.
      # You will need to create your DNS entry manually.
      # route53_create_record = false
    }
  }
}
```

### Required Values

The only ***required*** options are:

* `name` - A unique identifier for this environment. This will be used for other resources, (e.g. the Kubernetes `namespace`), unless overridden elswehere.
* `eks_cluster_name` - The name of the EKS cluster that was already provisioned.
* `ingress_config.public.parent_domain` - The parent domain for the public ingress.

### Default Configuration

Using the above code snippet, a default install of Smile CDR will be created in the EKS cluster. This will include:

* In-cluster Postgres database (Using CrunchyData PGO)
* Default Smile CDR configuration
* Single Ingress using the Nginx Ingress controller
* Single DNS entry in existing Route 53 Hosted Zone
    * Default HostName will be `<name>.<parent_domain>`.
    * In the example above, it would be `mydeploymentname.example.com`
* Helm Release of Smile CDR

### Provider Configuration
This module requires the following providers to be configured in your Terraform project in order to communicate with the EKS cluster:

```
provider "aws" {
  region = local.region
}

provider "helm" {

  kubernetes {
    host                   = module.smile_cdr_dependencies.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(module.smile_cdr_dependencies.eks_cluster.certificate)
    token                  = module.smile_cdr_dependencies.eks_cluster.auth_token
  }
}

provider "kubernetes" {
  host                   = module.smile_cdr_dependencies.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(module.smile_cdr_dependencies.eks_cluster.certificate)
  token                  = module.smile_cdr_dependencies.eks_cluster.auth_token
}
```

## Advanced Configurations

The configuration provided so far is not sufficient for a typical install of Smile CDR. A more common pattern would require more configurations to be provided.

### Helm Values Files
When deploying Smile CDR using the Helm Chart, configuration is performed by updating the Helm Values file. See the [Smile CDR Helm Chart User Guide](../guide/smilecdr/index.md) for more information on how to create and organize your Values files.

Once you have prepared your Values files, they can be referenced from this Terraform module using the `helm_chart_values` configuration. Multiple values files may be referenced, which can greatly help with organising configuration.

```
helm_chart_values = [
  file("helm/smilecdr/values.yaml"),
  file("helm/smilecdr/feature1.yaml")
]
```

You can also override values directly from the Terraform module using the `helm_chart_values_set_overrides` configuration. This is helpful when you want to pass in infrastructure dependent values, rather than having to manually edit the values file separately.

```
helm_chart_values_set_overrides = {
  "replicaCount" = 1
}
```

### Terraform Module Helpers
This Terraform module also provides some helper configurations to simplify some configrations that would otherwise be troublesome to implement.

#### Mapped Files
When using the ***Helm Chart Method*** for [Including Extra Files](../guide/smilecdr/storage/files.md), you would typically pass the files as [commandline options](../guide/smilecdr/storage/files.md#include-file-in-helm-deployment) like so:
```
helm upgrade -i my-smile-env --devel -f my-values.yaml --set-file mappedFiles.logback\\.xml.data=logback.xml smiledh/smilecdr
```

As you are unable to manipulate the helm command when using the Terraform module, a helper configuration, `helm_chart_mapped_files`, has been provided to facilitate this functionality.

Include files using this method like so:
```
helm_chart_mapped_files = [
  {
    name = "file1.txt"
    location = "classes"
    data = file("files/classes/file1.txt")
  },
  {
    name = "file2.txt"
    location = "cutomerlib"
    data = file("files/cutomerlib/file2.txt")
  }
]
```

### Further Configuration

For further configuration options and examples, please refer to the [Smile CDR Dependencies Terraform Module](../terraform/smilecdrdeps/index.md) and [Smile CDR Helm Chart User Guide](../guide/smilecdr/index.md) sections.

## Terraform 'Quickstart' Project

A Terraform project is provided in the [examples](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/tree/pre-release/examples/terraform/workload/quickstart) section of the [Smile CDR Helm Chart](https://gitlab.com/smilecdr-public/smile-dh-helm-charts) repository. It brings together all of the concepts mentioned above and can be used as a starting point to deploy Smile CDR.

### Download Terraform Quickstart Project
In a terminal, change to a suitable folder to manage your project.
```
mkdir -p ~/my-sdh-eks/
cd ~/my-sdh-eks
```

Clone the Terraform Quickstart Project if you have not already done so.
>**Note:** If you followed the [Prepare EKS Cluster](./eks-cluster.md) section, you should have already completed this step.

```
git clone --depth 1 https://gitlab.com/smilecdr-public/smile-dh-helm-charts.git
```

Optionally make a copy of the project to work from
```
cp -rp smile-dh-helm-charts/examples/terraform/workload/quickstart workload
cd workload
```

### Configure the project for your environment
Due to the pre-requisites, this project will ***NOT*** run without modification, you should update some of the Terraform `locals` to suit your environment.

At a minimum, you ***MUST*** should configure the following:

* `cdr_regcred_secret_arn` - The ARN for a pre-provisioned secret for the Container Registry. If not specified, then a blank secret will be created automatically.
* `parent_domain` - Set this to the subdomain where you will create your DNS entry.
* `route53_create_record` - Set this to `false` if you are not able to create Route53 DNS entries. You will need to create your DNS record using another mechanism.

You should also consider updating the following, as they are based on the default cluster that was deployed in the [Prepare EKS Cluster](./eks-cluster.md) section.

* `name` - A unique name that will be used for your Smile CDR deployment and any supporting resources (Default is `MyDeploymentName`)
* `eks_cluster_name` - The name/id of the EKS cluster. (Default is `MyClusterName`)
* `region` - The AWS region where you wish to deploy Smile CDR. This must be the same region that you deployed the EKS cluster. (Default is `us-east-1`)

>**Note:** It's advisable at this point to configure your Terraform remote state. For this guide, we will continue to use local state.

Edit the `main.tf` file. At the top of the file, you will see the following `locals` block that you should update based on the above.

```
locals {
    name = "MyDeploymentName"
    eks_cluster_name = "MyClusterName"
    cdr_regcred_secret_arn = null
    parent_domain = "example.com"
    # If you are not able to create Route53 DNS entries, then set to false
    # You will then need to create your DNS entry manually.
    route53_create_record = true
    region="us-east-1"
}
```

### Prepare Terraform Project
Make sure that you have valid AWS credentials loaded and that you are able to authenticate against the AWS API.

```
aws sts get-caller-identity
{
    "UserId": "AROAXAABBCCDDEEFFGG",
    "Account": "012345678910",
    "Arn": "arn:aws:sts::012345678910:role/MyAdminRole"
}
```
Double check that you are using the correct AWS account and have a suitable IAM role/user that has Administrative privileges.

Initialize the Terraform Project
```
terraform init
```

After all of the Terraform modules have been installed, you should see the following message:
```
Terraform has been successfully initialized!
```

### Deploy Smile CDR
Now you can plan, review and apply the Terraform project to create the Smile CDR environment and the required components.

```
terraform plan
```

Review the output to see what resources will be created.

```
terraform apply

Plan: 9 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

>**NOTE:** If you did not provide an existing Container Registry credentials secret, you will need to manually update the secret that was created in AWS Secrets Manager after running `terraform apply`. If you do not do this, then the `apply` operation will not complete, as the Smile CDR pods will not come up until the credentials are available.

Once completed, you should see output as follows:

```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

helm_release_notes = <<EOT

***************************
**** NO CHART WARNINGS ****
***************************

Thank you for installing Smile CDR by Smile Digital Health!

                              ,.,;pppppQQQQQQQQppppppppppppp;,..
                      .s#################################SlSSS#######pp,
                 ;s######################################SlSSSSSSSS#######Np.
              ;###Sl#####################################SlSSSSSSSS###########p.
            ;#SGSSSl#####################################SlSSSSSSSS#############Qp
          .SGGGGSSSl#####################################SlSSSSSSSS###############p
         .lGGGGGSSSl#####################################SlSSSSSSSS###############bp
         lSGGGGGSSSl#####################################SlSSSSSSSS###############bG
         lGGGGGGSSSl#####################################SlSSSSSSSS###############bC
         lGGGGSSS###########################################SSSSSSS###############bC
        :GGSG#Tb""^"""T88#####$8$$8888888##############$TTG$S#SSSSS#######$TT8@###b
        ISGb^             ?@#               ^"6@######p    !@#SSSSS#####b     @###b
        $G      .;ppp;,.  ;#b     ,,,,,,,.      '8@###b    !$#SSSSS#####b     @###b
       'G     ;##S$$$#######b     @#########p.    '8##p    !$#SSSSS#####b     @##b|
       :G     8$#SSl########b     @###########N     8#b    !$#SSSSSS####b     @##b
       !Sp     "6@S#########b     @############b    '@p    l$##SSS######N     @##b
       GG$p.      ^"T8@#####b     @############N     GC     ^^^^^^^^^^^^^     @##b
       GGGGSSp         '8@##b     @############b     GC                       @#bb
      'GGGGGGGS##Sp       7@#     @############b     $C    ;#############     @#b
      !GGGGGGGGGS$$##N.    l$     @############b    '@p    !@#SSSS$$$###b     @#b
      GGGSGGGGGGSSSS$#N    '$     @###########b     $#b    !$#SSSSS#####b     @#b
      GGGTT8$GSSS#####b    l#     @########b^     ,###b    !$#SSSSS#####b     @#~
     !GGG     '^^^^^      ;##     '"*"^^'       ,#####b    !$#SSSSS#####b     $G
     !GGG.             ,s###b               ,s########~    j@#SSSSS#####b     $G
     !GGG$#SQppppppQ###################################QQQQ##SSSSSS#######QQQ##C
     GGGGGGGGGGGGSS$$$##################################$$SSSSSSSSS########$##b
    oGGGGGGGGGGGSSSl#####################################SlSSSSSSSS###########b
    ^GGGGGGGGGGGSSSl#####################################SlSSSSSSSS##########bb
     ?GGGGGGGGGGSSSl#####################################SlSSSSSSSS##########b
      *GGGGGGGGGSSSl#####################################SlSSSSSSSS#########b
        ?8GGGGGGSSSl#####################################SlSSSSSSSS#######b
          '?GGGGSSSl#####################################SlSSSSSSSS###bb^
              ^"G8$$######################################llSll$GG"*^
                    ^^7T888888888888888#####88888888888TTT""^^

Smile, we're up and running! :)

  You can access your Smile CDR instance at:

  https://mydeploymentname.example.com/

EOT
```

### Verify Helm Deployment
The Smile CDR Helm Chart provides some configuration feedback after installing. This feedback provides warnings and information about incorrect or deprecated configurations that may need to be updated.

The provided example includes this output as can be seen above. It's vital that you review this output during installs and upgrades so that you can pre-emptively avoid any disruptions due to future configuration schema changes.

If you do not include the above output section, or if you are unable to review your Terraform output, then you can manually check the Helm Chart notes as follows

```
helm get notes smilecdr
```

### Destroy Environment

You can destroy this environment and all related resources like so:

```
terraform destroy
```

>**Warning!:** If you have deployed any in-cluster stateful resources, such as a Postgres cluster or Strimzi Kafka cluster, they will also be destroyed using this command. Data will be irreversibly lost unless you have configured backups.
