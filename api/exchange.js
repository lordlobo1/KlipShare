module.exports = async function handler(req, res) {
    const { code, redirect_uri } = req.query;

    if (!code) {
        return res.status(400).json({ error: 'Parâmetro code ausente' });
    }

    const APP_ID     = process.env.THREADS_APP_ID;
    const APP_SECRET = process.env.THREADS_APP_SECRET;
    const REDIRECT   = process.env.REDIRECT_URI;

    if (redirect_uri && redirect_uri !== REDIRECT) {
        return res.status(400).json({ error: 'redirect_uri não autorizado' });
    }

    try {
        // 1. Troca código por token de curta duração
        const shortResp = await fetch('https://graph.threads.net/oauth/access_token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({
                client_id:     APP_ID,
                client_secret: APP_SECRET,
                grant_type:    'authorization_code',
                redirect_uri:  REDIRECT,
                code
            }).toString()
        });

        const shortData = await shortResp.json();
        if (!shortData.access_token) {
            return res.status(400).json({ error: 'Falha ao obter token', details: shortData });
        }

        // 2. Troca por token de longa duração (60 dias)
        const longResp = await fetch(
            `https://graph.threads.net/access_token?grant_type=th_exchange_token` +
            `&client_secret=${encodeURIComponent(APP_SECRET)}` +
            `&access_token=${encodeURIComponent(shortData.access_token)}`
        );
        const longData = await longResp.json();
        if (!longData.access_token) {
            return res.status(400).json({ error: 'Falha ao obter token longo', details: longData });
        }

        return res.status(200).json({
            user_id:      shortData.user_id,
            access_token: longData.access_token
        });

    } catch (err) {
        return res.status(500).json({ error: 'Erro interno', details: err.message });
    }
};
