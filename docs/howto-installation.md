## Prerequisites

1. Create basic Yandex.Cloud objects (folder, service account, network and s3 bucket) 
   ```
   ./prerequisites.sh
   ```
1. update ./builder/builder.env
1. update the following files with the passwords and certificates:
   ./infrastructure/envs/env-platform/group_vars/all/secrets.yaml  
   ./infrastructure/envs/env-*/group_vars/all/secrets.yml
1. build `builder image`
   ```
   docker build --no-cache ./builder/ -t builder
   ```
1. run the `builder` container  
   ```
   docker run \
        --rm \
        --env-file builder/builder.env \
        -v $(pwd)/infrastructure:/app/infrastructure \
        -v $HOME/ya_key.pub:/root/ya_key.pub \
        -v $HOME/ya_key:/root/ya_key \
        -v $(pwd)/boutique/components:/boutique \
        -ti builder
   ```

## Base Infrastructure Installation

1. install hosts with the command `terraform_apply`
1. provision bastion with the command `provision_bastion`
1. check installed hosts with `yc_get_instances` and set bastion address as a proxy with the following variable  
   ```
    BASTION_IP=x.x.x.x
    export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@'${BASTION_IP}' -p 22322"'
   ```
1. Update all other installed hosts and add trusted certificates with the command `provision_misc`
1. provision nexus with the command `provision_nexus`
1. provision gitlab with the command `provision_gitlab`
1. creating source code repositories
    - for infrastructure with the command `provision_infra_repo`
    - for application and deploy with the command `provision_apps_repo`
1. provision infrastructure runner with the command `provision_infra_runner`
1. Deploy socks5 on your local machine with the command
    `BASTION_IP=x.x.x.x ssh -D 1337 -f -C -q -N ubuntu@${BASTION_IP} -p 22322`
1. Configure web browser with the proxy and open gitlab web UI.
1. Navigate to `infrastructure/build-stack` project, start CI job to build `builder` image and wait until it completed. Credentials can be found in step #3.
1. Open nexus web UI and check the `builder` image is created in the `docker-group` repository. Credentials can be found in step #3.

## Deploying dev Infrastructure

1. Open `boutique` group and copy Registration Token from Runners page.
1. Open `infrastructure/envs` project and put copied on previous step token to the CI/CD varilable `RUNNER_TOKEN` for environment `env-dev`.
1. Open `infrastructure/envs` project and create new branch named `env-dev`.
1. Browse to `envs/env-dev/` directory, revise all the variables and make any commit to `master` (or `main`).
1. Create a merge request from `master` to `env-dev`. Check the status of running CI/CD job. It will show the resources which will be created.
1. Merge the request and monitor the job which will install kubernetes cluster. Wait for the job completion.


## Development Process

1. Open `boutique` group, navigate to Runners page and check that the runners is online. 
1. Navigate to every repository in `boutique` group and create a tag to start building images. For example create tag `test` which will point to the latest existing version tag in every repository.
1. Wait until the jobs completion and check that all 10 images for boutqiue application are created in the nexus repository `docker-group`. 

## Deploy Application

1. Open `release`
1. Update versions and hosts in values.yaml
1. Make a merge requests
1. Check the installation (set host into hosts file on bastion)

## Load Testing and Monitoring
   
Run locally:

   ```
   docker run --net=host weaveworksdemos/load-test -h localhost -r 100 -c 2
   ```

## Destroy Infrastructure

1. Start `builder` container
1. Set variable ENV for the environment you want to destroy
1.  Run th command `terraform_destroy`