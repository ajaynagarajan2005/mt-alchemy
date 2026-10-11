# MT Alchemy - Flutter app (NET4207 group project)

## Goal
Human-centred digital platform for MT Alchemy (People Development Consultancy: Emotional Intelligence,
Leadership Development, Team Engagement, Workplace Well-being).
Modules: Corporate Website, LMS, E-Commerce Store, Role-Based Portals (Individual, Employer, Trainer/Admin).
Tagline: "We don't just run activities. We shift mindsets, behaviours, and team culture."

## Must-haves (marking rubric, never break these)
- Scaffold + AppBar on main screens
- Container used for at least 3 meaningful purposes (grouping, padding, decoration, cards)
- At least one Form with TextFormField and required-field validation (Login/Register, Contact)
- Navigation with go_router: Home, About, Services, Upskilling, Store, Insights, Contact, Login/Register, Cart
- Journey A: Visitor -> Register -> Browse Learning -> Enrol -> Course
- Journey B: Store -> Product -> Cart -> Checkout
- Journey C: Register Organization -> Add Employees -> Assign Course -> View Progress
- Responsive from 360px to 1440px (use the flutter-build-responsive-layout skill)
- No Firebase/backend for the Oct 14 checkpoint; use local mock data in lib/data/

## Design system
- Colours: white / grey / red. Off-white #FCFCFC base, neutral zinc grey scale (#F4F4F5 to #18181B),
  Crimson Red #C8102E as the single accent (CTAs, active states, progress, focus).
  Story: grey -> red = transformation ("alchemy"); grey-to-red gradients only at moments of change
- Glassmorphism: shared GlassPanel (BackdropFilter blur, translucent white fill, 1px light border)
  over soft red/grey blurred blobs or video. Use on nav, hero copy, service cards, summaries,
  auth card, portal tiles. Few per viewport, never nested; solid fallback for high contrast.
- Fonts: Fraunces (headlines), Manrope (body), via google_fonts
- All tokens live in lib/theme/ (colors, typography, spacing, radii). Never hard-code colours or sizes in widgets.
- Feel: calm, artistic, generous whitespace, soft gradients, subtle grain, organic rounded shapes.
  Avoid the generic Material look and stock purple-gradient templates.
- Reusable widgets live in lib/widgets/

## Motion
- Home: looping muted hero video (assets/videos/hero_loop.mp4) with a still-image placeholder,
  then zoom-through scroll into Services (ScrollController + Transform.scale + Opacity)
- Staggered text and card reveals with flutter_animate
- 3D: tilt cards using Matrix4 perspective; one GLB crystal/flask via flutter_3d_controller (final project phase)
- Respect reduced motion (MediaQuery.disableAnimations); target smooth 60fps on Flutter web

## Videos
- Hero loop: generate with the fal MCP (abstract crimson ink blooming through clear water on a soft
  white-grey background, cinematic, seamless loop, 6-10 s). ALWAYS show me the model and price and wait for my OK before running.
- Brand intro and section videos: Remotion project in /video (use the Remotion skills),
  rendered to assets/videos/*.mp4, H.264, under 5 MB each (compress with ffmpeg)

## Tools and checks
- The Dart MCP server is disabled (blocked by Windows Smart App Control). Use the terminal instead:
  flutter pub get, flutter analyze, flutter test, flutter run -d chrome, flutter build web
- Visual checks: serve the web build and use the Playwright MCP to take screenshots at 375px and 1440px

## Workflow rules
- Use plan mode first; wait for my approval before building
- Build one screen or phase at a time
- After each screen: flutter analyze (zero errors), web build, Playwright screenshots, fix issues, then summarise
- Commit after each working screen with a clear message
- Add short comments explaining where Scaffold, Container and Form are used (needed for the report)
