resource "yandex_cm_certificate" "cert" {
  name    = var.name
  domains = var.domains
  managed {
    challenge_type  = "HTTP"
    challenge_count = length(var.domains)
  }
}

resource "yandex_storage_bucket" "hosting" {
  count = yandex_cm_certificate.cert.managed[0].challenge_count
  bucket = yandex_cm_certificate.cert.domains[count.index]
  force_destroy = true
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}

resource "yandex_storage_object" "challenge" {
  count = yandex_cm_certificate.cert.managed[0].challenge_count
  bucket = yandex_cm_certificate.cert.domains[count.index]
  acl = "public-read"
  key    = regex(".well-known/acme-challenge/.*", yandex_cm_certificate.cert.challenges[count.index].http_url)
  content = yandex_cm_certificate.cert.challenges[count.index].http_content
}

data "yandex_cm_certificate" "certificate" {
  certificate_id            = yandex_cm_certificate.cert.id
  wait_validation = var.wait_validation
  depends_on = [yandex_storage_object.challenge]
}