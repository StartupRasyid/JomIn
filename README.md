# JomIn
 
A mobile campus events app for UTM students. Students discover events in a personalised feed, save and share them, and get help from an AI assistant choosing programmes and committee roles. Organisers publish posters with interactive link stickers and see engagement analytics. Admins approve posts and handle reports.
 
| Layer | Technology |
|---|---|
| Frontend (mobile) | Flutter (Dart) |
| Backend (API) | Node.js + NestJS (TypeScript) |
| ORM | Prisma |
| Database | PostgreSQL |
 
Repo: https://github.com/StartupRasyid/JomIn
 
## Contents
 
1. [Project structure](#1-project-structure)
2. [What to install](#2-what-to-install)
3. [First-time setup](#3-first-time-setup)
4. [Running the project day to day](#4-running-the-project-day-to-day)
5. [Common problems and quick fixes](#5-common-problems-and-quick-fixes)
6. [Git workflow](#6-git-workflow)
7. [Team conventions](#7-team-conventions)
> Commands below are for **Windows PowerShell**. On macOS or Linux, replace `copy` with `cp` and use forward slashes in paths.
 
---
 
## 1. Project structure
 
```
JomIn/
├── backend/            NestJS API + Prisma
│   ├── prisma/         schema.prisma and migrations
│   ├── src/            modules, controllers, services
│   └── .env            Created on First-time setup
├── frontend/           Flutter app
│   ├── lib/            Dart source
│   └── android/        Android build config
├── scripts/            helper scripts (for example connect-phone.ps1)
└── README.md
```
 
How the parts talk to each other:
 
```
Flutter app  ──HTTP──▶  NestJS API  ──Prisma──▶  PostgreSQL
 (phone)                (your PC)                 (your PC)
```
 
The app never talks to the database directly. Every developer runs **their own local database**, so nobody can break anyone else's data.
 
---
 
## 2. What to install
 
| Tool | Version | Notes |
|---|---|---|
| **Git** | latest | Check: `git --version` |
| **VS Code** | latest | Extensions: Flutter, Dart, Prisma, ESLint |
| **Node.js** | **v26.x** (match the team's major version) | Check: `node -v`. npm comes with it |
| **PostgreSQL** | 16 or newer | Include **pgAdmin** in the installer |
| **Flutter SDK** | v3.47.9 | Extract to a path with no spaces, e.g. `C:\src\flutter`, and add `flutter\bin` to PATH |
| **Android Studio** | latest stable | For the Android SDK, emulator and licences (not compulsory) |
| **JDK 17** | 17 (LTS) | Used by Flutter's Android builds. **Not** JDK 25, see the pitfalls |
 
Android Studio → **Settings → Languages & Frameworks → Android SDK**:
 
- **SDK Platforms:** tick **Android 16.0 (API 36)**
- **SDK Tools:** tick Build-Tools, Command-line Tools, Platform-Tools, and Emulator (only if you use one)
- NDK and CMake are normally downloaded automatically on the first build
Optional: **Postman** or **Insomnia** to test API endpoints.
 
### Verify your tools
 
```
git --version
node -v
npm -v
flutter doctor -v
```
 
`flutter doctor` should show a green tick for the Android toolchain. Fix anything red before continuing. Accept Android licences with:
 
```
flutter doctor --android-licenses
```
 
---
 
## 3. First-time setup
 
### 3.1 Get the code
 
```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
 
git clone https://github.com/StartupRasyid/JomIn
cd JomIn
```
 
You need to be added as a collaborator on the GitHub repo first.
 
### 3.2 Create your local database
 
1. Open **pgAdmin** and connect to your server. Use the `postgres` password you set during installation.
2. Right-click **Databases → Create → Database...**
3. Name it `jomin_dev` and click **Save**.
Or from the command line (if `psql` is on your PATH):
 
```
psql -U postgres -c "CREATE DATABASE jomin_dev;"
```
 
### 3.3 Backend
 
```
cd backend
npm install
copy .env.example .env
```
 
Open `backend\.env` and fill in your values:
 
```
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/jomin_dev?schema=public"
```
 
- `postgres` is the default username, `5432` the default port.
- If your password contains special characters (`@`, `#`, `/`), URL-encode them (`@` becomes `%40`) or use a simpler local password.
- **Never commit `.env`.** It is already in `.gitignore`.
Create the tables and start the API:
 
```
npx prisma generate
npx prisma migrate dev
npm run start:dev
```
 
> This project's Prisma config file is named `prisma7.config.ts`. If a Prisma command ignores your settings or can't find the config, check the scripts in `backend/package.json` or add `--config prisma7.config.ts` to the command.
 
Success looks like `Nest application successfully started`. Optional: `npx prisma studio` opens a browser viewer for your tables.
 
### 3.4 Frontend
 
```
cd frontend
flutter pub get
flutter devices
flutter run
```
 
`flutter devices` lists where you can run the app (an emulator, a USB phone, Chrome or Edge).
 
**Telling the app where the API is.** TODO: state the file where the base URL is set. The address depends on where the app runs:
 
| App runs on | API address |
|---|---|
| Android emulator | `http://10.0.2.2:3000` (not `localhost`) |
| Real phone on the same Wi-Fi | `http://<your PC's local IP>:3000` (find it with `ipconfig`) |
| Chrome or Edge | `http://localhost:3000` |
 
For a real phone: turn on **Developer options → USB debugging**, plug it in, accept the prompt on the phone, and check it appears in `flutter devices`. The `scripts/connect-phone.ps1` helper may help here (TODO: describe what it does).
 
---
 
## 4. Running the project day to day
 
Open two terminals:
 
```
# Terminal 1: backend
cd backend
npm run start:dev
 
# Terminal 2: frontend
cd frontend
flutter run
```
 
After pulling new changes from GitHub:
 
```
cd backend
npm install                 # only if package.json changed
npx prisma generate         # only if schema.prisma changed
npx prisma migrate dev      # applies any new migrations from teammates
 
cd ../frontend
flutter pub get            # only if pubspec.yaml changed
```
 
If you're unsure, running all of them is harmless.
 
---
 
## 5. Common problems and quick fixes
 
### Backend and database
 
| Problem | Cause | Fix |
|---|---|---|
| `Configuration key "DATABASE_URL" does not exist` | No `.env` file, or it is in the wrong folder | Create `backend\.env` (next to `package.json`) from `.env.example` and set `DATABASE_URL`. Restart the server |
| `psql` is not recognised | PostgreSQL's `bin` folder isn't on PATH | Add `C:\Program Files\PostgreSQL\<version>\bin` to PATH and reopen the terminal. Or just use pgAdmin |
| `Can't reach database server` | PostgreSQL isn't running, or the port is wrong | Open Windows **Services**, start `postgresql-x64-<version>`. Check port 5432 |
| `Authentication failed` | Wrong password in `DATABASE_URL` | Fix the password. URL-encode special characters |
| `Database "jomin_dev" does not exist` | The database was never created | Create it (section 3.2). The name must match `DATABASE_URL` |
| `Cannot find module '.../generated/prisma'` | Prisma client not generated. It is not stored in Git | Run `npx prisma generate` |
| Tables missing, or a new column is "unknown" | Migrations not applied | Run `npx prisma migrate dev`. To wipe and rebuild your local database: `npx prisma migrate reset` |
| Strange `npm install` errors | Node version differs from the team's | Check `node -v`, match the team's major version, delete `node_modules`, run `npm install` again |
| Port 3000 already in use | Another process is using it | Close the other terminal, or change `PORT` in `.env` |
| `Running scripts is disabled on this system` | PowerShell execution policy | Run once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
 
### Flutter and Android
 
| Problem | Cause | Fix |
|---|---|---|
| `Unsupported class file major version 69` or "Gradle 8.3 incompatible with Java 25" | Flutter is using a JDK that is too new | Install **JDK 17**, then `flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot"` (use your real folder), then `flutter clean` |
| `Gradle version is lower than Flutter's minimum` | Android build files older than your Flutter SDK | Use the Gradle, Android Gradle Plugin and Kotlin versions already in the repo. Don't downgrade them or upgrade them on your own. Ask the team first |
| "Flutter support for Gradle/AGP/Kotlin will soon be dropped" | Version warning only | Safe to ignore for now. One person upgrades for everyone later |
| `NDK ... did not have a source.properties file` | An interrupted NDK download left a broken folder | Run `cd frontend\android; .\gradlew --stop`, delete `%LOCALAPPDATA%\Android\sdk\ndk\<that version>`, run `flutter run` again and let it re-download (over 1 GB) |
| `flutter doctor` says Android licences are not accepted | Licences not accepted | `flutter doctor --android-licenses`, answer `y` |
| Phone not listed in `flutter devices` | USB debugging off, or cable is charge-only | Enable USB debugging, use a data cable, accept the prompt on the phone |
| App can't reach the API (timeouts, connection refused) | Wrong base URL, different Wi-Fi, or firewall | Use the right address from section 3.4. Same Wi-Fi for phone and PC. Allow Node.js through Windows Firewall on private networks |
| Weird build errors after switching branches or pulling | Stale build cache | `flutter clean`, `flutter pub get`, run again |
| Nothing happens when running on Edge or Chrome | Web build is slow on first run | Wait. Use `flutter run -d edge`. Test the final app on Android |
| Warning about `--enable-native-access` | Java noise | Ignore it. It disappears with JDK 17 |
 
### Git
 
| Problem | Cause | Fix |
|---|---|---|
| `fatal: cannot switch branch while merging` | A merge is unfinished | Resolve conflicts and `git commit`, or cancel with `git merge --abort` |
| `both added` / `both modified` conflicts | You and a teammate changed the same file | See [Resolving conflicts](#resolving-merge-conflicts) |
| `rejected ... fetch first` or `non-fast-forward` | A teammate pushed first | `git pull origin main` (or `git pull --rebase`), then push again |
| `403` or `Permission denied` | Not a collaborator, or the wrong account is signed in | Ask to be added. Sign in through the browser prompt, or use a personal access token (passwords no longer work) |
| Hundreds of files in `git status` (`node_modules`, `.claude`, `generated`...) | Not covered by `.gitignore` | Add them to `.gitignore`, then `git rm -r --cached <path>` and commit |
| Pushed or committed `.env` by mistake | `.env` was tracked | `git rm --cached backend/.env`, commit, and **change the exposed passwords and keys**. Deleting the file doesn't remove it from history |
| A folder shows up empty on GitHub | A nested repo (a subfolder with its own `.git`) | Delete the subfolder's `.git` folder, then `git rm --cached <folder>` and re-add |
| Warning about CRLF or LF line endings | Windows vs Linux line endings | Harmless. `.gitattributes` handles it |
 
---
 
## 6. Git workflow
 
### The rules
 
1. **`main` always works.** Never commit or push directly to `main`.
2. **One task = one branch = one pull request (PR).**
3. **Pull `main` before you start** so you build on the latest work.
4. **Someone else reviews** your PR before it merges.
5. **Keep PRs small.** A PR that does one thing gets reviewed fast and rarely conflicts.
### Everyday flow
 
```
# 1. Start from an up-to-date main
git switch main
git pull origin main
 
# 2. Make a branch for your task
git switch -c feature/signup-screen
 
# 3. Work, then check what changed
git status
git diff
 
# 4. Commit (as often as you like, in small logical steps)
git add .
git commit -m "feat(auth): add signup form validation"
 
# 5. Push your branch
git push -u origin feature/signup-screen      # first push of the branch
git push                                       # later pushes
 
# 6. Open a pull request on GitHub, ask for a review, then merge
```
 
After your PR is merged:
 
```
git switch main
git pull origin main
git branch -d feature/signup-screen
```
 
### Branch names
 
Use `type/short-description`, lowercase, with hyphens.
 
| Prefix | Use for | Example |
|---|---|---|
| `feature/` | New functionality | `feature/post-editor-stickers` |
| `fix/` | Bug fixes | `fix/login-error-message` |
| `docs/` | README and documentation | `docs/update-setup` |
| `chore/` | Config, dependencies, cleanup | `chore/upgrade-gradle` |
 
### Commit messages
 
Format: `type(scope): short summary in the present tense`
 
```
feat(auth): add register endpoint
fix(feed): stop duplicate posts on scroll
docs: add setup troubleshooting table
chore(android): pin JDK 17 in README
```
 
Keep the first line under about 70 characters. Say what changed and why, not "update" or "fix stuff".
 
### Before you push, check
 
- `git status` shows only the files you meant to change.
- No `.env`, `node_modules`, build folders, or passwords are included.
- The app still builds (`npm run start:dev`, `flutter run`).
### Keeping your branch up to date
 
If `main` moved while you were working (a teammate's PR merged), bring it into your branch:
 
```
git switch feature/signup-screen
git pull origin main          # merges the latest main into your branch
```
 
Fix any conflicts (below), run the app, then push. Do this before opening your PR, and again if GitHub says the branch is out of date.
 
### Resolving merge conflicts
 
A conflict means two people changed the same lines. Git marks the file like this:
 
```
<<<<<<< HEAD
your version
=======
teammate's version
>>>>>>> origin/main
```
 
1. Open the file in VS Code. Use the **Accept Current / Accept Incoming / Accept Both** buttons above each conflict, or edit by hand.
2. Delete all the `<<<<<<<`, `=======` and `>>>>>>>` lines.
3. Test that the project still works.
4. Finish:
```
   git add <the file>
   git commit
```
5. If you get stuck, `git merge --abort` returns to before the merge. Then ask the team.
Generated files such as `pubspec.lock` or `package-lock.json`: take the version from `main`, then run `flutter pub get` or `npm install` and commit the result.
 
### Handy rescue commands
 
| Situation | Command |
|---|---|
| Discard changes to one file (cannot be undone) | `git restore <file>` |
| Unstage a file but keep the changes | `git restore --staged <file>` |
| Undo the last commit but keep the changes | `git reset --soft HEAD~1` |
| Save work in progress to switch branches | `git stash`, then `git stash pop` later |
| Stop tracking a file but keep it on disk | `git rm --cached <file>` |
| See recent history | `git log --oneline -10` |
| See which branch you're on | `git branch --show-current` |
 
### Things not to do
 
- Don't use `git push --force` on a shared branch. It can erase teammates' work.
- Don't commit `.env`, passwords, API keys, `node_modules`, `build/`, or `src/generated/prisma`.
- Don't start new work on a stale `main`. Pull first.
- Don't leave a branch open for weeks. Merge small pieces often.
- Don't edit the Prisma schema, Gradle versions, or other shared config without telling the team.
### Database changes (Prisma)
 
The database structure is shared through **migrations**, not by copying databases.
 
1. Edit `backend/prisma/schema.prisma`.
2. Run `npx prisma migrate dev --name describe_the_change`. This creates a new folder in `backend/prisma/migrations`.
3. **Commit the migration folder** together with the schema change.
4. Teammates pull and run `npx prisma migrate dev` to update their own database.
Never edit a migration that has already been merged. Create a new one instead. If two people change the schema at once, the second person pulls `main`, resolves conflicts, and regenerates their migration.
 
---
 
## 7. Team conventions
 
**Definition of Done.** A task is finished only when:
 
- the code is merged to `main` through a reviewed PR,
- the acceptance criteria are tested,
- it runs on a real device or emulator against the backend,
- there are no hardcoded secrets or URLs (use `.env` or a config file),
- new endpoints appear in the API docs (TODO: Swagger URL, for example `http://localhost:3000/api`),
- any new environment variable is added to `.env.example`.
**Secrets.** Share passwords and API keys privately, never in a public chat, an issue, or a commit.
 
**Updating this README.** If you hit a new problem and fix it, add it to section 5 so the next person doesn't lose the same time.
 
**Ask early.** If something is blocked for more than about 30 minutes, post the exact error message in the group chat. Include the command you ran and the full output, not a screenshot of the last line.
 