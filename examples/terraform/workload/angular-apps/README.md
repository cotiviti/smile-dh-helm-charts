# Deploying Angular Apps

## Overview

This solution provieds a way to deploy Nginx based static HTML sites into a Kubernetes cluster alongside Smile CDR deployments.

This solution was developed to get around some issues with the existing mechanisms being used to deplpoy such applications.

In order to provide configurability as well as use secure best practices, it leverages the Bitnami Nginx Helm Chart.

## Existing Challenges

Many of the internally developed applications are built using the main Nginx docker container as a base image. This approach leaves us with some challenges.

### Tightly Coupled Infrastructure

Typicaly, the GitLab pipelines for these Angular apps build a Docker container that needs to run in a certain way. This was not a huge concern when these images are run on a local workstation Docker install or on a VM, but in Kubernetes where best practices should be followed, these default Nginx based images are not appropriate for the following reasons:

* They run as the `root` user.
* They listen on port `80`.
* The Root FS is not read-only.

### Configuration

Although there have been some effoerts in the past to design the web applications to be configurable at deploy time, many still do not do this. As a result, there are many instances where separate build pipelines are run for each distinct environment. This results in increased management overhead and complexity in deployment solutions.

This has been solved in the past using the `envsubst` functionality that exists within the officail Nginx Docker image, however this functionality relies on the user being root, or by overwriting a lot of the default startup mechanism of said image. This would lead down a path of extra maintenancre andf unexpected behaviour as the upstream image version implements changes that are not accounted for locally.

## Proposed Solution - Bitnami Nginx Helm Chart

While the above issues can be individually addressed, this needs to be done in multiple locations and there is currently no elegant manageable solution that can be used across the board to solve this.

Although a solution (likely using Helm Charts) could be developed to encapsulate the patterns, it makes more sense to leverage existing solutions that have already solved these issues.

**The Bitnami Nginx Helm Chart solves the above issues.**

* Runs as non-root
* Runs on arbitrary port > 1024
* Allows including additional config files

### Deploying Site Content

The Bitnami Nginx Helm Chart supports three official mechanisms for including static content (i.e. your Angular application):

* Downloads from a git repository
* Use ConfigMaps
* Use an exisitng PVC

None of the above solutions support the mechanisms we currently have in place where the build pipeline produces a Docker image as an artifact. However, as a temporary solution, this does work.

In order to build an Angular application to be deployed using this solution, it should use the `bitnami/nginx` base image.

>***Note:*** There is still a challenge with this solution in that is is not ***designed*** to work with custom built images. It will work with custom built images, but as it's not an officially supported mechanism for including site content, there may be unexpected breaking changes if the Helm Chart version is updated without updating the Docker image to use a matching version.


### A note on the Bitnami Nginx Chart Versions.

The latest versions of the chart do not work with the images that were built earlier this year
This is due to 2 things:

- The Bitnami Helm chart was updated to use a read-only root filesystem in vas of version 15.14.0
  This was NOT listed as a breaking change, as they updated the source image to handle this scenario

- We are not using the charts as designed. They are not meant to use pre-built images. As the
  earlier versions of these images were built with an older base image, there were
  changes that resulted in a breaking change in this scenario

There are 2 temporary solutions to this issue:
1. Pin to Vitnami Nginx Helm Chart to version "15.12.2" which still works.
2. Update the images to use a newer version of the base Bitnmi Nginx image that supports the latest
   version of the Bitnami Nginx Helm Chart

The ideal solution is for us to not publish the Angular App as an nginx container at all as this is
method tightly couples the application code with the infrastructure deployment method. This causes
extra complexity as we are seeing here.

Instead, the compiled Angular apps should be published as a set of static files that can then be deployed
using multiple mechanism as required, e.g.
- Plain nginx for developer use or Docker Compose
- Pull from git branch (This is one of the intended ways for the Bitnami Nginx Helm Chart to work)
- Push to a CDN such as CloudFront

## Example Deployment Solutions

The following two solutions show how you can deploy an Angular application using the Bitnami Helm Chart in an existing Terraform project for a Smile CDR deployment.

They both build on the solution provided in the [AWS Quickstart](https://smilecdr-public.gitlab.io/smile-dh-helm-charts/latest/quickstart-aws/deploy-terraform/) and assume that you already have Smile CDR deployed by following the quickstart.

Both examples will do the following:

* Create a new Bitnami Nginx deployment in the same namespace as Smile CDR
* Inject environment specific configuration into the deployment
* Create ingress routes using the ingress-nginx controller
* Create a Route53 host entry in the same Hosted Zone as your Smile CDR deployment

The examples differ in how the Angular applications are configured.

The source code for these examples is located [here](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/-/tree/pre-release/examples/terraform/workload/angular-apps)

### Option 1 - Single App, Single HCL File

The first solution is the simplest if you only have a single Angular app that needs to be deployed. Only a single HCL file needs to be created and configured.

With this option, application configurations can be provided directly in the HCL file and they will be automatically formatted and included in the deployment. By following this approach, it is possible to have the config settings be derived from existing infrastructure, which can simplify configuring going forwards.

However, this solution is only suitable for a single deployment as deploying multiple apps would require duplicating the configuration logic for each environment. While possible, this could prove hard to maintain going forwards.

**Using this solution:**

* Copy the `single/angular-apps-single.tf` HCL file into your existing Terraform project and rename it appropriately
* Review the code and follow the instructions in the comments on how to configure your application.
* Deploy

### Option 2 - Multiple Apps, with supporting files

The second option is currently preferred if you are deploying more than one application. To use this solution, you will need to also include some extra Helm Values files that will be used to configure the application.

This option does not currently have any support for providing the application configuration via the HCL file, as all config items must be defined in the per-environment values files.

With this approach it's easy to add new applications, however it does mean that configurations must be hard coded and cannot be passed in easily.

**Using this solution:**

* Copy the following files from the `multiple` directory into your existing Terraform project and rename them where appropriate.
  * `helm/bitnami-nginx/*` - Keep the same path when copying
  * `appDataSources.tf`
  * `myApp1.tf` and `myApp2.tf` - Rename these appropriately
* For each application do the following:
  * Review the code from the `myApp*.tf` file and follow the instructions in the comments on how to configure your application.
  * Review the `my-app*-values.yaml` file and update any required configurations
* If required, create more apps by duplicating the `myApp*.tf` and `my-app*-values.yaml` files, configuring them in the same way as in the previous step.
* Deploy

### Future Option - Terraform Module

Combining the benefits from each of the above solutions may be done by creating a Terraform module that could be used on an arbitrary number of applications and generate passed-in configurations. At this point, no such solution is available.