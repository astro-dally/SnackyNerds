# 🍿 SnackyNerds

SnackyNerds is a premium, high-energy snack shop experience for true nerds. Fuel your brain with our crunchy collection, manage your loot in the cart, and pay using **Snacky Coins** 🪙.

## 🚀 Features

- **Dynamic Snack Grid**: Explore our curated collection of snacks with real-time stock and price information.
- **Snacky Wallet**: Every user starts with a stash of Snacky Coins to spend.
- **Brutal Cart & Loot Management**: Easily add or remove items from your pack.
- **Terminal Checkout**: A seamless checkout experience with balance verification.
- **Vibrant Design**: A bold, "brutal" aesthetic with smooth animations and responsive layouts.

## 🛠 Tech Stack

### Frontend
- **React (Vite)**: For a lightning-fast user interface.
- **React Router**: Multi-page navigation (Home, Cart, Checkout, Success).
- **Vanilla CSS**: Custom "brutal" design system with animations and glassmorphism.

### Backend
- **Express.js**: Robust RESTful API.
- **Prisma ORM**: Modern database access.
- **SQLite**: Local database storage for simplicity and portability.

## 📦 Project Structure

```text
SnackyNerds/
├── client/           # React frontend
│   ├── src/          # Design system, components, and pages
│   └── ...
├── server/           # Express backend
│   ├── prisma/       # Database schema and migrations
│   ├── src/          # API routes and logic
│   └── ...
└── README.md         # You are here!
```

## 🛠 Setup & Installation

### Prerequisites
- Node.js (v18+)
- npm

### 1. Backend Setup
```bash
cd server
npm install
npx prisma migrate dev --name init
npm run dev
```

### 2. Frontend Setup
```bash
cd client
npm install
npm run dev
```

The app will be available at `http://localhost:5173`. Make sure the backend is running at `http://localhost:5001`.

*Currently in progress: Making things even crazier — by @astro-dally* 🚀
