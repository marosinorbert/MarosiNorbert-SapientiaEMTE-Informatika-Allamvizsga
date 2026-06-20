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

router.get('/', authMiddleware, async (req, res) => {
  const result = await pool.query(
    `
    SELECT *
    FROM plants
    WHERE user_id = $1
    ORDER BY created_at DESC
    `,
    [req.user.id]
  );

  res.json(result.rows);
});

router.post('/', authMiddleware, async (req, res) => {
  const {
    name,
    species,
    emoji,
    tempMin,
    tempMax,
    humidityMin,
    humidityMax,
    soilMin,
    soilMax,
    lightMin,
    lightMax,
  } = req.body;

  const result = await pool.query(
    `
    INSERT INTO plants (
      user_id,
      name,
      species,
      emoji,
      temp_min,
      temp_max,
      humidity_min,
      humidity_max,
      soil_min,
      soil_max,
      light_min,
      light_max
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
    RETURNING *
    `,
    [
      req.user.id,
      name,
      species || 'Ismeretlen fajta',
      emoji || '🌱',
      tempMin,
      tempMax,
      humidityMin,
      humidityMax,
      soilMin,
      soilMax,
      lightMin,
      lightMax,
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
      'Új növény hozzáadva',
      `${name} hozzá lett adva a növények listájához.`,
    ]
  );

  res.status(201).json(result.rows[0]);
});

router.put('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  const {
    name,
    species,
    emoji,
    tempMin,
    tempMax,
    humidityMin,
    humidityMax,
    soilMin,
    soilMax,
    lightMin,
    lightMax,
  } = req.body;

  const result = await pool.query(
    `
    UPDATE plants
    SET
      name = $1,
      species = $2,
      emoji = $3,
      temp_min = $4,
      temp_max = $5,
      humidity_min = $6,
      humidity_max = $7,
      soil_min = $8,
      soil_max = $9,
      light_min = $10,
      light_max = $11,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $12
    AND user_id = $13
    RETURNING *
    `,
    [
      name,
      species || 'Ismeretlen fajta',
      emoji || '🌱',
      tempMin,
      tempMax,
      humidityMin,
      humidityMax,
      soilMin,
      soilMax,
      lightMin,
      lightMax,
      id,
      req.user.id,
    ]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({
      message: 'A növény nem található ennél a felhasználónál.',
    });
  }

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
      'Növény módosítva',
      `${name} adatai módosítva lettek.`,
    ]
  );

  res.json(result.rows[0]);
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  const plantResult = await pool.query(
    `
    SELECT name
    FROM plants
    WHERE id = $1
    AND user_id = $2
    `,
    [id, req.user.id]
  );

  if (plantResult.rows.length === 0) {
    return res.status(404).json({
      message: 'A növény nem található ennél a felhasználónál.',
    });
  }

  await pool.query(
    `
    DELETE FROM plants
    WHERE id = $1
    AND user_id = $2
    `,
    [id, req.user.id]
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
      'Növény törölve',
      `${plantResult.rows[0].name} törölve lett a növények közül.`,
    ]
  );

  res.json({ success: true });
});

module.exports = router;