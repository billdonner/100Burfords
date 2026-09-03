<!-- MASTERINDEX:START -->
## MasterIndex coordination

For portfolio-wide, cross-repository, cross-app, cross-machine, periodic, or operational work, read these files in order:

1. `~/masterindex/current/index.json`
2. `~/masterindex/tasks/index.json`
3. `~/masterindex/current/handoffs/index.json`

Use `entities[].id` as canonical target keys. Apply active handoff directives addressed to the target entity or `all-entities`. The task registry requires a verification every six hours and an observed-fact refresh every day. When facts change, update `current/index.json` before `current/inventory.md`; record gaps and ambiguities explicitly.

This delimited block is managed by MasterIndex. Preserve all instructions outside it.
<!-- MASTERINDEX:END -->

## Release lanes (set up 2026-09-03)

- **TestFlight from this Mac:** `xcodebuild archive` + `-exportArchive` with `ExportOptions.plist`, then
  `xcrun altool --upload-app -f build/export/Burfords.ipa -t ios --apiKey MN6H2P6385 --apiIssuer 69a6de6f-2572-47e3-e053-5b8c7c11a4d1`.
  Works for TestFlight only — local archives fail App Store ingestion (ITMS-90111) while this Mac is on the macOS 27 beta.
- **App Store archives go through Xcode Cloud.** ciProduct `a6fb8847-f1fc-483e-8dcb-61d817e2c0c3` (Burfords);
  workflow `C6D6A4EE-2EE2-4884-8471-F3EA1244457A` "Archive → TestFlight & App Store" — manual start only,
  ARCHIVE action with Deployment Preparation = App Store Eligible, pinned to Xcode 26.6 (17F113). Start a run with
  `POST /v1/ciBuildRuns` (workflow + the `main` scmGitReference). Cloud runs stamp their own build number
  (1, 2, …) independent of `project.yml`; uniqueness is per marketing version, so keep the local counter
  well above the cloud counter.
- ASC app id `6766107636`. Version records: 1.0 live, 1.2 in Prepare for Submission (renamed from the never-submitted 1.1).
- **Data refresh from West Side Rag:** see the `wsr-scrape-method` memory — WebFetch the Sunday day archives
  (curl is Cloudflare-blocked), cartoon may post Saturday night, catalog `date` is always the Sunday.
- **Print pipeline test:** launch with `--export-print-pdfs`; every print job lands in the app container's
  `Documents/PrintExport/` as Letter PDFs plus `manifest.json`.
