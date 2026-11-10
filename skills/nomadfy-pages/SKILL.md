---
name: nomadfy-pages
description: "Cria e muda páginas de vendas, checkouts, ofertas e páginas de obrigado da NomadFy escritas em arquivos (HTML, CSS, JS e imagens), testa na prévia com pagamento de verdade e publica no domínio do site, ligadas a um funil. Use quando o usuário pedir uma página de vendas, um checkout, uma oferta ou outra página do site dele na NomadFy."
---

# Páginas da NomadFy em arquivos

A página é um site estático em arquivos: você escreve numa pasta, envia para o rascunho de uma página da NomadFy, testa na prévia e publica no domínio do site, com a navegação feita pelo funil.

Precisa do MCP da NomadFy conectado (`https://api.nomadfy.app/mcp`). Sem ele, peça ao usuário que conecte: o passo a passo está no hub, em Integrações › Integrações com IA (`https://hub.nomadfy.app/integracoes/mcp`).

## 1. Carregue o guia do servidor

- Chame `load_skill` do MCP com `{"name": "site-pages"}` e siga: ele traz como a página é servida, o tema do site, as seções de referência, o checkout, o arquivo das ações (`nomadfy.json`) e a publicação.
- Antes de escrever a página que vende, mostra o pagamento, a oferta ou o obrigado, carregue o SDK da página (`window.nf`): `{"name": "site-pages", "resource": "sdk"}`.
- Para o funil, `{"name": "funnels"}`.

## 2. Escreva a página numa pasta

- Uma pasta por página no espaço de trabalho (ex.: `paginas/vendas/`), com o `index.html` na raiz dela.
- Não use a ferramenta de Artifact para a página. Os controles de compartilhar dela confundem o usuário com o link da página, e as regras de segurança dela (script só de alguns CDNs, imagem e `fetch` para fora bloqueados) não são as que valem na página publicada.
- Preço, total e desconto nunca ficam escritos na página: vêm do SDK, que lê o carrinho no servidor.
- Imagem: use primeiro as do usuário (a biblioteca "Meus Arquivos", como o guia do servidor diz, ou os arquivos que ele der). O que faltar, faça por código: SVG para ícone, ilustração e fundo; imagem em pixels, gere com um script e salve em WebP ou PNG na largura em que ela aparece.
- Limites da página: até 300 arquivos, 15 MB por arquivo e 80 MB no total; caminhos com letras, números, `-`, `_` e `.`, sem arquivo oculto.

## 3. Envie para o rascunho

Crie a página com `create_page`, como o guia manda. Para mudar uma página que já existe, baixe os arquivos dela para a pasta com `download_page_files`.

Com terminal, use o script `scripts/upload.sh` desta skill. No Claude Code, `${CLAUDE_SKILL_DIR}` é a pasta da skill; em outro agente, troque-o pela pasta onde este `SKILL.md` está.

1. `sh "${CLAUDE_SKILL_DIR}/scripts/upload.sh" list <pasta>` imprime a lista dos arquivos (caminho, tamanho e sha256) e recusa o que a página não aceita.
2. Chame `start_page_upload` com o `pageId` e essa lista.
3. Para cada item de `uploads` da resposta, escreva uma linha `<caminho> <url>`, com um dos `paths` do item, e passe as linhas ao script. Com `uploads` vazio, a NomadFy já tem todo o conteúdo: siga para o passo 4.

```sh
sh "${CLAUDE_SKILL_DIR}/scripts/upload.sh" send <pasta> <<'EOF'
index.html https://...
img/capa.webp https://...
EOF
```

4. Chame `commit_page_files` com o `pageId` e a mesma lista do passo 1: ela troca o rascunho pela lista inteira, e o arquivo fora dela sai da página.

Se o `send` sair com o código 3, o terminal não alcança o endereço de envio. Mande cada arquivo que faltou pelo `upload_page_file_part`, em ordem: `sh "${CLAUDE_SKILL_DIR}/scripts/upload.sh" part <arquivo> <offset>` imprime a parte em base64 e, na linha seguinte, o offset da próxima (ou `end`). Nesse caminho o arquivo vai até 2 MB, em partes de 21 KB: diminua a imagem antes, e prefira gravar os arquivos de texto com `write_page_file`. Depois, `commit_page_files` como no passo 4.

Sem terminal, grave cada arquivo de texto com `write_page_file`, como o guia do servidor diz.

## 4. Teste na prévia

- `open_page_preview` com o `pageId` devolve o `openUrl`, que abre o rascunho como o comprador vê, sem os controles da prévia. Ele entra uma vez e vale 10 minutos; depois de aberto, a prévia segue no mesmo navegador por 12 horas.
- No app do Claude no computador, abra o `openUrl` no navegador do app (o painel Browser, pela ferramenta `preview_start` com a URL): o usuário acompanha no painel ao lado.
- Confira a página no celular (390 px de largura) e no computador (1280 px ou mais). Se a ferramenta do navegador não muda a largura, peça ao usuário para estreitar o painel até a largura do celular e confira de novo. Não diga que conferiu uma largura que não viu.
- Teste o checkout até a cobrança: preencha com os dados que o usuário der e gere o PIX, que é de verdade. Peça que ele pague e confira que a página segue até o obrigado.
- Sem o navegador do app (no claude.ai pelo navegador, ou em outro programa), entregue ao usuário o `previewUrl`, que abre a prévia para ele, e peça que confira.

## 5. Ligue ao funil

Toda ação do `nomadfy.json` é uma saída da etapa "Página" do funil e precisa de destino lá. Monte ou atualize o funil pelo guia `funnels`. Quando a página que já está num funil ganha, troca ou perde uma ação, atualize a etapa dela e ligue a saída nova antes de publicar o funil.

## 6. Publique

Só quando o usuário pedir: `publish_page` publica a página no domínio do site, e o funil é publicado pelo guia `funnels`. Ao terminar, diga o endereço e, em termos do que o comprador vê, o que mudou.
