## Gitlab Configuration

Default name: https://gitlab11.ru-central1.internal  
List of installed repositories:   


| Group            |   Name    | Installation         | Description     | Deploy |
| :---             | :----:    |            :---      | :---            | :--- |
| Infrastructure   | dev-stack   | provision_infra_repo | Copy of public repo | Build `builder` image |
| Infrastructure   | envs        | provision_infra_repo | List of infrastructure environments to create | Build infrastructure
| Boutique         | carts       | provision_apps_repo | Copy of `microservices-demo/carts` repo with injected deploy | Build `carts` image |
| Boutique         | catalogue   | provision_apps_repo | Copy of `microservices-demo/catalogue` repo with injected deploy | Build `catalogue` image |
| Boutique         | front-end   | provision_apps_repo | Copy of `microservices-demo/front-end` repo with injected deploy | Build `front-end` image |
| Boutique         | orders      | provision_apps_repo | Copy of `microservices-demo/orders` repo with injected deploy | Build `orders` image |
| Boutique         | payment     | provision_apps_repo | Copy of `microservices-demo/payment` repo with injected deploy | Build `payment` image |
| Boutique         | queue-master| provision_apps_repo | Copy of `microservices-demo/queue-master` repo with injected deploy | Build `queue-master` image |
| Boutique         | shipping    | provision_apps_repo | Copy of `microservices-demo/shipping` repo with injected deploy | Build `shipping` image |
| Boutique         | user        | provision_apps_repo | Copy of `microservices-demo/user` repo with injected deploy | Build `user` image |
| deploy           | prod        | provision_apps_repo | Full solution configuration for `prod` environment | deploy full solution to `prod` environment |

