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
	helm template cilium cilium/cilium --version $(CILIUM_VERSION) --set internalTrafficPolicy=local --namespace kube-system > ./templates/cilium.yaml
	kubectl apply -f ./templates/cilium.yaml

new: create-kind-mgmt-cluster crs-cilium
