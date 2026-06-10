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

  res.json(result.rows[0]);
});

module.exports = router;