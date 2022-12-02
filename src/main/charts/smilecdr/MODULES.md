# Configuring Smile CDR Module Definitions

Most Smile CDR configuration is done via module definitions. This Helm Chart will take your module definitions and automatically generate any required Kubernetes Objects to support the configuration.

For example: Say you wish to enable a new module in your SmileCDR cluster, and this module creates a new endpoint. In your module definition, you will specify a port for the endpoint as well as (possibly) a context path.

When the SmileCDR Helm Chart renders the Kubernetes Manifests, it will use your module definitions to automatically create appropriate `Service` and `Ingress` objects so that the new endpoint is accessible.

Module definitions can be provided to this Helm Chart in multiple ways.
* Define modules directly in your custom `values.yaml` file.
* Define modules in extra YAML files just containing module definitions and reference them during the `helm install` command.

The first option is good if you want all of your configurations to be in one place.

The second option allows you to keep the module definitions separate. There are a few reasons you may want to do this.
* Your main `values.yaml` file could grow very large and unwieldy if it contains all module definitions
* You may want to keep SmileCDR configurations separate from your main `values.yaml` file.
* You can organize your module definitions into separate files, which may make it simpler to manage your modules.
* This is a good technique if you have some external process generate your module configurations, as it will not affect your main `values.yaml` file.

You may define some modules in your `values.yaml` and others in extra YAML files. Be careful with this as it may get confusing.

## Including Module Definitions in `values.yaml` File

Blah Blah Blah

## Including Module Definitions in Extra YAML Files

When adding module definitions in extra files, it is done in the same way as when adding them directly to `values.yaml`. Just like in your values file, all modules need to be under the `modules` top level map key.

These extra files can be passed in when running helm install using a number of methods.
* Use the `-f` option to pass it in as an extra values file
* Use the `--set-file` option to pass it in
* Use the `--include-files` option, once it is available in Helm

My notes....
The choice depends how I implement the default module definitions. I can do this 2 ways...
* **Leave them in the default values file**

  If I do this, the values file is unwieldy. It also means I will not be able to use external processes to generate the default modules based on the default config file provided with SmileCDR. Most YAML libraries will strip comments and possibly re-order items when modifying YAML files. They tend to read in the whole file semantically, then modify the required bits before writing it out. There may be some that support preserving comments and item order, but it could be delicate.
* **Have them in a separate file**

  Maintaining the module definitions in a separate file will certainly be easier to manage and allow for module values file auto-generation. But now I need to reference this file in my `values.yaml` and then use the `$.File.Get` command to read it into the template. This only works inside the Helm Chart, and cannot be used to pass in extra files from outside the chart. A different mechanism is used by `helm install` when passing in files using the `--set-file` flag. When doing this, the file is included into the .Values scope.

  Doing it this way does mean that passing the extra YAML files using `-f` may not override the default module definition files as they would still be referenced (Adding to the `modules` map would not prevent the template using anything in the `externalModuleDefinitions` map).
  If you did this, you would need to explicitly disable the default modules by providing an empty `externalModuleDefinitions` option. This is not an intuitive way to override default behaviour.
  Instead, by using `--set-file`, you explicitly add your file into the `externalModuleDefinitions` map.

TODO: Check some overriding and precedence behaviour. This is what we want.

If no files are provided, it uses the default modules definition
  * Moot, you cannot provide extra files
If one file is provided with the specified key of 'default', it should completely override any default modules.
  * Not using this, using an explicit 'usedefaultmodules' flag that defaults to true, instead.
It does this by virtue of the fact that the chart no longer reads the chart-local default modules file.
  * Moot. See previous point
If one or more files are provided with the specified keys being something other than default, the default module definitions will still be used, but if any of the modules defined in the passed in file have the same module name, the configurations will be merged such that the module configurations in the provided file will take precedence over the default module configurations.
  * This was overly complicated. Not doing it.
If some module configuration is explicitly provided in the values file, it will still take effect. If this module configuration entry is the same as some module configuration provided in the default module configs or in a file provided with `--set-file`, the provided values file will take precedence.
  * This mostly still stands, except now we can just use -f instead of --set-file for this.
