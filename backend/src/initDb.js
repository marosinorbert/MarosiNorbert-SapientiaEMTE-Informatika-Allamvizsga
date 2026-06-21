const pool = require('./db');

async function initDb() {
  await pool.query(`
  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS greenhouse_devices (
      id SERIAL PRIMARY KEY,
      device_name VARCHAR(100) DEFAULT 'Okos melegház',
      claim_code VARCHAR(50) UNIQUE NOT NULL,
      device_token TEXT UNIQUE NOT NULL,
      user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      is_claimed BOOLEAN DEFAULT false,
      created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
      claimed_at TIMESTAMPTZ
    );
  `);

  await pool.query(`
    INSERT INTO greenhouse_devices (
      device_name,
      claim_code,
      device_token
    )
    VALUES (
      'ESP32-S3 Okos melegház',
      'GH-001-A7K9',
      'esp32_device_token_gh_001_a7k9_2026'
    )
    ON CONFLICT (claim_code) DO NOTHING;
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS sensor_data (
      id SERIAL PRIMARY KEY,
      temperature NUMERIC(5,2),
      humidity NUMERIC(5,2),
      soil_moisture NUMERIC(5,2),
      light_on BOOLEAN DEFAULT false,
      pump_on BOOLEAN DEFAULT false,
      created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  `);

  await pool.query(`
  ALTER TABLE sensor_data
  ADD COLUMN IF NOT EXISTS water_detected BOOLEAN DEFAULT true;
`);

  await pool.query(`
  ALTER TABLE sensor_data
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;
`);

  await pool.query(`
  ALTER TABLE sensor_data
  ADD COLUMN IF NOT EXISTS greenhouse_device_id INTEGER REFERENCES greenhouse_devices(id) ON DELETE SET NULL;
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS device_state (
    id SERIAL PRIMARY KEY,
    device_name VARCHAR(50) NOT NULL,
    is_on BOOLEAN DEFAULT FALSE,
    is_auto BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  ALTER TABLE device_state
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
`);

  await pool.query(`
  ALTER TABLE device_state
  ADD COLUMN IF NOT EXISTS greenhouse_device_id INTEGER REFERENCES greenhouse_devices(id) ON DELETE CASCADE;
`);

  await pool.query(`
  ALTER TABLE device_state
  DROP CONSTRAINT IF EXISTS device_state_device_name_key;
`);

  await pool.query(`
  CREATE UNIQUE INDEX IF NOT EXISTS device_state_user_device_unique
  ON device_state(user_id, greenhouse_device_id, device_name);
`);


  await pool.query(`
  ALTER TABLE device_state
  ADD COLUMN IF NOT EXISTS is_auto BOOLEAN DEFAULT TRUE;
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

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  ALTER TABLE system_settings
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
`);

  await pool.query(`
  CREATE UNIQUE INDEX IF NOT EXISTS system_settings_user_unique
  ON system_settings(user_id);
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
    last_seen TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );
`);


  await pool.query(`
  INSERT INTO esp32_status (id, is_online)
  VALUES (1, false)
  ON CONFLICT (id) DO NOTHING;
`);

  await pool.query(`
  ALTER TABLE esp32_status
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;
`);

  await pool.query(`
  ALTER TABLE esp32_status
  ADD COLUMN IF NOT EXISTS greenhouse_device_id INTEGER REFERENCES greenhouse_devices(id) ON DELETE SET NULL;
`);

  await pool.query(`
  CREATE UNIQUE INDEX IF NOT EXISTS esp32_status_device_unique
  ON esp32_status(greenhouse_device_id);
`);

  await pool.query(`
CREATE TABLE IF NOT EXISTS alerts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  severity VARCHAR(20) NOT NULL,
  sensor VARCHAR(100),
  acknowledged BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
`);

  await pool.query(`
  ALTER TABLE alerts
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
`);

  await pool.query(`
  ALTER TABLE alerts
  ADD COLUMN IF NOT EXISTS greenhouse_device_id INTEGER REFERENCES greenhouse_devices(id) ON DELETE SET NULL;
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    type VARCHAR(30) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  ALTER TABLE system_logs
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
`);

  await pool.query(`
  ALTER TABLE system_logs
  ADD COLUMN IF NOT EXISTS greenhouse_device_id INTEGER REFERENCES greenhouse_devices(id) ON DELETE SET NULL;
`);

  await pool.query(`
  CREATE TABLE IF NOT EXISTS plants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    species VARCHAR(150) DEFAULT 'Ismeretlen fajta',
    emoji VARCHAR(10) DEFAULT '🌱',
    planted_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    temp_min NUMERIC(5,2) DEFAULT 18,
    temp_max NUMERIC(5,2) DEFAULT 28,

    humidity_min NUMERIC(5,2) DEFAULT 50,
    humidity_max NUMERIC(5,2) DEFAULT 75,

    soil_min NUMERIC(5,2) DEFAULT 35,
    soil_max NUMERIC(5,2) DEFAULT 80,

    light_min NUMERIC(8,2) DEFAULT 800,
    light_max NUMERIC(8,2) DEFAULT 3000,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
  );
`);

  await pool.query(`
  ALTER TABLE plants
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
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
  ADD COLUMN IF NOT EXISTS planted_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
`);

  await pool.query(`
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sensor_data'
        AND column_name = 'created_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE sensor_data
        ALTER COLUMN created_at TYPE TIMESTAMPTZ
        USING created_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'device_state'
        AND column_name = 'updated_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE device_state
        ALTER COLUMN updated_at TYPE TIMESTAMPTZ
        USING updated_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'greenhouse_devices'
        AND column_name = 'created_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE greenhouse_devices
        ALTER COLUMN created_at TYPE TIMESTAMPTZ
        USING created_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'greenhouse_devices'
        AND column_name = 'claimed_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE greenhouse_devices
        ALTER COLUMN claimed_at TYPE TIMESTAMPTZ
        USING claimed_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'system_settings'
        AND column_name = 'updated_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE system_settings
        ALTER COLUMN updated_at TYPE TIMESTAMPTZ
        USING updated_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'esp32_status'
        AND column_name = 'last_seen'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE esp32_status
        ALTER COLUMN last_seen TYPE TIMESTAMPTZ
        USING last_seen AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'alerts'
        AND column_name = 'created_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE alerts
        ALTER COLUMN created_at TYPE TIMESTAMPTZ
        USING created_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'system_logs'
        AND column_name = 'created_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE system_logs
        ALTER COLUMN created_at TYPE TIMESTAMPTZ
        USING created_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'plants'
        AND column_name = 'planted_date'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE plants
        ALTER COLUMN planted_date TYPE TIMESTAMPTZ
        USING planted_date AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'plants'
        AND column_name = 'created_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE plants
        ALTER COLUMN created_at TYPE TIMESTAMPTZ
        USING created_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'plants'
        AND column_name = 'updated_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE plants
        ALTER COLUMN updated_at TYPE TIMESTAMPTZ
        USING updated_at AT TIME ZONE 'Europe/Bucharest';
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'created_at'
        AND data_type = 'timestamp without time zone'
      ) THEN
        ALTER TABLE users
        ALTER COLUMN created_at TYPE TIMESTAMPTZ
        USING created_at AT TIME ZONE 'Europe/Bucharest';
      END IF;
    END $$;
  `);

  console.log('Database initialized');
}



module.exports = initDb;