#!/usr/bin/env bash
# Cria um usuário e um token de API SOMENTE LEITURA no Proxmox para o assistente.
# Execute no HOST Proxmox, como root.
set -euo pipefail

PVE_USER=hermes@pve
TOKEN_NAME=agent

if ! pveum user list --output-format json | grep -q "\"$PVE_USER\""; then
  echo "==> Criando o usuário $PVE_USER..."
  pveum user add "$PVE_USER" --comment "Assistente de IA - somente leitura"
fi

echo "==> Dando o papel PVEAuditor (somente leitura) em todo o datacenter..."
pveum acl modify / --users "$PVE_USER" --roles PVEAuditor

if pveum user token list "$PVE_USER" --output-format json | grep -q "\"$TOKEN_NAME\""; then
  echo "O token $PVE_USER!$TOKEN_NAME já existe. Para recriar:"
  echo "  pveum user token remove $PVE_USER $TOKEN_NAME"
  exit 1
fi

echo "==> Gerando o token de API..."
# privsep=0: o token herda as permissões do usuário (que são só de leitura).
SECRET=$(pveum user token add "$PVE_USER" "$TOKEN_NAME" --privsep 0 --output-format json \
  | sed -E 's/.*"value":"([^"]+)".*/\1/')

echo
echo "============================================================"
echo " Guarde a linha abaixo. Ela NÃO será exibida novamente."
echo " Cole-a em /home/hermes/.hermes/secrets/pve.token (Passo 7)."
echo "============================================================"
echo "PVEAPIToken=$PVE_USER!$TOKEN_NAME=$SECRET"
echo
echo "Atenção: NÃO dê sudo para o assistente no host Proxmox."
echo "Comandos como 'pct' e 'qm' com sudo equivalem a acesso total ao servidor."
