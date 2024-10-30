export PROXMOX_URL = https://192.168.2.10:8006/api2/json
export PROXMOX_USERNAME = root@pam!capi
export PROXMOX_TOKEN = 2245782d-dbfe-4f9a-9a57-f2c24e44ddd0
export PROXMOX_NODE = pve1
export PROXMOX_ISO_POOL = local
export PROXMOX_BRIDGE = vmbr0
export PROXMOX_STORAGE_POOL = local-lvm

export CILIUM_VERSION = 1.16.3

.PHONY: imagebuilder getArgoPW crs-cilium

imagebuilder:
	@echo "Building imagebuilder"
	@echo "!!! make sure to add nfs-common as a package to the ubuntu imagebuilder user-data file !!!"
	(cd image-builder && make deps-proxmox && make build-proxmox-ubuntu-2204)

getArgoPW:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | wl-copy

create-kind-mgmt-cluster:
	@echo "Creating kind mgmt cluster"
	(cd ./capi_setup/proxmox/ && make run)

crs-cilium:
	@echo "Deploying cilium configmap to mgmt cluster"
	helm repo add cilium https://helm.cilium.io/ --force-update

	helm template \
    cilium \
    cilium/cilium \
    --namespace kube-system \
    --set bpf.hostLegacyRouting=false \
	--set internalTrafficPolicy=local
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set gatewayAPI.enabled=true \
    --set gatewayAPI.hostNetwork.enabled=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set ipam.mode=kubernetes \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
    --set kubeProxyReplacement=true \
    --set envoy.securityContext.capabilities.keepCapNetBindService=true \
    --set envoy.securityContext.capabilities.envoy="{NET_ADMIN,NET_BIND_SERVICE,SYS_ADMIN}" \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --api-versions 'gateway.networking.k8s.io/v1/GatewayClass' \
	--version $(CILIUM_VERSION) > ./templates/cilium.yaml

	kubectl apply -f ./templates/cilium.yaml

new: create-kind-mgmt-cluster crs-cilium
