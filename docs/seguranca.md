# Segurança

O assistente tem acesso à sua infraestrutura. A regra deste projeto é simples: **ele pode ver tudo e não pode mudar nada**.

## 1. A permissão é que protege, não o texto

O arquivo `SOUL.md` pede ao assistente que nunca altere nada sem confirmação. Isso ajuda, mas **não é uma barreira de segurança**. Um modelo de IA pode errar, interpretar mal um pedido ou ser enganado por um conteúdo malicioso (por exemplo, um log ou uma página web com instruções escondidas).

Por isso, cada conta usada pelo assistente precisa ser **tecnicamente** somente leitura:

| Sistema | Conta | Permissão |
|---|---|---|
| Proxmox | `hermes@pve` (token de API) | papel `PVEAuditor` |
| UniFi | administrador local | função `View Only` |
| MikroTik | `hermes` | grupo `read` |
| Container | `hermes` (Linux) | sem sudo |

## 2. Erro comum: sudo para `pct` ou `qm`

É tentador criar um usuário SSH no host Proxmox e liberar só alguns comandos com sudo, por exemplo:

```
hermes ALL=(ALL) NOPASSWD: /usr/sbin/pct, /usr/sbin/qm, /usr/bin/pve*
```

**Isso equivale a acesso total ao servidor.** Com `pct exec` e `qm`, é possível entrar em qualquer container, mudar configurações, desligar ou apagar máquinas virtuais. Use a API com `PVEAuditor`. Se precisar de SSH no host, use um usuário comum, sem sudo.

Para conferir no host:

```bash
sudo -l -U hermes                 # não deve listar nada
ls /etc/sudoers.d/                # não deve ter regra para o assistente
pveum acl list                    # hermes@pve deve aparecer só com PVEAuditor
```

## 3. Quem pode falar com o assistente

- Preencha sempre `TELEGRAM_ALLOWED_USERS` com os IDs numéricos autorizados.
- Não adicione o bot a grupos.
- Se o token do bot vazar, gere um novo no @BotFather (`/revoke`).

## 4. Segredos

- Tokens e senhas ficam em `~/.hermes/.env` e `~/.hermes/secrets/`, com permissão `600`.
- O `.gitignore` deste projeto impede o envio desses arquivos para o GitHub. Mesmo assim, revise antes de cada `git push`.
- Use uma chave SSH exclusiva para o assistente (`hermes_ativos`). Assim, você consegue revogar o acesso dele sem afetar o seu.

## 5. Rede

- Use o firewall do Proxmox para liberar SSH e o painel (9119) apenas para o seu computador. Veja [firewall/CTID.fw.example](../firewall/CTID.fw.example).
- Não exponha o painel nem o container para a internet.
- No MikroTik, restrinja o usuário ao IP do container (`address=<IP>/32`).

## 6. Revisão periódica

- Atualize o Hermes Agent e o Ubuntu do container regularmente.
- Revise os logs: `journalctl -u hermes-gateway --since today`.
- Teste de tempos em tempos se o acesso continua somente leitura (veja a seção **Testar** do README).
