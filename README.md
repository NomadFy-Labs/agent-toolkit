<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/symbol-dark.svg">
    <img src=".github/assets/symbol-light.svg" alt="NomadFy" width="72" height="72">
  </picture>
</p>

<h1 align="center">NomadFy Agent Toolkit</h1>

<p align="center">
  Skills e plugin para agentes de IA trabalharem com a NomadFy:<br>
  integração por API, páginas de venda e checkout, funis, área de membros e produtos.
</p>

<p align="center">
  <a href="https://nomadfy.app/documentacao">Documentação da API</a> ·
  <a href="https://nomadfy.app/llms.txt">llms.txt</a> ·
  <a href="https://hub.nomadfy.app/integracoes/mcp">Agentes e MCP no hub</a>
</p>

---

## O que vem aqui

| | |
|---|---|
| **Servidor MCP** | `https://api.nomadfy.app/mcp`. Liga o agente à sua conta NomadFy. |
| **Skills** | Uma por tarefa, listadas [abaixo](#skills). |
| **Plugin** | As skills e o conector do servidor MCP num pacote só, para o Claude Code e o app do Claude. |

## Instalação

### Claude Code

```text
/plugin marketplace add NomadFy-Labs/agent-toolkit
/plugin install nomadfy-agent-toolkit@nomadfy-labs
```

Depois, rode `/mcp` e entre no servidor `plugin:nomadfy-agent-toolkit:nomadfy`: o navegador abre o hub para você permitir o acesso à conta, com o seu PIN.

### App do Claude

1. Em **Customize › Plugins**, clique em **Add › Add marketplace** e informe `NomadFy-Labs/agent-toolkit`.
2. Instale o plugin **nomadfy-agent-toolkit**.
3. Na aba **Connectors** do plugin, adicione e conecte o servidor da NomadFy. O app abre o hub para você permitir o acesso à conta.

### Outros agentes

Para Cursor, Codex, Gemini CLI e outros agentes compatíveis com skills:

```bash
npx skills add NomadFy-Labs/agent-toolkit
```

E conecte o servidor MCP no seu agente, com o endereço `https://api.nomadfy.app/mcp`.

## Skills

| Skill | Para quê | Precisa de |
|---|---|---|
| [`nomadfy-integration`](skills/nomadfy-integration/SKILL.md) | Integrar a NomadFy numa aplicação: cobrança Pix, QR Code para o comprador, webhook de pagamento e estorno | Chave de API |
| [`nomadfy-pages`](skills/nomadfy-pages/SKILL.md) | Criar páginas de venda e checkouts em arquivos, testar na prévia com pagamento de verdade e publicar no domínio do site | Servidor MCP |
| [`nomadfy`](skills/nomadfy/SKILL.md) | Funis de venda e recuperação de carrinho, área de membros, produtos e kits, pelos guias do servidor MCP | Servidor MCP |

## Licença

[Apache-2.0](LICENSE). A marca e o logo da NomadFy não estão incluídos na licença.
