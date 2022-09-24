1. This repo contains two images:
   - catalogue
   - catalogue-db

2. `vendor` folder should be fixed in the repo to build `catalogue` image

3. For `catalogue-db` the key `--ignore-path=/lib` should be specified. See https://github.com/GoogleContainerTools/kaniko/issues/1745 for more details.