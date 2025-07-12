const express = require('express');
const pool = require('../config');
const auth = require('../middleware/authMiddleware');
const router = express.Router();

router.post('/', auth, async (req, res) => {
  const { to_user_id, message } = req.body;
  const from_user_id = req.user.id;

  try {
    const existing = await pool.query(
      'SELECT * FROM swap_requests WHERE from_user_id = $1 AND to_user_id = $2',
      [from_user_id, to_user_id]
    );
    if (existing.rows.length) return res.status(400).json({ error: 'Already requested' });

    await pool.query(
      'INSERT INTO swap_requests (from_user_id, to_user_id, message) VALUES ($1, $2, $3)',
      [from_user_id, to_user_id, message]
    );

    res.json({ success: true });
  } catch {
    res.status(500).json({ error: 'Error sending swap request' });
  }
});

module.exports = router;
