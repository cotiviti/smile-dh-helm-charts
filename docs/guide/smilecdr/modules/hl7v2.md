# HL7 v2.x Listening Endpoint Module
To use the HL7 v2.x Listening Endpoint module with this Helm Chart, special configuration is required. For more info on this module, please refer to the official Smile CDR documentation [here](https://smilecdr.com/docs/configuration_categories/hl7v2_mllp_listener.html)

This module supports 2 transport mechanisms:

* `HL7_OVER_HTTP`
* `MLLP_OVER_TCP`

Currently, the Helm Chart only supports using the `HL7_OVER_HTTP` transport protocol. `MLLP_OVER_TCP` support may be added in the future.

## Prerequisites
To use this module, you need to configure an additional DNS entry. This is because this module will only function using the root context path (i.e. `https://hl7endpoint.mydomain.com/`) which prevents it from running on the same hostname as the other Smile CDR endpoints.

The DNS entry created for this module should point to the same load balancer that is used for the other Smile CDR endpoints.

## Configuring Module
To configure the HL7 v2.x Listening Endpoint module to use the above domain, you need to add a `hostName` entry to the `service` section of your module definition.

Use the following module definition to enable this module and ingress route.

```yaml
modules:
  hlendpoint:
    name: hl7v2
    enabled: true
    type: ENDPOINT_HL7V2_IN
    service:
      enabled: true
      svcName: hl7v2
      hostName: hl7endpoint.mydomain.com
    requires:
      PERSISTENCE_ALL: persistence
    config:
      port: 8008
      store_original_message: true
      transport: HL7_OVER_HTTP
```
