const request = require('supertest');

// Mock Prisma Client before importing app
const mockSnack = {
    findMany: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
};

jest.mock('@prisma/client', () => {
    return {
        PrismaClient: jest.fn(() => ({
            snack: mockSnack,
        })),
    };
});

const app = require('../src/app');

describe('SnackyNerds API', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('GET /api/health', () => {
        it('should return 200 and status ok', async () => {
            const res = await request(app).get('/api/health');
            expect(res.statusCode).toEqual(200);
            expect(res.body).toEqual({ status: 'ok', message: 'SnackyNerds Backend is running 🍿' });
        });
    });

    describe('GET /api/snacks', () => {
        it('should return all snacks', async () => {
            const mockSnacks = [
                { id: 1, name: 'Chips', price: 10 },
                { id: 2, name: 'Soda', price: 5 }
            ];
            mockSnack.findMany.mockResolvedValue(mockSnacks);

            const res = await request(app).get('/api/snacks');
            expect(res.statusCode).toEqual(200);
            expect(res.body).toEqual(mockSnacks);
            expect(mockSnack.findMany).toHaveBeenCalledWith({ orderBy: { id: 'asc' } });
        });
    });

    describe('GET /api/snacks/:id', () => {
        it('should return a snack if found', async () => {
            const mockSnackItem = { id: 1, name: 'Chips', price: 10 };
            mockSnack.findUnique.mockResolvedValue(mockSnackItem);

            const res = await request(app).get('/api/snacks/1');
            expect(res.statusCode).toEqual(200);
            expect(res.body).toEqual(mockSnackItem);
            expect(mockSnack.findUnique).toHaveBeenCalledWith({ where: { id: 1 } });
        });

        it('should return 404 if snack not found', async () => {
            mockSnack.findUnique.mockResolvedValue(null);

            const res = await request(app).get('/api/snacks/999');
            expect(res.statusCode).toEqual(404);
            expect(res.body).toEqual({ error: 'Snack not found' });
        });
    });

    describe('POST /api/snacks', () => {
        it('should create a new snack', async () => {
            const newSnack = { name: 'Popcorn', price: 8, description: 'Butter', emoji: '🍿', inStock: true };
            const createdSnack = { id: 3, ...newSnack };
            mockSnack.create.mockResolvedValue(createdSnack);

            const res = await request(app).post('/api/snacks').send(newSnack);
            expect(res.statusCode).toEqual(201);
            expect(res.body).toEqual(createdSnack);
            expect(mockSnack.create).toHaveBeenCalledWith({ data: newSnack });
        });
    });

    describe('PUT /api/snacks/:id', () => {
        it('should update a snack', async () => {
            const updateData = { name: 'Popcorn XL', price: 12 };
            const updatedSnack = { id: 3, ...updateData };
            mockSnack.update.mockResolvedValue(updatedSnack);

            const res = await request(app).put('/api/snacks/3').send(updateData);
            expect(res.statusCode).toEqual(200);
            expect(res.body).toEqual(updatedSnack);
        });

        it('should return 404 if updating non-existent snack', async () => {
            mockSnack.update.mockRejectedValue(new Error('Record to update not found'));

            const res = await request(app).put('/api/snacks/999').send({ name: 'Ghost' });
            expect(res.statusCode).toEqual(404);
            expect(res.body).toEqual({ error: 'Snack not found' });
        });
    });

    describe('DELETE /api/snacks/:id', () => {
        it('should delete a snack', async () => {
            mockSnack.delete.mockResolvedValue({ id: 1 });

            const res = await request(app).delete('/api/snacks/1');
            expect(res.statusCode).toEqual(200);
            expect(res.body).toEqual({ message: 'Snack deleted' });
        });

        it('should return 404 if deleting non-existent snack', async () => {
            mockSnack.delete.mockRejectedValue(new Error('Record to delete not found'));

            const res = await request(app).delete('/api/snacks/999');
            expect(res.statusCode).toEqual(404);
            expect(res.body).toEqual({ error: 'Snack not found' });
        });
    });
});
