const CLIENT_ID     = process.env.TWITTER_CLIENT_ID;
const CLIENT_SECRET = process.env.TWITTER_CLIENT_SECRET;

module.exports = async function handler(req, res) {
    const { token } = req.query;

    if (!token) {
        return res.status(400).json({ error: 'Parâmetro token ausente' });
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
                grant_type:    'refresh_token',
                refresh_token: token,
            }).toString(),
        });

        const data = await resp.json();

        if (!data.access_token) {
            return res.status(400).json({ error: 'Falha ao renovar token', details: data });
        }

        return res.status(200).json({
            access_token:  data.access_token,
            refresh_token: data.refresh_token,
        });

    } catch (err) {
        return res.status(500).json({ error: 'Erro interno', details: err.message });
    }
};
