resource "kubernetes_persistent_volume" "pvc" {
  metadata {
    name = "pvc"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      gce_persistent_disk {
        pd_name = "pvc"
      }
    }
  }
}