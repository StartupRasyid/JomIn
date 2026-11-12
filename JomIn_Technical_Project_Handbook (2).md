# JomIn — Technical Project Handbook

**Document type:** Developer technical reference  
**Project:** JomIn  
**Last updated:** 6 November 2026  
**Status:** Working handbook based on the project's documented architecture, setup discussions, and current development decisions.

> **Important accuracy rule**
>
> This handbook explains the intended architecture and the development foundation documented so far. It is not a substitute for inspecting the current Git repository. Any path, class, endpoint, command, environment variable, or implementation marked **verify**, **illustrative**, or **recommended** must be checked against the actual code before relying on it. Do not create duplicate files merely to match an example structure.

---

# Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Repository Structure and How to Navigate It](#3-repository-structure-and-how-to-navigate-it)
4. [Backend Architecture (NestJS)](#4-backend-architecture-nestjs)
5. [Database Layer (PostgreSQL and Prisma)](#5-database-layer-postgresql-and-prisma)
6. [Backend Business Logic: Adding or Changing a Feature](#6-backend-business-logic-adding-or-changing-a-feature)
7. [API Design and Frontend–Backend Integration](#7-api-design-and-frontendbackend-integration)
8. [Exceptions, Validation, and Error Handling](#8-exceptions-validation-and-error-handling)
9. [Authentication, Authorization, and Security](#9-authentication-authorization-and-security)
10. [Frontend Architecture (Flutter)](#10-frontend-architecture-flutter)
11. [Frontend State, Data, and UI Flow](#11-frontend-state-data-and-ui-flow)
12. [How to Add a Frontend Feature](#12-how-to-add-a-frontend-feature)
13. [Navigation, Theme, Assets, and Reusable UI](#13-navigation-theme-assets-and-reusable-ui)
14. [AI Chatbot Integration (Ollama)](#14-ai-chatbot-integration-ollama)
15. [Configuration, Environments, and Networking](#15-configuration-environments-and-networking)
16. [Running JomIn on a New Windows Machine](#16-running-jomin-on-a-new-windows-machine)
17. [Testing and Debugging](#17-testing-and-debugging)
18. [Git and Team Development Workflow](#18-git-and-team-development-workflow)
19. [Feature Module Reference](#19-feature-module-reference)
20. [Common Problems and Troubleshooting](#20-common-problems-and-troubleshooting)
21. [Development Checklist and Repository Verification](#21-development-checklist-and-repository-verification)
22. [Glossary](#22-glossary)

---

# 1. Project Overview

JomIn is a mobile-first campus event and social-content application. Its intended experience allows users to create and edit posts, browse a For You feed, search and explore catalogue content, interact with other users, and use an AI chatbot.

## 1.1 Confirmed working feature scope

The current agreed modules are:

1. **Authentication** — registration, login, logout, and access control.
2. **Profile** — viewing and managing user information.
3. **Post Creation & Editor** — composing and editing posts, including interactive stickers.
4. **For You Feed** — presenting relevant or recommended posts.
5. **Search & Catalogue** — searching and browsing available content.
6. **Engagement** — sharing, saving, following, and related interactions.
7. **AI Chatbot** — conversational AI using Ollama.
8. **Analytics** — analytical information and summaries defined by the final requirements.
9. **Admin** — administrative management and privileged operations.

These are the current scope names. The detailed requirements, data models, and endpoints for each module should be defined as implementation proceeds.

## 1.2 Technology stack

| Layer | Technology | Responsibility |
|---|---|---|
| Frontend | Flutter / Dart | Screens, widgets, navigation, user interaction |
| State management | Riverpod | Application and feature state |
| Navigation | GoRouter | Route definitions and navigation |
| HTTP client | Dio | Frontend-to-backend HTTP communication |
| Backend | Node.js / NestJS / TypeScript | API, validation, business rules, integrations |
| ORM | Prisma | Typed database access and schema migrations |
| Database | PostgreSQL | Persistent application data |
| AI runtime | Ollama | Hosts the selected language model |
| Android build | Gradle | Builds the Android application |
| IDE / workflow | VS Code | Main development environment |

**Version note:** Do not infer exact versions from this table. The actual versions are defined by `package.json`, lockfiles, `pubspec.yaml`, Flutter tooling, and Android Gradle configuration.

## 1.3 What each technology does

- **Flutter** draws the app and handles user interaction. It should not contain database credentials or query PostgreSQL directly.
- **Riverpod** exposes and manages state so screens can react to loading, success, and error changes.
- **GoRouter** maps URLs/route names to screens and controls navigation.
- **Dio** sends HTTP requests to the backend and receives responses.
- **NestJS** receives requests, validates them, applies rules, accesses data, and returns responses.
- **Prisma** translates backend data operations into database queries.
- **PostgreSQL** stores the durable records.
- **Ollama** runs the language model. The backend should mediate requests to it.

---

# 2. System Architecture

JomIn follows a client–server architecture.

```text
+------------------------------------------------+
|                Flutter frontend                |
|                                                |
| Screens / Widgets                              |
| Riverpod providers                             |
| Feature repositories / models                  |
| Shared Dio API client                          |
+------------------------+-----------------------+
                         |
                         | HTTP REST / JSON
                         v
+------------------------------------------------+
|                 NestJS backend                 |
|                                                |
| Controllers -> DTO validation -> Services      |
| Guards / authorization / exception handling    |
| Prisma service                                 |
+----------------------+-------------------------+
                       |
             +---------+----------+
             |                    |
             v                    v
+----------------------+  +----------------------+
|     PostgreSQL       |  |       Ollama         |
| Persistent records   |  | Model inference API  |
+----------------------+  +----------------------+
```

## 2.1 The responsibility boundary

| Concern | Correct home |
|---|---|
| Layout, buttons, forms, visual states | Flutter presentation |
| Temporary UI state | Riverpod / frontend state layer |
| HTTP request construction | Flutter repository / API client |
| Request validation | NestJS DTO / validation pipeline |
| Permission checks | Backend guards and service rules |
| Business decisions | NestJS services |
| Database reads and writes | Prisma, called by backend services |
| Durable data | PostgreSQL |
| Model inference | Ollama, called by backend |
| API URL for a runtime | Central frontend configuration |

The backend is the authority for business rules and access control. Frontend validation improves user experience but must never be the only validation.

## 2.2 A complete request lifecycle

Example: a user opens a profile page.

1. The user navigates to the profile screen.
2. The screen watches a Riverpod provider.
3. The provider asks the profile repository for data.
4. The repository calls the shared Dio client.
5. Dio sends an HTTP request to the NestJS API.
6. NestJS routes the request to a controller.
7. The controller reads validated parameters and calls a service.
8. The service checks business rules and permissions.
9. The service uses Prisma to query PostgreSQL.
10. PostgreSQL returns the records.
11. The backend returns a response DTO/JSON payload.
12. Dio receives the response.
13. The repository converts the response into a frontend model.
14. Riverpod publishes the new state.
15. Flutter rebuilds the relevant UI.

```text
User
  |
Profile screen
  |
Riverpod provider
  |
Profile repository
  |
Dio API client
  |  HTTP GET
  v
NestJS controller
  |
Profile service
  |  permission / business rules
  v
Prisma Client
  |
PostgreSQL
  |
JSON response back through the same layers
  |
Riverpod state changes
  |
Profile screen renders data
```

---

# 3. Repository Structure and How to Navigate It

The documented project is divided into `frontend/` and `backend/`. The following is a conceptual map; verify the current repository tree before treating every entry as an existing file.

```text
JomIn/
|
+-- frontend/                       Flutter application
|   +-- lib/
|   |   +-- main.dart               App entry point
|   |   +-- core/                   Shared app infrastructure
|   |   |   +-- network/            Dio client and API providers
|   |   |   +-- router/             GoRouter configuration
|   |   |   +-- theme/              Theme and brand styling
|   |   |   +-- config/             Environment/config values (if present)
|   |   |   +-- utils/              Shared helpers (if present)
|   |   +-- features/               Feature-first modules
|   |   |   +-- auth/
|   |   |   +-- profile/
|   |   |   +-- post_creation/
|   |   |   +-- for_you_feed/
|   |   |   +-- search_catalogue/
|   |   |   +-- engagement/
|   |   |   +-- ai_chatbot/
|   |   |   +-- analytics/
|   |   |   +-- admin/
|   |   +-- shared/                 Cross-feature widgets (if present)
|   +-- assets/                     Images, icons, fonts
|   +-- android/                    Android project and Gradle files
|   +-- ios/                        iOS project files (if used)
|   +-- web/                        Web runner files (if used)
|   +-- test/                       Flutter tests
|   +-- pubspec.yaml                Dependencies and asset declarations
|
+-- backend/                        NestJS application
|   +-- src/
|   |   +-- main.ts                 Backend bootstrap
|   |   +-- app.module.ts           Root module
|   |   +-- [feature modules]/      Controllers, services, DTOs
|   |   +-- prisma/                 Shared Prisma integration (if present)
|   +-- prisma/
|   |   +-- schema.prisma           Data model definition
|   |   +-- migrations/             Schema migration history
|   +-- test/                       Backend tests
|   +-- package.json                Dependencies and scripts
|   +-- prisma.config.ts            Prisma config (if this version uses it)
|   +-- .env                        Local secrets/config; never commit
|
+-- README.md
+-- .gitignore
```

## 3.1 Where should I make a change?

| If you want to… | Start looking in… |
|---|---|
| Change a screen layout | `frontend/lib/features/<feature>/presentation/` |
| Add a reusable feature widget | Feature `presentation/widgets/` |
| Add a data model / JSON parsing | Feature `data/models/` |
| Add an API operation | Feature `data/repositories/` |
| Manage feature state | Feature `providers/` |
| Change the API base URL | `frontend/lib/core/network/api_client.dart` (documented location; verify) |
| Add/change app navigation | `frontend/lib/core/router/router.dart` |
| Change global theme | `frontend/lib/core/theme/app_theme.dart` |
| Add an API route | Corresponding backend feature controller |
| Add business rules | Corresponding backend service |
| Validate request input | Backend DTOs and validation |
| Add/change database tables | `backend/prisma/schema.prisma` |
| Apply database schema changes | Prisma migration workflow |
| Change database connection | Backend `.env` and Prisma configuration |
| Change Android build setup | `frontend/android/` |

## 3.2 Feature-first organization

Keep code belonging to one business feature together. For example, the profile screen, profile model, profile repository, and profile provider should live in the Profile feature rather than being scattered across unrelated folders.

Shared infrastructure belongs in `core/`. A widget used only by one feature belongs in that feature. A genuinely cross-feature widget may belong in `shared/`.

---

# 4. Backend Architecture (NestJS)

NestJS structures the backend into modules. A feature module groups the controller, service, DTOs, and related code for one area of the application.

## 4.1 The usual backend request path

```text
HTTP request
   |
   v
Controller
   |
   +--> DTO / validation pipeline
   |
   v
Service
   |
   +--> Business rules
   +--> Authorization checks (where appropriate)
   +--> Prisma database operations
   +--> External integrations (e.g. Ollama)
   |
   v
Controller response
   |
   v
HTTP response / JSON
```

## 4.2 Main NestJS building blocks

### `main.ts` — application bootstrap

This is the application entry point. It commonly:

- Creates the NestJS application.
- Configures a global API prefix.
- Enables validation.
- Configures CORS when required.
- Configures global exception handling and logging.
- Starts listening on the configured port.
- May set up Swagger/OpenAPI documentation.

Do not add feature-specific business logic here.

### `app.module.ts` — root module

The root module imports the feature modules and shared infrastructure modules. When creating a new NestJS feature module, it normally needs to be registered/imported here unless the project's module architecture handles registration differently.

### Controller — HTTP interface

A controller defines routes and receives HTTP requests. Its job is to:

- Declare the HTTP method and route.
- Read path parameters, query parameters, and request body.
- Use validated DTOs.
- Obtain the authenticated user context when applicable.
- Call a service.
- Return the service result.

Keep controllers thin. Avoid writing long database queries and complex business rules directly in controllers.

### Service — business logic

A service performs the actual application work. Examples:

- Decide whether a user can edit a post.
- Confirm that a post exists.
- Check whether a user already follows another user.
- Create or update records using Prisma.
- Coordinate multiple data operations.
- Call Ollama or another external service.
- Return data for the controller.

A service is the normal home for feature-specific backend logic.

### DTO — Data Transfer Object

A DTO describes the expected shape of request input. It is used with the project's validation setup to reject invalid data before business logic runs.

Example (illustrative TypeScript):

```ts
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  content: string;
}
```

Use the validation decorators and conventions already installed in the repository. Do not assume the sample DTO matches the current project configuration.

### Module — feature wiring

A NestJS module groups its controller and providers and imports any dependencies it needs.

Illustrative layout:

```text
posts/
  posts.module.ts
  posts.controller.ts
  posts.service.ts
  dto/
    create-post.dto.ts
    update-post.dto.ts
```

The actual feature may also contain guards, strategies, tests, serializers, or helper services.


## 4.5 Backend file and folder management

This section explains where backend files should live when you add a new business capability, which files are normally needed, and how NestJS connects them.

### 4.5.1 Find the right place first

Inspect the existing backend and follow its conventions before creating anything:

```powershell
cd backend
Get-ChildItem .\src -Recurse -File
```

If the capability belongs to an existing module, extend that module. Do not create duplicate Prisma services, authentication guards, API clients, or exception handlers when shared versions already exist.

| Concern | Where it belongs | Responsibility |
|---|---|---|
| HTTP route and request mapping | Feature controller | Defines how the client calls the feature |
| Business rules and workflow | Feature service | Implements decisions and use cases |
| Request validation | Feature `dto/` folder | Defines valid request input |
| Feature-specific helper | Feature folder, near its users | Keeps related code together |
| Database models and relations | `prisma/schema.prisma` | Central data model |
| Database migrations | `prisma/migrations/` | Versioned schema changes |
| Database access | Feature service via shared Prisma provider | Reuses the configured DB connection |
| Shared guards, filters, decorators | Existing shared/common folder | Cross-feature infrastructure |
| Tests | Beside source or project test folder | Verifies behavior |

Use the shared-folder convention that already exists in the repository. Do not create `common/`, `shared/`, and `infrastructure/` just because they appear in examples.

### 4.5.2 Recommended feature folder layout

Example only:

```text
backend/
  src/
    main.ts
    app.module.ts

    prisma/
      prisma.module.ts
      prisma.service.ts

    posts/
      posts.module.ts
      posts.controller.ts
      posts.service.ts
      dto/
        create-post.dto.ts
        update-post.dto.ts
        query-posts.dto.ts
      helpers/                 # Only when needed
      __tests__/               # Follow existing test convention

    profile/
      profile.module.ts
      profile.controller.ts
      profile.service.ts
      dto/
        update-profile.dto.ts

    common/                    # Shared code, if this is the repo convention
      guards/
      filters/
      decorators/

  prisma/
    schema.prisma
    migrations/
```

A small feature may only need a module, controller, service, and DTO. Do not create empty folders in advance.

### 4.5.3 What goes into each file?

**`<feature>.module.ts` — dependency wiring**
- Registers the feature's controllers and providers.
- Imports modules that export dependencies the feature needs.
- Exports a provider only when another module genuinely needs it.
- Contains no route handlers or business rules.

**`<feature>.controller.ts` — HTTP boundary**
- Declares routes and HTTP methods.
- Reads path parameters, query parameters, and validated DTOs.
- Obtains the authenticated user from the established auth mechanism.
- Calls the service and returns its result.
- Avoids long Prisma queries and complex business workflows.

**`<feature>.service.ts` — business logic**
- Implements the feature's use cases.
- Checks whether records exist.
- Enforces ownership and business permissions.
- Uses the shared Prisma provider for database work.
- Coordinates transactions when several writes must succeed together.
- Calls external integrations through injected services.
- Throws the project's expected NestJS exceptions for expected failures.

Keep methods focused. If a service becomes too large, split cohesive responsibilities into additional providers within the feature rather than moving logic into the controller.

**`dto/*.dto.ts` — request contracts**
- Defines accepted request fields.
- Applies validation decorators supported by the installed validation setup.
- Specifies required/optional fields and constraints.
- Does not perform database writes.

Use separate create, update, and query DTOs when their validation rules differ.

**Tests — behavior verification**
- Unit-test service rules and edge cases.
- Mock injected dependencies where appropriate.
- Use integration/e2e tests for behavior that requires the NestJS application or a real database.
- Follow the test naming and location convention already used by the repository.

### 4.5.4 Add a new business capability: file-by-file workflow

1. **Identify the owning module.** For example, add post-related operations to the existing Posts or Engagement module according to the team's agreed responsibility.
2. **Define the API contract.** Agree on method, route, authentication, input, response, and error cases.
3. **Check the data model.** Decide whether existing Prisma models are sufficient or a schema change is required.
4. **Create/update DTOs.** Put request validation in the owning feature's `dto/` folder.
5. **Implement the service method.** Put the business workflow in the feature service or a focused injected provider.
6. **Add the controller route.** Keep the HTTP handler thin; delegate to the service.
7. **Check module wiring.** Register the controller/provider and import required dependencies.
8. **Add a migration if needed.** Update the central Prisma schema and commit the generated migration with the code.
9. **Add tests.** Cover success, invalid input, missing records, permission failures, conflicts, and dependency failures as appropriate.
10. **Tell the frontend developer the contract.** Share the exact endpoint, request, response, and error behavior.
11. **Run checks.** Use scripts in `backend/package.json` and test the endpoint through Swagger or an HTTP client.

### 4.5.5 When should you create a new module?

Create a separate NestJS module when the capability represents a distinct area of responsibility with its own routes/providers and a meaningful boundary. JomIn's feature areas include Authentication, Profile, Posts, Search/Catalogue, Engagement, Chatbot, Analytics, and Admin.

Do not create a new module for every endpoint. Saving and unsaving a post are usually operations within the agreed Posts or Engagement module.

Ask:
- Does this capability have a distinct responsibility?
- Does it need its own controller or providers?
- Is it reused by other modules?
- Would keeping it in the existing module make that module confusing or tightly coupled?

### 4.5.6 How NestJS files become active

Creating a TypeScript file alone does not add it to the running API. Check that:

1. The controller is listed in the feature module's `controllers`.
2. The service/provider is listed in `providers` or supplied by an imported module.
3. The feature module is imported by `AppModule`, directly or through an existing parent module.
4. Injected dependencies are exported by their owning module and imported where needed.
5. The controller prefix and route decorators produce the intended full API path.

Illustrative module:

```ts
@Module({
  controllers: [PostsController],
  providers: [PostsService],
  exports: [PostsService], // Only if another module needs it
})
export class PostsModule {}
```

Illustrative root registration:

```ts
@Module({
  imports: [PrismaModule, PostsModule, ProfileModule],
})
export class AppModule {}
```

These are examples. Preserve the actual module names and registration pattern in JomIn.

### 4.5.7 Nest CLI scaffolding

If `@nestjs/cli` is installed, it can generate standard files. Run commands from `backend/` and inspect the generated diff:

```powershell
npx nest g module posts
npx nest g controller posts
npx nest g service posts
```

Do not generate a second copy if the module already exists. The CLI may automatically update module registration; verify what it changed. Create DTOs using the project's established convention.

### 4.5.8 File-management mistakes to avoid

- Putting Prisma queries and business rules directly in controllers.
- Creating a new Prisma client/service inside every feature.
- Creating a module for every small endpoint.
- Putting feature-only helpers in a global shared folder.
- Combining unrelated responsibilities in one oversized service.
- Forgetting to register a controller, provider, or module.
- Changing the Prisma schema without a migration.
- Moving files without updating imports and tests.
- Copying another feature's DTO without checking its validation rules.
- Committing generated output, secrets, or `.env` files.

**Rule of thumb:** one feature owns its controller, service, DTOs, and tests; shared infrastructure is injected into it; Prisma schema and migrations stay centralized; and Flutter communicates with the feature through the agreed API contract.

---

## 4.3 Dependency injection

NestJS commonly creates and injects services through its dependency-injection container. Prefer constructor injection and registered providers over manually creating service instances with `new`.

Illustrative example:

```ts
@Injectable()
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  // Route handlers call postsService methods.
}
```

If a service cannot be injected, check that it is registered in the relevant module's `providers` and exported/imported correctly when used across modules.

## 4.4 Where to put new backend code

- Route definition and HTTP input/output: controller.
- Input shape and validation: DTO.
- Business decisions: service.
- Database structure: Prisma schema.
- Database reads/writes: service using the shared Prisma service/client.
- Reusable backend infrastructure: shared module/provider.
- Authentication enforcement: guard and service-level ownership checks.
- Automated behavior checks: unit/integration tests.

---

# 5. Database Layer (PostgreSQL and Prisma)

## 5.1 Connection architecture

The intended connection chain is:

```text
NestJS feature service
        |
        v
Prisma Client / Prisma service
        |
        | DATABASE_URL / Prisma configuration
        v
PostgreSQL server
        |
        v
jomin_db (development database name discussed)
```

Flutter must not connect directly to PostgreSQL. It calls NestJS. This keeps credentials on the server and ensures business rules cannot be bypassed by a modified client.

## 5.2 PostgreSQL's role

PostgreSQL is the persistent data store. It holds application records such as users, posts, media metadata, follows, saves, and other data defined by the final schema.

Common local development values discussed for JomIn:

| Setting | Development example |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `jomin_db` |
| Username | Local PostgreSQL account, often `postgres` |
| Password | Set locally by each developer |

These are examples, not universal credentials. Confirm the local PostgreSQL service, database, account, and password on each machine.

## 5.3 Environment configuration

The database URL belongs in the backend environment, not in Flutter source code or Git.

Illustrative `.env` value:

```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/jomin_db"
```

Replace the placeholder with the local password. Never paste real passwords into documentation, commits, screenshots, or chat.

The project's README documents `DATABASE_URL` and `jomin_db`. Prisma's configuration mechanism differs between major versions. Some Prisma 7 setups define the datasource URL in `prisma.config.ts`; older configurations may place it in `schema.prisma`. **Inspect the installed Prisma version and current config before changing either file.**

## 5.4 `schema.prisma` — the data model

The Prisma schema defines the database models, fields, types, IDs, unique constraints, relations, and datasource/generator configuration as supported by the installed version.

Illustrative example only:

```prisma
model User {
  id       String @id @default(uuid())
  username String @unique
}
```

This is not a complete JomIn schema. Never assume that a model exists just because it appears in a handbook example.

### Common schema concepts

- `@id`: primary key.
- `@default(...)`: default value generated by Prisma or the database.
- `@unique`: prevents duplicate values.
- `@relation`: defines a relationship between models.
- `?`: optional field or relation.
- `[]`: one-to-many/list relation.
- `@@index`: database index.
- `@@map` / `@map`: maps Prisma names to database names.

Before adding a model, decide:

1. What real-world entity does it represent?
2. What fields are required or optional?
3. What uniquely identifies a record?
4. Which records relate to it?
5. What should happen when a related record is deleted?
6. Which fields need indexes?
7. What data is private and who can access it?

## 5.5 Prisma Client — querying the database

Backend services use Prisma Client to perform typed database operations. The exact injection class/file depends on the repository.

Illustrative service logic:

```ts
// Illustrative only: use the project's actual Prisma service name.
const post = await this.prisma.post.findUnique({
  where: { id: postId },
});
```

Common operation families:

| Operation | Typical Prisma method |
|---|---|
| Find one by unique key | `findUnique()` |
| Find matching records | `findMany()` |
| Insert one record | `create()` |
| Update one record | `update()` |
| Delete one record | `delete()` |
| Insert or update | `upsert()` |
| Count records | `count()` |
| Run related operations atomically | `$transaction()` |

Do not place Prisma calls in Flutter. Keep them in backend services or a deliberately designed data-access layer.

## 5.6 How to change the database safely

A normal development workflow is:

1. Discuss the data change with the team.
2. Update `schema.prisma`.
3. Review relations, constraints, nullability, and deletion behavior.
4. Create a migration using the project's Prisma version and scripts.
5. Inspect the generated migration SQL.
6. Apply it to the local development database.
7. Regenerate Prisma Client if the workflow requires it.
8. Update backend service logic and DTOs.
9. Update frontend models and UI if the API contract changes.
10. Test both new behavior and existing features.

Common Prisma commands (use only if supported by this repository's installed version/configuration):

```powershell
npx prisma migrate dev --name describe_the_change
npx prisma generate
npx prisma studio
```

- `migrate dev` is commonly used for development migrations.
- `generate` generates the client from the schema.
- `studio` opens a visual data browser.

Check `backend/package.json`, Prisma version, and Prisma configuration first. Do not run reset, destructive migration, or production migration commands casually.

## 5.7 Migrations and Git

Migration files are part of the shared database history. Commit schema changes and their migration files together. Teammates should pull the migration and apply it to their own local database using the project's documented workflow.

Never solve a migration conflict by deleting migration history without team agreement. Do not edit an already-applied shared migration as if it had never been used; create a new migration for subsequent changes.

## 5.8 Transactions

Use a database transaction when multiple database operations must succeed or fail together. For example, creating a record and its required related records may need atomic behavior.

A transaction is not a substitute for validation or authorization. It protects database consistency across a group of operations.

## 5.9 Database troubleshooting checklist

If NestJS cannot connect to PostgreSQL, check:

1. Is the PostgreSQL service running?
2. Does `jomin_db` exist?
3. Is the server listening on the expected port?
4. Are host, username, password, and database name correct?
5. Is `DATABASE_URL` loaded by the backend process?
6. Is the Prisma configuration consistent with the installed Prisma version?
7. Has Prisma Client been generated as required?
8. Is the database reachable from the machine running NestJS?

---

# 6. Backend Business Logic: Adding or Changing a Feature

This chapter describes the usual implementation path. Adjust names and files to match the actual codebase.

## 6.1 Example: adding a “save post” operation

A save operation may require:

- An authenticated user.
- A post identifier.
- A check that the post exists.
- A check for an existing save to prevent duplicates.
- A database record representing the save.
- A response describing the result.

### Step A — define the contract

Decide the HTTP method, route, request fields, response shape, authentication requirement, and possible errors before coding.

Illustrative contract:

```text
POST /api/v1/posts/:postId/save
Authorization: Bearer <token>

Response example:
{
  "postId": "…",
  "saved": true
}
```

This is a design example, not confirmation that the route currently exists.

### Step B — define database requirements

Decide whether the save is represented by a join model such as `SavedPost`, how it relates to `User` and `Post`, and whether a compound unique constraint should prevent duplicate saves.

### Step C — create/update the DTO

If the operation has a request body, define and validate it. A route that only uses a path parameter may not need a body DTO, but the parameter still needs validation.

### Step D — implement service logic

The service should:

1. Obtain the authenticated user's ID from trusted backend context.
2. Confirm the post exists.
3. Check whether the save already exists.
4. Create/remove/update the relation according to the agreed behavior.
5. Return a stable result.

Do not accept a user ID from the client as proof of identity. Use the authenticated principal.

### Step E — expose the controller route

The controller maps the HTTP request to the service method. Keep the controller small.

### Step F — connect the frontend

Add a repository method, expose it through a Riverpod provider/notifier, and connect the relevant button to that state operation.

### Step G — test

Test success, missing post, unauthenticated request, duplicate save, and database failure.

## 6.2 A practical backend feature checklist

- [ ] Requirements and API contract agreed.
- [ ] Database impact reviewed.
- [ ] Prisma schema and migration updated if needed.
- [ ] DTO and validation added.
- [ ] Service business logic implemented.
- [ ] Controller route added.
- [ ] Module dependencies registered.
- [ ] Authentication and authorization enforced.
- [ ] Errors mapped consistently.
- [ ] Unit/integration tests added.
- [ ] API documentation updated.
- [ ] Frontend contract and models coordinated.

---

# 7. API Design and Frontend–Backend Integration

## 7.1 API prefix and documented development endpoints

The project README documents:

- Backend base: `http://localhost:3000`
- API prefix: `/api/v1`
- Swagger UI: `http://localhost:3000/api/docs`
- Database health: `GET http://localhost:3000/api/v1/database/health`

Confirm these values against the current backend bootstrap and route implementation.

## 7.2 HTTP method conventions

| Method | Common purpose |
|---|---|
| `GET` | Retrieve data |
| `POST` | Create a record or perform an action |
| `PATCH` | Partially update a record |
| `PUT` | Replace a resource (when the API uses this convention) |
| `DELETE` | Delete a record |

Use consistent status codes and response shapes. Do not return database objects blindly if they contain private fields.

## 7.3 Agree on the API contract first

For each endpoint, document:

- Method and route.
- Authentication requirement.
- Required role/ownership rules.
- Path/query/body fields.
- Validation rules.
- Success response.
- Error response and status codes.
- Database effects.
- Pagination/filter/sort behavior, if relevant.

Frontend and backend developers should agree on this contract before implementing against assumptions.

## 7.4 Example JSON contract

Illustrative request:

```http
GET /api/v1/profile/123
Accept: application/json
Authorization: Bearer <access-token>
```

Illustrative response:

```json
{
  "id": "123",
  "username": "sample_user",
  "displayName": "Sample User",
  "bio": "Welcome to my profile"
}
```

The frontend should depend on the public API response, not on internal Prisma model names or database column layout.

## 7.5 Integration debugging sequence

If the UI does not show data:

1. Confirm the backend is running.
2. Call the endpoint directly using Swagger or an HTTP client.
3. Inspect the backend terminal logs.
4. Confirm the Flutter base URL is correct for the runtime.
5. Inspect Dio request URL, method, headers, and body.
6. Check response status and JSON shape.
7. Check model parsing.
8. Check Riverpod state transitions.
9. Check whether the widget watches the provider and renders the expected state.

This sequence isolates whether the issue is networking, backend logic, response parsing, state management, or UI rendering.

---

# 8. Exceptions, Validation, and Error Handling

Errors should be handled at the layer that can understand them, then returned in a predictable form.

## 8.1 Backend error categories

| Category | Example | Typical handling |
|---|---|---|
| Input validation | Missing title, invalid ID | Return a client error such as 400 |
| Authentication | Missing/invalid token | Return 401 |
| Authorization | User cannot edit another user's post | Return 403 |
| Missing resource | Post does not exist | Return 404 |
| Conflict | Duplicate unique value | Return 409 where appropriate |
| Rate limit | Too many requests | Return 429 |
| Unexpected server failure | Unhandled exception | Return 500 with safe message |

The exact status and error response format should follow the project's global exception setup.

## 8.2 Where exceptions should be handled

- **DTO/validation pipeline:** malformed or invalid request input.
- **Service:** expected business failures, such as a missing record or forbidden action.
- **NestJS exception filters/global handler:** consistent conversion of exceptions into HTTP responses.
- **Logging layer:** diagnostic details for developers/operators.
- **Flutter repository/provider:** translate HTTP/network failures into application state.
- **Flutter screen:** display a helpful message and recovery action.

Do not catch every exception and silently ignore it. That hides bugs.

## 8.3 Safe error responses

A client-facing error should be useful without revealing secrets, SQL statements, stack traces, filesystem paths, or credentials.

Illustrative response:

```json
{
  "statusCode": 404,
  "message": "Post not found",
  "error": "Not Found"
}
```

The actual shape depends on the backend's exception filter and NestJS defaults.

## 8.4 Frontend error states

A screen that loads remote data should normally handle:

- Initial/idle state.
- Loading state.
- Loaded state.
- Empty state.
- Error state.
- Retry or recovery action where sensible.

Do not show a permanent spinner when a request fails. Do not display raw server stack traces to users.

---

# 9. Authentication, Authorization, and Security

Authentication and authorization are different:

- **Authentication:** who is making the request?
- **Authorization:** what is that user allowed to do?

The exact JomIn authentication implementation and token strategy must be verified in the repository; earlier project documentation described authentication as planned/in progress.

## 9.1 Typical protected request flow

1. User submits login details.
2. Backend verifies the credentials.
3. Backend creates a session or issues a token according to the chosen design.
4. Flutter stores credentials using an appropriate secure storage mechanism.
5. Dio attaches the credential to protected requests.
6. NestJS guard verifies the credential.
7. Backend service checks ownership/role permissions.
8. Backend returns the permitted result.

## 9.2 Security rules

- Never store database credentials in Flutter.
- Never commit `.env` files, passwords, signing keys, or tokens.
- Never trust a client-supplied user ID as proof of identity.
- Validate all incoming data on the backend.
- Enforce authorization on every protected operation.
- Return only fields the caller is allowed to see.
- Use secure credential storage appropriate to the platform.
- Avoid logging passwords, access tokens, or private user data.
- Configure CORS for the intended clients; CORS is not authentication.
- Apply rate limits and sensible request size limits where needed.

---

# 10. Frontend Architecture (Flutter)

The frontend uses a feature-first structure with shared infrastructure in `lib/core/` and feature-specific code in `lib/features/`.

## 10.1 Main application entry point

`lib/main.dart` is the documented Flutter entry point. It commonly configures:

- Flutter initialization.
- Provider scope (for Riverpod).
- The root application widget.
- Router configuration.
- Theme configuration.

Keep feature business logic out of `main.dart`.

## 10.2 Core folders

The README documents these shared files:

| Path | Responsibility |
|---|---|
| `lib/core/network/api_client.dart` | Shared Dio configuration and API base URL |
| `lib/core/network/api_provider.dart` | Exposes API client through Riverpod |
| `lib/core/router/router.dart` | GoRouter route definitions |
| `lib/core/theme/app_theme.dart` | Shared dark theme and brand colours |

Verify the exact filenames and current contents before editing.

### `core/network/`

Shared networking setup belongs here. Feature repositories should use the shared client rather than creating separate Dio instances with inconsistent base URLs, headers, timeouts, and interceptors.

### `core/router/`

Central route definitions live here. When adding a screen that needs navigation, add or update its route and ensure route names/paths do not conflict.

### `core/theme/`

Global colours, typography, component themes, and dark/light behavior belong here. Avoid hard-coding a different version of the same global style in every feature.

### `core/config/`, `utils/`, `services/`

These are common organizational locations if the repository uses them. Do not assume they exist or create them without checking current conventions.

## 10.3 Feature folder anatomy

The initial Authentication structure documented in the README is:

```text
features/auth/
  data/
    models/             # API/domain data representations
    repositories/       # Calls backend operations
  providers/            # Riverpod state/providers
  presentation/
    screens/            # Full pages
    widgets/            # Feature-specific UI components
```

The same pattern can be used for other modules as they are implemented.

## 10.4 What belongs in each layer?

### `presentation/screens/`

Full screens/pages. A screen composes widgets and watches providers. It should not contain large HTTP calls or database/business rules.

### `presentation/widgets/`

Small UI components used by that feature, such as a post card, profile header, or editor toolbar.

### `data/models/`

Dart classes that represent API data or domain data. They parse JSON and provide typed values to the UI.

### `data/repositories/`

The feature's data access boundary. Repositories call the shared API client, map responses into models, and expose meaningful operations such as `fetchProfile()` or `createPost()`.

### `providers/`

Riverpod providers/notifiers that expose data and manage feature state. They coordinate UI actions with repositories and publish loading/data/error states.

---

# 11. Frontend State, Data, and UI Flow

## 11.1 Why use Riverpod?

A screen needs to know whether data is loading, available, empty, or failed. Riverpod provides a shared reactive state layer so the UI can rebuild when state changes.

Avoid storing all application data in widget-local variables. Local state is suitable for short-lived presentation details (for example, whether a menu is expanded). Remote data and feature workflows should follow the project's provider conventions.

## 11.2 Recommended data flow

```text
Screen / Widget
     |
     | watches provider
     v
Riverpod provider / notifier
     |
     | calls repository
     v
Feature repository
     |
     | uses shared Dio client
     v
NestJS API
```

When the response returns:

```text
NestJS JSON
    |
Dio response
    |
Repository parses model
    |
Provider updates state
    |
Screen rebuilds
```

## 11.3 Models and JSON

If the backend changes a response field, check the corresponding Dart model and parsing code. A mismatch between JSON keys/types and the model can cause parsing errors even when the HTTP request succeeds.

Agree on field names and nullability with the backend team. Treat optional response fields as optional in Dart where appropriate.

## 11.4 Repository responsibilities

A repository should:

- Know which endpoint to call.
- Send the correct request fields.
- Use the shared Dio instance.
- Parse the response.
- Convert transport details into a feature-level result/error.
- Avoid containing UI code.

A repository should not decide how a screen looks or show a dialog directly.

## 11.5 Provider responsibilities

A provider/notifier should:

- Expose state to the UI.
- Call repository methods.
- Manage loading/success/error transitions.
- Coordinate refresh or mutation behavior.
- Avoid duplicating the same request logic across multiple screens.

Follow the Riverpod version and provider style already used in the repository; do not mix incompatible patterns.

---

# 12. How to Add a Frontend Feature

Example: add a Profile screen that retrieves profile data.

## Step 1 — inspect the existing feature convention

Look at `features/auth/` and copy the project's actual naming and provider style. Do not introduce a different architecture for every feature.

## Step 2 — create the feature structure

Illustrative structure:

```text
features/profile/
  data/
    models/
      profile_model.dart
    repositories/
      profile_repository.dart
  providers/
    profile_provider.dart
  presentation/
    screens/
      profile_screen.dart
    widgets/
      profile_header.dart
```

## Step 3 — agree on the backend endpoint

For example, agree on a profile retrieval endpoint, its authentication requirements, and the exact JSON response. The path is illustrative until implemented.

## Step 4 — create the model

Create a Dart model that matches the API response. Add JSON parsing using the project's existing serialization style.

## Step 5 — create the repository

The repository should call the shared Dio client. Do not hard-code a second base URL in the feature.

Illustrative pseudocode:

```dart
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<ProfileModel> fetchProfile(String userId) async {
    final response = await _dio.get('/profile/$userId');
    return ProfileModel.fromJson(response.data);
  }
}
```

This example assumes the shared Dio base URL already includes the API prefix. Confirm the real base URL and route composition to avoid accidentally duplicating `/api/v1`.

## Step 6 — expose it through Riverpod

Create a provider/notifier that calls the repository and exposes loading/data/error state. Follow the exact Riverpod API already used by the project.

## Step 7 — build the screen and widgets

The screen watches the provider and renders the correct state. Keep the visual components in feature widgets when they are reusable.

## Step 8 — register navigation

Add the route in `core/router/router.dart` or the project's current routing arrangement.

## Step 9 — test the complete flow

Check the endpoint independently, then test it through Flutter. Verify loading, success, empty, and error states.

## 12.1 Frontend feature checklist

- [ ] Feature requirements and endpoint agreed.
- [ ] Feature folder created using existing conventions.
- [ ] Model matches the API response.
- [ ] Repository uses shared Dio.
- [ ] Provider exposes state and actions.
- [ ] Screen watches provider state.
- [ ] Widgets are separated from data logic.
- [ ] Route added if needed.
- [ ] Loading/empty/error states handled.
- [ ] Tests and analyzer checks pass.

---

# 13. Navigation, Theme, Assets, and Reusable UI

## 13.1 Navigation (GoRouter)

The documented router location is:

```text
frontend/lib/core/router/router.dart
```

When adding a screen:

1. Define a stable route path/name.
2. Register the route.
3. Pass required identifiers/arguments safely.
4. Navigate using the project's GoRouter conventions.
5. Consider protected-route behavior once authentication is implemented.
6. Test direct navigation and back navigation.

Do not place route definitions independently in many feature files unless the project intentionally uses a route-composition pattern.

## 13.2 Theme

The documented theme location is:

```text
frontend/lib/core/theme/app_theme.dart
```

Use shared theme values for colors, typography, input decoration, buttons, cards, and other global components. If a design value is used throughout the app, define it centrally rather than repeating arbitrary literals.

## 13.3 Assets

The Flutter asset directory is documented as `frontend/assets/`. The actual asset subfolders must be checked.

Typical asset categories:

```text
assets/
  images/
  icons/
  fonts/
```

Flutter assets generally need to be declared in `pubspec.yaml`. After changing asset declarations, run:

```powershell
flutter pub get
```

Use the existing naming convention and avoid adding duplicate copies of the same image.

## 13.4 Reusable widgets

A widget belongs in a feature when it is only used by that feature. Move it into a shared location only when multiple features genuinely reuse it.

Avoid building a huge widget that owns API calls, state, navigation, and presentation all at once. Separate responsibilities so each part is easier to test and modify.

---

# 14. AI Chatbot Integration (Ollama)

The agreed AI runtime for JomIn's chatbot is Ollama.

## 14.1 Intended request flow

```text
Flutter chatbot screen
       |
       | message / conversation context
       v
NestJS chatbot controller
       |
       v
Chatbot service
       |
       | HTTP request
       v
Ollama API + selected model
       |
       | generated response
       v
Chatbot service
       |
       | JSON response
       v
Flutter UI
```

Flutter should call NestJS, not Ollama directly. This keeps model configuration and server-side prompt handling out of the mobile client.

## 14.2 Ollama local endpoint

A commonly used local Ollama API address is:

```text
http://localhost:11434
```

This is only correct when the backend process can reach Ollama on the same machine. If they run in separate containers or machines, `localhost` may refer to the wrong environment.

Check locally installed models with:

```powershell
ollama list
```

The selected model name, endpoint, timeout, and related configuration should be centralized in backend configuration rather than scattered through code.

## 14.3 Reliability considerations

- Handle Ollama being offline.
- Handle a model that is not installed.
- Set appropriate timeouts.
- Show a loading state while generating.
- Consider streaming versus one complete response.
- Control conversation history and prompt size.
- Avoid sending unnecessary private data.
- Treat model output as untrusted content.
- Do not assume an AI response is always correct.

---

# 15. Configuration, Environments, and Networking

## 15.1 API base URL

The README documents the frontend API base URL in:

```text
frontend/lib/core/network/api_client.dart
```

It records this development value:

```text
http://localhost:3000/api/v1
```

That value is appropriate for Flutter Web running on the same PC as the backend, assuming the backend uses port 3000 and the API prefix remains `/api/v1`.

The correct URL depends on where Flutter runs:

| Runtime | Typical base URL |
|---|---|
| Flutter Web on same PC | `http://localhost:3000/api/v1` |
| Standard Android emulator | `http://10.0.2.2:3000/api/v1` |
| Physical Android phone with ADB reverse | `http://localhost:3000/api/v1` |
| Physical phone over same Wi-Fi | `http://<PC-LAN-IP>:3000/api/v1` |

The phone's `localhost` normally refers to the phone itself. ADB reverse is what makes the PC's backend reachable through the phone's localhost in the USB setup.

## 15.2 USB phone: ADB reverse

Enable Developer Options and USB debugging, connect the phone, approve the authorization prompt, then run:

```powershell
adb devices
adb reverse tcp:3000 tcp:3000
adb reverse --list
```

This forwards the phone's port 3000 to the PC's port 3000. The mapping may need to be re-established after reconnecting the phone or restarting ADB.

A small script can make the step repeatable:

```bat
@echo off
adb reverse tcp:3000 tcp:3000
pause
```

Only use this when the device is connected and authorized. If the project uses a different backend port, update both sides of the mapping consistently.

## 15.3 Android emulator

The standard Android emulator commonly reaches the host PC through:

```text
http://10.0.2.2:3000
```

Append the project's API prefix when setting the full API base URL.

## 15.4 Wi-Fi phone connection

Find the PC's active IPv4 address:

```powershell
ipconfig
```

Use the PC's LAN IP in the phone's API base URL. Both devices must be on the same network, the backend must listen on a reachable interface, and Windows Firewall must permit the connection. Do not expose a development server to untrusted networks.

## 15.5 CORS and network access

CORS is a browser security mechanism, so it matters particularly for Flutter Web. Android native networking does not use browser CORS in the same way, but still requires a reachable server and correct platform network configuration.

Do not treat enabling CORS as a fix for an incorrect host address, stopped backend, firewall block, or failed ADB reverse mapping.

## 15.6 Keep configuration centralized

Avoid scattering base URLs and environment-specific values across screens and repositories. Use the project's central API client/configuration and the backend's environment configuration.

---

# 16. Running JomIn on a New Windows Machine

This section reflects the documented team workflow. Use the exact scripts and dependency versions committed to the repository.

## 16.1 Prerequisites

Install the tools required by the target platform:

- Git.
- Node.js and npm.
- Flutter SDK (Dart is included).
- PostgreSQL.
- JDK compatible with the committed Gradle/Android Gradle Plugin configuration.
- Android SDK and platform tools for Android development.
- VS Code or another editor.
- Ollama if the developer needs to run the chatbot locally.
- Chrome if testing Flutter Web.

The project has discussed a JDK 17 baseline for the Android build setup. A teammate previously reported Flutter 3.27.1 stable, Dart 3.6.0, Temurin Java 17.0.12, and Android SDK/build tools 35.0.0. These are environment observations, not proof that every future repository revision requires those exact versions. Check the committed Gradle wrapper and plugin versions before upgrading Java or Gradle.

## 16.2 Verify installations

Run in PowerShell:

```powershell
git --version
node --version
npm --version
flutter --version
dart --version
java -version
psql --version
adb version
flutter doctor -v
```

If a command is not recognized, verify installation and PATH configuration.

## 16.3 Get the repository

```powershell
git clone <REPOSITORY-URL>
cd <PROJECT-FOLDER>
```

Do not run `git init` after cloning an existing repository.

## 16.4 Set up PostgreSQL

1. Ensure the PostgreSQL service is installed and running.
2. Create the development database `jomin_db` if it does not exist.
3. Confirm the local username, password, host, and port.
4. Do not reuse another developer's local password.

You can use pgAdmin or PostgreSQL command-line tools.

## 16.5 Set up the backend

Open a terminal in `backend/`:

```powershell
cd backend
npm install
```

Create `backend/.env` from the team's `.env.example` if available. Configure `DATABASE_URL` with the local credentials. Never commit `.env`.

Run the project's documented Prisma migration/client-generation commands if required. Check `package.json`, Prisma version, and Prisma config first.

Start the backend using the script documented in the README:

```powershell
npm run start:dev
```

The documented development endpoints are:

- API: `http://localhost:3000`
- Swagger: `http://localhost:3000/api/docs`
- Database health: `http://localhost:3000/api/v1/database/health`

## 16.6 Set up the frontend

Open another terminal in `frontend/`:

```powershell
cd frontend
flutter pub get
```

Run checks:

```powershell
flutter analyze
flutter test
```

## 16.7 Run on Chrome

With the backend running:

```powershell
flutter run -d chrome
```

Use the local PC API URL in the Flutter API client.

## 16.8 Run on a physical Android phone

1. Enable Developer Options and USB debugging.
2. Connect the phone using a data-capable USB cable.
3. Approve the debugging authorization prompt.
4. Confirm detection:

```powershell
adb devices
```

5. Set up the reverse connection:

```powershell
adb reverse tcp:3000 tcp:3000
```

6. Start PostgreSQL.
7. Start NestJS in the backend terminal.
8. Start Flutter in the frontend terminal:

```powershell
flutter run
```

### Recommended run order

1. **PostgreSQL:** ensure the service and `jomin_db` are available.
2. **Android connection (if using USB):** run `adb devices` and `adb reverse`.
3. **Backend:** start NestJS and confirm the health endpoint.
4. **Frontend:** run Flutter on the selected device.

If the chatbot is being tested, also ensure Ollama is running and the backend can reach it.

---

# 17. Testing and Debugging

## 17.1 Frontend checks

From `frontend/`:

```powershell
flutter analyze
flutter test
```

Use widget tests for UI behavior, unit tests for model/repository/provider logic, and integration tests for important user journeys where appropriate.

## 17.2 Backend checks

Inspect `backend/package.json` for the actual scripts. Common NestJS scripts may include:

```powershell
npm run test
npm run test:e2e
npm run build
```

These names are common examples; use the scripts actually defined in the repository.

## 17.3 Test at multiple layers

| Layer | What to test |
|---|---|
| DTO | Reject invalid input |
| Service | Business rules and permission decisions |
| Repository/data access | Correct database operations |
| Controller/API | Route, status code, request/response |
| Flutter model | JSON parsing and nullability |
| Flutter provider | Loading, data, and error transitions |
| Widget | User interaction and rendered state |
| End-to-end | Complete flow across client, API, and database |

## 17.4 Debug in layers

When a feature fails, do not immediately edit random files. Identify the failing boundary:

1. Does the screen trigger the action?
2. Does the provider call the repository?
3. Does Dio send the request?
4. Does the request reach NestJS?
5. Does the controller call the service?
6. Does the service execute the expected rule?
7. Does Prisma query PostgreSQL?
8. Does the backend return the expected response?
9. Does Flutter parse it?
10. Does Riverpod publish the expected state?
11. Does the widget render that state?

---

# 18. Git and Team Development Workflow

## 18.1 Start work safely

```powershell
git pull
git switch -c feature/short-task-name
```

Keep a branch focused on one task or coherent feature.

## 18.2 Coordinate shared files

Changes to these areas can affect many teammates:

- Prisma schema and migrations.
- Backend module registration and global configuration.
- API route/response contracts.
- Frontend API client and base URL.
- GoRouter configuration.
- Global theme.
- Shared models/providers.
- Android Gradle configuration.

Discuss shared changes before making conflicting edits.

## 18.3 Before committing

Run relevant tests and inspect the diff:

```powershell
git status
git diff
```

Frontend:

```powershell
cd frontend
flutter analyze
flutter test
```

Backend: run the test/build scripts defined in `backend/package.json`.

Commit and push:

```powershell
git add .
git commit -m "Describe the change"
git push -u origin feature/short-task-name
```

## 18.4 Files that should not normally be committed

Examples of local/generated/secret files:

```gitignore
# Flutter
.dart_tool/
build/

# Android / Gradle
.gradle/
local.properties

# Node
node_modules/

# Secrets
.env
.env.*

# OS / editor
.DS_Store
Thumbs.db
```

Review the actual `.gitignore` before changing it. Do not ignore lockfiles or shared configuration files that the team needs.

Usually commit:

- `pubspec.yaml` and Flutter lockfile.
- `package.json` and backend lockfile.
- Prisma schema and migrations.
- Gradle wrapper files.
- Shared Android Gradle configuration.
- `.env.example` with placeholder values only.
- README and technical documentation.

---

# 19. Feature Module Reference

This section describes each confirmed module's likely responsibilities. It is a planning guide, not a claim that every endpoint, model, or screen already exists.

## 19.1 Authentication

**Frontend:** login/register forms, validation feedback, session state, secure credential handling, protected navigation.

**Backend:** credential validation, account creation, login/session/token handling, guards, authorization.

**Database:** user/account records and any session/refresh-token data required by the chosen design.

## 19.2 Profile

**Frontend:** profile screen, profile header, editable fields, profile image display/upload UI.

**Backend:** retrieve/update profile, validate fields, enforce profile ownership and visibility rules.

**Database:** user profile fields and media references as required.

## 19.3 Post Creation & Editor

**Frontend:** composition screen, editor controls, media/sticker interactions, preview, draft/edit states.

**Backend:** create/update/retrieve/delete post operations, ownership checks, content validation, media metadata handling.

**Database:** posts and any related media/sticker data required by the final design.

## 19.4 For You Feed

**Frontend:** feed list, post cards, pagination/infinite scroll, refresh and loading states.

**Backend:** feed retrieval, filtering, pagination, ranking/recommendation logic as defined by requirements.

**Database:** post visibility/status, relationships, and any ranking signals required.

## 19.5 Search & Catalogue

**Frontend:** search field, filters, result list, catalogue detail views, empty states.

**Backend:** search query validation, filtering, sorting, pagination, catalogue retrieval.

**Database:** searchable fields and indexes appropriate to the actual query patterns.

## 19.6 Engagement

**Frontend:** save/share/follow controls and immediate state feedback.

**Backend:** follow/unfollow, save/unsave, sharing-related operations, duplicate prevention, permission checks.

**Database:** relationship records and uniqueness constraints as designed.

## 19.7 AI Chatbot (Ollama)

**Frontend:** chat interface, message history display, loading/generation state, retry behavior.

**Backend:** prompt/context assembly, Ollama request, timeout/error handling, response formatting.

**External dependency:** Ollama endpoint and selected model configuration.

## 19.8 Analytics

**Frontend:** charts, summaries, date/filter controls, loading and empty states.

**Backend:** authorized aggregation and reporting endpoints.

**Database:** source records and indexes needed for efficient aggregation. Avoid exposing private data through analytics responses.

## 19.9 Admin

**Frontend:** admin-only navigation and management screens.

**Backend:** role/permission checks, moderation or management operations, audit-sensitive actions.

**Database:** role/permission data and audit records if required by the final design.

---

# 20. Common Problems and Troubleshooting

## 20.1 Flutter says it cannot reach the backend

Check in this order:

1. Is NestJS running?
2. Is it listening on the expected port?
3. Does the backend health endpoint work on the PC?
4. Is Flutter using the correct URL for Chrome, emulator, or phone?
5. For a USB phone, is the device authorized in `adb devices`?
6. Has `adb reverse tcp:3000 tcp:3000` been run?
7. Does `adb reverse --list` show the mapping?
8. Is Windows Firewall blocking the connection?
9. Does the backend terminal show that the request arrived?

## 20.2 Backend cannot connect to PostgreSQL

Check the PostgreSQL service, database name, port, credentials, environment loading, and Prisma configuration. Read the actual backend error rather than guessing.

## 20.3 Prisma command fails

Check:

- Installed Prisma package versions.
- The correct working directory.
- The repository's `package.json` scripts.
- Whether `prisma.config.ts` is used.
- Whether environment variables are loaded.
- Whether the schema is valid.
- Whether the required client generation step has run.

Do not blindly upgrade Prisma or copy configuration from another major version.

## 20.4 Flutter/Gradle build fails

Inspect the actual versions and compatibility of:

- Flutter and Dart.
- JDK used by Gradle.
- Gradle wrapper.
- Android Gradle Plugin.
- Kotlin plugin.
- Android SDK/platform/build tools.

Useful commands:

```powershell
java -version
flutter doctor -v
cd frontend
.\android\gradlew.bat --version
Get-Content android\gradle\wrapper\gradle-wrapper.properties
Get-Content android\settings.gradle
Get-Content android\app\build.gradle
```

The Gradle JVM can differ from the Java executable shown by `java -version`, due to `JAVA_HOME`, IDE settings, or Flutter configuration. Do not upgrade several build components at once without checking compatibility.

## 20.5 Flutter build output is locked on Windows/OneDrive

If Flutter cannot delete generated build assets:

1. Stop the running Flutter process.
2. Close Chrome or other processes using the build.
3. Retry `flutter clean`.
4. If the project is inside a synchronized OneDrive folder, pause syncing temporarily while building if file locks persist.

Do not delete source files to resolve a generated build lock.

## 20.6 API request succeeds but UI is blank

Check the JSON response, Dart model field names/types, JSON parsing, provider state, and whether the widget is watching the correct provider.

---

# 21. Development Checklist and Repository Verification

A technical manual should match the actual repository. Verify these items whenever the codebase changes significantly.

## 21.1 Backend verification

- [ ] Actual `src/` folder tree recorded.
- [ ] Actual NestJS modules and module imports recorded.
- [ ] Actual controllers, routes, and API prefix recorded.
- [ ] DTO and validation setup recorded.
- [ ] Global exception filter/handler recorded.
- [ ] Authentication and authorization implementation recorded.
- [ ] Prisma service/provider location recorded.
- [ ] Prisma version and config mechanism recorded.
- [ ] Actual schema and migrations recorded.
- [ ] Database health endpoint and scripts verified.
- [ ] Actual environment variable names documented without secret values.

## 21.2 Frontend verification

- [ ] Actual `lib/` folder tree recorded.
- [ ] Actual Riverpod version and provider patterns recorded.
- [ ] Actual GoRouter structure recorded.
- [ ] Actual Dio configuration and interceptors recorded.
- [ ] Actual API base URL mechanism recorded.
- [ ] Feature folders and screens recorded.
- [ ] Model serialization approach recorded.
- [ ] Theme and asset structure recorded.
- [ ] Tests and run commands verified.

## 21.3 Build and team verification

- [ ] Node.js version requirement recorded.
- [ ] Flutter/Dart version requirement recorded.
- [ ] JDK requirement recorded.
- [ ] Gradle wrapper version recorded.
- [ ] Android Gradle Plugin and Kotlin versions recorded.
- [ ] PostgreSQL setup steps verified on a clean machine.
- [ ] USB ADB reverse procedure verified.
- [ ] Chrome run procedure verified.
- [ ] Ollama model and endpoint documented.
- [ ] README and this handbook updated after architecture changes.

## 21.4 Repository inspection commands

From the repository root, useful Windows commands include:

```powershell
Get-ChildItem
Get-ChildItem .\backend\src -Recurse -File
Get-ChildItem .\backend\prisma -Recurse -File
Get-ChildItem .\frontend\lib -Recurse -File
Get-Content .\backend\package.json
Get-Content .\frontend\pubspec.yaml
```

Do not share `.env` contents when collecting configuration information. Share variable names and redacted values only.

---

# 22. Glossary

| Term | Meaning |
|---|---|
| API | Interface through which software components communicate |
| REST | HTTP API style using resources and standard HTTP methods |
| JSON | Common text format for API request/response data |
| Controller | NestJS component that defines HTTP routes |
| Service | Backend component that implements application/business logic |
| DTO | Data Transfer Object; describes request/response data shape |
| Provider | Riverpod mechanism for exposing and managing state/dependencies |
| Repository | Frontend data-access abstraction that calls APIs and maps data |
| Widget | Reusable building block of Flutter UI |
| Route | A navigable path mapped to a screen |
| ORM | Object-relational mapper; Prisma is the project's ORM |
| Prisma Client | Generated typed API for database operations |
| Schema | Definition of database models and relationships |
| Migration | Versioned database structure change |
| PostgreSQL | Relational database management system |
| Exception | Error condition represented and handled by application code |
| Authentication | Verifying who a user is |
| Authorization | Determining what an authenticated user may do |
| CORS | Browser policy controlling cross-origin requests |
| ADB reverse | Android Debug Bridge port forwarding from device to host |
| Ollama | Runtime for running language models locally or on a configured host |
| Gradle wrapper | Project-pinned Gradle launcher used for consistent builds |

---

## Final maintenance note

Treat the Git repository as the source of truth. When a developer changes a route, schema, environment variable, module, folder convention, dependency, or run command, update this handbook and the README in the same development task where practical.

**Never document secrets. Never assume a planned feature is already implemented. Mark examples clearly until they are verified against code.**
