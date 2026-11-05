# farm

homelab pt 2

* openwrt one: router for the lab L2
* dell r230: talos all-in-one k8s cluster

### Init (talos)

1. install talos, get kubectl creds
https://docs.siderolabs.com/talos/v1.13/getting-started/getting-started#

or reset via
`talosctl reset --nodes 192.168.2.240 --endpoints 192.168.2.240 --graceful=false --reboot --wipe-mode all --talosconfig talosconfig`


- `talosctl get disks --insecure --nodes $IP`
- `talosctl gen config farm https://192.168.2.240:6443 --install-disk /dev/sdb --config-patch @patch.yaml`
- `talosctl apply-config --insecure --nodes 192.168.2.240 --file controlplane.yaml`
- `talosctl --talosconfig=./talosconfig config endpoints 192.168.2.240`
- `talosctl bootstrap --nodes 192.168.2.240 --talosconfig=./talosconfig`
- `talosctl kubeconfig --nodes 192.168.2.240 --talosconfig=./talosconfig`

### Cilium
```
helm repo add cilium https://helm.cilium.io/
helm repo update

# taken from https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#without-kube-proxy-2
# edits
# operator.replicas : 2->1
# ingressController.enabled: false->true
# ingressController.loadbalakcerMode: dedicated->shared
helm template \
    cilium \
    cilium/cilium \
    --version 1.18.0 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set operator.replicas=1 \
    --set ingressController.enabled=true \
    --set ingressController.loadbalancerMode=shared \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 > cilium.yaml

kubectl apply -f cilium.yaml
```

### Init (Flux)

Flux itself is managed by the flux-operator, so the controllers are a reconciled
object (`apps-infra/flux-instance.yaml`) rather than whatever the local CLI
happened to install.

```
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace

# deploy key for the private repo (read-only is enough)
kubectl create secret generic flux-system -n flux-system \
  --from-file=identity=$HOME/.ssh/pubgh-deploy \
  --from-file=identity.pub=$HOME/.ssh/puhgb-deploy.pub \
  --from-literal=known_hosts="$(ssh-keyscan github.com)"

kubectl apply -f apps-infra/flux-instance.yaml
```

- `flux get all -A`
- `flux reconcile kustomization flux-system --with-source`
- `flux suspend|resume kustomization <name>`
- `kubectl -n flux-system get fluxinstance flux` (controller rollout status)
