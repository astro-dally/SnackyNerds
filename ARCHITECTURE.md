# 🏗️ SnackyNerds - Architecture

**Full-Stack E-Commerce App** | React (Vite) • Express • Prisma • SQLite

## Tech Stack

- **Frontend**: React 18 + React Router + CSS Design System
- **Backend**: Express.js + Prisma ORM + SQLite
- **Testing**: Vitest + Jest + Playwright
- **DevOps**: GitHub Actions + AWS EC2

## System Flow

```
Browser (React SPA)
    ↓ HTTP/REST
Express API
    ↓ Prisma ORM
SQLite Database
```

---

## Frontend Structure

**Components**: App.jsx (routing + state) • SnackCard.jsx (reusable)
**State Management**: React hooks + localStorage for wallet/cart persistence
**Styling**: Vanilla CSS with design system tokens (colors, animations)
**Key Features**:

- Multi-page routing (Home, Cart, Checkout, Success)
- Real-time cart updates
- Snacky Coins wallet with localStorage persistence

---

## Backend Structure

**API Endpoints**:

- `GET /api/health` - Server status
- `GET /api/snacks` - List all snacks
- `GET /api/snacks/:id` - Single snack
- `POST /api/snacks` - Create snack

**Database**: SQLite with Prisma ORM

```prisma
model Snack {
  id          Int     @id @default(autoincrement())
  name        String  @unique
  price       Int
  emoji       String
  description String
  inStock     Boolean @default(true)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}
```

**Tech Choices**:

- Express: Lightweight, simple REST API
- Prisma: Type-safe ORM with auto-migrations
- SQLite: Zero-config database, perfect for MVP

---

## Design Decisions

| Decision             | Why                                | Alternative              |
| -------------------- | ---------------------------------- | ------------------------ |
| React + Vite         | Component reuse, modern build tool | Vanilla HTML/Vue/Angular |
| Express.js           | Lightweight, simple REST API       | Django/Rails/FastAPI     |
| Prisma ORM           | Type-safe, auto-migrations         | Raw SQL/Sequelize        |
| SQLite               | Zero setup, perfect for MVP        | PostgreSQL/MySQL         |
| Hooks + localStorage | Simple state management            | Redux/Zustand            |
| GitHub Actions       | Native to GitHub, free tier        | Jenkins/GitLab CI        |
| EC2 Deployment       | AWS familiar, scalable             | Heroku/DigitalOcean      |

---

## Key Features

**Snacky Coins Wallet**: Start with 50 coins, spend on snacks, persisted in localStorage

**Snack Hunt**: Hidden daily snack (deterministic hash based on date) grants 15 bonus coins

**Shopping Cart**: Add/remove snacks, calculate total, checkout with coin deduction

---

## Challenges & Solutions

| Challenge                   | Solution                                         |
| --------------------------- | ------------------------------------------------ |
| Mocking API in tests        | Use `vi.fn()` in Vitest to mock fetch            |
| E2E testing with mocked API | Playwright's `page.route()` intercepts requests  |
| Idempotent EC2 deployment   | Check state before action (skip if already done) |
| Cart state on page reload   | Store cart in localStorage, restore on mount     |
| Testing async API calls     | Use `waitFor()` from React Testing Library       |

---

## Deployment

**GitHub Actions Workflow** (.github/workflows/deploy.yml):

1. Checkout code
2. Setup Node.js v20
3. Build client (vite build)
4. Install server dependencies
5. SSH into EC2
6. Clone/pull latest repository code
7. Start server in background
8. Health check (verify running)
9. Cleanup SSH keys

**Idempotency**: Check state before action (skip if already in desired state)

**Deployment Flow**: Push to main → Tests pass → Auto-deploy to EC2

---

## Testing Strategy

**Test Pyramid**:

- **Unit** (Vitest/Jest): Fast, many tests, catch logic errors
- **Integration** (Jest + Supertest): API contracts, component interaction
- **E2E** (Playwright): Real browser, complete user flows

**Test Files**:

- Client: `client/src/App.test.jsx`, `client/src/components/SnackCard.test.jsx`
- Server: `server/tests/app.test.js`
- E2E: `client/tests/e2e/shop.spec.js`

---

## Lessons Learned

**Went Well**:

- ✅ Hooks-based architecture (simple, powerful, reusable)
- ✅ Test pyramid (caught different issues at each layer)
- ✅ GitHub Actions automation (eliminated manual deployment)
- ✅ Simple stack (avoided over-engineering for MVP)

**Could Improve**:

- Database migrations (currently only initial setup)
- Error handling (basic 404s, could add validation)
- Authentication (not in MVP scope)
- Structured logging (need centralized logging service)

## Tech Stack

| Layer                 | Technology        | Why?                             |
| --------------------- | ----------------- | -------------------------------- |
| Frontend              | React 18 + Vite   | Component reuse, fast dev server |
| Routing               | React Router 7.12 | Multi-page SPA support           |
| Backend               | Express.js 4.19   | Lightweight REST API             |
| ORM                   | Prisma 6.19       | Type-safe, auto-migrations       |
| Database              | SQLite            | Zero-config, perfect for MVP     |
| Testing (Unit)        | Vitest 4.0        | ESM-native, blazing fast         |
| Testing (Integration) | Jest 29.7         | Node.js standard                 |
| Testing (E2E)         | Playwright 1.58   | Real browser testing             |
| Linting               | ESLint 8.57       | Code quality                     |
| Formatting            | Prettier 3.0      | Auto code formatting             |
| CI/CD                 | GitHub Actions    | Native, free, simple             |
| Deployment            | AWS EC2           | Scalable, familiar               |

## Summary

SnackyNerds demonstrates **full-stack development** with:

- ✅ Modern frontend (React + CSS design system)
- ✅ Simple backend (Express REST API)
- ✅ Type-safe database (Prisma + SQLite)
- ✅ Comprehensive testing (unit, integration, E2E)
- ✅ Automated CI/CD (GitHub Actions)
- ✅ Production deployment (EC2 + SSH)
- ✅ Code quality (linting, formatting)
- ✅ Version control best practices (meaningful commits)

This is a **professional, scalable foundation** for an e-commerce app.

---

**Last Updated**: March 20, 2026
