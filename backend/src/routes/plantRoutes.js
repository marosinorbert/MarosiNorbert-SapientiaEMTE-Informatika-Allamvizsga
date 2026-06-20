const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  const result = await pool.query(`
    SELECT *
    FROM plants
    ORDER BY created_at DESC
  `);

  res.json(result.rows);
});

router.post('/', async (req, res) => {
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
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
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
    ]
  );

  await pool.query(
    `
    INSERT INTO system_logs (type, title, description)
    VALUES ($1, $2, $3)
    `,
    [
      'system',
      'Új növény hozzáadva',
      `${name} hozzá lett adva a növények listájához.`,
    ]
  );

  res.status(201).json(result.rows[0]);
});

router.put('/:id', async (req, res) => {
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
    ]
  );

  res.json(result.rows[0]);
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  await pool.query(
    'DELETE FROM plants WHERE id = $1',
    [id]
  );

  res.json({ success: true });
});

module.exports = router;