const express = require('express');
const router = express.Router();
const pool = require('../db');

router.get('/', async (req, res) => {
  const result = await pool.query(`
    SELECT *
    FROM system_logs
    ORDER BY created_at DESC
    LIMIT 200
  `);

  res.json(result.rows);
});

router.post('/', async (req, res) => {
  const { type, title, description } = req.body;

  const result = await pool.query(
    `
    INSERT INTO system_logs (type, title, description)
    VALUES ($1, $2, $3)
    RETURNING *
    `,
    [type, title, description]
  );

  res.status(201).json(result.rows[0]);
});

module.exports = router;