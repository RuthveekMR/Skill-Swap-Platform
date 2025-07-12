const express = require('express');
const pool = require('../config');
const router = express.Router();

router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const user = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    const offered = await pool.query('SELECT skill FROM skills_offered WHERE user_id = $1', [id]);
    const wanted = await pool.query('SELECT skill FROM skills_wanted WHERE user_id = $1', [id]);

    if (!user.rows.length) return res.status(404).json({ error: 'User not found' });

    res.json({
      ...user.rows[0],
      skills_offered: offered.rows.map(r => r.skill),
      skills_wanted: wanted.rows.map(r => r.skill)
    });
  } catch {
    res.status(500).json({ error: 'Error fetching user' });
  }
});

module.exports = router;
