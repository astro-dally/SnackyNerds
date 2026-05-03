// SnackyNerds Backend - Express + Prisma
// Simple CRUD API for our snack shop

const express = require('express');
const cors = require('cors');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const app = express();
const prisma = new PrismaClient();

// ──────────────────────────────────────────
// MIDDLEWARE
// ──────────────────────────────────────────
app.use(cors());           // Allow cross-origin requests
app.use(express.json());   // Parse JSON bodies

// ──────────────────────────────────────────
// HEALTH CHECK
// ──────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'SnackyNerds Backend is running 🍿' });
});

// ──────────────────────────────────────────
// SNACK CRUD ROUTES
// ──────────────────────────────────────────

// GET all snacks
app.get('/api/snacks', async (req, res) => {
  const snacks = await prisma.snack.findMany({ orderBy: { id: 'asc' } });
  res.json(snacks);
});

// GET single snack by ID
app.get('/api/snacks/:id', async (req, res) => {
  const snack = await prisma.snack.findUnique({
    where: { id: parseInt(req.params.id) }
  });
  if (!snack) return res.status(404).json({ error: 'Snack not found' });
  res.json(snack);
});

// CREATE new snack
app.post('/api/snacks', async (req, res) => {
  const { name, price, description, emoji, inStock } = req.body;
  const snack = await prisma.snack.create({
    data: { name, price, description, emoji, inStock }
  });
  res.status(201).json(snack);
});

// UPDATE snack
app.put('/api/snacks/:id', async (req, res) => {
  const { name, price, description, emoji, inStock } = req.body;
  try {
    const snack = await prisma.snack.update({
      where: { id: parseInt(req.params.id) },
      data: { name, price, description, emoji, inStock }
    });
    res.json(snack);
  } catch {
    res.status(404).json({ error: 'Snack not found' });
  }
});

// DELETE snack
app.delete('/api/snacks/:id', async (req, res) => {
  try {
    await prisma.snack.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'Snack deleted' });
  } catch {
    res.status(404).json({ error: 'Snack not found' });
  }
});

// ──────────────────────────────────────────
// SERVE FRONTEND (Production)
// ──────────────────────────────────────────
const publicPath = path.join(__dirname, '..', 'public');
app.use(express.static(publicPath));

// SPA fallback — serve index.html for all non-API routes
app.get('*', (req, res) => {
  const indexPath = path.join(publicPath, 'index.html');
  const fs = require('fs');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.send('🍿 SnackyNerds Backend - Grab some snacks!');
  }
});

module.exports = app;

