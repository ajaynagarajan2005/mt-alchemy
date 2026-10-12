# Maintenance guide

## Everyday tasks

| Task | Where | How |
|---|---|---|
| Add or edit a course | Trainer portal › Courses | **New course**: add video, PDF, reading and quiz lessons, then toggle **Published** |
| Add a product | Super Admin › Products | **New product**. Choose Shipped (set stock) or Digital download (set a file link) |
| Upload a new PDF | `web/downloads/` | Add the file, run `flutter build web`, then deploy. Link it as `/downloads/<file>.pdf` |
| Ship an order | Super Admin › Orders and shipping | **Mark as shipped**, then **Mark as delivered**. The buyer is notified each time |
| Reply to an enquiry | Super Admin › Enquiries | Move it through the status chips and save the programme proposal |
| Give someone staff access | Super Admin › Users | Change their role, or create an account with **New user** |
| Remove access | Super Admin › Users | **Disable**. The person is signed out on their next action |
| See who is on a course and what they paid | Courses › **Students** | Counts for enrolled, paid, employer seats and free access, plus amount received and each person's progress |
| Give someone a course free, or remove them | Courses › Students | **Give free access** (search by name or email) or the bin icon. A paid student is not refunded automatically |
| Try a course without paying | Courses › play icon, or **Open course free** | Admin preview: progress is not saved |

## Deploying

```bash
flutter build web --release
firebase deploy --only hosting            # site
firebase deploy --only firestore:rules    # after editing firestore.rules
firebase deploy --only firestore:indexes  # after editing firestore.indexes.json
```

## Changing the data model

1. Update the model's `toMap` / `fromMap` in `lib/data/models/`. Readers fall back to defaults, so old documents keep working.
2. If the field is needed in seed data, update `lib/data/mock/`, then run `cd tools/seed && npm run seed`.
3. Add a rule in `firestore.rules` if the field controls access. Extend `tools/seed/verify.mjs` with an allow check and a deny check.
4. Run `flutter test` and `npm run verify`.

## Videos

The hero, services and brand videos are Remotion compositions in `video/src`.

```bash
cd video
npm install
npm run render:all   # writes assets/videos/*.mp4 (H.264, under 5 MB each)
npm run still        # hero poster
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "You do not have permission to do that." | A security rule refused the write | Check the role in `users/{uid}`. Test the case in `verify.mjs` |
| Catalogue shows but never updates | Firestore unreachable (offline or a blocked network) | The app keeps showing the bundled catalogue. Check the console for "Could not reach Cloud Firestore" |
| A query fails with "requires an index" | A new compound query | Follow the link in the error, or add it to `firestore.indexes.json` and deploy |
| Login works but the portal is empty | The profile document is missing | Re-run the seed, or create `users/{uid}` with a `role` |

## Security notes

- Payments run in test mode only (`gateway: test-mode`). No card data is stored, only the last 4 digits.
- The seed opens bootstrap rules while it writes, then redeploys the real rules automatically. Rule changes can take a few minutes to reach every Firestore server, so wait about 3 minutes after `npm run seed` before running `npm run verify` (early runs can still see the open rules). Never deploy `tools/seed/bootstrap.rules` on its own.
- The Firebase web API key in `lib/firebase_options.dart` is public by design. Access is enforced by Auth and the security rules.
