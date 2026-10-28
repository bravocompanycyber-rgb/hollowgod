# HOLLOWGOD release guide (Windows, itch.io, then Steam)

Written for a first-time game publisher. Everything here is free except the optional Steam fee.

## 1. Make a Windows build (one file you can share)
1. Open the project in **Godot 3.5**.
2. Menu **Editor > Manage Export Templates**. Click **Download and Install** (one time, about 500 MB).
3. Menu **Project > Export**. A preset called **Windows Desktop** already exists in this project.
   - "Embed Pck" is already ON, so the result is a single file: `HOLLOWGOD.exe`.
4. Click **Export Project**, choose `build/windows/HOLLOWGOD.exe`, and **untick "Export With Debug"**.
5. Test the exe by double-clicking it on your PC. Then test it on a different PC if you can.
6. Put `HOLLOWGOD.exe` in a folder with a short `README.txt` (controls and credits) and zip it.

Command line version (same result): `godot --path . --export "Windows Desktop" build/windows/HOLLOWGOD.exe`

Notes
- The exe is unsigned. Windows SmartScreen may show "Windows protected your PC". Players click **More info > Run anyway**.
  Buying a code-signing certificate later removes the warning. itch.io's app avoids most of this.
- Save files are stored in the player's user folder (`%APPDATA%\Godot\app_userdata\HOLLOWGOD`).
- Windows icon: the exe uses Godot's default icon unless you set up `rcedit` (Project > Export > Application > Icon).
  This is cosmetic. The window and taskbar icon already use `icon.png`.

## 2. Publish on itch.io (free, no approval needed)
1. Create an account at itch.io and click **Upload new project**.
2. Kind of project: **Downloadable**. Upload your zip, tick **Windows**.
3. Fill the page using `docs/STORE_COPY.md` (title, tagline, description, tags, controls).
4. Add 5 to 8 screenshots (1280x720 or bigger) and a short GIF of combat.
5. Pricing: start with **Free** or **Pay what you want**, or fix a price such as $5 to $10 once you have more content.
6. Set visibility to **Draft**, test the download yourself, then **Public**.
7. Post a devlog with every update. Devlogs are the cheapest marketing there is.

Optional: the `butler` command line tool (free from itch.io) uploads new builds in one command.

## 3. Before you call it "1.0"
Honest list of what still needs work for a premium release:
- A final Line and ending (the Hollow). Currently three Lines exist.
- Real music and recorded combat sounds (the game uses CC0 UI sounds plus generated sounds and drones).
- Custom key art and a logo for store pages.
- A proper tutorial, achievements, localization, and full controller menus.
- Playtesting with at least 10 people and fixing what they find.
- Legal check: see the license notes in `assets/art/CREDITS.md`. Keep every asset license on file.

## 4. Version numbers
- 0.x = prototype / early access. 1.0 = complete game. Keep a CHANGELOG in the repo or in itch.io devlogs.
