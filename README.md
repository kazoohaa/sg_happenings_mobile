# SG Happenings

SG Happenings is a Flutter mobile app prototype for finding things to do around Singapore. It brings event discovery, event information, and community participation into one place, with a warm, approachable interface designed for exploring local happenings.

## What You Can Explore

- **Discover events:** The home screen highlights nearby and featured events, with category labels such as music, art, and food. It also includes a map preview and search entry point.
- **Browse event details:** Event cards show information such as the date, time, and venue. Detail screens add a description, organizer, category tags, and a bookmark control.
- **Keep up with updates:** The notifications screen presents sample event updates and reminders, with All and Unread views and a mark-as-read action.
- **Manage a profile:** Profile and account screens cover sign-in, sign-up, password recovery, and profile editing.
- **Apply to post events:** An application form collects contact and organization details, portfolio information, event categories, and operating area.

## Prototype Status

This project currently demonstrates the app's interface and user flows. Event listings and notification content are sample data; the map, search, and several account controls are presentation UI. The poster application performs local form validation and displays a confirmation, but does not send data to a service. Authentication, live event data, map services, file uploads, and persistent bookmarks are not connected.

## Technology

- Flutter
- Dart

## Run Locally

Install the Flutter SDK and start an emulator or connect a device. From the repository root, run:

```bash
cd sg_happenings_mobile
flutter pub get
flutter run
```
