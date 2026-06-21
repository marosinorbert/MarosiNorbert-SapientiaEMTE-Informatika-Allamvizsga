const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');

function localTimeSql(column, alias) {
  return `to_char(${column} AT TIME ZONE 'Europe/Bucharest', 'YYYY-MM-DD HH24:MI:SS') AS ${alias}`;
}

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
    SELECT *,
      ${localTimeSql('created_at', 'created_at_formatted')}
    FROM system_logs
    WHERE user_id = $1
    ORDER BY created_at DESC
    LIMIT 200
    `,
    [req.user.id]
  );

  res.json(result.rows);
});

router.post('/', authMiddleware, async (req, res) => {
  const { type, title, description } = req.body;

  const greenhouseDeviceId = await getUserDeviceId(req.user.id);

  const result = await pool.query(
    `
    INSERT INTO system_logs (
      user_id,
      greenhouse_device_id,
      type,
      title,
      description
    )
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
    `,
    [
      req.user.id,
      greenhouseDeviceId,
      type,
      title,
      description,
    ]
  );

  res.status(201).json(result.rows[0]);
});

module.exports = router;