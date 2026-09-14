# Onwards

A notepad that shows you what's actually yours.

It's easy to lose track of how much of a document is your own thinking. You
paste one line, then another, and by the end the voice isn't yours. Onwards
marks anything you paste. Everything else is you.

No account, no server, no tracking. Your writing stays on your machine.

## What it does

- **Pasted text is marked** as you write, in a soft lilac wash
- **Claim it back** — hover a mark and click *Mine* when a passage really is yours
- **A margin rule** shows the grain of the document: where the borrowed passages sit
- **Receipt** — a shareable card rendering your page as a fingerprint, dark where you
  wrote and lilac where you borrowed
- **Export** to Markdown with the provenance intact (`==pasted text==`), plain text,
  or print
- **Save to a folder** — pick a folder once and Onwards keeps real `.md` files there
  (Chrome/Edge; everywhere else use the export menu)

## Running it

It's a static site. Any web server will do:

```bash
python3 serve.py
```

Then open <http://127.0.0.1:8830>.

- `index.html` — the landing page
- `app/` — the writing app
- `app/fonts/` — Lato

## Deploying

Anything that serves static files works. For GitHub Pages:

1. Push this repo to GitHub.
2. **Settings → Pages → Source: Deploy from a branch**, branch `main`, folder `/ (root)`.
3. The landing page is at `/`, the app at `/app/`.

To collect emails for the Mac app, set `FORM_ENDPOINT` near the top of the
`<script>` in `index.html` to a Formspree, Buttondown or Tally endpoint. Until
you do, the form says so rather than pretending to work.

## The Mac app

A native shell (Swift + WKWebView) around the same web app.

```bash
./mac/build.sh      # → mac/build/Onwards.app, ad-hoc signed, runs on this machine
./mac/release.sh    # → signed, notarised .dmg + .zip for everyone else
```

The app serves its own files over a custom `onwards://` scheme rather than
`file://`, because WKWebView refuses `localStorage` on file origins — and
`localStorage` is where the writing lives.

**Folder-saving is browser-only.** `showDirectoryPicker` doesn't exist in
WKWebView, so the Mac app hides that option and relies on the export menu.

### Shipping a release

1. Paid Apple Developer Program, then create a **Developer ID Application**
   certificate in the portal and install it. An *Apple Development* certificate
   will not work — Gatekeeper rejects it.
2. Store notary credentials once:
   ```bash
   xcrun notarytool store-credentials onwards \
     --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"
   ```
3. `./mac/release.sh`
4. Attach `Onwards.dmg` to a GitHub Release, then set `DOWNLOAD_URL` near the
   top of the script in `index.html` to:
   `https://github.com/<you>/onwards/releases/latest/download/Onwards.dmg`

Check it the way a downloader's Mac will:

```bash
spctl -a -vvv -t install mac/build/Onwards.app   # want: accepted
```

## Credits

- [Lato](https://www.latofonts.com/) by Łukasz Dziedzic, SIL Open Font License
  (see `app/fonts/OFL.txt`)
- Nudged along by [freewrite](https://www.freewrite.io/) by Farza — a different
  answer to the same worry. Freewrite *prevents* (no backspace, a timer, a blank
  page); Onwards *reveals*.
