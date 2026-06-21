const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');
const {
  validateDeviceName,
  validateBoolean,
  validateTimeString,
} = require('../utils/validation');

async function getUserDevice(req, res) {
  const deviceResult = await pool.query(
    `
    SELECT id
    FROM greenhouse_devices
    WHERE user_id = $1
    AND is_claimed = true
    ORDER BY claimed_at DESC
    LIMIT 1
    `,
    [req.user.id]
  );

  if (deviceResult.rows.length === 0) {
    res.status(404).json({
      message: 'Nincs ESP32 eszköz hozzárendelve ehhez a fiókhoz.',
    });
    return null;
  }

  return deviceResult.rows[0];
}

router.get('/', authMiddleware, async (req, res) => {
  const device = await getUserDevice(req, res);
  if (!device) return;

  const result = await pool.query(
    `
    SELECT *
    FROM device_state
    WHERE user_id = $1
    AND greenhouse_device_id = $2
    ORDER BY id
    `,
    [req.user.id, device.id]
  );

  res.json(result.rows);
});

router.post('/:device', authMiddleware, async (req, res) => {
  const userDevice = await getUserDevice(req, res);
  if (!userDevice) return;

  const { device } = req.params;
  const { isOn } = req.body;

  const deviceError = validateDeviceName(device);
  if (deviceError) {
    return res.status(400).json({
      message: deviceError,
    });
  }

  const isOnError = validateBoolean(isOn, 'Eszköz állapot');
  if (isOnError) {
    return res.status(400).json({
      message: isOnError,
    });
  }

  const result = await pool.query(
    `
    UPDATE device_state
    SET is_on = $1,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = $2
    AND greenhouse_device_id = $3
    AND device_name = $4
    RETURNING *
    `,
    [
      isOn,
      req.user.id,
      userDevice.id,
      device,
    ]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({
      message: 'Az eszköz nem található ennél a felhasználónál.',
    });
  }

  const deviceLabels = {
    pump: 'Öntözőrendszer',
    light: 'Növénylámpa',
    fan: 'Szellőzés',
    heater: 'Fűtés',
  };

  const deviceLabel = deviceLabels[device] || device;

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
      userDevice.id,
      'device',
      `${deviceLabel} ${isOn ? 'bekapcsolva' : 'kikapcsolva'}`,
      'Az eszköz állapota manuálisan módosítva lett.',
    ]
  );

  res.json(result.rows[0]);
});

router.post('/:device/mode', authMiddleware, async (req, res) => {
  const userDevice = await getUserDevice(req, res);
  if (!userDevice) return;

  const { device } = req.params;
  const { isAuto } = req.body;

  const deviceError = validateDeviceName(device);
  if (deviceError) {
    return res.status(400).json({
      message: deviceError,
    });
  }

  const isAutoError = validateBoolean(isAuto, 'Automata mód');
  if (isAutoError) {
    return res.status(400).json({
      message: isAutoError,
    });
  }

  const result = await pool.query(
    `
    UPDATE device_state
    SET is_auto = $1,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = $2
    AND greenhouse_device_id = $3
    AND device_name = $4
    RETURNING *
    `,
    [
      isAuto,
      req.user.id,
      userDevice.id,
      device,
    ]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({
      message: 'Az eszköz nem található ennél a felhasználónál.',
    });
  }

  const deviceLabels = {
    pump: 'Öntözőrendszer',
    light: 'Növénylámpa',
    fan: 'Szellőzés',
    heater: 'Fűtés',
  };

  const deviceLabel = deviceLabels[device] || device;

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
      userDevice.id,
      'device',
      `${deviceLabel} mód módosítva`,
      `Az eszköz módja ${isAuto ? 'automata' : 'manuális'} módra lett állítva.`,
    ]
  );

  res.json(result.rows[0]);
});

router.post('/:device/schedule', authMiddleware, async (req, res) => {
  const userDevice = await getUserDevice(req, res);
  if (!userDevice) return;

  const { device } = req.params;

  const {
    scheduleEnabled,
    scheduleOn,
    scheduleOff,
  } = req.body;

  const deviceError = validateDeviceName(device);
  if (deviceError) {
    return res.status(400).json({
      message: deviceError,
    });
  }

  const scheduleEnabledError = validateBoolean(
    scheduleEnabled,
    'Ütemezés állapota'
  );

  if (scheduleEnabledError) {
    return res.status(400).json({
      message: scheduleEnabledError,
    });
  }

  const scheduleOnError = validateTimeString(scheduleOn, 'Bekapcsolási idő');
  const scheduleOffError = validateTimeString(scheduleOff, 'Kikapcsolási idő');

  const validationErrors = [
    scheduleOnError,
    scheduleOffError,
  ].filter(Boolean);

  if (validationErrors.length > 0) {
    return res.status(400).json({
      message: validationErrors[0],
      errors: validationErrors,
    });
  }

  if (scheduleOn === scheduleOff) {
    return res.status(400).json({
      message: 'A bekapcsolási és kikapcsolási idő nem lehet ugyanaz.',
    });
  }

  const result = await pool.query(
    `
    UPDATE device_state
    SET
      schedule_enabled = $1,
      schedule_on = $2,
      schedule_off = $3,
      updated_at = CURRENT_TIMESTAMP
    WHERE user_id = $4
    AND greenhouse_device_id = $5
    AND device_name = $6
    RETURNING *
    `,
    [
      scheduleEnabled,
      scheduleOn,
      scheduleOff,
      req.user.id,
      userDevice.id,
      device,
    ]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({
      message: 'Az eszköz nem található ennél a felhasználónál.',
    });
  }

  const deviceLabels = {
    pump: 'Öntözőrendszer',
    light: 'Növénylámpa',
    fan: 'Szellőzés',
    heater: 'Fűtés',
  };

  const deviceLabel = deviceLabels[device] || device;

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
      userDevice.id,
      'device',
      `${deviceLabel} ütemezés módosítva`,
      `Új ütemezés: ${scheduleEnabled ? 'bekapcsolva' : 'kikapcsolva'}, ${scheduleOn} - ${scheduleOff}.`,
    ]
  );

  res.json(result.rows[0]);
});

module.exports = router;