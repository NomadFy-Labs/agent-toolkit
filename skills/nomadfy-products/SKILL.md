---
name: nomadfy-products
description: "Cadastra e muda produtos na NomadFy: produto digital ou físico, preço, preço \"de\", descrição, fotos, arquivos para download e kits de produtos vendidos juntos por um preço só. Use quando o usuário pedir para criar, alterar ou listar produtos, ou montar um kit, na NomadFy."
---

# Produtos da NomadFy

Precisa do MCP da NomadFy conectado (`https://api.nomadfy.app/mcp`). Sem ele, peça ao usuário que conecte: o passo a passo está no hub, em Integrações › Integrações com IA (`https://hub.nomadfy.app/integracoes/mcp`).

- **Produto digital ou físico:** crie com `create_product`; mude nome, preço, preço "de" e descrição com `update_product`.
- **Fotos:** `set_product_photos`, na ordem em que aparecem (a primeira é a principal).
- **Arquivos que o comprador baixa:** `set_product_downloads`.
- **Kit:** chame `load_skill` com `{"name": "product-kits"}` e siga o guia.
- **Curso na área de membros:** use a skill `nomadfy-members-area`.
- **O resto** (listar, buscar, variantes): procure a rota na API do hub com `api_search`.

Preço vai em reais, como texto decimal (`"97.00"`).
