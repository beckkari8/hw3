apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
spec:
  resources:
    requests:
      storage: 2Gi
  accessModes:
  - ReadWriteOnce
