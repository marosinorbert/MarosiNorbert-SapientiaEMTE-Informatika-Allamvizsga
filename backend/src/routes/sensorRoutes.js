const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');
const deviceMiddleware = require('../middleware/deviceMiddleware');
const {
  isValidNumber,
  validateBoolean,
} = require('../utils/validation');


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
    VALUES ($1, 18, 28, 50, 75, 35, 80, 30, 80, false, 'hu', '°C')
    RETURNING *
    `,
    [userId]
  );

  return created.rows[0];
}

function localTimeSql(column, alias) {
  return `to_char(${column} AT TIME ZONE 'Europe/Bucharest', 'YYYY-MM-DD HH24:MI:SS') AS ${alias}`;
}

function mapSensorRow(row) {
  return {
    id: row.id,
    temperature: Number(row.temperature),
    humidity: Number(row.humidity),
    soilMoisture: Number(row.soil_moisture),
    lightIntensity: Number(row.light_intensity ?? 0),
    lightRaw: Number(row.light_raw ?? 0),
    waterAvailable: row.water_detected,
    lightOn: row.light_on,
    pumpOn: row.pump_on,
    createdAt: row.created_at,
    createdAtFormatted: row.created_at_formatted,
  };
}

function escapeCsv(value) {
  if (value === null || value === undefined) {
    return '';
  }

  const stringValue = value.toString();

  if (
    stringValue.includes(';') ||
    stringValue.includes('"') ||
    stringValue.includes('\n')
  ) {
    return `"${stringValue.replace(/"/g, '""')}"`;
  }

  return stringValue;
}

router.get('/export/csv', authMiddleware, async (req, res) => {
  const { days, today } = req.query;

  let result;

  if (today === 'true') {
    result = await pool.query(
      `
      SELECT *,
        ${localTimeSql('created_at', 'created_at_formatted')}
      FROM sensor_data
      WHERE user_id = $1
      AND created_at >= CURRENT_DATE
      AND created_at < CURRENT_DATE + INTERVAL '1 day'
      ORDER BY created_at ASC
      `,
      [req.user.id]
    );
  } else {
    const parsedDays = Math.max(parseInt(days, 10) || 7, 1);

    result = await pool.query(
      `
      SELECT *,
        ${localTimeSql('created_at', 'created_at_formatted')}
      FROM sensor_data
      WHERE user_id = $1
      AND created_at >= NOW() - ($2 * INTERVAL '1 day')
      ORDER BY created_at ASC
      `,
      [req.user.id, parsedDays]
    );
  }

  const header = [
    'id',
    'datum',
    'homerseklet_c',
    'paratartalom_szazalek',
    'talajnedvesseg_szazalek',
    'fenyerosseg_szazalek',
    'fenyerosseg_raw',
    'viz_elerheto',
    'lampa_bekapcsolva',
    'pumpa_bekapcsolva',
  ];

  const rows = result.rows.map((row) => [
    row.id,
    row.created_at_formatted,
    row.temperature,
    row.humidity,
    row.soil_moisture,
    row.light_intensity,
    row.light_raw,
    row.water_detected,
    row.light_on,
    row.pump_on,
  ]);

  const csvLines = [
    header.join(';'),
    ...rows.map((row) => row.map(escapeCsv).join(';')),
  ];

  const csvContent = `\uFEFF${csvLines.join('\n')}`;

  const fileName = today === 'true'
    ? 'szenzoradatok_ma.csv'
    : `szenzoradatok_${days || 7}_nap.csv`;

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="${fileName}"`
  );

  res.send(csvContent);
});

router.get('/history', authMiddleware, async (req, res) => {
  const { hours, days, today } = req.query;

  let result;

  if (today === 'true') {
    result = await pool.query(
      `
      SELECT *,
        ${localTimeSql('created_at', 'created_at_formatted')}
      FROM sensor_data
      WHERE user_id = $1
      AND created_at >= CURRENT_DATE
      AND created_at < CURRENT_DATE + INTERVAL '1 day'
      ORDER BY created_at ASC
      `,
      [req.user.id]
    );
  } else if (days) {
    const parsedDays = Math.max(parseInt(days, 10) || 1, 1);

    result = await pool.query(
      `
      SELECT *,
        ${localTimeSql('created_at', 'created_at_formatted')}
      FROM sensor_data
      WHERE user_id = $1
      AND created_at >= NOW() - ($2 * INTERVAL '1 day')
      ORDER BY created_at ASC
      `,
      [req.user.id, parsedDays]
    );
  } else {
    const parsedHours = Math.max(parseInt(hours, 10) || 24, 1);

    result = await pool.query(
      `
      SELECT *,
        ${localTimeSql('created_at', 'created_at_formatted')}
      FROM sensor_data
      WHERE user_id = $1
      AND created_at >= NOW() - ($2 * INTERVAL '1 hour')
      ORDER BY created_at ASC
      `,
      [req.user.id, parsedHours]
    );
  }

  res.json(result.rows.map(mapSensorRow));
});

router.get('/', authMiddleware, async (req, res) => {
  const result = await pool.query(
    `
    SELECT *,
      ${localTimeSql('created_at', 'created_at_formatted')}
    FROM sensor_data
    WHERE user_id = $1
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [req.user.id]
  );

  if (result.rows.length === 0) {
    return res.json({
      createdAt: null,
      createdAtFormatted: null,
      temperature: 0,
      humidity: 0,
      soilMoisture: 0,
      lightIntensity: 0,
      lightRaw: 0,
      waterAvailable: true,
      lightOn: false,
      pumpOn: false,
    });
  }

  res.json(mapSensorRow(result.rows[0]));
});

router.post('/', deviceMiddleware, async (req, res) => {
  const userId = req.device.user_id;
  const greenhouseDeviceId = req.device.id;

  const {
    temperature,
    humidity,
    soilMoisture,
    lightIntensity = 0,
    lightRaw = 0,
    waterDetected = true,
    lightOn = false,
    pumpOn = false,
  } = req.body;

  const validationErrors = [];

  if (!isValidNumber(temperature)) {
    validationErrors.push('A hőmérséklet értéke kötelező és szám kell legyen.');
  }

  if (!isValidNumber(humidity)) {
    validationErrors.push('A páratartalom értéke kötelező és szám kell legyen.');
  }

  if (!isValidNumber(soilMoisture)) {
    validationErrors.push('A talajnedvesség értéke kötelező és szám kell legyen.');
  }

  if (isValidNumber(humidity) && (Number(humidity) < 0 || Number(humidity) > 100)) {
    validationErrors.push('A páratartalom 0 és 100 között lehet.');
  }

  if (
    isValidNumber(soilMoisture) &&
    (Number(soilMoisture) < 0 || Number(soilMoisture) > 100)
  ) {
    validationErrors.push('A talajnedvesség 0 és 100 között lehet.');
  }

  if (!isValidNumber(lightIntensity)) {
    validationErrors.push('A fényerő értéke kötelező és szám kell legyen.');
  }

  if (
    isValidNumber(lightIntensity) &&
    (Number(lightIntensity) < 0 || Number(lightIntensity) > 100)
  ) {
    validationErrors.push('A fényerő 0 és 100 között lehet.');
  }

  if (
    isValidNumber(lightRaw) &&
    (Number(lightRaw) < 0 || Number(lightRaw) > 4095)
  ) {
    validationErrors.push('A nyers fényerő érték 0 és 4095 között lehet.');
  }

  const waterDetectedError = validateBoolean(waterDetected, 'Víztartály állapot');
  const lightOnError = validateBoolean(lightOn, 'Lámpa állapot');
  const pumpOnError = validateBoolean(pumpOn, 'Pumpa állapot');

  if (waterDetectedError) validationErrors.push(waterDetectedError);
  if (lightOnError) validationErrors.push(lightOnError);
  if (pumpOnError) validationErrors.push(pumpOnError);

  if (validationErrors.length > 0) {
    return res.status(400).json({
      message: validationErrors[0],
      errors: validationErrors,
    });
  }

  const result = await pool.query(
    `
    INSERT INTO sensor_data 
    (
      user_id,
      greenhouse_device_id,
      temperature,
      humidity,
      soil_moisture,
      light_intensity,
      light_raw,
      water_detected,
      light_on,
      pump_on
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING *
    `,
    [
      userId,
      greenhouseDeviceId,
      temperature,
      humidity,
      soilMoisture,
      lightIntensity,
      lightRaw,
      waterDetected,
      lightOn,
      pumpOn,
    ]
  );

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
      userId,
      greenhouseDeviceId,
      'sensor',
      'Új szenzoradat érkezett',
      `Hőmérséklet: ${temperature}°C, páratartalom: ${humidity}%, talajnedvesség: ${soilMoisture}%, fényerő: ${lightIntensity}%.`,
    ]
  );

  const settings = await getOrCreateSettings(userId);

  async function createAlertIfNeeded(title, message, severity, sensor) {
    const existing = await pool.query(
      `
      SELECT id
      FROM alerts
      WHERE user_id = $1
      AND greenhouse_device_id = $2
      AND title = $3
      AND acknowledged = false
      LIMIT 1
      `,
      [userId, greenhouseDeviceId, title]
    );

    if (existing.rows.length === 0) {
      await pool.query(
        `
        INSERT INTO alerts (
          user_id,
          greenhouse_device_id,
          title,
          message,
          severity,
          sensor
        )
        VALUES ($1, $2, $3, $4, $5, $6)
        `,
        [
          userId,
          greenhouseDeviceId,
          title,
          message,
          severity,
          sensor,
        ]
      );

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
          userId,
          greenhouseDeviceId,
          'alert',
          title,
          message,
        ]
      );
    }
  }

  async function updateDeviceStateIfAuto(deviceName, isOn) {
    await pool.query(
      `
      UPDATE device_state
      SET is_on = $1,
          updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $2
      AND greenhouse_device_id = $3
      AND device_name = $4
      AND is_auto = true
      `,
      [
        isOn,
        userId,
        greenhouseDeviceId,
        deviceName,
      ]
    );
  }

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

  // Lámpa automatika
  if (Number(lightIntensity) < Number(settings.light_min)) {
    await updateDeviceStateIfAuto('light', true);

    await createAlertIfNeeded(
      'Automatikus világítás bekapcsolva',
      `A fényerő ${lightIntensity}%, ezért a rendszer bekapcsolta a növénylámpát.`,
      'warning',
      'Fényerő'
    );
  }

  if (Number(lightIntensity) >= Number(settings.light_max)) {
    await updateDeviceStateIfAuto('light', false);

    await createAlertIfNeeded(
      'Automatikus világítás kikapcsolva',
      `A fényerő ${lightIntensity}%, ezért a rendszer kikapcsolta a növénylámpát.`,
      'ok',
      'Fényerő'
    );
  }

  res.status(201).json({
    message: 'Sensor data saved',
    data: result.rows[0],
  });
});

module.exports = router;