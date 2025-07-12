const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();
const { OAuth2Client } = require('google-auth-library');
const pool = require('./config');

const client = new OAuth2Client("144575491595-ff9egetl3svgbe6f83rtkggfek27pn3g.apps.googleusercontent.com");

router.post('/google', async (req, res) => {
  const { idToken } = req.body;

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: "144575491595-ff9egetl3svgbe6f83rtkggfek27pn3g.apps.googleusercontent.com"
    });

    const payload = ticket.getPayload();
    const { email, name } = payload;

    let user = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (!user.rows.length) {
      await pool.query('INSERT INTO users (name, email) VALUES ($1, $2)', [name, email]);
      user = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    }

    const token = jwt.sign({ id: user.rows[0].id, email }, 'your-secret-key');
    res.json({ token, user: user.rows[0] });
  } catch (err) {
    res.status(401).json({ error: 'Google verification failed' });
  }
});

module.exports = router;
