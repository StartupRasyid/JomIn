# JomIn

JomIn is a mobile-first campus event platform. This repository contains
the Flutter frontend and NestJS backend.

> **Project status:** The development foundation is set up. Flutter can
> communicate with the NestJS database-health endpoint. Feature
> implementation, including authentication, is still in progress.

## 1. Project structure

``` text
JomIn/
├── frontend/                 # Flutter application
│   ├── lib/
│   │   ├── core/             # Shared app infrastructure
│   │   │   ├── network/      # Dio API client and Riverpod API providers
│   │   │   ├── router/       # GoRouter configuration
│   │   │   └── theme/        # Shared theme and brand colours
│   │   └── features/         # Feature-based application code
│   │       └── auth/         # Authentication module (initial structure)
│   │           ├── data/
│   │           │   ├── models/
│   │           │   └── repositories/
│   │           ├── providers/
│   │           └── presentation/
│   │               ├── screens/
│   │               └── widgets/
│   ├── test/                 # Flutter tests
│   └── pubspec.yaml          # Flutter dependencies
└── backend/                  # NestJS API
    ├── src/                  # Backend application source
    ├── prisma/               # Prisma schema and database files
    ├── .env                  # Local environment variables (never commit)
    └── package.json          # Node.js dependencies and scripts
```

Some feature folders and backend feature modules may not exist yet. Add
them as work begins.

## 2. Prerequisites

Install: - Git - Flutter SDK (Dart is included with Flutter) - Node.js
and npm - PostgreSQL - Visual Studio Code or another code editor -
Chrome (for Flutter Web development)

Check your installations:

``` bash
git --version
flutter --version
flutter doctor
node --version
npm --version
```

## 3. Clone the repository

``` bash
git clone <GITHUB_REPOSITORY_URL>
cd <REPOSITORY_FOLDER>
```

Replace the placeholders with the actual repository URL and folder name.
Open the repository root in VS Code:

``` bash
code .
```

Do not run `git init` after cloning. The cloned repository already
contains its Git history and remote configuration.

## 4. Set up the backend

Open a terminal in the backend directory:

``` bash
cd backend
npm install
```

### Configure environment variables

Create a local `backend/.env` file. Ask the project maintainer for the
required development values. Do not copy credentials from another
person's machine or commit secrets to GitHub.

The current database connection variable is `DATABASE_URL`. For example:

``` env
DATABASE_URL="postgresql://<USERNAME>:<PASSWORD>@localhost:5432/jomin_db"
```

Replace the placeholders with your local PostgreSQL username and
password. The current development database name is `jomin_db`.

If the repository contains an `.env.example`, copy it to `.env` and fill
in the values:

``` powershell
Copy-Item .env.example .env
```

Never commit `.env`. Keep `.env.example` free of real passwords, tokens,
or other secrets.

### Create the local database

Create a PostgreSQL database named `jomin_db` if it does not already
exist. You can use pgAdmin or the PostgreSQL command line.

**Database schema changes must be coordinated with the team.** The JomIn
schema has not yet been finalized. Do not independently invent or apply
schema changes or migrations.

### Start NestJS

``` bash
npm run start:dev
```

The backend currently runs at:

-   API base: `http://localhost:3000`
-   API prefix: `/api/v1`
-   Swagger: `http://localhost:3000/api/docs`
-   Database health: `GET http://localhost:3000/api/v1/database/health`

Use the database health endpoint to check that NestJS can connect to
PostgreSQL.

## 5. Set up the Flutter frontend

Open a **separate terminal** in `frontend`:

``` bash
cd frontend
flutter pub get
```

Main packages currently used: - `flutter_riverpod` --- application state
management. - `go_router` --- application navigation. - `dio` --- HTTP
communication with the backend.

Run checks:

``` bash
flutter analyze
flutter test
```

Run the app in Chrome:

``` bash
flutter run -d chrome
```

Keep the backend terminal running while testing features that call the
API.

### Backend URL configuration

The API base URL is configured in:

``` text
frontend/lib/core/network/api_client.dart
```

The current value is:

``` text
http://localhost:3000/api/v1
```

This is suitable when Flutter Web and NestJS run on the same computer.

For Android testing, `localhost` refers to the Android device or
emulator, not the development computer. Adjust the URL for the target:

-   Android emulator: commonly `http://10.0.2.2:3000/api/v1`.
-   Physical Android device: use the development computer's LAN IP
    address; both devices must be on the same network.
-   Flutter Web on the same computer: `http://localhost:3000/api/v1`.

The backend must be reachable from the device and allow the relevant
origin/network access. Coordinate shared configuration changes and avoid
committing machine-specific URLs.

## 6. Frontend architecture: where to work

The frontend uses a **feature-first structure**. Shared infrastructure
belongs in `core/`; code for a particular JomIn module belongs in
`features/`.

### `lib/core/`

Code here is shared across features.

  -----------------------------------------------------------------------
  Folder/file                         Responsibility
  ----------------------------------- -----------------------------------
  `network/api_client.dart`           Creates the shared Dio
                                      configuration and defines the API
                                      base URL.

  `network/api_provider.dart`         Exposes the API client and shared
                                      API requests through Riverpod.

  `router/router.dart`                Defines application routes using
                                      GoRouter.

  `theme/app_theme.dart`              Defines the shared dark theme and
                                      JomIn brand colours.
  -----------------------------------------------------------------------

Avoid putting feature-specific business logic in `core/`.

### `lib/features/`

Each feature keeps its data, state and UI code together. The initial
Authentication structure is:

``` text
features/auth/
├── data/
│   ├── models/        # Data models and serialization
│   └── repositories/  # Authentication API operations
├── providers/         # Riverpod providers and authentication state
└── presentation/
    ├── screens/      # Full pages/screens
    └── widgets/      # Reusable UI components for this feature
```

Responsibilities: - **Models:** represent data exchanged with the API,
such as user information and authentication responses. -
**Repositories:** call the backend through the shared API client and
provide feature-level data operations. - **Providers:** expose and
manage feature state using Riverpod. - **Screens:** compose the UI for a
full page. - **Widgets:** contain smaller reusable UI components.

Keep widgets focused on presentation. Avoid putting direct HTTP requests
in screen widgets; use the feature's repository and providers instead.

### Confirmed JomIn feature modules

The current agreed scope is:

1.  Authentication
2.  Profile
3.  Post Creation & Editor (including interactive stickers)
4.  For You Feed
5.  Search & Catalogue
6.  Engagement (sharing, saving, following, etc.)
7.  AI Chatbot using Ollama
8.  Analytics
9.  Admin

Create each feature's folders as the team starts work. Follow the same
feature-first approach unless the team agrees otherwise.

## 7. Team workflow

1.  Pull the latest changes before starting:

    ``` bash
    git pull
    ```

2.  Create a branch for your task:

    ``` bash
    git switch -c feature/short-task-name
    ```

3.  Keep changes within your assigned feature where possible.

4.  Coordinate changes to shared files such as `api_client.dart`,
    `router.dart`, `app_theme.dart`, or shared backend configuration.

5.  Run checks before committing:

    ``` bash
    # Frontend
    flutter analyze
    flutter test
    ```

    For backend build and test commands, check the scripts listed in
    `backend/package.json`.

6.  Commit with a clear message:

    ``` bash
    git add .
    git commit -m "Add authentication login screen"
    ```

7.  Push your branch and open a Pull Request:

    ``` bash
    git push -u origin feature/short-task-name
    ```

Do not commit generated build folders, dependency folders, local
environment files, passwords, API keys, or personal machine
configuration. Check `.gitignore` before committing.

## 8. Important development notes

-   **Database schema:** The JomIn schema has not been finalized.
    Discuss schema changes before creating migrations or changing
    database models.
-   **Authentication:** The frontend folders are prepared, but login,
    registration, JWT handling and backend authentication are not yet
    implemented.
-   **API contract:** Coordinate endpoint paths, request fields and
    response formats between frontend and backend developers before
    integrating a feature.
-   **Ollama:** The planned AI chatbot uses Ollama through the backend.
    Flutter should communicate with NestJS rather than connect directly
    to Ollama.
-   **Secrets:** Never share or commit `.env` files, passwords, tokens
    or private keys.
-   **OneDrive on Windows:** If Flutter reports that it cannot delete
    `build/flutter_assets`, stop Flutter, close Chrome and other
    processes using the build, then retry. If needed, pause OneDrive
    syncing temporarily while building.

## 9. Quick-start checklist

After cloning, a team member should be able to:

-   [ ] Install the required tools.
-   [ ] Clone the repository.
-   [ ] Install backend dependencies with `npm install`.
-   [ ] Create their local PostgreSQL database.
-   [ ] Create and configure `backend/.env`.
-   [ ] Start NestJS with `npm run start:dev`.
-   [ ] Install frontend dependencies with `flutter pub get`.
-   [ ] Run `flutter analyze` and `flutter test`.
-   [ ] Launch Flutter with `flutter run -d chrome`.
-   [ ] Confirm the backend database-health endpoint responds.

If setup fails, share the exact command and complete error message with
the team rather than changing shared configuration blindly.
