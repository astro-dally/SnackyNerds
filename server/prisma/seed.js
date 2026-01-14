// Seed file - populates database with fun snacks
// Run with: npx prisma db seed

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Our delicious snack catalog 🍿
const snacks = [
  { name: 'Cheese Puffs', price: 3.99, emoji: '🧀', description: 'Crunchy, cheesy clouds of joy' },
  { name: 'Spicy Chips', price: 2.49, emoji: '🌶️', description: 'Hot and crispy potato goodness' },
  { name: 'Gummy Bears', price: 1.99, emoji: '🐻', description: 'Squishy fruity friends' },
  { name: 'Popcorn', price: 4.49, emoji: '🍿', description: 'Buttery movie night essential' },
  { name: 'Pretzels', price: 2.99, emoji: '🥨', description: 'Salty twisted perfection' },
  { name: 'Chocolate Bar', price: 1.49, emoji: '🍫', description: 'Rich and creamy delight' },
  { name: 'Cookie Pack', price: 3.49, emoji: '🍪', description: 'Fresh-baked happiness' },
  { name: 'Donut Box', price: 5.99, emoji: '🍩', description: 'Glazed rings of heaven' },
];

async function main() {
  console.log('🌱 Seeding snacks...');
  
  // Clear existing snacks and add fresh ones
  await prisma.snack.deleteMany();
  
  for (const snack of snacks) {
    await prisma.snack.create({ data: snack });
  }
  
  console.log(`✅ Seeded ${snacks.length} snacks!`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
