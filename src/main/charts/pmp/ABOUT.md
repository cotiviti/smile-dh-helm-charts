Helm chart to install PMP and associated application resources.


This chart can optionally install the following components:
* Postgres Database (Requires Crunchy Operator to be installed in cluster)
* SmileCDR
* Kafka (Not yet implemented)
* MongoDB (Not yet implemented)

If the above components are not enabled to be installed by this Helm Chart, then you will need to supply details for those components separately.

If SmileCDR is installed separately to this chart, then any configuration changes there will need to be made manually or using some other external process.

Prerequisites
AWS Cognito (Use the PMP-deps terraform/CFN project to install this).

If not using the chart-installed versions, then you also need:
Database & Secret
SmileCDR (& Secret?)




Chart Details:
Postgres.
Postgres sub chart is a K8s resource based on the Crunchy Postgres CRD. This is based on the helm chart at: https://github.com/CrunchyData/postgres-operator-examples
