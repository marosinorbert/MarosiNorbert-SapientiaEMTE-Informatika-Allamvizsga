const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  const result = await pool.query(`
    SELECT *
    FROM alerts
    ORDER BY created_at DESC
  `);

  res.json(result.rows);
});

router.patch('/:id/read', async (req, res) => {
  const { id } = req.params;

  await pool.query(
    `
    UPDATE alerts
    SET acknowledged = true
    WHERE id = $1
    `,
    [id]
  );

  res.json({ success: true });
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  await pool.query(
    'DELETE FROM alerts WHERE id = $1',
    [id]
  );

  res.json({
    success: true
  });
});

router.delete('/', async (req, res) => {
  await pool.query(
    'DELETE FROM alerts'
  );

  res.json({
    success: true
  });
});


module.exports = router;