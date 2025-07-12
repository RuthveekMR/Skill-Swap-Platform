const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgresql://postgres:J3ruy#B9Vi!F&em@db.sdznulpndcrmgxwdhxnn.supabase.co:5432/postgres',
  ssl: { rejectUnauthorized: false }
});
module.exports = pool;