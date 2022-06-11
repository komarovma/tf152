terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token = var.token
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = var.zone_id
}

resource "yandex_iam_service_account" "netology-sa" {
  folder_id = var.folder_id
  name      = "tf-netology-sa"
}

resource "yandex_resourcemanager_folder_iam_binding" "admin-account-iam" {
  folder_id   = var.folder_id
  role        = "editor"
  members     = [
    "serviceAccount:${yandex_iam_service_account.netology-sa.id}",
  ]
}

resource "yandex_vpc_network" "netology-network-tf" {
  name = "netology-tf"
}

 resource "yandex_vpc_subnet" "private" {
   name = "netology-tf-private"
   v4_cidr_blocks = ["192.168.20.0/24"]
   zone           = var.zone_id
   network_id     = yandex_vpc_network.netology-network-tf.id
 } 

resource "yandex_compute_instance_group" "lamp-group" {
  name                = "netology-lamp-mike"
  folder_id           = var.folder_id
  service_account_id  = "${yandex_iam_service_account.netology-sa.id}"
  deletion_protection = false
  instance_template {
    platform_id = "standard-v1"
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"
    }
    }
    network_interface {
    network_id = "${yandex_vpc_network.netology-network-tf.id}"
    subnet_ids = ["${yandex_vpc_subnet.private.id}"]
    nat       = true
    }

   metadata = {
    ssh-keys  = "myuser:${file(var.public_key_path)}"
    user_data = <<EOF
          #!/bin/bash
          yum install httpd -y
          service httpd start
          chkconfig httpd on
          cd /var/www/html
          echo "https://storage.yandexcloud.net/tf-netology-bucket/foto-lake.jpg" > index.html
      EOF
   } 
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }
  load_balancer {
    target_group_name        = "netology-group"
    target_group_description = "load balancer netology group"
  }
  }
