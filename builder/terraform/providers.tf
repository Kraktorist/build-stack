terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.83"
    }
  }

  backend "s3" {}
  #backend "local" {}
}
