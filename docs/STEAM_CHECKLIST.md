# HOLLOWGOD Steam checklist

Prices, image sizes and rules change. Always confirm on https://partner.steamgames.com before you pay or upload.
Last written from general knowledge, not live Steam documentation.

## A. Accounts and money (start early, this takes days or weeks)
- [ ] Create a Steamworks partner account.
- [ ] Complete identity, tax and bank details (the form asks which country you are in; Kenya is supported by most payout methods but confirm).
- [ ] Pay the one-time **app fee** (about $100 per game at the time of writing; Steam normally returns it after the game earns a set amount).
- [ ] Decide who the publisher is (you as an individual or a company).

## B. The store page (create it as soon as you have screenshots, up to months before release)
- [ ] Short description (one or two sentences) and long description (see `docs/STORE_COPY.md`).
- [ ] 5 or more screenshots, 1920x1080, showing real gameplay (combat, hub, choices, bosses).
- [ ] Trailer (30 to 60 seconds, gameplay in the first 5 seconds).
- [ ] Capsule and header images. Typical sizes (verify current list): Header 460x215, Small 231x87, Main 616x353,
      Vertical 374x448, Library capsule 600x900, Library hero 3840x1240, Logo 1280x720 (transparent).
- [ ] Tags (examples): Action Roguelite, Roguelike, Pixel Graphics, Dark Fantasy, Story Rich, Mythology, Choices Matter, Singleplayer.
- [ ] System requirements (this game is light: old dual-core PC, 4 GB RAM, Intel integrated graphics with OpenGL 2.1).
- [ ] Age rating questionnaire (the game has fantasy violence, no blood-heavy gore).
- [ ] Content disclosure: tell Steam about any AI-generated content. This project currently uses CC0 art (DungeonTileset II) and
      code-generated sound, and no AI-generated art.
- [ ] Credits and licenses are listed in `assets/art/CREDITS.md`. CC0 assets do not require credit but we give it anyway.
- [ ] Press "Coming soon" and start collecting **wishlists**. Aim for several thousand before launch.

## C. The game build
- [ ] Windows build exported and tested on a clean PC (see `docs/RELEASE_GUIDE.md`).
- [ ] Steamworks integration (optional but expected): achievements, cloud saves, overlay. For Godot 3.5 use the GodotSteam plugin.
- [ ] Controller support verified on a real gamepad (menus too).
- [ ] Settings menu: volume, fullscreen (done), and ideally resolution and key rebinding.
- [ ] Upload through the Steamworks SDK `steamcmd` into a depot, set the launch option, set a "default" branch.
- [ ] Final bug pass with the checklist in section E.

## D. Marketing and launch
- [ ] Devlogs on itch.io and a Steam news post every few weeks.
- [ ] Short clips for TikTok, YouTube Shorts and X (combat, boss fights, funny deaths).
- [ ] Steam demo + **Steam Next Fest** (needs a demo build and an approved store page).
- [ ] Send free keys to small streamers and reviewers.
- [ ] Pick a launch date at least 2 weeks after the page is live ("Coming soon" requirement). Avoid big-release weeks.
- [ ] Launch price and regional pricing. Launch discount is typically 10 to 20% for the first week.
- [ ] Reply to every review and bug report in the first week.

## E. Final QA checklist (play all of it)
- [ ] New game, Continue, quit and reload, save survives closing the game.
- [ ] Each of the 3 Lines: win once, die once, abandon once.
- [ ] All shop upgrades, all gifts, all three Reckoning choices.
- [ ] Pause and options during fights, dialogue, shops and doors.
- [ ] Fullscreen on and off, 1366x768 and 1920x1080 monitors.
- [ ] Gamepad only run start to finish.
- [ ] No red text in the Godot Output panel during a full run.
