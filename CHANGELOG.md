# Changelog

Notable project changes are recorded here.

## [Unreleased] - 2026-11-28

### Added

- Email verification screen in the Flutter app, including automatic token verification and a resend option.
- Verification email links that honor the Flutter web app's request origin and use GoRouter's hash URL format.
- Public event feed endpoints: `GET /api/v1/events` and `GET /api/v1/events/:eventId`.
- Home feed cards showing event details, organizer, like/comment counts, and a registration link when one is attached to the post.
- External registration link opening through `url_launcher`.
- Home account status loaded from `/auth/me`; the guest banner is shown only for visitors without a valid session.
- Role-aware navigation: the Create tab is shown only to organizers; guests see browsing tabs, and signed-in users also see Saved and Profile tabs.

### Changed

- Successful registration now leads to the email verification screen.
- Event endpoints are registered in the NestJS application.

### Notes

- The `RolesGuard` currently protects the existing admin test endpoint. Event creation, editing, deletion, likes, comments, saves, and organizer statistics are not implemented yet, so those permissions are not enforced by event APIs.
- The organizer Create screen is still a media picker placeholder and does not publish an event post.
- Flutter analysis did not complete in this environment; the backend build completed successfully.
