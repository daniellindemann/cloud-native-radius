# Cloud-native DevOps with Radius


## Forward KIND cluster services

- Do a port-forward in VS Code to `IP:Port` or
- Do a service forward with *kubectl*: `kubectl port-forward svc/nginx 8080:8080 --address 0.0.0.0`

## cloud-provider-kind service

[`cloud-provider-kind`](https://github.com/kubernetes-sigs/cloud-provider-kind) implements `LoadBalancer` services for KIND clusters and runs as a background service in the dev container (no systemd is available, so it is managed via a SysV init script).

- Start: `sudo service cloud-provider-kind start`
- Stop: `sudo service cloud-provider-kind stop`
- Restart: `sudo service cloud-provider-kind restart`
- Status: `sudo service cloud-provider-kind status`

### Retrieve logs

Logs are written to `/var/log/cloud-provider-kind.log`:

```bash
tail -n +1 -f /var/log/cloud-provider-kind.log
```

### ngix test

kubectl create deployment --image=nginx --replicas=3 --port=80 nginx

kubectl expose deployment nginx --port=8080 --target-port=80 --type=LoadBalancer
