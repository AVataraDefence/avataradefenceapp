# Avatara Defence — mobile app (Flutter)

Mobile client for the Avatara Defence web app (`../avataradefence`, Next.js). This first
step sets up the **design system**: the web app's theme and UI components, rebuilt in
Flutter so every screen that follows looks like the web app.

## Screens (connected to the web API)

Every web page is rebuilt for the phone at the **same path**: `src/app/module/employee/bank/page.tsx` →
`lib/app/module/employee/bank/page.dart`, routed by the same URL (see `lib/app/routes.dart`).
Shared shell: `lib/components/layout`; list + form pages use `lib/components/crud/crud_page.dart`, which
takes a `CrudApi('/api/…', idKey: …)` and does GET / POST / PUT / DELETE itself. Field keys are the API's own
names, so a page is just its fields and columns.

Data layer (`lib/data`): `app_api.dart` (client + live socket, token kept in secure storage),
`session.dart` (sign in / out, permissions that hide modules and menu items), `directory.dart` (employees, users,
departments … used by pickers), `notifications_store.dart` (list + WebSocket push), `models.dart` (tasks).

Start the web project first (`npm run dev`); the phone reaches it at `ApiConfig.deviceUrl`.
Check the field names against the running server with
`dart run -DAPI_BASE_URL=http://localhost:3000 tool/live_check.dart <jwt>`.

## Push notifications (Firebase)

Popup + chime while the app is closed, and everything missed while offline when the internet returns, comes from
Firebase Cloud Messaging. One-time setup:

1. `npm i -g firebase-tools` → `firebase login` → `dart pub global activate flutterfire_cli` → `flutterfire configure --project=avataradefence`
   (run in this folder; it replaces `lib/firebase_options.dart`). Until then the app runs without push.
2. Firebase console → Project settings → Service accounts → *Generate new private key*, then in the **web** project's
   `.env`: `FIREBASE_SERVICE_ACCOUNT_PATH=C:/path/to/key.json` and restart `npm run dev`.
3. iOS only: upload an APNs key in Firebase (Project settings → Cloud Messaging) and enable Push Notifications in Xcode.

Flow: sign in → `PushService.register()` posts the phone's token to `POST /api/devices` → every new notification
(`src/lib/notify.ts`) is also sent to that token (`src/lib/push.ts`).

## Run

```bash
flutter pub get
flutter run            # opens the component gallery
```

The app currently opens on the **Component gallery** (`lib/features/gallery`): every theme
token and component, with a light / dark toggle (moon / sun in the header). Use it to
compare with the web. Replace `home:` in `lib/main.dart` when the real screens exist.

## Layout

```
lib/
  core/
    core.dart                 one import: theme + components
    theme/
      app_colors.dart         web tokens (globals.css :root / .dark), as `context.colors`
      app_tokens.dart         radius (10px base), spacing, control sizes, motion
      app_typography.dart     Poppins + Tailwind type scale
      app_theme.dart          Material ThemeData built from the tokens (light + dark)
      theme_controller.dart   light / dark / system switch (ThemeScope)
    ui/                       component library (counterpart of web components/ui)
  features/gallery/           living style guide
assets/fonts/                 Poppins 300–800 (the web font, bundled)
```

## API (reuses the web project's `/api/*`)

The app talks to the same Next.js server as the website; nothing is duplicated.

```
lib/core/api/
  api_config.dart      base URL(s) — the only place to edit addresses
  api_endpoints.dart   every route by name (ApiEndpoints.tasks, ApiEndpoints.task(id) …)
  api_client.dart      HTTP client: JSON envelope, session cookie, uploads, friendly errors
```

**Base URL** (`ApiConfig`): defaults to the live site `https://avataradefenceerp.cloud`. Switch without editing code:

```bash
flutter run                                   # live site (default)
flutter run --dart-define=API_ENV=device      # PC on the same Wi-Fi → 192.168.1.6:3000
flutter run --dart-define=API_ENV=emulator    # Android emulator → 10.0.2.2:3000
flutter run --dart-define=API_ENV=local       # iOS simulator / desktop → localhost:3000
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000   # any server
```

If the PC's IP changes, update `ApiConfig.deviceUrl` (find it with `ipconfig`). The web
server must be started with `npm run dev` (it listens on all interfaces). Check reachability:

```bash
dart run tool/ping_api.dart
```

**Auth:** the web uses an HttpOnly `session` cookie (JWT). `ApiClient` captures it from the
sign-in response, stores it in a `SessionStore` (in-memory for now; use secure storage once the
login screen exists) and sends it on every call — also needed for the `/ws` notification socket
(`ApiConfig.webSocketUrl`, header `Cookie: ${api.cookieHeader}`).

```dart
final api = ApiClient(onUnauthorized: () => goToLogin());
final r = await api.get(ApiEndpoints.tasks, query: {'scope': 'mine'});
if (r.ok) { final tasks = r.data as List; } else { showError(r.message); }

await api.postMultipart(ApiEndpoints.taskDocuments(17), files: [await http.MultipartFile.fromPath('files', path)]);
```

**Real-time notifications:** `ApiSocket` (in `api_socket.dart`) connects to `/ws` with the session
cookie and reconnects by itself:

```dart
final socket = ApiSocket(api)..connect();           // after sign-in
socket.notifications.listen((n) => showBadge(n));   // same shape as GET /api/notifications
socket.connected.listen((live) => setDot(live));
// on sign-out: socket.disconnect();
```

**Files / photos (MinIO):** the app never talks to MinIO itself. Uploads go through the web API
(`postMultipart`), which stores them in MinIO; the API answers with a 1-hour signed `fileUrl`
(documents) or a public `imageUrl` (profile photos) pointing at the MinIO server
(`http://187.127.191.130:9000`). Open that URL with any HTTP/image widget. It is plain `http://` for
now, so iOS has an ATS exception for that IP; for release builds MinIO needs https.

Notes: there is no `GET /api/tasks/<id>` (only list, PUT, DELETE) — read one task from the list.
Request / response bodies: `../avataradefence/postman/`. Plain `http://` is allowed for debug /
profile builds only (Android `usesCleartextTraffic`, iOS `NSAllowsLocalNetworking`); release must use https.

## Using the design system

```dart
import 'package:avataradefence/core/core.dart';

AppButton(label: 'Save', icon: LucideIcons.check, onPressed: save);
AppButton(label: 'Delete', variant: AppButtonVariant.destructive, onPressed: remove);
AppInput(label: 'Task title', hint: 'e.g. Coordinate sweep', error: titleError);
AppSelect<String>(label: 'Priority', options: priorities, value: p, onChanged: setP);
AppCard(title: 'Task Details', child: …);
final c = context.colors;        // c.primary, c.mutedForeground, c.border …
```

| Web (`components/ui`) | Flutter |
|---|---|
| Button | `AppButton`, `AppIconButton` (primary · outline · secondary · ghost · destructive · link) |
| Input, Textarea, Field, Label | `AppInput`, `AppInput.multiline`, `AppPasswordInput`, `AppSearchField`, `AppField` |
| Select, Combobox, multi-select | `AppSelect`, `AppMultiSelect` (bottom sheet with search) |
| Checkbox, Switch, RadioGroup | `AppCheckbox`, `AppSwitch`, `AppRadioGroup` |
| Calendar / date input | `AppDateField` |
| Badge | `AppBadge` (+ `TaskStatusBadge`, `TaskPriorityBadge`, `ProjectStatusBadge`) |
| Card | `AppCard`, `TaskCard` |
| Avatar | `AppAvatar`, `AppAvatarStack` |
| Progress, Skeleton, Spinner | `AppProgress`, `AppSkeleton`, `AppSpinner` |
| Alert, Empty | `AppAlert`, `AppEmpty` |
| Dialog, AlertDialog, Sheet, Drawer | `showAppDialog`, `showAppConfirm`, `showAppSheet`, `showAppActionSheet` |
| Sonner (toast) | `AppToast.show / success / error` |
| Tabs, Pagination, Accordion, Separator | `AppTabs`, `AppPagination`, `AppAccordion`, `AppSeparator` |
| Table | `AppTable` |
| Header, Sidebar | `AppHeader`, `AppBottomNav`, `AppMenuItem`, `AppMenuSection`, `AppModuleTile` |

## Differences from the web (on purpose)

- **Control heights** are touch-friendly: 44 px default (web 32), 36 small, 28 extra small,
  48 large. Radii, colours and type sizes are identical. Tune them in `core/theme/app_tokens.dart`.
- **Selects** open a bottom sheet instead of a small popup.
- **Icons** are Lucide (`lucide_icons_flutter`), the same set as the web.
- Colours were converted from the web's `oklch()` values to sRGB; the light primary is `#432DD7`.

## Tests

```bash
flutter test
flutter test --dart-define=SCREENSHOTS=true --update-goldens   # writes test/screenshots/*.png
```
