const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token required' });

  try {
    req.user = jwt.verify(token, 'your-secret-key');
    next();
  } catch {
    res.status(403).json({ error: 'Invalid token' });
  }
}

module.exports = authMiddleware;
