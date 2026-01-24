# Namespace for Debezium
resource "kubernetes_namespace_v1" "debezium" {
  metadata {
    name = "debezium"
  }
}

# Service for Debezium REST API
resource "kubernetes_service_v1" "debezium" {
  metadata {
    name      = "debezium"
    namespace = kubernetes_namespace_v1.debezium.metadata[0].name
    labels = {
      app = "debezium"
    }
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "debezium"
    }

    port {
      port        = 8083
      target_port = 8083
      name        = "rest"
    }
  }
}

# StatefulSet for Debezium Connect
resource "kubernetes_stateful_set_v1" "debezium" {
  metadata {
    name      = "debezium"
    namespace = kubernetes_namespace_v1.debezium.metadata[0].name
    labels = {
      app = "debezium"
    }
  }

  spec {
    service_name = kubernetes_service_v1.debezium.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "debezium"
      }
    }

    template {
      metadata {
        labels = {
          app = "debezium"
        }
      }

      spec {
        container {
          name  = "debezium"
          image = "debezium/connect:2.7.1.Final"

          port {
            container_port = 8083
            name           = "rest"
          }

          env {
            name  = "BOOTSTRAP_SERVERS"
            value = "kafka-0.kafka.kafka.svc.cluster.local:9092"
          }

          env {
            name  = "GROUP_ID"
            value = "1"
          }

          env {
            name  = "CONFIG_STORAGE_TOPIC"
            value = "connect-configs"
          }

          env {
            name  = "OFFSET_STORAGE_TOPIC"
            value = "connect-offsets"
          }

          env {
            name  = "STATUS_STORAGE_TOPIC"
            value = "connect-status"
          }

          env {
            name  = "KEY_CONVERTER"
            value = "org.apache.kafka.connect.json.JsonConverter"
          }

          env {
            name  = "VALUE_CONVERTER"
            value = "org.apache.kafka.connect.json.JsonConverter"
          }

          env {
            name  = "KEY_CONVERTER_SCHEMAS_ENABLE"
            value = "false"
          }

          env {
            name  = "VALUE_CONVERTER_SCHEMAS_ENABLE"
            value = "false"
          }

          volume_mount {
            name       = "debezium-data"
            mount_path = "/kafka/connect"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "debezium-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "8Gi"
          }
        }

        storage_class_name = "standard"
      }
    }
  }
}
