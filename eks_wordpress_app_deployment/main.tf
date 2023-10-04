resource "kubernetes_namespace" "wp_namespace" {
  metadata {
    name = "wp_namespace"
  }
}

resource "kubernetes_secret" "prometheus" {
    metadata {
        name      = "prometheus"
        namespace = "monitoring"
    }

    data = {
        password     = data.vault_generic_secret.prometheus.data["password"]
        bearer_token = data.vault_generic_secret.prometheus.data["bearer_token"]
    }
    type = "Opaque"
}

resource "kubernetes_persistent_volume" "wp_persistent_volume" {
  metadata {
    name = "wp-pv-claim"
    labels {
      app = "wordpress_app"
    }
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    access_modes = ["ReadWriteOnce"]

  }
}

resource "kubernetes_deployment" "wordpress_app" {
  metadata {
    name      = "wp_namespace"
    namespace = kubernetes_namespace.wp_namespace.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "wordpress_app"
        tier = "frontend"
      }
    }
    strategy {
      type = Recreate
    }
    template {
      metadata {
        labels = {
          app = "wordpress_app"
          tier = "frontend"
        }
      }
      spec {
        container {
          image = "wordpress:6.2.1-apache"
          name  = "wordpress"
          port {
            container_port = 80
            name = "wordpress_app"
          }
          env {
           name = "WORDPRESS_DB_HOST"
           value = "wordpress-mysql"
            }
           env {
           name = "WORDPRESS_DB_PASSWORD"
           value_from {
              secret_key_ref {
                name = "mysql-pass"
                key = "password"
              } 
           }
            }
            env {
              name = "WORDPRESS_DB_USER"
              value = "wordpress"
            }
          volume_mount {
            name = "wordpress-persistent-storage"
            mount_path =  "/var/www/html"
          }

        }
        volume{
          name = "wordpress-persistent-storage"
          persistent_volume_claim {
            claim_name = "wp-pv-claim"
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