resource "kubernetes_namespace" "wp_namespace" {
  metadata {
    name = "wp-namespace"
  }
}

resource "kubernetes_secret" "wp_secret" {
  metadata {
    name = "wp-auth"
    namespace = "wp-namespace"
  }

  data = {
    username = "admin"
    password = "P4ssw0rd"
  }

  type = "kubernetes.io/basic-auth"
}


resource "kubernetes_config_map" "env_values" {
  metadata {
    name = "db-env-values"
    namespace = "wp-namespace"
  }

  data = {
    WORDPRESS_DB_HOST = "wordpress-db-host",
    wordpress-mysql = "wordpress-mysql",
    WORDPRESS_DB_USER = "wordpress-db-user",
    wordpress = "wordpress"
  }
}

resource "kubernetes_secret" "wordpress_db_secret" {
    metadata {
        name      = "wordpress-db-password"
        namespace = "wp-namespace"
    }

    data = {
        WORDPRESS_DB_PASSWORD     = "dbsecretvalue"
    }
    
}

resource "kubernetes_persistent_volume" "wp_db_persistent_volume" {
  metadata {
    name = "mysql-pv-claim"

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

resource "kubernetes_deployment" "wordpress_db" {
  metadata {
    name      = "wp-db-deployment"
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

    template {
      metadata {
        labels = {
          app = "wordpress-db"
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
           name = "wordpress-db-host"
           value = "wordpress-mysql"
            }
           env {
           name = "wordpress-db-password"
           value_from {
              secret_key_ref {
                name = kubernetes_secret.wordpress_db_secret.metadata[0].name
                key = "wordpress-db-password"
              } 
           }
            }

           env {
               name = "wordpress-db-user"
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
