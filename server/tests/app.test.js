// Tests for SnackyNerds API
const request = require('supertest');
const app = require('../src/app');

describe('GET /api/health', () => {
    it('should return 200 and status ok', async () => {
        const res = await request(app).get('/api/health');
        expect(res.statusCode).toEqual(200);
        expect(res.body).toHaveProperty('status', 'ok');
    });
});

describe('GET /api/snacks', () => {
    it('should return array of snacks', async () => {
        const res = await request(app).get('/api/snacks');
        expect(res.statusCode).toEqual(200);
        expect(Array.isArray(res.body)).toBe(true);
    });
});
