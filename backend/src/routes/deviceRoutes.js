const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  const result = await pool.query(`
    SELECT *
    FROM device_state
    ORDER BY id
  `);

  res.json(result.rows);
});

router.post('/:device', async (req, res) => {
  const { device } = req.params;
  const { isOn } = req.body;

  const result = await pool.query(
    `
    UPDATE device_state
    SET is_on = $1,
        updated_at = CURRENT_TIMESTAMP
    WHERE device_name = $2
    RETURNING *
    `,
    [isOn, device]
  );

  const deviceLabels = {
    pump: 'Öntözőrendszer',
    light: 'Növénylámpa',
    fan: 'Szellőzés',
    heater: 'Fűtés',
  };

  const deviceLabel = deviceLabels[device] || device;

  await pool.query(
    `
  INSERT INTO system_logs (type, title, description)
  VALUES ($1, $2, $3)
  `,
    [
      'device',
      `${deviceLabel} ${isOn ? 'bekapcsolva' : 'kikapcsolva'}`,
      `Az eszköz állapota manuálisan módosítva lett.`,
    ]
  );

  res.json(result.rows[0]);
});

router.post('/:device/mode', async (req, res) => {
  const { device } = req.params;
  const { isAuto } = req.body;

  const result = await pool.query(
    `
    UPDATE device_state
    SET is_auto = $1,
        updated_at = CURRENT_TIMESTAMP
    WHERE device_name = $2
    RETURNING *
    `,
    [isAuto, device]
  );

  res.json(result.rows[0]);
});

router.post('/:device/schedule', async (req, res) => {
  const { device } = req.params;

  const {
    scheduleEnabled,
    scheduleOn,
    scheduleOff,
  } = req.body;

  const result = await pool.query(
    `
    UPDATE device_state
    SET
      schedule_enabled = $1,
      schedule_on = $2,
      schedule_off = $3,
      updated_at = CURRENT_TIMESTAMP
    WHERE device_name = $4
    RETURNING *
    `,
    [
      scheduleEnabled,
      scheduleOn,
      scheduleOff,
      device,
    ]
  );

  res.json(result.rows[0]);
});

module.exports = router;