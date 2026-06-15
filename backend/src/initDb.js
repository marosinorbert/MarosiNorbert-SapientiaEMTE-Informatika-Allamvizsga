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

  await pool.query(`
<<<<<<< Updated upstream
=======
  ALTER TABLE sensor_data
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
`);

  await pool.query(`
  ALTER TABLE sensor_data
  ADD COLUMN IF NOT EXISTS water_detected BOOLEAN DEFAULT true;
`);

  await pool.query(`
>>>>>>> Stashed changes
  CREATE TABLE IF NOT EXISTS device_state (
    id SERIAL PRIMARY KEY,
    device_name VARCHAR(50) UNIQUE NOT NULL,
    is_on BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`);

await pool.query(`
  INSERT INTO device_state (device_name, is_on)
  VALUES
    ('pump', false),
    ('light', false),
    ('fan', false),
    ('heater', false)
  ON CONFLICT (device_name) DO NOTHING;
`);
  console.log('Database initialized');
}

module.exports = initDb;