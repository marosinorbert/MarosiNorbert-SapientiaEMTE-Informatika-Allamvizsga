const express = require('express');
const router = express.Router();
const pool = require('../db');
const authMiddleware = require('../middleware/authMiddleware');

function localTimeSql(column, alias) {
  return `to_char(${column} AT TIME ZONE 'Europe/Bucharest', 'YYYY-MM-DD HH24:MI:SS') AS ${alias}`;
}

router.get('/', authMiddleware, async (req, res) => {
  const result = await pool.query(
    `
    SELECT *,
      ${localTimeSql('created_at', 'created_at_formatted')}
    FROM alerts
    WHERE user_id = $1
    ORDER BY created_at DESC
    `,
    [req.user.id]
  );

  res.json(result.rows);
});

router.patch('/:id/read', authMiddleware, async (req, res) => {
  const { id } = req.params;

  const result = await pool.query(
    `
    UPDATE alerts
    SET acknowledged = true
    WHERE id = $1
    AND user_id = $2
    RETURNING *
    `,
    [id, req.user.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({
      message: 'A riasztás nem található ennél a felhasználónál.',
    });
  }

  res.json({ success: true });
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  const result = await pool.query(
    `
    DELETE FROM alerts
    WHERE id = $1
    AND user_id = $2
    RETURNING *
    `,
    [id, req.user.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({
      message: 'A riasztás nem található ennél a felhasználónál.',
    });
  }

  res.json({
    success: true,
  });
});

router.delete('/', authMiddleware, async (req, res) => {
  await pool.query(
    `
    DELETE FROM alerts
    WHERE user_id = $1
    `,
    [req.user.id]
  );

  res.json({
    success: true,
  });
});

module.exports = router;