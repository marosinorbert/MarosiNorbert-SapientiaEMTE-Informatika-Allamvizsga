const express = require('express');
const router = express.Router();
const pool = require('../db');

function formatDate(row) {
  return row.created_at_formatted;
}

router.get('/history', async (req, res) => {
<<<<<<< Updated upstream
  const result = await pool.query(`
    SELECT *
    FROM sensor_data
    WHERE created_at >= NOW() - INTERVAL '24 hours'
=======
  const { today, hours, days } = req.query;

  let query = `
  SELECT *,
    TO_CHAR(
      created_at + INTERVAL '3 hours',
      'YYYY. MM. DD. HH24:MI:SS'
    ) AS created_at_formatted
  FROM sensor_data
`;

  if (today === 'true') {
    query += `
      WHERE created_at >= DATE_TRUNC('day', NOW())
      AND created_at < DATE_TRUNC('day', NOW()) + INTERVAL '1 day'
    `;
  } else if (days) {
    query += `
      WHERE created_at >= NOW() - INTERVAL '${parseInt(days)} days'
    `;
  } else if (hours) {
    query += `
      WHERE created_at >= NOW() - INTERVAL '${parseInt(hours)} hours'
    `;
  } else {
    query += `
      WHERE created_at >= DATE_TRUNC('day', NOW())
      AND created_at < DATE_TRUNC('day', NOW()) + INTERVAL '1 day'
    `;
  }

  query += `
>>>>>>> Stashed changes
    ORDER BY created_at ASC
  `;

  const result = await pool.query(query);

  const data = result.rows.map(row => ({
    id: row.id,
    temperature: Number(row.temperature),
    humidity: Number(row.humidity),
    soilMoisture: Number(row.soil_moisture),
<<<<<<< Updated upstream
=======
    waterDetected: row.water_detected,
>>>>>>> Stashed changes
    lightOn: row.light_on,
    pumpOn: row.pump_on,
    createdAt: row.created_at,
    createdAtFormatted: row.created_at_formatted,
  }));

  res.json(data);
});

router.get('/', async (req, res) => {
  const result = await pool.query(`
SELECT *,
  TO_CHAR(
    created_at + INTERVAL '3 hours',
    'YYYY. MM. DD. HH24:MI:SS'
  ) AS created_at_formatted
FROM sensor_data
ORDER BY created_at DESC
LIMIT 1
  `);

  if (result.rows.length === 0) {
    return res.json({
      temperature: 0,
      humidity: 0,
      soilMoisture: 0,
      lightOn: false,
      pumpOn: false,
    });
  }

  const row = result.rows[0];

  res.json({
    temperature: Number(row.temperature),
    humidity: Number(row.humidity),
    soilMoisture: Number(row.soil_moisture),
    lightOn: row.light_on,
    pumpOn: row.pump_on,
    createdAt: row.created_at,
    createdAtFormatted: row.created_at_formatted,
  });
});

router.post('/', async (req, res) => {
  const {
    temperature,
    humidity,
    soilMoisture,
    lightOn = false,
    pumpOn = false,
  } = req.body;

  const result = await pool.query(
    `
    INSERT INTO sensor_data 
    (temperature, humidity, soil_moisture, light_on, pump_on)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
    `,
    [temperature, humidity, soilMoisture, lightOn, pumpOn]
  );

  res.status(201).json({
    message: 'Sensor data saved',
    data: result.rows[0],
  });
});

module.exports = router;