
resource "yandex_resourcemanager_folder_iam_member" "netology-sa" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.netology-sa.id}"
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.netology-sa.id
  description        = "static access key for object storage"
}

// Use keys to create bucket
resource "yandex_storage_bucket" "netology-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "tf-netology-bucket"
}

resource "yandex_storage_object" "foto-picture" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "tf-netology-bucket"
  key    = "foto-lake.jpg"
  source = "foto.jpg"
  acl = "public-read"
} 