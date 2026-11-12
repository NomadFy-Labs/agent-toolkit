---
name: nomadfy-pages
description: "Cria e muda páginas de vendas, checkouts, ofertas e páginas de obrigado da NomadFy escritas em arquivos (HTML, CSS, JS e imagens), testa na prévia com pagamento de verdade e publica no domínio do site, ligadas a um funil. Use quando o usuário pedir uma página de vendas, um checkout, uma oferta ou outra página do site dele na NomadFy."
---

# Páginas da NomadFy em arquivos

A página é um site estático em arquivos, e o trabalho é o de qualquer página web feita numa pasta: você cria a página na NomadFy, abre a prévia no navegador, escreve os arquivos e envia para o rascunho em pedaços, e publica quando o usuário pedir. Mudar é editar a pasta e enviar de novo.

Precisa do MCP da NomadFy conectado (`https://api.nomadfy.app/mcp`). Sem ele, peça ao usuário que conecte: o passo a passo está no hub, em Integrações › Agentes e MCP (`https://hub.nomadfy.app/integracoes/mcp`).

## 1. Carregue o guia do servidor

Chame `load_skill` do MCP com `{"name": "site-pages"}` e siga: ele traz o contrato da página (o que a plataforma impõe), o ciclo, o que faz uma boa página de vendas e o checkout. Os recursos dele se carregam com `{"name": "site-pages", "resource": "<recurso>"}`: `sdk` antes de escrever a página que vende, mostra o pagamento, a oferta ou o obrigado; `design` antes de escrever a primeira página de um site; `checkout` antes do checkout; `secoes` para seções de exemplo. Para o funil, `{"name": "funnels"}`.

Esta skill traz o que roda no seu computador: a pasta do site e o envio.

## 2. Crie a página e abra a prévia

Crie a página com `create_page`, como o guia manda, e abra a prévia logo em seguida, antes de escrever o resto: a página nasce com uma tela provisória de "construindo", que recarrega sozinha quando o `index.html` de verdade chega, e o usuário vê a página nascer em vez de esperar em silêncio.

`open_page_preview` com o `pageId` devolve dois links, cada um com o destinatário no nome:

- `previewForAgent` é seu. Abra no navegador embutido no app em que o usuário conversa, ao lado da conversa, onde ele acompanha, mesmo com outro navegador como preferido nas configurações: essa preferência vale quando ele pede para abrir algo para ver, e a conferência do que você constrói é sua; ele abre no navegador dele pelo `previewForHuman` quando quiser. Só sem o embutido, use um navegador do computador que ele veja. Ele entra uma vez e vale 10 minutos; depois de aberto, a prévia segue nesse navegador por 12 horas.
- `previewForHuman` é do usuário: entregue a ele, que abre a prévia com a barra de compartilhar.

## 3. Escreva a página na pasta do site

A pasta do site espelha o endereço:

```text
[site]/index.html       a página da raiz (/): num site de um produto só, a página de vendas
[site]/_assets          os arquivos da página da raiz
[site]/_shared          arquivos comuns às páginas: CSS, fontes, componentes, bibliotecas
[site]/vendas           a página /vendas, com o index.html e a pasta _assets dela
[site]/oferta/vendas    a página /oferta/vendas
```

Os arquivos de cada página, além do `index.html`, ficam numa pasta que começa com `_` (`_assets/`): a pasta com o nome de uma página do site some atrás dela, e o caminho de página nunca começa com `_`.

- Use a tecnologia que quiser (HTML puro, React, Tailwind, um bundler): o que vai para a NomadFy é a página pronta para o navegador, com o `index.html` na pasta dela.
- Para mudar uma página que já existe, baixe os arquivos dela para a pasta com `download_page_files` (e os da `_shared`, com o `pageId` que `get_site_shared_files` dá).
- Sem foto do lojista, baixe fotos de banco gratuito (Unsplash, Pexels) para a pasta, na largura em que elas aparecem, e diga que são provisórias. Ícone e ilustração simples, faça em SVG.
- Envie em pedaços, para o usuário acompanhar na prévia: primeiro a dobra de cima com o visual, depois o resto das seções, em vez de um envio só no fim.

## 4. Envie para o rascunho

O envio é pelo script `scripts/upload.sh` desta skill: `${CLAUDE_SKILL_DIR}` é a pasta da skill (a deste `SKILL.md`); no agente que não define essa variável, use o caminho da pasta.

1. `sh "${CLAUDE_SKILL_DIR}/scripts/upload.sh" list <site> <página>` imprime a lista dos arquivos da página e os da `_shared` (caminho, tamanho e sha256) e recusa o que a página não aceita. `<página>` é a pasta dela dentro do site (`vendas`, `oferta/vendas`, `.` na raiz). É o envio de todo arquivo, e não só do grande.
2. Chame `start_page_upload` com o `pageId` e essa lista.
3. Para cada item de `uploads` da resposta, escreva uma linha `<caminho> <url>`, com um dos `paths` do item, e passe as linhas ao script. Com `uploads` vazio, a NomadFy já tem todo o conteúdo: siga para o passo 4.

```sh
sh "${CLAUDE_SKILL_DIR}/scripts/upload.sh" send <site> <página> <<'EOF'
index.html https://...
_shared/marca.css https://...
EOF
```

4. Chame `commit_page_files` com o `pageId` e a mesma lista do passo 1: ela troca o rascunho da página pela lista inteira, e grava os da `_shared` por cima dos de mesmo caminho. Cada pedaço é um envio da pasta como ela está.

Não suponha que a rede do terminal bloqueia o envio: rode o `send`. Se ele sair com o código 3, o terminal não alcança o endereço de envio. Mande cada arquivo que faltou pelo `upload_page_file_part`, em ordem: `sh "${CLAUDE_SKILL_DIR}/scripts/upload.sh" part <arquivo> <offset>` imprime a parte em base64 e, na linha seguinte, o offset da próxima (ou `end`). Nesse caminho o arquivo vai até 2 MB, em partes de 21 KB: diminua a imagem antes, e prefira gravar os arquivos de texto com `write_page_file`. Depois, `commit_page_files` como no passo 4.

## 5. Confira e ajuste

Com a página inteira enviada, confira na prévia no celular (390 px de largura) e no computador (1280 px ou mais). Não diga que conferiu uma largura que não viu: se o navegador não muda a largura, peça ao usuário que confira no celular.

Ajustar é editar a pasta e enviar de novo: a prévia mostra a versão nova no mesmo endereço. O teste do checkout, a ligação ao funil e a publicação seguem o guia.
