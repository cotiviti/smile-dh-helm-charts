# smilecdr

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2022.08.R03](https://img.shields.io/badge/AppVersion-2022.08.R03-informational?style=flat-square)

A Helm chart for Kubernetes

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `4` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| database.crunchypgo.enabled | bool | `true` |  |
| database.external.credentialsSource | string | `"k8s"` |  |
| database.external.dbType | string | `"postgres"` |  |
| database.external.enabled | bool | `false` |  |
| database.external.port | int | `5432` |  |
| database.external.secretName | string | `"changeme"` |  |
| image.credentials.jsonfile | string | `"misc/docker-config.json"` |  |
| image.credentials.pullSecrets[0].name | string | `"scdr-docker-secretssss"` |  |
| image.credentials.type | string | `"values"` |  |
| image.credentials.values[0].password | string | `"pass"` |  |
| image.credentials.values[0].registry | string | `"docker.com"` |  |
| image.credentials.values[0].username | string | `"user"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"docker.smilecdr.com/smilecdr"` |  |
| image.tag | string | `"2022.08.R03"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.extraAnnotations | object | `{}` |  |
| ingress.type | string | `"aws-lbc-nlb"` |  |
| kafka.bootstrapAddress | string | `"kafka-example.local"` |  |
| kafka.channelPrefix | string | `"SCDR-ENV-"` |  |
| kafka.enabled | bool | `false` |  |
| labels.application | string | `"smilecdr"` |  |
| labels.client | string | `"internal"` |  |
| labels.env | string | `"dev"` |  |
| labels.version | string | `"one"` |  |
| modules.admin_json.config."anonymous.access.enabled" | bool | `true` |  |
| modules.admin_json.config."security.http.basic.enabled" | bool | `true` |  |
| modules.admin_json.config."tls.enabled" | bool | `false` |  |
| modules.admin_json.config.context_path | string | `"json-admin"` |  |
| modules.admin_json.config.https_forwarding_assumed | bool | `true` |  |
| modules.admin_json.config.port | int | `9000` |  |
| modules.admin_json.config.respect_forward_headers | bool | `true` |  |
| modules.admin_json.enabled | bool | `true` |  |
| modules.admin_json.name | string | `"JSON Admin Services"` |  |
| modules.admin_json.requires.SECURITY_IN_UP | string | `"local_security"` |  |
| modules.admin_json.service.enabled | bool | `true` |  |
| modules.admin_json.service.svcName | string | `"admin-json"` |  |
| modules.admin_json.type | string | `"ADMIN_JSON"` |  |
| modules.admin_web.config."tls.enabled" | bool | `false` |  |
| modules.admin_web.config.context_path | string | `""` |  |
| modules.admin_web.config.https_forwarding_assumed | bool | `true` |  |
| modules.admin_web.config.port | int | `9100` |  |
| modules.admin_web.config.respect_forward_headers | bool | `true` |  |
| modules.admin_web.enabled | bool | `true` |  |
| modules.admin_web.name | string | `"Web Admin"` |  |
| modules.admin_web.requires.SECURITY_IN_UP | string | `"local_security"` |  |
| modules.admin_web.service.enabled | bool | `true` |  |
| modules.admin_web.service.hostName | string | `"default"` |  |
| modules.admin_web.service.svcName | string | `"admin-web"` |  |
| modules.admin_web.type | string | `"ADMIN_WEB"` |  |
| modules.clustermgr.config."audit_log.request_headers_to_store" | string | `"Content-Type,Host"` |  |
| modules.clustermgr.config."db.driver" | string | `"POSTGRES_9_4"` |  |
| modules.clustermgr.config."db.schema_update_mode" | string | `"UPDATE"` |  |
| modules.clustermgr.config."db.url" | string | `"jdbc:postgresql://#{env['DB_URL']}:5432/#{env['DB_DATABASE']}?sslmode=require"` |  |
| modules.clustermgr.config."stats.heartbeat_persist_frequency_ms" | int | `15000` |  |
| modules.clustermgr.config."stats.stats_cleanup_frequency_ms" | int | `300000` |  |
| modules.clustermgr.config."stats.stats_persist_frequency_ms" | int | `60000` |  |
| modules.clustermgr.configFromEnv."db.password" | string | `"DB_PASS"` |  |
| modules.clustermgr.configFromEnv."db.username" | string | `"DB_USER"` |  |
| modules.clustermgr.enabled | bool | `true` |  |
| modules.clustermgr.name | string | `"Cluster Manager Configuration"` |  |
| modules.fhir_endpoint.config."anonymous.access.enabled" | bool | `true` |  |
| modules.fhir_endpoint.config."base_url.fixed" | string | `"default"` |  |
| modules.fhir_endpoint.config."browser_highlight.enabled" | bool | `true` |  |
| modules.fhir_endpoint.config."cors.enable" | bool | `true` |  |
| modules.fhir_endpoint.config."request_validating.enabled" | bool | `false` |  |
| modules.fhir_endpoint.config."request_validating.fail_on_severity" | string | `"ERROR"` |  |
| modules.fhir_endpoint.config."request_validating.require_explicit_profile_definition.enabled" | bool | `false` |  |
| modules.fhir_endpoint.config."request_validating.response_headers.enabled" | bool | `false` |  |
| modules.fhir_endpoint.config."request_validating.tags.enabled" | bool | `false` |  |
| modules.fhir_endpoint.config."security.http.basic.enabled" | bool | `true` |  |
| modules.fhir_endpoint.config."threadpool.max" | int | `10` |  |
| modules.fhir_endpoint.config."threadpool.min" | int | `2` |  |
| modules.fhir_endpoint.config."tls.enabled" | bool | `false` |  |
| modules.fhir_endpoint.config.context_path | string | `"fhir_request"` |  |
| modules.fhir_endpoint.config.default_encoding | string | `"JSON"` |  |
| modules.fhir_endpoint.config.default_pretty_print | bool | `true` |  |
| modules.fhir_endpoint.config.https_forwarding_assumed | bool | `true` |  |
| modules.fhir_endpoint.config.port | int | `8000` |  |
| modules.fhir_endpoint.config.respect_forward_headers | bool | `true` |  |
| modules.fhir_endpoint.enabled | bool | `true` |  |
| modules.fhir_endpoint.name | string | `"FHIR Service"` |  |
| modules.fhir_endpoint.requires.PERSISTENCE_R4 | string | `"persistence"` |  |
| modules.fhir_endpoint.requires.SECURITY_IN_UP | string | `"local_security"` |  |
| modules.fhir_endpoint.service.enabled | bool | `true` |  |
| modules.fhir_endpoint.service.hostName | string | `"default"` |  |
| modules.fhir_endpoint.service.svcName | string | `"fhir"` |  |
| modules.fhir_endpoint.type | string | `"ENDPOINT_FHIR_REST_R4"` |  |
| modules.fhirweb_endpoint.config."anonymous.access.enabled" | bool | `false` |  |
| modules.fhirweb_endpoint.config."threadpool.max" | int | `10` |  |
| modules.fhirweb_endpoint.config."threadpool.min" | int | `2` |  |
| modules.fhirweb_endpoint.config."tls.enabled" | bool | `false` |  |
| modules.fhirweb_endpoint.config.context_path | string | `"fhirweb"` |  |
| modules.fhirweb_endpoint.config.https_forwarding_assumed | bool | `true` |  |
| modules.fhirweb_endpoint.config.port | int | `8001` |  |
| modules.fhirweb_endpoint.config.respect_forward_headers | bool | `true` |  |
| modules.fhirweb_endpoint.enabled | bool | `true` |  |
| modules.fhirweb_endpoint.name | string | `"FHIRWeb Console"` |  |
| modules.fhirweb_endpoint.requires.ENDPOINT_FHIR | string | `"fhir_endpoint"` |  |
| modules.fhirweb_endpoint.requires.SECURITY_IN_UP | string | `"local_security"` |  |
| modules.fhirweb_endpoint.service.enabled | bool | `true` |  |
| modules.fhirweb_endpoint.service.svcName | string | `"fhirweb"` |  |
| modules.fhirweb_endpoint.type | string | `"ENDPOINT_FHIRWEB"` |  |
| modules.local_security.config."seed.users.file" | string | `"classpath:/config_seeding/users.json"` |  |
| modules.local_security.config.password_encoding_type | string | `"BCRYPT_12_ROUND"` |  |
| modules.local_security.enabled | bool | `true` |  |
| modules.local_security.name | string | `"Local Storage Inbound Security"` |  |
| modules.local_security.type | string | `"SECURITY_IN_LOCAL"` |  |
| modules.package_registry.config."anonymous.access.enabled" | bool | `true` |  |
| modules.package_registry.config."security.http.basic.enabled" | bool | `true` |  |
| modules.package_registry.config."tls.enabled" | bool | `false` |  |
| modules.package_registry.config.context_path | string | `"package_registry"` |  |
| modules.package_registry.config.https_forwarding_assumed | bool | `true` |  |
| modules.package_registry.config.port | int | `8002` |  |
| modules.package_registry.config.respect_forward_headers | bool | `true` |  |
| modules.package_registry.enabled | bool | `true` |  |
| modules.package_registry.name | string | `"Package Registry"` |  |
| modules.package_registry.requires.PACKAGE_CACHE | string | `"persistence"` |  |
| modules.package_registry.requires.SECURITY_IN_UP | string | `"local_security"` |  |
| modules.package_registry.service.enabled | bool | `true` |  |
| modules.package_registry.service.svcName | string | `"pkg-registry"` |  |
| modules.package_registry.type | string | `"ENDPOINT_PACKAGE_REGISTRY"` |  |
| modules.persistence.config."dao_config.allow_external_references.enabled" | bool | `false` |  |
| modules.persistence.config."dao_config.allow_inline_match_url_references.enabled" | bool | `false` |  |
| modules.persistence.config."dao_config.allow_multiple_delete.enabled" | bool | `false` |  |
| modules.persistence.config."dao_config.expire_search_results_after_minutes" | int | `60` |  |
| modules.persistence.config."db.driver" | string | `"POSTGRES_9_4"` |  |
| modules.persistence.config."db.hibernate.showsql" | bool | `false` |  |
| modules.persistence.config."db.hibernate_search.directory" | string | `"./database/lucene_fhir_persistence"` |  |
| modules.persistence.config."db.schema_update_mode" | string | `"UPDATE"` |  |
| modules.persistence.config."db.url" | string | `"jdbc:postgresql://#{env['DB_URL']}:5432/#{env['DB_DATABASE']}?sslmode=require"` |  |
| modules.persistence.configFromEnv."db.password" | string | `"DB_PASS"` |  |
| modules.persistence.configFromEnv."db.username" | string | `"DB_USER"` |  |
| modules.persistence.enabled | bool | `true` |  |
| modules.persistence.name | string | `"Database Configuration"` |  |
| modules.persistence.type | string | `"PERSISTENCE_R4"` |  |
| modules.smart_auth.config."issuer.url" | string | `"default"` |  |
| modules.smart_auth.config."openid.signing.jwks_file" | string | `"classpath:/smilecdr-demo.jwks"` |  |
| modules.smart_auth.config."tls.enabled" | bool | `false` |  |
| modules.smart_auth.config.context_path | string | `"smartauth"` |  |
| modules.smart_auth.config.https_forwarding_assumed | bool | `true` |  |
| modules.smart_auth.config.port | int | `9200` |  |
| modules.smart_auth.config.respect_forward_headers | bool | `true` |  |
| modules.smart_auth.enabled | bool | `true` |  |
| modules.smart_auth.name | string | `"SMART Security"` |  |
| modules.smart_auth.requires.CLUSTERMGR | string | `"clustermgr"` |  |
| modules.smart_auth.requires.SECURITY_IN_UP | string | `"local_security"` |  |
| modules.smart_auth.service.enabled | bool | `true` |  |
| modules.smart_auth.service.svcName | string | `"smart-auth"` |  |
| modules.smart_auth.type | string | `"SECURITY_OUT_SMART"` |  |
| modules.subscription.enabled | bool | `true` |  |
| modules.subscription.name | string | `"Subscription"` |  |
| modules.subscription.requires.PERSISTENCE_ALL | string | `"persistence"` |  |
| modules.subscription.type | string | `"SUBSCRIPTION_MATCHER"` |  |
| name | string | `"smilecdr"` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| replicaCount | int | `2` |  |
| resources.limits.cpu | string | `"2"` |  |
| resources.limits.memory | string | `"4Gi"` |  |
| resources.requests.cpu | string | `"2"` |  |
| resources.requests.memory | string | `"4Gi"` |  |
| securityContext | object | `{}` |  |
| service.extraAnnotations | object | `{}` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.name | string | `""` |  |
| specs.hostname | string | `"smilecdr-example.local"` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
