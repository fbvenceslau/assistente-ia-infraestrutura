#!/usr/bin/env bash
# Prepara o container: pacotes, idioma, usuário sem sudo, comandos e serviços.
# Execute DENTRO do container, como root.
set -euo pipefail

AGENT_USER=hermes
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="/home/$AGENT_USER"
HERMES_DIR="$HOME_DIR/.hermes"

echo "==> Instalando pacotes..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  curl git jq ca-certificates locales \
  iputils-ping traceroute mtr-tiny dnsutils nmap netcat-openbsd \
  openssh-client ffmpeg

echo "==> Configurando o idioma pt_BR..."
locale-gen pt_BR.UTF-8 en_US.UTF-8 >/dev/null
update-locale LANG=pt_BR.UTF-8

echo "==> Criando o usuário $AGENT_USER (sem sudo)..."
if ! id "$AGENT_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$AGENT_USER"
fi
# Garante que o usuário do agente NÃO tenha acesso de administrador.
gpasswd -d "$AGENT_USER" sudo &>/dev/null || true
rm -f "/etc/sudoers.d/$AGENT_USER"

echo "==> Instalando os comandos pveapi e unifi..."
install -d "$HOME_DIR/.local/bin"
install -m 755 "$REPO_DIR/bin/pveapi" "$REPO_DIR/bin/unifi" "$HOME_DIR/.local/bin/"
chown -R "$AGENT_USER:$AGENT_USER" "$HOME_DIR/.local"

echo "==> Copiando os modelos de configuração..."
install -d -m 700 -o "$AGENT_USER" -g "$AGENT_USER" "$HERMES_DIR" "$HERMES_DIR/secrets" "$HOME_DIR/.ssh"
copy_if_missing() { # origem destino modo
  if [ ! -e "$2" ]; then install -m "$3" -o "$AGENT_USER" -g "$AGENT_USER" "$1" "$2"; fi
}
copy_if_missing "$REPO_DIR/config/SOUL.md.example"        "$HERMES_DIR/SOUL.md"                 600
copy_if_missing "$REPO_DIR/config/ativos.md.example"      "$HERMES_DIR/ativos.md"               600
copy_if_missing "$REPO_DIR/config/endpoints.env.example"  "$HERMES_DIR/secrets/endpoints.env"   600
copy_if_missing "$REPO_DIR/config/ssh_config.example"     "$HOME_DIR/.ssh/config"               600

echo "==> Instalando os serviços do systemd..."
install -m 644 "$REPO_DIR/systemd/hermes-gateway.service" "$REPO_DIR/systemd/hermes-dashboard.service" /etc/systemd/system/
systemctl daemon-reload

echo
echo "Pronto! Próximos passos (README, Passo 5):"
echo "  su - $AGENT_USER"
echo "  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
