# SnapTune

> **Perfect before you share.**

A premium Android gallery app with a built-in media optimization engine. Browse your photos and videos beautifully — and before you share anywhere, SnapTune silently preprocesses your media so it survives platform compression with the least possible visible quality loss.

---

## What it does

- **Gallery first** — a smooth, fast, intentional photo and video browser
- **Optimization engine** — intelligent preprocessing before you share (WhatsApp Status, Instagram Stories, Telegram, and more)
- **Offline, private** — everything runs on-device, nothing leaves your phone

---

## Tech stack

- Flutter (Android)
- `photo_manager` — gallery access
- `ffmpeg_kit_flutter_min` — native FFmpeg for video/image processing
- `flutter_bloc` — state management
- `get_it` — dependency injection
- `go_router` — navigation
- `dartz` — functional error handling

---

## Architecture

Feature-first Clean Architecture:

```
lib/
├── core/              # Theme, DI, router, constants, errors
└── features/
    ├── gallery/       # Media browsing
    ├── viewer/        # Full-screen media viewer
    ├── optimization/  # FFmpeg processing engine
    ├── onboarding/    # First-run experience
    └── splash/        # Launch screen
```

---

## Design

Material 3 · Material You · Light & Dark theme

| Token | Value |
|---|---|
| Primary | `#6750A4` |
| Secondary | `#625BFF` |
| Tertiary | `#FF8A65` |

---


