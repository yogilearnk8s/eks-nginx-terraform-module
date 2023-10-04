data "kubernetes_namespace" "wp_namespace" {
  metadata {
    name = "wp_namespace"
  }
}

resource "kubernetes_secret" "wp_secret" {
  metadata {
    name = "wp-auth"
  }

  data = {
    username = "admin"
    password = "P4ssw0rd"
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_persistent_volume" "wp_db_persistent_volume" {
  metadata {
    name = "mysql-pv-claim"
    labels {
      app = "wordpress_db"
    }
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    access_modes = ["ReadWriteOnce"]

  }
}

resource "kubernetes_deployment" "wordpress_db" {
  metadata {
    name      = "wp_namespace"
    namespace = data.kubernetes_namespace.wp_namespace.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "wordpress_db"
        tier = "backend"
      }
    }
    strategy {
      type = Recreate
    }
    template {
      metadata {
        labels = {
          app = "wordpress_db"
          tier = "backend"
        }
      }
      spec {
        container {
          image = "mysql:8.0"
          name  = "mysql"
          port {
            container_port = 3306
            name = "mysql"
          }
          env {
           name = "MYSQL_DATABASE"
           value = "wordpress"
            }
           env {
           name = "MYSQL_ROOT_PASSWORD"
           value_from {
              secret_key_ref {
                name = "mysql-pass"
                key = "password"
              } 
           }
            }

           env {
           name = "MYSQL_PASSWORD"
           value_from {
              secret_key_ref {
                name = "mysql-pass"
                key = "password"
              } 
           }
            }

            env {
              name = "MYSQL_USER"
              value = "wordpress"
            }
          volume_mount {
            name = "wordpress-persistent-storage"
            mount_path =  "/var/lib/mysql"
          }

        }
        volume{
          name = "wordpress-persistent-storage"
          persistent_volume_claim {
            claim_name = "mysql-pv-claim"
          }
        }


      }
    }
  }
}

resource "kubernetes_service" "wp_app_service" {
  metadata {
    name      = "wp_wordpress"
    namespace = kubernetes_namespace.wp_namespace.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.wordpress_app.spec.0.template.0.metadata.0.labels.app
      tier = kubernetes_deployment.wordpress_app.spec.0.template.0.metadata.0.labels.tier
    }
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 80
    }
  }
}