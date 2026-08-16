# KlipShare para Kindle

**Compartilhe seus destaques de leitura diretamente para o Threads, sem sair do Kindle.**

KlipShare é uma extensão para o [KUAL](https://www.mobileread.com/forums/showthread.php?t=203326) (Kindle Unified Application Launcher) que lê os destaques salvos no `My Clippings.txt` e publica automaticamente no [Threads](https://www.threads.net) com um toque — sem abrir o celular, sem copiar e colar.

---

## Funcionalidades

- **Publicação com um toque** — selecione o destaque no menu e ele é postado imediatamente
- **Formatação automática** — o post é gerado no formato `"trecho" — Livro #kindle #leitura`
- **Limpeza de títulos** — remove metadados de e-books (z-library, [PDF], emojis, parênteses duplicados)
- **Capitalização inteligente** — capitaliza a primeira letra, incluindo caracteres acentuados (á, é, ó...)
- **Indicador de caracteres** — exibe o tamanho estimado do post antes de publicar
- **Fila offline** — se o Kindle estiver sem WiFi, o post é salvo e enviado automaticamente na próxima conexão
- **Token persistente** — renovação automática do token de acesso à API do Threads
- **Suporte ao KOReader** — lê highlights do KOReader além do `My Clippings.txt` nativo
- **Até 30 destaques recentes** exibidos no menu

---

## Pré-requisitos

- Kindle com jailbreak
- [KUAL](https://www.mobileread.com/forums/showthread.php?t=203326) instalado
- [KOReader](https://github.com/koreader/koreader) instalado (fornece o `curl` usado pela extensão)
- Conta no Threads
- App KlipShare cadastrado no [Meta for Developers](https://developers.facebook.com)

---

## Instalação

1. Copie a pasta `klipshare/` para `/mnt/us/extensions/` no Kindle
2. Crie o arquivo de credenciais em `/mnt/us/extensions/klipshare/config/credentials.conf`:

```sh
THREADS_USER_ID="SEU_USER_ID"
THREADS_ACCESS_TOKEN="SEU_TOKEN_DE_ACESSO"
```

3. Abra o KUAL → selecione **KlipShare**
4. Clique em **Atualizar lista** para carregar seus destaques

---

## Como obter as credenciais

1. Acesse [developers.facebook.com](https://developers.facebook.com) e crie um app com a API do Threads
2. Adicione as permissões `threads_basic` e `threads_content_publish`
3. Gere um token de acesso de longa duração
4. Localize seu User ID em **Ferramentas → Explorador da API do Graph**

---

## Formato do post

```
"Assim como a planta brota das sementes ocultas do pensamento..."

— O Homem é Aquilo que Ele Pensa (James Allen)

#kindle #leitura
Compartilhado via KlipShare para Kindle
```

---

## Privacidade

KlipShare **não coleta, armazena nem transmite nenhum dado pessoal** para servidores próprios.

- Os destaques são lidos diretamente do arquivo `My Clippings.txt` no dispositivo
- O token de acesso é salvo apenas localmente em `credentials.conf`
- A única comunicação de rede é com a API oficial do Threads (Meta) para publicar o post autorizado pelo próprio usuário
- Nenhum dado é enviado a terceiros além da Meta

---

## Limitações conhecidas

- Requer Kindle com jailbreak (não funciona em Kindles sem modificação)
- Depende do `curl` do KOReader para comunicação com a API
- O parser do KOReader lê apenas highlights marcados no formato Lua padrão

---

## Licença

MIT — livre para uso pessoal e distribuição.

---

## English summary

**KlipShare** is a KUAL extension for jailbroken Kindles that reads highlights from `My Clippings.txt` (and KOReader) and posts them directly to [Threads](https://www.threads.net) with a single tap. No phone needed. Features include automatic post formatting, smart capitalization, offline queue, token auto-refresh, and KOReader highlight support.

**Privacy:** KlipShare does not collect or transmit any personal data to its own servers. The only network communication is with the official Threads API (Meta) to publish posts authorized by the user. The access token is stored locally on the device only.
