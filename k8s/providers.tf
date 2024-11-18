provider "vault" {
  address         = "https://vault-test.com/"
  token           = var.vault_token
  skip_tls_verify = true
}

provider "yandex" {
  service_account_key_file = data.vault_generic_secret.yandex_credentials.data["service-account-key"]
  cloud_id                 = data.vault_generic_secret.yandex_credentials.data["cloud_id"]
  folder_id                = data.vault_generic_secret.yandex_credentials.data["folder_id"]
  endpoint                 = "api.yandexcloud.kz:443"
  zone                     = "kz1-a"
}