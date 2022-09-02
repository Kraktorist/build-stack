variable config {
  type        = string
  default     = "../hosts.yml"
  description = "List of machines to build"
}

variable token {
  type        = string
  default     = "tbd_token"
  description = "Yandex Cloud service account file"
}

variable folder_id {
  type        = string
  default     = "tbd_folder"
  description = "Yandex Cloud Folder ID"
}

variable zone {
  type        = string
  default     = "tbd_folder"
  description = "Yandex Cloud Zone"
}
