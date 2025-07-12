const express = require("express");
const jwt = require("jsonwebtoken");
const db = require("../db"); // your DB connection
const verifyGoogleToken = require("Backend\verify_google_tokens.js");
const router = express.Router();

router.post("/google", async (req, res) => {
  const { idToken } = req.body;

  try {
    const userData = await verifyGoogleToken(idToken);

    let result = await db.query(
      "SELECT * FROM users WHERE google_id = $1",
      [userData.googleId]
    );

    let user = result.rows[0];

    if (!user) {
      const insert = await db.query(
        "INSERT INTO users (name, email, profile_pic, google_id) VALUES ($1, $2, $3, $4) RETURNING *",
        [userData.name, userData.email, userData.picture, userData.googleId]
      );
      user = insert.rows[0];
    }

    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: "1d" });

    res.json({ token, user });
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: "Invalid Google token" });
  }
});

module.exports = router;
