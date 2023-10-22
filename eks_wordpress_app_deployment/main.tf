resource "kubernetes_namespace" "wp_namespace" {
  metadata {
    name = "wp_namespace"
  }
}

resource "kubernetes_secret" "wordpress_app_secret" {
    metadata {
        name      = "appsecret"
        namespace = "wp_namespace"
    }

    data = {
        secret_key     = "appsecretvalue"
    }
    
}


resource "kubernetes_config_map" "env_values" {
  metadata {
    name = "example-env-values"
  }

  data = {
    WORDPRESS_DB_HOST = "WORDPRESS_DB_HOST",
    wordpress-mysql = "wordpress-mysql",
    WORDPRESS_DB_USER = "WORDPRESS_DB_USER",
    wordpress = "wordpress"
  }
}


resource "kubernetes_secret" "wordpress_db_secret" {
    metadata {
        name      = "WORDPRESS_DB_PASSWORD"
        namespace = "wp_namespace"
    }

    data = {
        WORDPRESS_DB_PASSWORD     = "dbsecretvalue"
    }
    
}


resource "kubernetes_persistent_volume" "wp_persistent_volume" {
  metadata {
    name = "wp-pv-claim"
 
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    access_modes = ["ReadWriteOnce"]
        persistent_volume_source {
        csi {
          driver = "ebs.csi.aws.com"
          volume_handle = "awsElasticBlockStore"
        }
    }

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
                name = kubernetes_secret.wordpress_db_secret.metadata[0].name
                key = "WORDPRESS_DB_PASSWORD"
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