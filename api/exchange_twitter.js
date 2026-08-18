const CLIENT_ID     = process.env.TWITTER_CLIENT_ID;
const CLIENT_SECRET = process.env.TWITTER_CLIENT_SECRET;
const REDIRECT      = process.env.TWITTER_REDIRECT_URI;
const CODE_VERIFIER = 'klipshare-twitter-pkce-verifier-personal-v1';

module.exports = async function handler(req, res) {
    const { code, error } = req.query;

    if (error) {
        return res.status(400).send(renderPage('error', { message: error }));
    }

    if (!code) {
        const params = new URLSearchParams({
            response_type:         'code',
            client_id:             CLIENT_ID,
            redirect_uri:          REDIRECT,
            scope:                 'tweet.write users.read offline.access',
            state:                 'klipshare',
            code_challenge:        CODE_VERIFIER,
            code_challenge_method: 'plain',
        });
        return res.redirect(`https://twitter.com/i/oauth2/authorize?${params.toString()}`);
    }

    try {
        const credentials = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');

        const resp = await fetch('https://api.twitter.com/2/oauth2/token', {
            method:  'POST',
            headers: {
                'Authorization': `Basic ${credentials}`,
                'Content-Type':  'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                code,
                grant_type:    'authorization_code',
                redirect_uri:  REDIRECT,
                code_verifier: CODE_VERIFIER,
            }).toString(),
        });

        const data = await resp.json();

        if (!data.access_token) {
            return res.status(400).send(renderPage('error', {
                message: `Falha ao obter token: ${JSON.stringify(data)}`
            }));
        }

        return res.status(200).send(renderPage('success', {
            access_token:  data.access_token,
            refresh_token: data.refresh_token,
        }));

    } catch (err) {
        return res.status(500).send(renderPage('error', { message: err.message }));
    }
};

function escHtml(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function renderPage(state, data) {
    const credBlock = state === 'success'
        ? `TWITTER_ACCESS_TOKEN="${data.access_token}"\nTWITTER_REFRESH_TOKEN="${data.refresh_token}"\nTWITTER_MAX_LEN=280`
        : '';

    return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>KlipShare — Twitter/X</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0f0f0f;color:#e8e8e8;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:24px}
.container{max-width:520px;width:100%}
.logo{text-align:center;margin-bottom:36px}
.logo h1{font-size:26px;font-weight:700;letter-spacing:-0.5px}
.logo p{color:#666;font-size:13px;margin-top:6px}
.card{background:#1a1a1a;border:1px solid #272727;border-radius:14px;padding:32px}
.step-title{font-size:17px;font-weight:600;margin-bottom:10px}
.step-desc{color:#888;font-size:14px;line-height:1.65;margin-bottom:0}
.success-check{font-size:38px;text-align:center;margin-bottom:14px}
.error-box{background:#1f0e0e;border:1px solid #4a1c1c;border-radius:9px;padding:16px;color:#f08080;font-size:14px;line-height:1.5;margin-bottom:20px}
.code-block{background:#111;border:1px solid #222;border-radius:8px;padding:16px;font-family:'Courier New',monospace;font-size:13px;line-height:1.7;color:#7ecf7e;white-space:pre;overflow-x:auto;margin-top:20px}
.copy-btn{width:100%;margin-top:10px;padding:10px;border-radius:7px;border:1px solid #333;background:#222;color:#aaa;font-size:13px;cursor:pointer;transition:color .2s,border-color .2s}
.copy-btn:hover{background:#2a2a2a}
.copy-btn.copied{color:#6bcb77;border-color:#6bcb77}
.next-steps{margin-top:28px;padding-top:24px;border-top:1px solid #222}
.next-steps h3{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:1px;color:#555;margin-bottom:14px}
.next-steps ol{padding-left:18px;color:#777;font-size:13px;line-height:2.1}
.next-steps ol li strong{color:#ccc}
code{background:#222;border:1px solid #333;border-radius:4px;padding:1px 5px;font-family:monospace;font-size:12px;color:#aaa}
.note{margin-top:16px;font-size:12px;color:#555;line-height:1.6}
</style>
</head>
<body>
<div class="container">
<div class="logo">
  <h1>KlipShare</h1>
  <p>Destaques do Kindle direto para o Threads e Twitter/X</p>
</div>
<div class="card">
${state === 'success' ? `
  <div class="success-check">✓</div>
  <div class="step-title" style="text-align:center">Twitter/X autorizado!</div>
  <div class="step-desc" style="text-align:center">
    Adicione as linhas abaixo ao <code>credentials.conf</code> no Kindle.
  </div>
  <div class="code-block" id="cred">${credBlock}</div>
  <button class="copy-btn" id="copy-btn" onclick="copy()">Copiar</button>
  <div class="next-steps">
    <h3>Próximos passos</h3>
    <ol>
      <li>Abra <strong><code>/mnt/us/extensions/klipshare/config/credentials.conf</code></strong></li>
      <li>Cole as linhas copiadas ao final do arquivo</li>
      <li>Ejete o Kindle com segurança</li>
      <li>Abra o <strong>KUAL → KlipShare</strong> e selecione um destaque</li>
      <li>O post irá para <strong>Threads e Twitter</strong> ao mesmo tempo</li>
    </ol>
    <p class="note">
      Usuários <strong>X Premium</strong>: mude <code>TWITTER_MAX_LEN=280</code> para um valor maior
      (ex.: <code>4096</code>) para aproveitar o limite estendido de caracteres.
    </p>
  </div>
` : `
  <div class="error-box">Erro ao autorizar: ${escHtml(data.message || 'desconhecido')}</div>
  <a href="/setup/twitter" style="display:block;text-align:center;color:#888;font-size:14px;">Tentar novamente</a>
`}
</div>
</div>
<script>
function copy() {
  var t = document.getElementById('cred').textContent;
  navigator.clipboard.writeText(t).then(function() {
    var b = document.getElementById('copy-btn');
    b.textContent = 'Copiado!';
    b.classList.add('copied');
    setTimeout(function(){ b.textContent='Copiar'; b.classList.remove('copied'); }, 2000);
  });
}
</script>
</body>
</html>`;
}
