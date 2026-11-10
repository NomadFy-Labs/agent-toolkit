---
name: nomadfy-funnels
description: "Monta, altera, publica, pausa ou exclui um funil de vendas ou uma campanha de recuperação de carrinho na NomadFy, ou explica como um funil está montado. Use quando o usuário pedir algo sobre funil, etapa de checkout, oferta (upsell e downsell) ou recuperação de carrinho na NomadFy."
---

# Funis da NomadFy

1. Com o MCP da NomadFy conectado, chame a ferramenta `load_skill` dele com `{"name": "funnels"}` e siga o guia que voltar. Um recurso do guia se carrega com `{"name": "funnels", "resource": "<nome do recurso>"}`.
2. Sem o MCP conectado, peça ao usuário que conecte: o endereço é `https://api.nomadfy.app/mcp`, e o passo a passo está no hub, em Integrações › Integrações com IA (`https://hub.nomadfy.app/integracoes/mcp`). Ao conectar, o programa abre o hub para ele permitir o acesso.
