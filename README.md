# JomIn
A mobile campus events app for UTM students. Students discover events in a personalised feed, save and share them, and get help from an AI assistant choosing programmes and committee roles. Organisers publish posters with interactive link stickers and see engagement analytics. Admins approve posts and handle reports.

| Layer | Technology |
| :--- | :--- |
| **Frontend (mobile)** | Flutter (Dart) |
| **Backend (API)** | Node.js + NestJS (TypeScript) |
| **ORM** | Prisma |
| **Database** | PostgreSQL (Hosted on Supabase) |

**Repo:** https://github.com/StartupRasyid/JomIn

## Contents
1. Project structure
2. What to install
3. First-time setup (Cloud Database)
4. Running the project day to day
5. Common problems and quick fixes
6. Git workflow
7. Team conventions

*(Commands below are for Windows PowerShell. On macOS or Linux, replace `copy` with `cp` and use forward slashes in paths.)*

---

## 1. Project structure
```text
JomIn/
├── backend/            NestJS API + Prisma
│   ├── prisma/         schema.prisma and migrations
│   ├── src/            modules, controllers, services
│   └── .env            Created on First-time setup (Contains Supabase URL)
├── frontend/           Flutter app
│   ├── lib/            Dart source
│   └── android/        Android build config
├── scripts/            helper scripts (for example connect-phone.ps1)
└── README.md