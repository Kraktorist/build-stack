## Nexus Configuration

Default name: https://nexus11.ru-central1.internal  
It's installed with Apache TLS reverse-proxy.  
List of configured container repositories:  

| Name            | Ext.Port| Description     |
| :---            | :----:  |            :--- |
| docker-group    | 9182    | Group repo for all other repos below   |
| docker-release  | 9179    | Internal repo for releases     |
| docker-snapshots| 9180    | Internal repo for snapshots (daily clean policy) |
| gcr-proxy       | -       | proxy repo for gcr.io     |
| docker-proxy    | 9181    | proxy repo for docker.io     |
| quay-proxy      |         | proxy repo for quay.io     |