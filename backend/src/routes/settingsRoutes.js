const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');

async function getUserDeviceId(userId) {
  const result = await pool.query(
    `
    SELECT id
    FROM greenhouse_devices
    WHERE user_id = $1
    AND is_claimed = true
    ORDER BY claimed_at DESC
    LIMIT 1
    `,
    [userId]
  );

  if (result.rows.length === 0) {
    return null;
  }

  return result.rows[0].id;
}

async function getOrCreateSettings(userId) {
  const existing = await pool.query(
    `
    SELECT *
    FROM system_settings
    WHERE user_id = $1
    LIMIT 1
    `,
    [userId]
  );

  if (existing.rows.length > 0) {
    return existing.rows[0];
  }

  const created = await pool.query(
    `
    INSERT INTO system_settings (
      user_id,
      temp_min,
      temp_max,
      humidity_min,
      humidity_max,
      soil_min,
      soil_max,
      light_min,
      light_max,
      dark_mode,
      language,
      temp_unit
    )
    VALUES ($1, 18, 28, 50, 75, 35, 80, 800, 3000, false, 'hu', '°C')
    RETURNING *
    `,
    [userId]
  );

  return created.rows[0];
}

router.get('/', authMiddleware, async (req, res) => {
  const settings = await getOrCreateSettings(req.user.id);
  res.json(settings);
});

router.post('/', authMiddleware, async (req, res) => {
  const {
    tempMin,
    tempMax,
    humidityMin,
    humidityMax,
    soilMin,
    soilMax,
    lightMin,
    lightMax,
    darkMode,
    language,
    tempUnit,
  } = req.body;

  const result = await pool.query(
    `
    INSERT INTO system_settings (
      user_id,
      temp_min,
      temp_max,
      humidity_min,
      humidity_max,
      soil_min,
      soil_max,
      light_min,
      light_max,
      dark_mode,
      language,
      temp_unit,
      updated_at
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,CURRENT_TIMESTAMP)
    ON CONFLICT (user_id)
    DO UPDATE SET
      temp_min = EXCLUDED.temp_min,
      temp_max = EXCLUDED.temp_max,
      humidity_min = EXCLUDED.humidity_min,
      humidity_max = EXCLUDED.humidity_max,
      soil_min = EXCLUDED.soil_min,
      soil_max = EXCLUDED.soil_max,
      light_min = EXCLUDED.light_min,
      light_max = EXCLUDED.light_max,
      dark_mode = EXCLUDED.dark_mode,
      language = EXCLUDED.language,
      temp_unit = EXCLUDED.temp_unit,
      updated_at = CURRENT_TIMESTAMP
    RETURNING *
    `,
    [
      req.user.id,
      tempMin,
      tempMax,
      humidityMin,
      humidityMax,
      soilMin,
      soilMax,
      lightMin,
      lightMax,
      darkMode,
      language,
      tempUnit,
    ]
  );

  const greenhouseDeviceId = await getUserDeviceId(req.user.id);

  await pool.query(
    `
    INSERT INTO system_logs (
      user_id,
      greenhouse_device_id,
      type,
      title,
      description
    )
    VALUES ($1, $2, $3, $4, $5)
    `,
    [
      req.user.id,
      greenhouseDeviceId,
      'system',
      'Beállítások módosítva',
      'Az automata vezérléshez használt határértékek frissítve lettek.',
    ]
  );

  res.json(result.rows[0]);
});

module.exports = router;