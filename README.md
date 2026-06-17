# Tornado Gallery — website

Marketing landing site for **Tornado Gallery**, an app that visually encrypts your
photos into harmless-looking glitch on-device. Only your password rebuilds the
original, pixel-perfect. Open source, 100% local, no account.

Built with Flutter (web target) from the Claude Design handoff. The whole landing
page lives in [`lib/main.dart`](lib/main.dart).

## Sections

Nav · animated glitch hero · the problem · how it works (interactive
Encrypt/Decrypt demo) · features · privacy/code band · download CTA · footer.
Light + dark theme toggle, neon-glass aesthetic, scroll-reveal animations.

## Run

```bash
flutter pub get
flutter run -d chrome      # dev
flutter build web          # production build → build/web
```

Fonts (Space Grotesk, IBM Plex Sans, JetBrains Mono) load at runtime via
`google_fonts`, so the dev/build machine needs network access.

© 2026 Riccardo Cescon. Free for personal use. Commercial use requires the
author's permission.
