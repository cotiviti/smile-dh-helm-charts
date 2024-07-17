# Observability TODO.

## Agent Jar Logic
For the OTEL and Prometheus agents, the agent jar is referenced in multiple locations. As this jar can be overriden, currently this 'override' check is done in multple places.

This should be moved to the config template for each of these agents so that it only needs to be defined in a single location.
