const crypto = require('crypto');

const CONSUMER_KEY    = process.env.TWITTER_CONSUMER_KEY;
const CONSUMER_SECRET = process.env.TWITTER_CONSUMER_SECRET;
const ACCESS_TOKEN    = process.env.TWITTER_ACCESS_TOKEN_V1;
const TOKEN_SECRET    = process.env.TWITTER_ACCESS_TOKEN_SECRET;
const KINDLE_SECRET   = process.env.KINDLE_SECRET;

// RFC 3986 percent-encoding (stricter than encodeURIComponent)
function pct(s) {
    return encodeURIComponent(String(s))
        .replace(/!/g, '%21').replace(/'/g, '%27')
        .replace(/\(/g, '%28').replace(/\)/g, '%29').replace(/\*/g, '%2A');
}

module.exports = async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    const { text, secret } = req.body || {};

    if (!text) return res.status(400).json({ error: 'Missing text' });
    if (KINDLE_SECRET && secret !== KINDLE_SECRET) {
        return res.status(403).json({ error: 'Forbidden' });
    }

    const url       = 'https://api.twitter.com/2/tweets';
    const timestamp = String(Math.floor(Date.now() / 1000));
    const nonce     = crypto.randomBytes(16).toString('hex');

    const oauthParams = {
        oauth_consumer_key:     CONSUMER_KEY,
        oauth_nonce:            nonce,
        oauth_signature_method: 'HMAC-SHA1',
        oauth_timestamp:        timestamp,
        oauth_token:            ACCESS_TOKEN,
        oauth_version:          '1.0',
    };

    // JSON bodies are not included in OAuth 1.0a signature base string
    const paramStr = Object.keys(oauthParams).sort()
        .map(k => `${pct(k)}=${pct(oauthParams[k])}`).join('&');
    const base = `POST&${pct(url)}&${pct(paramStr)}`;
    const key  = `${pct(CONSUMER_SECRET)}&${pct(TOKEN_SECRET)}`;

    oauthParams.oauth_signature = crypto.createHmac('sha1', key).update(base).digest('base64');

    const authHeader = 'OAuth ' + Object.keys(oauthParams).sort()
        .map(k => `${pct(k)}="${pct(oauthParams[k])}"`).join(', ');

    try {
        const resp = await fetch(url, {
            method:  'POST',
            headers: { 'Authorization': authHeader, 'Content-Type': 'application/json' },
            body:    JSON.stringify({ text }),
        });

        const data = await resp.json();

        if (data.data && data.data.id) {
            return res.status(200).json({ id: data.data.id });
        }
        return res.status(resp.status).json(data);
    } catch (err) {
        return res.status(500).json({ error: err.message });
    }
};
