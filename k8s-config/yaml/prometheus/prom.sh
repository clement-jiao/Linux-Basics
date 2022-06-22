# 创建名称空间
kubectl create namespace monitoring

# 创建监控账号
kubectl create serviceaccount monitor -n monitoring

# 管理员权限慎用
kubectl create clusterrolebinding monitor-clusterrolebinding \
-n monitoring --clusterrole=cluster-admin --serviceaccount=monitoring:monitor

# 部署 prom-server
kubectl apply -f prom-deploy.yaml

# 部署 svc
kubectl apply -f prom-svc.yaml