# Managing Values Files
As explained in the quick start, you should configure your instance of Smile CDR using Helm Values Files.

## Create New Values Files
It is generally recommended to create a new, empty values file rather than copying the default values.yaml file from the Helm chart. The default values file can be lengthy and may contain values that are not relevant or suitable for your specific deployment.

By starting with a fresh values file, you can customize your configuration to only include the values that you need to override. This can help to make your values file more concise and easier to manage. Additionally, starting from a blank file allows you to ensure that your deployment is not impacted by future updates to the default values file, which could potentially cause issues if you are using an older version.

Creating your own values file from scratch gives you greater control and flexibility over your Helm chart deployment. It can help to ensure that your deployment is secure and stable, as you have the ability to carefully consider and set the values that are most relevant to your specific needs.

## Organizing Values Files
It is a common practice to put all Helm Chart configurations into a single values file and provide that to the `helm upgrade` command.

Using multiple values files can be a more efficient way to manage configurations, particularly in complex environments. This approach can help to avoid having a single, large values file that may be difficult to read and maintain. By dividing the configuration into smaller, more focused files, it can be easier to manage and update the settings as needed.

To use multiple values files, you would simply provide multiple `-f valuesfle.yaml` options on the `helm upgrade` command.

### Multiple Environments
When deploying an application, it is often necessary to consider multiple environments, such as dev, uat, and prod. While it is possible to create a separate configuration for each environment, this approach can lead to repetition and duplication of settings.

This can be problematic, as it can result in configuration drift between environments. If there are changes that need to be made to the configuration, it can be challenging to ensure that the updates are applied consistently across all environments.

>**TODO** Insert Diagram explaining Drift

A more effective approach may be to use a base configuration, with per-environment overlays. This allows you to define a set of common configuration settings that apply to all environments, while also allowing you to specify any environment-specific settings as needed. This can help to minimize repetition and ensure that the configuration is consistent across all environments.

This can be easily achieved using multiple directories for the different environments like so:
>**TODO** Insert Diagram showing multiple configurations in a per-directory model

### Modular Configurations
Using multiple values files can also be a useful way to create modular units of configuration that can be easily included or excluded in your environment. This can help to make your configuration more flexible and adaptable to changing needs.

For example, you might create a set of values files that represent different configurations or modules that have been fully tested and approved for use in your organization. These might include a base configuration file that defines the minimum requirements for running Smile CDR, as well as additional files for specific features or components, such as an R4 persistence module, a MongoDB persistence module, or an AWS Healthlake module.

>**TODO** Insert Diagram showing module files

This approach allows you to build your configuration in a modular way, which can be more manageable and easier to maintain. It also gives you the flexibility to selectively include or exclude certain modules as needed, depending on the specific requirements of your environment.

## Flexible Solution
When it comes to managing values files, there isn't a single "right" way to do it - the approach that works best will depend on specific needs and organizational standards.

Although the above techniques can be helpful for keeping things organized and efficient, they may not be right for you or your organization. You should use a technique that works for your team and organization. If this means using a single large values file per environment or some other technique, then that is fine.

The aim here is to find a solution that helps you maintain a stable, well-organized configuration.
