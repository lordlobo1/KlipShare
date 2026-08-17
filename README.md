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

Antes de instalar, verifique se o seu Kindle atende a todos os requisitos abaixo.

### 1. Kindle com jailbreak
O KlipShare requer um Kindle desbloqueado (jailbreak). Modelos compatíveis e instruções estão disponíveis no [MobileRead Forum](https://www.mobileread.com/forums/showthread.php?t=346037).

**Como verificar:** conecte o Kindle ao computador. Se existir uma pasta `extensions/` na raiz do dispositivo, o jailbreak está ativo.

### 2. KUAL instalado
O KUAL (Kindle Unified Application Launcher) é o menu de extensões do Kindle.

**Como verificar:** na tela inicial do Kindle, procure por um livro chamado **"KUAL"** na biblioteca. Se aparecer, está instalado.

**Como instalar:** baixe em [MobileRead — KUAL](https://www.mobileread.com/forums/showthread.php?t=203326) e copie o arquivo `.azw2` para a pasta `documents/` do Kindle.

### 3. KOReader instalado
O KOReader fornece o programa `curl` que o KlipShare usa para se comunicar com a API do Threads.

**Como verificar:** abra o KUAL. Se aparecer a opção **KOReader**, está instalado.

**Como instalar:** baixe em [github.com/koreader/koreader](https://github.com/koreader/koreader/releases) e siga as instruções para Kindle.

### 4. Conta no Threads
Você precisa de uma conta ativa no [Threads](https://www.threads.net) para autorizar o app.

---

## Instalação

### Passo 1 — Baixar o KlipShare

1. Acesse [github.com/lordlobo1/KlipShare](https://github.com/lordlobo1/KlipShare)
2. Clique no botão verde **Code**
3. Clique em **Download ZIP**
4. Extraia o arquivo ZIP no seu computador — você verá a pasta `KlipShare-main/`

### Passo 2 — Copiar para o Kindle

1. Conecte o Kindle ao computador via cabo USB
2. O Kindle aparecerá como um dispositivo de armazenamento (ex: `D:\` no Windows, `/Volumes/Kindle` no Mac)
3. Abra a pasta `extensions/` na raiz do Kindle
4. Copie a pasta `klipshare/` (que está dentro de `KlipShare-main/`) para dentro de `extensions/`

A estrutura final no Kindle deve ser exatamente esta:

```
Kindle/
└── extensions/
    └── klipshare/
        ├── config.xml
        ├── menu.json
        ├── bin/
        │   ├── generate_menu.sh
        │   └── share_threads.sh
        └── config/               ← criar esta pasta manualmente
            └── credentials.conf  ← criar este arquivo manualmente
```

5. Dentro de `extensions/klipshare/`, crie a pasta `config/` manualmente
6. Dentro de `config/`, crie o arquivo `credentials.conf` conforme o Passo 4

### Passo 3 — Obter as credenciais do Threads

Acesse a página de configuração automática:

**[https://klipshare.vercel.app/setup](https://klipshare.vercel.app/setup)**

1. Clique em **Autorizar com Threads**
2. Autorize o app na tela do Threads
3. A página gera o `credentials.conf` automaticamente — copie o conteúdo

> Prefere fazer manualmente? Expanda as instruções abaixo.

<details>
<summary>Configuração manual (avançado)</summary>

Esta etapa conecta o KlipShare à sua conta do Threads. Você precisará de dois dados:

- **User ID** — número que identifica sua conta na API do Threads
- **Access Token** — chave de acesso que autoriza o KlipShare a publicar em seu nome

#### 3.1 — Autorizar o KlipShare

Abra o link abaixo no navegador do celular ou computador **onde você está logado no Threads**:

```
https://threads.net/oauth/authorize?client_id=1817010732620817&redirect_uri=https://localhost&scope=threads_basic,threads_content_publish&response_type=code
```

- O Threads mostrará uma tela pedindo permissão para o KlipShare publicar em seu nome
- Clique em **Continuar como @seu_usuario**
- O navegador tentará abrir `https://localhost` e mostrará uma mensagem de erro ("Esse site não pode ser acessado" ou similar) — **isso é completamente normal e esperado**
- **Não feche a aba.** Olhe para a barra de endereços do navegador

A URL na barra de endereços estará assim:
```
https://localhost/?code=AQBxxxxxxxxxxxxxxxxxxxxxxxx#_
```

Selecione e copie apenas o trecho entre `code=` e `#_`. Exemplo:
```
AQBxxxxxxxxxxxxxxxxxxxxxxxx
```

> ⚠️ **Atenção:** este código expira em **10 minutos**. Complete o passo seguinte sem demora.

#### 3.2 — Trocar o código pelo token de acesso

**No Windows — abra o PowerShell** (tecla Windows + R → digite `powershell` → Enter) e execute:

```powershell
curl.exe -X POST "https://graph.threads.net/oauth/access_token" `
  -d "client_id=1817010732620817" `
  -d "grant_type=authorization_code" `
  -d "redirect_uri=https://localhost" `
  -d "code=COLE_O_CODIGO_AQUI"
```

**No Mac/Linux — abra o Terminal** e execute:

```sh
curl -X POST "https://graph.threads.net/oauth/access_token" \
  -d "client_id=1817010732620817" \
  -d "grant_type=authorization_code" \
  -d "redirect_uri=https://localhost" \
  -d "code=COLE_O_CODIGO_AQUI"
```

Substitua `COLE_O_CODIGO_AQUI` pelo código copiado no passo anterior.

A resposta será um texto no formato JSON como este:

```json
{
  "access_token": "THAAAAxxxxxxxxxxxxxxxx",
  "token_type": "bearer",
  "expires_in": 3600
}
```

Copie o valor de `access_token`. Este é o **token de curta duração** (válido por 1 hora).

#### 3.3 — Gerar token de longa duração (válido por 60 dias)

Execute o comando abaixo substituindo `TOKEN_CURTO` pelo token obtido no passo anterior:

**Windows (PowerShell):**
```powershell
curl.exe "https://graph.threads.net/access_token?grant_type=th_exchange_token&access_token=TOKEN_CURTO"
```

**Mac/Linux (Terminal):**
```sh
curl "https://graph.threads.net/access_token?grant_type=th_exchange_token&access_token=TOKEN_CURTO"
```

A resposta será:

```json
{
  "access_token": "THAAAAyyyyyyyyyyyyyyyy",
  "token_type": "bearer",
  "expires_in": 5183944
}
```

Copie o novo `access_token`. Este é o **token de longa duração** que você usará no arquivo de configuração.

> ✅ O KlipShare renova este token automaticamente antes de cada publicação. Você não precisará repetir este processo.

#### 3.4 — Obter o seu User ID

Execute o comando abaixo substituindo `TOKEN_LONGO` pelo token obtido no passo 3.3:

**Windows (PowerShell):**
```powershell
curl.exe "https://graph.threads.net/me?fields=id&access_token=TOKEN_LONGO"
```

**Mac/Linux (Terminal):**
```sh
curl "https://graph.threads.net/me?fields=id&access_token=TOKEN_LONGO"
```

A resposta será:

```json
{
  "id": "12345678901234567"
}
```

Copie o valor de `id`. Este é o seu **User ID**.

</details>

### Passo 4 — Criar o arquivo de configuração

Crie o arquivo `credentials.conf` dentro da pasta `extensions/klipshare/config/` no Kindle com o seguinte conteúdo:

```sh
THREADS_USER_ID="12345678901234567"
THREADS_ACCESS_TOKEN="THAAAAyyyyyyyyyyyyyyyy"
```

Substitua pelos valores reais obtidos nos passos 3.3 e 3.4.

**Como criar o arquivo corretamente:**

- **Windows:** abra o Bloco de Notas → cole o conteúdo → **Arquivo → Salvar como** → navegue até `extensions/klipshare/config/` → no campo **Nome do arquivo** digite `credentials.conf` → em **Tipo** selecione **Todos os arquivos (\*.\*)** → clique em Salvar
- **Mac:** abra o TextEdit → **Formato → Converter para Formato Simples** → cole o conteúdo → **Arquivo → Salvar** → navegue até a pasta correta → salve como `credentials.conf`

> ⚠️ Verifique que o arquivo se chama exatamente `credentials.conf` e **não** `credentials.conf.txt`. No Windows, ative a exibição de extensões em **Explorador de Arquivos → Exibir → Extensões de nome de arquivo** para confirmar.

> 🔒 **Segurança:** nunca compartilhe este arquivo. O token dá acesso à publicação na sua conta do Threads.

### Passo 5 — Ejetar e testar

1. Ejete o Kindle com segurança:
   - **Windows:** clique no ícone de ejetar na barra de tarefas → selecione o Kindle
   - **Mac:** arraste o ícone do Kindle para a lixeira ou clique no ⏏ ao lado do nome no Finder
2. Na tela inicial do Kindle, abra o **KUAL**
3. Selecione **KlipShare**
4. Clique em **Atualizar lista** e aguarde a mensagem de confirmação na tela
5. Seus destaques aparecerão no menu com o tamanho estimado do post entre colchetes:
   ```
   [142] Assim como a planta brota...
   [89] Servir de modelo e de inspi...
   ```
6. Toque em qualquer destaque — ele será publicado automaticamente no Threads
7. Uma mensagem na tela do Kindle confirmará o envio

---

## Formato do post publicado

```
"Assim como a planta brota das sementes ocultas do pensamento..."

— O Homem é Aquilo que Ele Pensa (James Allen)

#kindle #leitura
Compartilhado via KlipShare para Kindle
```

---

## Solução de problemas

| Problema | Causa provável | Solução |
|---|---|---|
| KlipShare não aparece no KUAL | Pasta copiada no lugar errado | Verifique se `klipshare/` está diretamente dentro de `extensions/` |
| "ERRO: credentials.conf nao encontrado" | Arquivo ausente ou caminho incorreto | Confirme que está em `extensions/klipshare/config/credentials.conf` |
| "ERRO: curl nao encontrado" | KOReader não instalado | Instale o KOReader — ele fornece o `curl` usado pela extensão |
| "FALHA ao criar post. Verifique WiFi e token" | Token inválido ou sem internet | Refaça o processo de obtenção do token; verifique o WiFi do Kindle |
| "Sem WiFi. Post salvo na fila offline" | Kindle sem conexão WiFi | Normal — o post será enviado quando o WiFi reconectar |
| Lista de destaques vazia | Nenhum destaque em `My Clippings.txt` | Faça ao menos um destaque em um livro no Kindle e clique em "Atualizar lista" |
| Código OAuth expirou | Mais de 10 min entre os passos 3.1 e 3.2 | Repita o passo 3.1 e complete o 3.2 imediatamente |
| Arquivo salvo como `credentials.conf.txt` | Extensão duplicada no Windows | Ative a exibição de extensões e renomeie removendo o `.txt` |

---

## Privacidade

KlipShare **não coleta, armazena nem transmite nenhum dado pessoal** para servidores próprios.

- Os destaques são lidos diretamente do arquivo `My Clippings.txt` no dispositivo
- O token de acesso é salvo apenas localmente em `credentials.conf` dentro do Kindle
- A única comunicação de rede é com a API oficial do Threads (Meta) para publicar o post autorizado pelo próprio usuário
- Nenhum dado é enviado a terceiros além da Meta

Leia a [Política de Privacidade completa](PRIVACY.md).

---

## Licença

MIT — livre para uso pessoal e distribuição.

---

## English summary

**KlipShare** is a KUAL extension for jailbroken Kindles that reads highlights from `My Clippings.txt` (and KOReader) and posts them directly to [Threads](https://www.threads.net) with a single tap. No phone needed. Features include automatic post formatting, smart capitalization, offline queue, token auto-refresh, and KOReader highlight support.

**Privacy:** KlipShare does not collect or transmit any personal data to its own servers. The only network communication is with the official Threads API (Meta) to publish posts authorized by the user. The access token is stored locally on the device only.

Full documentation and privacy policy: [github.com/lordlobo1/KlipShare](https://github.com/lordlobo1/KlipShare)
