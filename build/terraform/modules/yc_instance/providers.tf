terraform {
  required_providers {
    yandex = {
      source = "terraform-registry.storage.yandexcloud.net/yandex-cloud/yandex"
      version = ">= 0.72"
    }
  }

  # backend "s3" {}
}
