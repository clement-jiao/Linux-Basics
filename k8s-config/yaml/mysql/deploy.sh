kubectl create namespace mysql
kubectl apply -f mysql-storageclass-local.yaml
kubectl apply -f mysql-pv-local.yaml
kubectl apply -f mysql-pvc.yaml
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-service.yaml
kubectl apply -f mysql-deployment.yaml
