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
  ALTER TABLE sensor_data
  ADD COLUMN IF NOT EXISTS water_detected BOOLEAN DEFAULT true;
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS device_state (
    id SERIAL PRIMARY KEY,
    device_name VARCHAR(50) UNIQUE NOT NULL,
    is_on BOOLEAN DEFAULT FALSE,
    is_auto BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  ALTER TABLE device_state
  ADD COLUMN IF NOT EXISTS is_auto BOOLEAN DEFAULT TRUE;
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

  await pool.query(`
  ALTER TABLE device_state
  ADD COLUMN IF NOT EXISTS schedule_enabled BOOLEAN DEFAULT false;
`);

  await pool.query(`
  ALTER TABLE device_state
  ADD COLUMN IF NOT EXISTS schedule_on TIME DEFAULT '08:00';
`);

  await pool.query(`
  ALTER TABLE device_state
  ADD COLUMN IF NOT EXISTS schedule_off TIME DEFAULT '20:00';
`);

  await pool.query(`
  UPDATE device_state
  SET 
    schedule_enabled = true,
    schedule_on = '08:00',
    schedule_off = '08:30'
  WHERE device_name = 'pump';
`);

  await pool.query(`
  UPDATE device_state
  SET 
    schedule_enabled = true,
    schedule_on = '06:00',
    schedule_off = '20:00'
  WHERE device_name = 'light';
`);

  await pool.query(`
  UPDATE device_state
  SET 
    schedule_enabled = true,
    schedule_on = '07:00',
    schedule_off = '21:00'
  WHERE device_name = 'fan';
`);

  await pool.query(`
  UPDATE device_state
  SET 
    schedule_enabled = true,
    schedule_on = '05:00',
    schedule_off = '09:00'
  WHERE device_name = 'heater';
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    temp_min NUMERIC(5,2) DEFAULT 18,
    temp_max NUMERIC(5,2) DEFAULT 28,

    humidity_min NUMERIC(5,2) DEFAULT 50,
    humidity_max NUMERIC(5,2) DEFAULT 75,

    soil_min NUMERIC(5,2) DEFAULT 35,
    soil_max NUMERIC(5,2) DEFAULT 80,

    light_min NUMERIC(8,2) DEFAULT 800,
    light_max NUMERIC(8,2) DEFAULT 3000,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  INSERT INTO system_settings (
    id,
    temp_min,
    temp_max,
    humidity_min,
    humidity_max,
    soil_min,
    soil_max,
    light_min,
    light_max
  )
  VALUES (
    1,
    18,
    28,
    50,
    75,
    35,
    80,
    800,
    3000
  )
  ON CONFLICT (id) DO NOTHING;
`);

  await pool.query(`
  ALTER TABLE system_settings
  ADD COLUMN IF NOT EXISTS dark_mode BOOLEAN DEFAULT false;
`);

  await pool.query(`
  ALTER TABLE system_settings
  ADD COLUMN IF NOT EXISTS language VARCHAR(10) DEFAULT 'hu';
`);

  await pool.query(`
  ALTER TABLE system_settings
  ADD COLUMN IF NOT EXISTS temp_unit VARCHAR(10) DEFAULT '°C';
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS esp32_status (
    id SERIAL PRIMARY KEY,
    is_online BOOLEAN DEFAULT false,
    wifi_connected BOOLEAN DEFAULT false,
    mqtt_connected BOOLEAN DEFAULT false,
    signal_strength INTEGER DEFAULT 0,
    free_ram INTEGER DEFAULT 0,
    total_ram INTEGER DEFAULT 320,
    cpu_temp INTEGER DEFAULT 0,
    uptime_seconds INTEGER DEFAULT 0,
    ip_address VARCHAR(50),
    firmware_version VARCHAR(50) DEFAULT 'v1.0.0',
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  INSERT INTO esp32_status (id, is_online)
  VALUES (1, false)
  ON CONFLICT (id) DO NOTHING;
`);

  await pool.query(`
CREATE TABLE IF NOT EXISTS alerts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  severity VARCHAR(20) NOT NULL,
  sensor VARCHAR(100),
  acknowledged BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    type VARCHAR(30) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS plants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    species VARCHAR(150) DEFAULT 'Ismeretlen fajta',
    emoji VARCHAR(10) DEFAULT '🌱',
    planted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    temp_min NUMERIC(5,2) DEFAULT 18,
    temp_max NUMERIC(5,2) DEFAULT 28,

    humidity_min NUMERIC(5,2) DEFAULT 50,
    humidity_max NUMERIC(5,2) DEFAULT 75,

    soil_min NUMERIC(5,2) DEFAULT 35,
    soil_max NUMERIC(5,2) DEFAULT 80,

    light_min NUMERIC(8,2) DEFAULT 800,
    light_max NUMERIC(8,2) DEFAULT 3000,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  ALTER TABLE plants
  ADD COLUMN IF NOT EXISTS species VARCHAR(150) DEFAULT 'Ismeretlen fajta';
`);

  await pool.query(`
  ALTER TABLE plants
  ADD COLUMN IF NOT EXISTS emoji VARCHAR(10) DEFAULT '🌱';
`);

  await pool.query(`
  ALTER TABLE plants
  ADD COLUMN IF NOT EXISTS planted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
`);

  console.log('Database initialized');
}



module.exports = initDb;