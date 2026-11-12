---
name: nomadfy
description: "Trabalha na conta NomadFy do usuário pelo servidor MCP da NomadFy: funis de venda e recuperação de carrinho, área de membros (cursos, aulas, alunos e certificados), produtos, kits e ideias de produto. Use quando o usuário pedir algo na conta NomadFy dele que não seja uma página do site."
---

# NomadFy

O servidor MCP da NomadFy traz um guia para cada tarefa, com as ferramentas, as regras e os erros comuns. Para qualquer tarefa na conta NomadFy do usuário:

1. Chame `load_skill` do MCP com o nome do guia (a descrição da ferramenta lista os guias e quando usar cada um) e siga o que voltar. Um recurso do guia se carrega com `{"name": "<guia>", "resource": "<recurso>"}`.
2. Sem o MCP conectado, peça ao usuário que conecte: o endereço é `https://api.nomadfy.app/mcp`, e o passo a passo está no hub, em Integrações › Agentes e MCP (`https://hub.nomadfy.app/integracoes/mcp`). Ao conectar, o agente abre o hub para ele permitir o acesso.

Página de vendas, checkout ou outra página do site: use a skill `nomadfy-pages`.
