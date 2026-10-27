#!/usr/bin/env bash
# Cria o container LXC do assistente de IA.
# Execute no HOST Proxmox, como root.
set -euo pipefail

# ---- Ajuste estas variáveis --------------------------------------------
CTID=140                          # ID do container
CT_HOSTNAME=ct-hermes-agent       # nome do container
CT_IP=192.168.1.50/24             # IP fixo do container (com máscara)
CT_GW=192.168.1.1                 # gateway da rede
BRIDGE=vmbr0                      # bridge de rede do Proxmox
STORAGE=local-lvm                 # storage do disco do container
TEMPLATE_STORAGE=local            # storage onde ficam os templates
DISK_GB=16
CORES=4
MEMORY_MB=3072
SWAP_MB=1024
UBUNTU_VERSION=26.04              # versão do Ubuntu (ex.: 24.04, 26.04)
# -------------------------------------------------------------------------

if pct status "$CTID" &>/dev/null; then
  echo "Erro: já existe um container com o ID $CTID." >&2
  exit 1
fi

echo "==> Procurando o template do Ubuntu $UBUNTU_VERSION..."
pveam update >/dev/null
TEMPLATE=$(pveam available --section system | awk -v v="ubuntu-$UBUNTU_VERSION" '$2 ~ v {print $2}' | sort | tail -1)
if [ -z "$TEMPLATE" ]; then
  echo "Erro: template do Ubuntu $UBUNTU_VERSION não encontrado. Veja: pveam available --section system" >&2
  exit 1
fi

if ! pveam list "$TEMPLATE_STORAGE" | grep -q "$TEMPLATE"; then
  echo "==> Baixando $TEMPLATE..."
  pveam download "$TEMPLATE_STORAGE" "$TEMPLATE"
fi

echo "==> Criando o container $CTID ($CT_HOSTNAME)..."
pct create "$CTID" "$TEMPLATE_STORAGE:vztmpl/$TEMPLATE" \
  --hostname "$CT_HOSTNAME" \
  --unprivileged 1 \
  --features nesting=1 \
  --cores "$CORES" \
  --memory "$MEMORY_MB" \
  --swap "$SWAP_MB" \
  --rootfs "$STORAGE:$DISK_GB,mountoptions=noatime" \
  --net0 "name=eth0,bridge=$BRIDGE,ip=$CT_IP,gw=$CT_GW,firewall=1" \
  --ostype ubuntu \
  --onboot 1 \
  --description "Assistente de IA (Hermes Agent) - acesso somente leitura"

echo "==> Ligando o container..."
pct start "$CTID"
sleep 5
pct exec "$CTID" -- bash -c "apt-get update -qq && apt-get -y -qq upgrade"

echo
echo "Pronto! Container $CTID criado e ligado em ${CT_IP%/*}."
echo "Próximo passo: bash scripts/02-proxmox-somente-leitura.sh"
