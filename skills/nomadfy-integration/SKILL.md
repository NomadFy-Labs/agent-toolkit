---
name: nomadfy-integration
description: "Integra a NomadFy numa aplicação: a cobrança Pix criada no backend, o copia e cola e o QR Code para o comprador, o webhook que confirma o pagamento e libera o pedido, e o estorno. Use quando o usuário pedir para integrar a NomadFy, aceitar Pix pela NomadFy ou receber o aviso de pagamento da NomadFy no sistema dele."
---

# Integrar a NomadFy numa aplicação

A integração usa a API REST da NomadFy (`https://api.nomadfy.app/v1`). A documentação é a referência de cada passo: leia a página indicada antes de escrever o código dele.

- Índice da documentação: `https://nomadfy.app/llms.txt` (cada página em Markdown)
- Tudo num arquivo: `https://nomadfy.app/llms-full.txt`
- OpenAPI: `https://nomadfy.app/documentacao/openapi.json`

Use só as rotas que a documentação lista.

## 1. Conheça o projeto

Antes de escrever código, descubra onde fica o backend, como a aplicação guarda os pedidos, como lê variáveis de ambiente e se ela já tem fila de tarefas. A integração acompanha os padrões que o projeto já usa.

## 2. A chave de API

Guia: `https://nomadfy.app/documentacao/autenticacao.md`

- O usuário cria a chave no hub, em Integrações › API PIX, com as permissões que a integração usa: criar e consultar cobranças, e criar webhooks e reembolsos quando o código fizer isso.
- O código lê a chave de `NOMADFY_API_KEY`. Ponha a variável no exemplo de ambiente do projeto, sem valor. A chave nunca vai para o navegador, para o aplicativo do celular nem para o repositório.

## 3. A cobrança no backend

Guia: `https://nomadfy.app/documentacao/inicio-rapido.md` · Referência: `https://nomadfy.app/documentacao/referencia/cobrancas.md`

- Crie a cobrança Pix no backend quando o comprador fecha o pedido, com o valor que o servidor calculou, nunca um valor vindo do navegador.
- Mande o id do pedido da aplicação na `metadata`: ele volta em toda consulta e em todo webhook.
- Guarde o id da cobrança junto com o pedido.
- Dinheiro vai em reais, como texto decimal (`"49.90"`), e as datas voltam em UTC.

## 4. O Pix para o comprador

Mostre o copia e cola que a cobrança devolve, com um botão de copiar, e o QR Code gerado a partir dele por uma biblioteca da stack do projeto. Mostre também até quando o Pix vale.

## 5. O aviso de pagamento

Guia: `https://nomadfy.app/documentacao/webhooks.md`

- Crie na aplicação o endpoint que recebe o webhook e cadastre-o, pela API ou no hub, com o evento de cobrança paga (e o de estornada, se a aplicação trata estorno).
- O endpoint responde `2xx` logo e processa depois.
- O aviso não é assinado. Antes de liberar o pedido, consulte a cobrança pela API e libere só com `status` `PAID`.
- Os avisos podem chegar repetidos e fora de ordem: o processamento é idempotente.
- A tela do comprador acompanha o pagamento consultando o backend da aplicação, nunca a API da NomadFy pelo navegador.

## 6. Erros e estorno

Guias: `https://nomadfy.app/documentacao/erros.md` · `https://nomadfy.app/documentacao/referencia/estornos.md`

- Siga a página de erros para o que repetir e o que corrigir. Antes de repetir uma cobrança que falhou sem resposta, procure-a pela `metadata`.
- Estorno e saque movem dinheiro: o código que os faz automaticamente precisa do sim do usuário.

## 7. Teste

- Não há ambiente de teste: a cobrança é de verdade. Teste com o valor mínimo, pago pelo próprio usuário.
- O webhook precisa de endereço público com HTTPS. Na máquina local, use um túnel.
- Os registros de entrega do webhook mostram o que a aplicação respondeu a cada aviso.
