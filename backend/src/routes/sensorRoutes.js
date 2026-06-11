const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/history', async (req, res) => {
  const { hours, days } = req.query;

  let interval = '24 hours';

  if (days) {
    interval = `${parseInt(days)} days`;
  }

  if (hours) {
    interval = `${parseInt(hours)} hours`;
  }

  const result = await pool.query(`
    SELECT *
    FROM sensor_data
    WHERE created_at >= NOW() - INTERVAL '${interval}'
    ORDER BY created_at ASC
  `);

  const data = result.rows.map(row => ({
    id: row.id,
    temperature: Number(row.temperature),
    humidity: Number(row.humidity),
    soilMoisture: Number(row.soil_moisture),
    waterAvailable: row.water_available,
    lightOn: row.light_on,
    pumpOn: row.pump_on,
    createdAt: row.created_at,
  }));

  res.json(data);
});

router.get('/', async (req, res) => {
  const result = await pool.query(`
    SELECT *
    FROM sensor_data
    ORDER BY created_at DESC
    LIMIT 1
  `);

  if (result.rows.length === 0) {
    return res.json({
      temperature: 0,
      humidity: 0,
      soilMoisture: 0,
      waterAvailable: true,
      lightOn: false,
      pumpOn: false,
    });
  }

  const row = result.rows[0];

  res.json({
    temperature: Number(row.temperature),
    humidity: Number(row.humidity),
    soilMoisture: Number(row.soil_moisture),
    waterAvailable: row.water_available,
    lightOn: row.light_on,
    pumpOn: row.pump_on,
    createdAt: row.created_at,
  });
});

router.post('/', async (req, res) => {
  const {
    temperature,
    humidity,
    soilMoisture,
    waterDetected = true,
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
    [temperature, humidity, soilMoisture, waterDetected, lightOn, pumpOn]
  );

  await pool.query(
    `
  INSERT INTO system_logs (type, title, description)
  VALUES ($1, $2, $3)
  `,
    [
      'sensor',
      'Új szenzoradat érkezett',
      `Hőmérséklet: ${temperature}°C, páratartalom: ${humidity}%, talajnedvesség: ${soilMoisture}%.`,
    ]
  );

  const settingsResult = await pool.query(`
    SELECT *
    FROM system_settings
    WHERE id = 1
  `);

  const settings = settingsResult.rows[0];

  async function createAlertIfNeeded(title, message, severity, sensor) {
    const existing = await pool.query(
      `
      SELECT id
      FROM alerts
      WHERE title = $1
      AND acknowledged = false
      LIMIT 1
      `,
      [title]
    );

    if (existing.rows.length === 0) {
      await pool.query(
        `
        INSERT INTO alerts (title, message, severity, sensor)
        VALUES ($1, $2, $3, $4)
        `,
        [title, message, severity, sensor]
      );
    }
  }

  if (settings) {
    if (temperature > Number(settings.temp_max)) {
      await createAlertIfNeeded(
        'Hőmérséklet túl magas',
        `A mért hőmérséklet ${temperature}°C, ami magasabb a beállított ${settings.temp_max}°C határértéknél.`,
        'warning',
        'Hőmérséklet'
      );
    }

    if (temperature < Number(settings.temp_min)) {
      await createAlertIfNeeded(
        'Hőmérséklet túl alacsony',
        `A mért hőmérséklet ${temperature}°C, ami alacsonyabb a beállított ${settings.temp_min}°C határértéknél.`,
        'warning',
        'Hőmérséklet'
      );
    }

    if (humidity > Number(settings.humidity_max)) {
      await createAlertIfNeeded(
        'Páratartalom túl magas',
        `A mért páratartalom ${humidity}%, ami magasabb a beállított ${settings.humidity_max}% határértéknél.`,
        'warning',
        'Páratartalom'
      );
    }

    if (humidity < Number(settings.humidity_min)) {
      await createAlertIfNeeded(
        'Páratartalom túl alacsony',
        `A mért páratartalom ${humidity}%, ami alacsonyabb a beállított ${settings.humidity_min}% határértéknél.`,
        'warning',
        'Páratartalom'
      );
    }

    if (soilMoisture > Number(settings.soil_max)) {
      await createAlertIfNeeded(
        'Talajnedvesség túl magas',
        `A mért talajnedvesség ${soilMoisture}%, ami magasabb a beállított ${settings.soil_max}% határértéknél.`,
        'warning',
        'Talajnedvesség'
      );
    }

    if (soilMoisture < Number(settings.soil_min)) {
      await createAlertIfNeeded(
        'Talajnedvesség túl alacsony',
        `A mért talajnedvesség ${soilMoisture}%, ami alacsonyabb a beállított ${settings.soil_min}% határértéknél.`,
        'critical',
        'Talajnedvesség'
      );
    }

    if (!waterDetected) {
      await createAlertIfNeeded(
        'Nincs víz a tartályban',
        'Az öntözőrendszer víztartályában nincs elegendő víz. Az öntözés letiltva.',
        'critical',
        'Víztartály'
      );
    }
  }

  async function updateDeviceStateIfAuto(deviceName, isOn) {
    await pool.query(
      `
    UPDATE device_state
    SET is_on = $1,
        updated_at = CURRENT_TIMESTAMP
    WHERE device_name = $2
    AND is_auto = true
    `,
      [isOn, deviceName]
    );
  }

  if (settings) {
    // Öntözés automatika
    if (soilMoisture < Number(settings.soil_min) && waterDetected) {
      await updateDeviceStateIfAuto('pump', true);

      await createAlertIfNeeded(
        'Automatikus öntözés bekapcsolva',
        `A talajnedvesség ${soilMoisture}%, ezért a rendszer bekapcsolta az öntözést.`,
        'warning',
        'Öntözőrendszer'
      );
    }

    if (soilMoisture >= Number(settings.soil_max)) {
      await updateDeviceStateIfAuto('pump', false);

      await createAlertIfNeeded(
        'Automatikus öntözés kikapcsolva',
        `A talajnedvesség ${soilMoisture}%, ezért a rendszer kikapcsolta az öntözést.`,
        'ok',
        'Öntözőrendszer'
      );
    }

    // Szellőzés automatika
    if (temperature > Number(settings.temp_max)) {
      await updateDeviceStateIfAuto('fan', true);

      await createAlertIfNeeded(
        'Automatikus szellőzés bekapcsolva',
        `A hőmérséklet ${temperature}°C, ezért a rendszer bekapcsolta a szellőzést.`,
        'warning',
        'Szellőzés'
      );
    }

    if (temperature <= Number(settings.temp_max) - 1) {
      await updateDeviceStateIfAuto('fan', false);
    }

    // Fűtés automatika
    if (temperature < Number(settings.temp_min)) {
      await updateDeviceStateIfAuto('heater', true);

      await createAlertIfNeeded(
        'Automatikus fűtés bekapcsolva',
        `A hőmérséklet ${temperature}°C, ezért a rendszer bekapcsolta a fűtést.`,
        'warning',
        'Fűtés'
      );
    }

    if (temperature >= Number(settings.temp_min) + 1) {
      await updateDeviceStateIfAuto('heater', false);
    }
  }

  res.status(201).json({
    message: 'Sensor data saved',
    data: result.rows[0],
  });
});

module.exports = router;