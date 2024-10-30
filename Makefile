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


getArgoPW:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | wl-copy
