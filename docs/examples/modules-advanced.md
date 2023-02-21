# Advanced Modules Configuration

This example demonstrates defining all modules from scratch, not using any of the default modules.

It is based on the [minimal](minimal.md) example.

We will create a couple of examples.

This will configure Smile CDR as follows:

* Completely custom Smile CDR module configuraton
    * Disabled default module configuraton
* Ingress configured for `smilecdr.mycompany.com` using NginX Ingress
* Docker registry credentials passed in via Secret Store CSI Driver using AWS Secrets Manager
* Postgres DB automatically created

## Requirements

* Nginx Ingress Controller must be installed, with TLS certificate
* DNS for `smilecdr.mycompany.com` needs to be exist and be pointing to the load balancer used by Nginx Ingress
* CrunchyData Operator must be installed
* Image repository credentials stored in AWS Secrets Manager
* AWS IAM Role configured to access AWS Secrets Manager

## Example 1 - Minimal module config
This example shows how you would configure Smile CDR to just use the following modules:

* Cluster Manager
* Persistence Module
* Local Security
* Admin Web
* Fhir Endpoint


```yaml
specs:
  hostname: smilecdr.mycompany.com

image:
  repository: docker.smilecdr.com/smilecdr
  credentials:
    type: sscsi
    provider: aws
    secretarn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"

database:
  crunchypgo:
    enabled: true
    internal: true

modules:
  useDefaultModules: false

  clustermgr:
    name: Cluster Manager Configuration
    enabled: true
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
      db.schema_update_mode:  UPDATE
      stats.heartbeat_persist_frequency_ms: 15000
      stats.stats_persist_frequency_ms: 60000
      stats.stats_cleanup_frequency_ms: 300000
      audit_log.request_headers_to_store: Content-Type,Host
      seed_keystores.file: "classpath:/config_seeding/keystores.json"

  persistence:
    name: Database Configuration
    enabled: true
    type: PERSISTENCE_R4
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
      db.hibernate.showsql: false
      db.hibernate_search.directory: ./database/lucene_fhir_persistence
      db.schema_update_mode: UPDATE
      dao_config.expire_search_results_after_minutes: 60
      dao_config.allow_multiple_delete.enabled: false
      dao_config.allow_inline_match_url_references.enabled: false
      dao_config.allow_external_references.enabled: false
      dao_config.inline_resource_storage_below_size: 4000

  local_security:
    name: Local Storage Inbound Security
    enabled: true
    type: SECURITY_IN_LOCAL
    config:
      seed.users.file: classpath:/config_seeding/users.json
      # This is required right now as the default is not being honored.
      # Can be removed if the default gets fixed. May be good to leave it explicit.
      # Note: Smile CDR still chooses the wrong default as of `2022.11.R01`
      password_encoding_type: BCRYPT_12_ROUND

  admin_web:
    name: Web Admin
    enabled: true
    type: ADMIN_WEB
    service:
      enabled: true
      svcName: admin-web
      hostName: default
    requires:
      SECURITY_IN_UP: local_security
    config:
      context_path: ""
      port: 9100
      tls.enabled: false
      https_forwarding_assumed: true
      respect_forward_headers: true

  fhir_endpoint:
    name: FHIR Service
    enabled: true
    type: ENDPOINT_FHIR_REST_R4
    service:
      enabled: true
      svcName: fhir
      hostName: default
    requires:
      PERSISTENCE_R4: persistence
      SECURITY_IN_UP: local_security
    config:
      context_path: fhir_request
      port: 8000
      base_url.fixed: default
      threadpool.min: 2
      threadpool.max: 10
      browser_highlight.enabled: true
      cors.enable: true
      default_encoding: JSON
      default_pretty_print: true
      tls.enabled: false
      anonymous.access.enabled: true
      security.http.basic.enabled: true
      request_validating.enabled: false
      request_validating.fail_on_severity: ERROR
      request_validating.tags.enabled: false
      request_validating.response_headers.enabled: false
      request_validating.require_explicit_profile_definition.enabled:  false
      https_forwarding_assumed: true
      respect_forward_headers: true
```

## Example 2 - Minimal module config with separate values files
As you can see from the above, the values file can start getting unwieldy.

It is advised to split them up into manageable chunks like so.

**values-common.yaml**
```yaml
specs:
  hostname: smilecdr.mycompany.com

image:
  repository: docker.smilecdr.com/smilecdr
  credentials:
    type: sscsi
    provider: aws
    secretarn: "arn:aws:secretsmanager:us-east-1:1234567890:secret:secretname"

serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/example-role-name"

database:
  crunchypgo:
    enabled: true
    internal: true

modules:
  usedefaultmodules: false
```

**values-clustermgr.yaml**
```yaml
modules:
  clustermgr:
    name: Cluster Manager Configuration
    enabled: true
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
      db.schema_update_mode:  UPDATE
      stats.heartbeat_persist_frequency_ms: 15000
      stats.stats_persist_frequency_ms: 60000
      stats.stats_cleanup_frequency_ms: 300000
      audit_log.request_headers_to_store: Content-Type,Host
      seed_keystores.file: "classpath:/config_seeding/keystores.json"
```

**values-persistence-r4.yaml**
```yaml
modules:
  persistence:
    name: Database Configuration
    enabled: true
    type: PERSISTENCE_R4
    config:
      db.driver: POSTGRES_9_4
      db.url: jdbc:postgresql://#{env['DB_URL']}:#{env['DB_PORT']}/#{env['DB_DATABASE']}?sslmode=require
      db.password: "#{env['DB_PASS']}"
      db.username: "#{env['DB_USER']}"
      db.hibernate.showsql: false
      db.hibernate_search.directory: ./database/lucene_fhir_persistence
      db.schema_update_mode: UPDATE
      dao_config.expire_search_results_after_minutes: 60
      dao_config.allow_multiple_delete.enabled: false
      dao_config.allow_inline_match_url_references.enabled: false
      dao_config.allow_external_references.enabled: false
      dao_config.inline_resource_storage_below_size: 4000
```

**values-security.yaml**
```yaml
modules:
  local_security:
    name: Local Storage Inbound Security
    enabled: true
    type: SECURITY_IN_LOCAL
    config:
      seed.users.file: classpath:/config_seeding/users.json
      # This is required right now as the default is not being honored.
      # Can be removed if the default gets fixed. May be good to leave it explicit.
      # Note: Smile CDR still chooses the wrong default as of `2022.11.R01`
      password_encoding_type: BCRYPT_12_ROUND
```

**values-admin-web.yaml**
```yaml
modules:
  admin_web:
    name: Web Admin
    enabled: true
    type: ADMIN_WEB
    service:
      enabled: true
      svcName: admin-web
      hostName: default
    requires:
      SECURITY_IN_UP: local_security
    config:
      context_path: ""
      port: 9100
      tls.enabled: false
      https_forwarding_assumed: true
      respect_forward_headers: true
```

**values-fhir-endpoint.yaml**
```yaml
modules:
  fhir_endpoint:
    name: FHIR Service
    enabled: true
    type: ENDPOINT_FHIR_REST_R4
    service:
      enabled: true
      svcName: fhir
      hostName: default
    requires:
      PERSISTENCE_R4: persistence
      SECURITY_IN_UP: local_security
    config:
      context_path: fhir_request
      port: 8000
      base_url.fixed: default
      threadpool.min: 2
      threadpool.max: 10
      browser_highlight.enabled: true
      cors.enable: true
      default_encoding: JSON
      default_pretty_print: true
      tls.enabled: false
      anonymous.access.enabled: true
      security.http.basic.enabled: true
      request_validating.enabled: false
      request_validating.fail_on_severity: ERROR
      request_validating.tags.enabled: false
      request_validating.response_headers.enabled: false
      request_validating.require_explicit_profile_definition.enabled:  false
      https_forwarding_assumed: true
      respect_forward_headers: true
```

When installing the above, you would then pass in the multiple values file like so:
```
helm upgrade -i my-smile-env -f values-clustermgr.yaml -f values-persistence-r4.yaml -f values-security.yaml -f values-admin-web.yaml -f values-fhir-endpoint.yaml smiledh/smilecdr
```
