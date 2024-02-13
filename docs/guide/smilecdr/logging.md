# Smile CDR Application Logging
Smile CDR uses the Logback logging framework to collect application logs and can be configured based on individual requirements.

Full documentation about the logging system is available [here](https://smilecdr.com/docs/logging/system_logging.html).

## Custom Log Configuration
As per the Smile CDR docs, [custom log configurations](https://smilecdr.com/docs/logging/custom_logging.html) can be used by providing a custom `logback-smile-custom.xml` file.

While you could create this file manually and include it in the Helm Chart deployment by using one of the [file copy methods](./files.md), editing this file and configuring the copying can be troublesome and error prone.

## Automatic Log Configuration
As an alternative to the above, you can specify common configurations for the custom logging directly in your Helm values file. This eliminates the need to to perform any extra steps. This can also be helpful for automating log configuration changes.

All of the below mentioned techniques may be combined in a single configuration.

### Enable Troubleshooting Loggers
As per the Smile CDR documentation, you can enable [Troubleshooting Logs](https://smilecdr.com/docs/logging/troubleshooting_logs.html) of various types.

The same configurations can be enabled in your Helm Values file like so:

This snippet shows how you would enable DEBUG logs for the [HTTP Troubleshooting Log](https://smilecdr.com/docs/logging/troubleshooting_logs.html#http-troubleshooting-log)
```
logging:
  troubleshootingLoggers:
    http_troubleshooting:
      enabled: true
      level: debug
```

Any of the troubleshooting loggers listed in the official docs can be enabled in the same way.

### Set Arbitrary Loggers
You can enable logging at any log level for any of the classes implemented within Smile CDR.

In this example, we demonstrate how to quiesce some noisy log messages that may be flooding the logs.

```
logging:
  setLoggers:
    thymeleaf:
      description: Mute Thymeleaf errors that were flooding the logs with errors.
      level: "OFF"
      paths:
      - org.thymeleaf.standard.processor.AbstractStandardFragmentInsertionTagProcessor
      - org.thymeleaf.standard.processor.StandardIncludeTagProcessor
```

Again, any Java class path can be enabled at any log level.

### Create Custom Loggers
If you have the requirement to store logs in an arbitrary log format, you can create a custom logger.

The following defines a custom logger for a fictional Smile CDR component, 'x', and saves the logs to `myApp.log`

```
logging:
  customLoggers:
    myCustomLogger:
      path: cdr.component.x
      enabled: true
      level: DEBUG
      pattern: "%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level M:%X{moduleId} R:%X{requestId} %logger{36} [%file:%line] %msg%n"
      target: myApp.log
```

You can also set `logging.customLoggers.<loggerName>.target: STDOUT` to log to `stdout` instead of writing to a log file.

### Provide Raw Custom Log Configuration
Finally, if you need to provide custom Logback configurations instead of using the above techniques to generate it automatically, you can do so directly in your Helm values file like so:

```
logging:
  rawLogConfig: |-
    <included>
      <!--
      Custom logging config:
      This will override and replace any auto-generated logger configurations defined above.
      -->
    </included>
```

## Log Collection and Aggregation
As with any application running in Kubernetes, you should stream logs from the Pods and use an aggregation solution to persist them in a single location.

There are numerous solutions available to perform this task. There is no single 'correct' solution as different organisations may have differing requirements for the persisting of application logs.

At a high level, here are some foundational concepts that should be reviewed so that a suitable logging solution may be devised.

[Kubernetes Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)


### Current Helm Chart Support
Currently this Helm Chart does not provide any functionality or guidance on how to perform these tasks.

It is up to the architect/implementer to devise and implement a suitable solution.

Some recommended solutions that are known to work are:

* [OpenTelemetry](https://opentelemetry.io/) + [Loki](https://grafana.com/oss/loki/) + [Grafana](https://grafana.com/grafana/)
* [EKS Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-EKS.html)
* [DataDog](https://www.datadoghq.com/)

### Future Helm Chart Support
There is a soon-to-be released feature of this Helm Chart that will automate the provisioning of a complete **Observability Suite** alongside your Smile CDR deployment.

This feature will enable and configure all of the followinf just by enabling a few simple options inside your Helm values file.

* Full OpenTelemetry instrumentation (Metrics, Traces and Logs)
* OpenTelemetry Collector to aggregate telemetry data and send to backends
* Prometheus back-end for Metrics telemetry
* Loki back-end for Log file aggregation
* Tempo back-end for Trace telemetry
* Grafana with default dashboards connecting all of the above and providing overall view of Smile CDR cluster.
