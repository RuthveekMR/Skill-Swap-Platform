const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Serve frontend
app.use(express.static(path.join(__dirname, 'public')));

// API routes
app.use('/api/user', require('./routes/userRoutes'));
app.use('/api/swap', require('./routes/swapRoutes'));
app.use('/api/auth', require('./auth'));

// Catch-all (serves login.html for unknown frontend routes)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.listen(5000, () => console.log('✅ Server running on http://localhost:5000'));
