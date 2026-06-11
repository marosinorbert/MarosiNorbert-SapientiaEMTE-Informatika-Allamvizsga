const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  const result = await pool.query(`
    SELECT *
    FROM system_settings
    WHERE id = 1
  `);

  res.json(result.rows[0]);
});

router.post('/', async (req, res) => {
  const {
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
    UPDATE system_settings
    SET
      temp_min = $1,
      temp_max = $2,
      humidity_min = $3,
      humidity_max = $4,
      soil_min = $5,
      soil_max = $6,
      light_min = $7,
      light_max = $8,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = 1
    RETURNING *
    `,
    [
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

  res.json(result.rows[0]);
});

module.exports = router;