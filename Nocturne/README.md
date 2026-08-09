<p align="center">
  <img src="docs/app-icon.png" width="120" alt="Nocturne app icon">
</p>

<h1 align="center">Nocturne</h1>

<p align="center">
  <strong>Write in the dark.</strong><br>
  A songwriter's sketchbook for iOS — lyrics, chords, rhymes, and voice memos,<br>
  in one calm, distraction-free black interface.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5-orange?style=flat-square&logo=swift&logoColor=white" alt="Swift 5">
  <img src="https://img.shields.io/badge/SwiftUI-✓-blue?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/dependencies-zero-black?style=flat-square" alt="Zero dependencies">
  <img src="https://img.shields.io/badge/version-1.0-333?style=flat-square" alt="Version 1.0">
  <img src="https://img.shields.io/badge/license-Proprietary-555?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#getting-started">Getting Started</a> ·
  <a href="#project-structure">Structure</a> ·
  <a href="#tech-stack">Tech</a> ·
  <a href="#data--privacy">Privacy</a>
</p>

---

<p align="center">
  <img src="docs/screenshots/01-library.png" width="200" alt="Library — songs and folders">
  &nbsp;
  <img src="docs/screenshots/02-song-editor.png" width="200" alt="Song editor — lyrics and chords">
  &nbsp;
  <img src="docs/screenshots/03-recordings.png" width="200" alt="Recordings — audio and video notes">
  &nbsp;
  <img src="docs/screenshots/04-profile.png" width="200" alt="Profile — writing stats and settings">
</p>

<p align="center"><em>Library · Song editor · Recordings · Profile</em></p>

---

## Why Nocturne

Most notes apps treat a song like a paragraph. Nocturne treats it like what it actually is — lyrics with **structure**: chords anchored to specific words, sections that mark the shape of the song, ideas that show up mid-line and need to be caught before they're gone.

Chords aren't text you type inline and hope stays aligned. They're **structured data** — "this chord belongs to word 3 of line 7" — so your chart never drifts out of place no matter how much you rewrite around it.

No account. No cloud sync. No analytics. It's just you, a black screen, and the song.

---

## Features

### Write & arrange
- Distraction-free **lyrics editor** — monospaced type, adjustable text size
- **Chords above words**, positioned exactly where you tapped — transpose the whole song in one step
- **Rhyme finder** — tap any word mid-write to pull matching rhymes, filter by syllable count, drop one straight into the lyric or onto a new line
- **Section labels** — Verse, Chorus, Bridge, and more, added inline as you write, not bolted on after
- **Line notes** for reminders, alternate phrasing, ideas you're not ready to commit to
- Full undo / redo while you write

### Capture & record
- **Audio memos** per song — record while you write, without leaving the page
- **Video notes** — short front-camera clips attached to a track
- Star a **main recording** to mark your best take
- **Fragments** — quick saves for stray lyric lines, riffs, titles, and moods before they slip away

### Organize & find
- **Folders** for demos, finished work, experiments
- **Search** across title, lyrics, *and* chord names
- **Soft delete** with 30-day recovery in Recently Deleted

### Share & export
- **PDF chord charts** with lyrics, chords, and section labels laid out properly
- **Nocturne links** (`nocturne://`) — a read-only in-app preview for collaborators, no account needed on their end
- Plain-text export via the system share sheet

### Privacy & security
- Everything — songs, fragments, recordings — stored **locally on your device**
- Optional **Face ID / passcode** app lock
- Microphone and camera are touched only when you actually hit record

---

## Requirements

| | |
|---|---|
| **OS** | iOS 17.0 or later |
| **Devices** | iPhone, iPad |
| **Build** | Xcode 15+ |
| **Account** | Apple Developer Program (for App Store distribution) |

---

## Getting started

### Clone & open

```bash
git clone https://github.com/Damoon03/Nocturne.git
cd Nocturne
open Nocturne.xcodeproj
```

### Run

1. Select your **Development Team** under **Signing & Capabilities**
2. Choose a simulator or connected iPhone
3. Press **⌘R** to build and run

### Archive for App Store

1. Set destination to **Any iOS Device (arm64)**
2. **Product → Archive**
3. **Distribute App → App Store Connect**

---

## Project structure

```
Nocturne/
├── Nocturne/
│   ├── Model/           Song, Chord, Fragment, Recording, SectionLabel
│   ├── ViewModel/       Library, Song, Audio, Settings
│   ├── View/
│   │   ├── Library/     Songs, folders, fragments list
│   │   ├── Song/        Editor, chords, rhymes, sections, lyrics display
│   │   ├── Recording/   Audio & video capture
│   │   └── Profile/     Settings & security
│   ├── Utilities/       Export, share links, rhyme lookup, persistence
│   └── Assets.xcassets/ App icon, accent color
├── docs/screenshots/    README & marketing screenshots
├── URLTypes.plist       nocturne:// deep link scheme
└── Nocturne.xcodeproj
```

---

## Permissions

Nocturne requests sensitive capabilities only when you use them:

| Permission | Purpose |
|------------|---------|
| **Microphone** | Audio memos for songs and fragments |
| **Camera** | Video notes attached to a song |
| **Face ID / Touch ID** | Optional app lock (Profile → Security) |

---

## Data & privacy

- **Songs, folders, fragments** — JSON in Application Support (`DataPersistence`)
- **Audio / video files** — stored in the app Documents directory
- **Settings & stats** — UserDefaults (font size, word counts, app lock)
- **Rhyme lookups** call the Datamuse API over HTTPS — the only network request Nocturne ever makes, and it sends nothing but the word you tapped
- **No analytics, no third-party SDKs, no tracking**

Legacy data in UserDefaults is migrated automatically on first launch after updating.

---

## Share links

Share links encode a read-only snapshot (title, lyrics, chords, sections) into a URL:

```
nocturne://song/<payload>
```

Opening the link in Nocturne shows a preview. **Audio is not included** — file paths are device-local. Attach recordings separately via AirDrop or Files if needed.

---

## Tech stack

- **SwiftUI** — UI and navigation
- **UIKit bridges** — `UITextView` lyrics editor, PDF export, share sheet, interactive swipe-back
- **AVFoundation** — audio recording/playback, video capture
- **LocalAuthentication** — biometric app lock
- **Combine** — debounced auto-save

No external dependencies. Nothing to install, nothing to break.

---

## Roadmap

- [ ] iCloud backup (optional)
- [ ] Alternate app icons
- [ ] Additional export formats
- [ ] Localization

---

## Author

**Damoon Saber** — [GitHub @Damoon03](https://github.com/Damoon03)

---

## License

Copyright © 2026 Damoon Saber. All rights reserved.

This project is proprietary. Unauthorized copying, distribution, or commercial use is not permitted without permission.

---

<p align="center">
  <img src="docs/app-icon.png" width="48" alt="Nocturne">
  <br>
  <sub>Made for late-night writing sessions.</sub>
</p>
