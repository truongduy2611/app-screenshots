# Google Play Custom Store Listings

## Why there is no upload path

App Store Connect exposes Custom Product Pages through the API
(`appCustomProductPages` → `appCustomProductPageVersions` →
`appCustomProductPageLocalizations`), so the ASC upload sheet can target one
directly. Google Play has no equivalent.

The Android Publisher v3 API has **no custom store listing surface at all**. Its
`edits.*` sub-resources are `apks`, `bundles`, `countryavailability`,
`deobfuscationfiles`, `details`, `expansionfiles`, `images`, `listings`,
`testers`, and `tracks`. Of those:

- `edits.listings` is keyed by **`language` only** — the schema is
  `{language, title, shortDescription, fullDescription, video}`.
- `edits.images` is keyed by **`language` + `imageType`**.

There is no listing-ID dimension anywhere, so every API write necessarily lands
on the main store listing. Searching the live discovery document for
`customStoreListing`, `storeListingGroup`, or `listingGroup` returns nothing.
fastlane's `supply` hits the same ceiling for the same reason.

Verify this against the current API with:

```bash
curl -sL 'https://www.googleapis.com/discovery/v1/apis/androidpublisher/v3/rest' | grep -ic customstorelisting
```

The feature itself is neither deprecated nor unsupported — Google is still
investing in it (Play Console can now generate a listing from a keyword
recommendation). It is simply **Play Console–only**.

## What we do instead

[`PlayCslExporter`](../../packages/app_screenshots_shared/lib/src/play/play_csl_export.dart)
lays screenshots out in the shape of the Console form and writes an `UPLOAD.md`
walkthrough:

```
out/
├── UPLOAD.md
└── fitness-keyword/            ← one custom store listing
    └── en-US/                  ← the language picker on the listing page
        └── phoneScreenshots/   ← the "Phone" uploader
            ├── 01.png
            └── 02.png
```

The exporter lives in `app_screenshots_shared` so the desktop app and the CLI
share one implementation, alongside the Play vocabulary
(`kPlayImageTypes`, `kPlayMaxScreenshotsPerType`, `playLocaleFor`) that
`PlayUploadService` also consumes.

Behaviour worth knowing:

- **Locales are mapped to Play codes.** `en` → `en-US`, `zh-Hant` → `zh-TW`.
  Same mapping the API upload uses, so folder names match Console.
- **Files are renumbered** `01`, `02`, … in display order; extensions are
  preserved.
- **The 8-per-locale cap is enforced** at export time, with a warning, rather
  than letting Console reject the upload halfway through.
- **Slugs double as URL parameters.** `fitness-keyword` is valid in
  `?id=<package>&listing=fitness-keyword`, so a listing targeted by URL needs no
  second naming decision.
- **`clean` (default on)** wipes each listing folder first, so a re-export never
  leaves screenshots behind that the design no longer has.

## Entry points

| Surface | How |
|---|---|
| Desktop app | Play upload sheet → **Destination: Custom store listing**. No service account needed — the sheet stays reachable without credentials in this mode. |
| CLI | `appshots play export-csl --listing NAME --source DIR --out DIR`. Runs entirely locally; the app does not need to be running. |

Because the export touches no credentials and no network, it deliberately does
**not** go through the local command server the way `play upload` does.

## If you are tempted to automate the Console

Driving `play.google.com/console` with browser automation was considered and
rejected: it breaks whenever Google changes the DOM, needs an interactive
logged-in session, cannot run headless in CI, and risks tripping bot detection
on an account that publishes apps. The export kit is the durable option until
Google ships an API.
