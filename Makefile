export PROXMOX_URL = https://192.168.2.10:8006/api2/json
export PROXMOX_USERNAME = root@pam!capi
export PROXMOX_TOKEN = 2245782d-dbfe-4f9a-9a57-f2c24e44ddd0
export PROXMOX_NODE = pve1
export PROXMOX_ISO_POOL = local
export PROXMOX_BRIDGE = vmbr0
export PROXMOX_STORAGE_POOL = local-lvm

.PHONY: imagebuilder getArgoPW

imagebuilder:
	@echo "Building imagebuilder"
	(cd image-builder && make deps-proxmox && make build-proxmox-ubuntu-2204)

cilium:
	@echo "Deploying cilium configmap to mgmt cluster"
	(cd ./cluster-api-provider-proxmox/ && make crs-cilium && kubectl create cm cilium  --from-file=data=templates/crs/cni/cilium.yaml)

getArgoPW:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | wl-copy

# generate-cluster:
# 	@echo "Generating cluster.yaml"
# 	clusterctl generate cluster proxmox-cilium \
# 		--infrastructure proxmox \
# 		--kubernetes-version v1.29.0 \
# 		--control-plane-machine-count 1 \
# 		--worker-machine-count 3 \
# 		--flavor cilium > cluster.yaml
