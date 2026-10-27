# Solução de problemas

## Comandos básicos

```bash
systemctl status hermes-gateway --no-pager     # o serviço está rodando?
journalctl -u hermes-gateway -f                # acompanhar os logs ao vivo
journalctl -u hermes-gateway --since "1 hour ago"
```

## A instalação do Hermes falha com "Connection reset by peer"

A conexão com o GitHub caiu durante o download. Rode o instalador de novo. Ele continua de onde parou.

## O assistente não responde no Telegram

1. Confira se o serviço está ativo: `systemctl status hermes-gateway`.
2. Confira se o seu ID está em `TELEGRAM_ALLOWED_USERS` no `~/.hermes/.env`.
3. Veja os logs. Mensagens como `Connect attempt 1/8 failed: Timed out` indicam falha de conexão com o Telegram. O gateway tenta de novo sozinho. Se continuar, teste a saída de internet do container:

```bash
curl -sI https://api.telegram.org | head -1
```

## `pveapi` não retorna nada ou retorna erro 401

O token está inválido ou foi apagado. Teste:

```bash
curl -sk -o /dev/null -w '%{http_code}\n' \
  -H "Authorization: $(cat ~/.hermes/secrets/pve.token)" \
  "https://<IP-DO-PROXMOX>:8006/api2/json/version"
```

- `200`: o token funciona.
- `401`: o token ou o usuário não existe. No host, confira com `pveum user token list hermes@pve` e, se preciso, gere de novo com `scripts/02-proxmox-somente-leitura.sh`.
- `000`: o container não alcança o Proxmox (rede ou firewall).

## `unifi` retorna "falha no login"

- Confira o usuário e a senha em `secrets/unifi.json`.
- Confira `UNIFI_URL` e a porta em `secrets/endpoints.env`.
- Controladora antiga (sem UniFi OS): use `UNIFI_PREFIX=` e `UNIFI_LOGIN=/api/login`.

## O container não liga junto com o Proxmox

```bash
pct set <CTID> --onboot 1
```

## Aviso "exited UNCLEANLY" nos logs

Aparece quando o container ou o host foi desligado sem parar o serviço antes (por exemplo, queda de energia ou reinício do host). Se `suspected_oom=False`, não foi falta de memória e pode ser ignorado.

## Git: "detected dubious ownership"

Acontece ao rodar `git` como root dentro da pasta do Hermes, que pertence ao usuário `hermes`. Rode os comandos como o usuário dono:

```bash
su - hermes -c "git -C ~/.hermes/hermes-agent log -1"
```

## Pouca memória

Com 3 GB de RAM, o uso normal fica em torno de 0,5 GB. Se o navegador do Hermes for muito usado, aumente para 4 GB:

```bash
pct set <CTID> --memory 4096
```
