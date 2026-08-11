# Lyrics fonts

This folder is inside Nocturne's synchronized source group, so any font
file you drop in here is picked up by Xcode automatically — no project
editing needed. `UIAppFonts` in `URLTypes.plist` and the `postScriptName`
values in `LyricsFontOption.swift` already expect these exact filenames:

| File to add here                | Font                | Where to get it |
|----------------------------------|---------------------|------------------|
| _(none — built in)_              | Monospaced          | System font (`.system(design: .monospaced)`). This is the default/fallback option and needs no file. |
| `CormorantGaramond-Regular.ttf`  | Cormorant Garamond  | Free — [Google Fonts](https://fonts.google.com/specimen/Cormorant+Garamond) (SIL Open Font License) — already added |
| `Baskervville-Regular.ttf`       | Baskervville        | Free — [Google Fonts](https://fonts.google.com/specimen/Baskervville) (SIL Open Font License) — already added |
| `Alegreya-Regular.ttf`           | Alegreya            | Free — [Google Fonts](https://fonts.google.com/specimen/Alegreya) (SIL Open Font License) — already added |

The three files above are already in this folder and registered in
`UIAppFonts`. Nothing further to add.

## Steps (for replacing/updating a font file)

1. Download each font file above.
2. Rename it to match the filename in the table exactly (case-sensitive).
3. Drag it into this folder (`Nocturne/Resources/Fonts/`) in Finder, or
   drag-and-drop it onto this folder inside Xcode's file navigator.
4. Build and run. `LyricsFontOption.isInstalled` checks for the font by
   its PostScript name at runtime, so as soon as a file is present and
   registered, its option in Profile → Lyrics font stops falling back
   to the default monospaced look and renders for real.

## Notes

- If a font file's actual PostScript name doesn't match what's in
  `LyricsFontOption.swift`, open the .ttf in Font Book (macOS) to check
  its real PostScript name, and update `postScriptName` for that case
  in `LyricsFontOption.swift` to match.
- If a bundled font file is ever removed or fails to register, Nocturne
  automatically falls back to the system monospaced font for that
  option — nothing breaks, it just won't look visually distinct from
  the others until the file is back.
