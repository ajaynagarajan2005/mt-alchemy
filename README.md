# MT Alchemy

A human-centred learning and people-development platform for MT Alchemy, built in Flutter with a Firebase backend (NET4207 group project).

**Live site:** https://ajaynagarajan2005.github.io/mt-alchemy/ · **Virtual tour:** https://ajaynagarajan2005.github.io/mt-alchemy/tour · **Code:** https://github.com/ajaynagarajan2005/mt-alchemy

> We don't just run activities. We shift mindsets, behaviours, and team culture.

The platform has four modules: a corporate website, an LMS, an e-commerce store and role-based portals for five roles (Guest, Individual, Employer, Trainer, Super Admin).

## Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter 3.47 (web, Android, iOS), Material 3 with a custom red / white / ash glassmorphism theme |
| Navigation | go_router with role-based redirects |
| State | Provider (`ChangeNotifier` stores in `lib/state/`) |
| Backend | Firebase Authentication (email and password), Cloud Firestore (asia-southeast1) |
| Security | Firestore rules in `firestore.rules`, with roles read from `users/{uid}.role` |
| Charts | fl_chart (employer analytics) |
| Motion | flutter_animate, Remotion loops (`video/`), a GLB crystal through flutter_3d_controller |

## Getting started

```bash
flutter pub get
flutter run -d chrome
```

The Firebase config is already generated in `lib/firebase_options.dart` for project `mt-alchemy-net4207`. To point the app at a different project:

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id> --platforms=web,android
firebase deploy --only firestore,auth
```

### Seeding the database

The seed script needs no npm packages. It calls Firebase over REST.

```bash
cd tools/seed
npm run seed     # export catalogue, open bootstrap rules, write data, redeploy secure rules
npm run verify   # 33 live checks: every journey and every forbidden write, per role
```

`npm run seed` is safe to repeat because every document has a fixed id.

### Demo accounts

All demo accounts use the password `alchemy123`. The Login screen also lists them.

| Role | Email | What to try |
|---|---|---|
| Individual | amara@example.com | Course in progress, an order being shipped, a digital download |
| Employee (individual) | callum@northlight.example.com | Courses assigned by an employer, a certificate |
| Employer | priya@northlight.example.com | Employees, seats, assignments, progress report, analytics |
| Trainer | maya@mtalchemy.example.com | Course CRUD with video, PDF and quiz lessons, open courses free, students and free access |
| Super Admin | admin@mtalchemy.example.com | Open any course free, see who is enrolled and what they paid, add or remove people, users, products, orders and shipping, enquiries, content |

## The five journeys

| Journey | Path through the app |
|---|---|
| A. Individual learning | Register → Upskilling → course → **Buy course** → Checkout (test card 4242 4242 4242 4242) → Start learning → video, PDF and quiz lessons, progress %, Previous / Mark complete / Next → pass quiz → certificate (`/certificates/<code>`, publicly verifiable) |
| B. Digital product | Store → EI Self-Coaching Toolkit → Add to cart → Checkout → Portal › **My downloads** → Download |
| C. Physical product | Store → Feedback Conversation Cards → Cart → Checkout with a shipping address → Portal › **Orders** shows Processing. Super Admin › Orders marks it Shipped, then Delivered, and the buyer gets a notification at each step |
| D. Employer | Register as an organisation → Employees › add people → Upskilling › course › **Buy seats** → Checkout → Assign courses → Progress report and Analytics charts |
| E. Corporate enquiry | Footer › For organisations (or the home page "Design a programme") → submit an enquiry → Super Admin › Enquiries: status pipeline and a customised programme proposal |

## Project structure

```
lib/
  data/        backend.dart, models/ (toMap/fromMap), mock/ (seed and offline catalogue)
  state/       auth, catalog, cart, commerce, learning, org, admin, notification stores
  router/      routes.dart (every path), app_router.dart (role guards, transitions)
  screens/     public site, learn/ (course player), portal/ (learner, employer, trainer, super)
  widgets/     GlassPanel, AlchemyButton, Reveal, TiltCard, ReviewsSection, layout shells
  theme/       colour, typography, spacing, radii and motion tokens (light and dark)
firestore.rules, firestore.indexes.json, firebase.json
tools/seed/    seed.mjs, verify.mjs, bootstrap.rules
web/downloads/ branded PDF workbooks and digital products
video/         Remotion project for the hero, services and brand videos
docs/          ER diagram, maintenance guide
```

## Testing

```bash
flutter analyze
flutter test                      # stores on fake Firestore and validators
flutter build web --release
node tools/serve_web.mjs 8080     # serves build/web with a single-page-app fallback
```

## Rubric pointers

- **Scaffold.** `AppShell` handles public pages and `PortalShell` handles signed-in portals. Both have an AppBar. Search for `SCAFFOLD:`.
- **Container.** Cards, padding, decoration and grouping throughout. Search for `CONTAINER (`.
- **Form.** Login, Register (gender radio, country dropdown, hobby checkboxes), Contact, Checkout, Organisations enquiry, Reviews, Course editor, Product editor and Profile. Search for `FORM:`.
- **CRUD.** Courses (Trainer and Super Admin), Products, Users, Articles and Impact Stories (Super Admin), Employees and Assignments (Employer).
- **Extras.** EQ self-assessment with course recommendation, employer analytics charts, an Impact Stories carousel, dark mode, public certificate verification and in-app notifications.

Documentation: **`docs/MT_Alchemy_Documentation.pdf`** (every page of the site with screenshots, architecture, data model, security, journeys, testing, deployment; source in `docs/documentation/`), `docs/MT_Alchemy_Architecture.pdf` (short architecture guide), `docs/ER_DIAGRAM.md` and `docs/MAINTENANCE.md`.
