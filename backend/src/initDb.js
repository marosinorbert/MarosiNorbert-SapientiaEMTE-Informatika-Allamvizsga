const pool = require('./db');

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS sensor_data (
      id SERIAL PRIMARY KEY,
      temperature NUMERIC(5,2),
      humidity NUMERIC(5,2),
      soil_moisture NUMERIC(5,2),
      light_on BOOLEAN DEFAULT false,
      pump_on BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  console.log('Database initialized');
}

module.exports = initDb;