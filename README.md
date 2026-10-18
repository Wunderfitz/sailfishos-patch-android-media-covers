# Media controls on Android app covers

A [Patchmanager](https://github.com/sailfishos-patches/patchmanager) patch for
Sailfish OS. While an Android app has something to play - an audiobook,
music, a podcast - its cover in the app switcher shows the artwork, the title
and the chapter or artist, with play/pause and next as cover actions, like a
native media player - or actions of its own: Audible gets back 30 s and
play/pause. Other Android apps and all native apps keep their covers.

## How it works

Android App Support already bridges every Android media session to MPRIS
(`apkd-plugin-media-mpris`): an app with a session appears on the session bus
as `org.mpris.MediaPlayer2.AppSupport.<package>`, which is what the lock
screen's media controls show. The switcher knows an Android app's package from
its launcher entry (`X-apkd-packageName`), so the patch can pair each tile with
its player.

The patch changes one file, lipstick's
`/usr/share/lipstick-jolla-home-qt5/switcher/SwitcherItem.qml`. Each of its
blocks starts with a `// android-media-covers:` comment:

- the tile's package and service name, and whether there is something to show;
- an `Amber.Mpris` `MprisController` per Android tile, locked to its own
  service (`singleService`), so it never follows another player;
- the overlay: the ambience cover background over a solid one, the artwork
  (or the app's icon) across the full width, and below it the title and the
  chapter or artist on one line each, elided at the right; laid out at the
  large cover size and scaled to the tile, as lipstick scales its icons;
- play/pause and next (when the player offers it) in the cover action row,
  built like lipstick's own, or the app's own actions from
  `androidMediaActionSets`: for Audible back 30 s (an MPRIS seek, with the
  icon from `icons/`) and play/pause.

## Layout

```
patch/unified_diff.patch   the patch, applied with -p1 at /
patch/patch.json           Patchmanager's metadata: category homescreen, compatible releases
rpm/                       spec and changelog of the RPM that installs the two and the icon
icons/                     the "back 30 s" cover action icon (SVG)
tools/prepare.sh           fetches the originals from a device and rebuilds work/patched
tools/make-diff.sh         writes patch/unified_diff.patch from work/
test/qmlrun/               a minimal QML runner, as devices ship no qmlscene
test/harness/              runs the patch's blocks outside lipstick (see Testing)
work/                      git-ignored: Jolla's originals and the patched copy
LICENSE                    GNU GPL version 3
```

Jolla's files are proprietary and never committed: `work/` is rebuilt from a
device with `tools/prepare.sh`.

## Changing the patch

```sh
tools/prepare.sh                 # originals from the Jolla Phone (2026), patch applied
$EDITOR work/patched/usr/share/lipstick-jolla-home-qt5/switcher/SwitcherItem.qml
tools/make-diff.sh
```

For a new OS release: run `tools/prepare.sh` against it. If the diff no longer
applies, apply it by hand to `work/patched`, regenerate it, test it, and add the
release to `compatible` in `patch.json`.

## Testing

Nothing here touches the installed files. Lipstick only runs one
`SwitcherItem.qml`, so the checks run it, or its blocks, elsewhere.

1. **Dry run** on the device: `patch --dry-run -p1 -d / < unified_diff.patch`.
2. **Compile** the patched file with the device's real QML modules: copy
   `/usr/share/lipstick-jolla-home-qt5` to `/tmp`, patch the copy and run
   `qmlrun --compile` on it. `com.jolla.coveractions` and
   `com.jolla.lipstick` live inside the lipstick binary, so they need stubs on
   `QML2_IMPORT_PATH`: a `CoverActionModel` (a `ListModel` with `window`,
   `background` and `trigger()`) and a `JollaSystemInfo` singleton. The
   unpatched original must compile the same way, as a control.
3. **Against the phone's services**, read-only:
   `make-harness.py <patched file> phone-live.qml` copies the patch's blocks
   into a stand-in tile and checks, with an Android app's media session open,
   that its tile locks onto it and shows it, that a tile without a session
   neither shows anything nor latches onto another player, and that a native
   app gets no controller. Run with `QT_QPA_PLATFORM=minimal
   QT_LOGGING_TO_CONSOLE=1 qmlrun --run`. It never calls a player.
4. **On screen in the emulator**, with `emulator-show.qml`: fake players for
   two Android apps and a native one, tiles at two sizes; it presses pause and
   next and checks that the players got them. `qmlrun --show`, then a
   screenshot through lipstick. Amber's `MprisPlayer` appends `.instance<pid>`
   to its name, so the scenario looks the fake names up first; the apkd bridge
   does not.

Build `qmlrun` through the engine's sb2, as it has no spec:

```sh
B=~/git/build-sailfishos-patch-android-media-covers-qmlrun-5.1.0.11-aarch64
mkdir -p $B
~/SailfishOS/bin/sfdk engine exec sb2 -t SailfishOS-5.1.0.11-aarch64 -m sdk-build sh -c \
    "cd $B && qmake ~/git/sailfishos-patch-android-media-covers/test/qmlrun/qmlrun.pro && make"
```

## Building and installing

```sh
mkdir -p ../build-sailfishos-patch-android-media-covers
cd ../build-sailfishos-patch-android-media-covers
~/SailfishOS/bin/sfdk -c target=SailfishOS-5.1.0.11-aarch64 -c no-fix-version \
    build ../sailfishos-patch-android-media-covers
```

The RPM is `noarch`. Install it on the phone - `sfdk deploy --sdk` and
confirm on the phone, or `devel-su pkcon install-local <rpm>` - then apply
"Media controls on Android app covers" in Patchmanager and let it restart the
home screen. Removing or upgrading the RPM unapplies the patch first.

## Known limits

- Tested against Sailfish OS 5.2.0.20 (`lipstick-jolla-home-qt5`
  1.27.18.1) and Android App Support 15, with Audible and VLC.
- What next does is the app's choice; it is only offered while the player
  can skip (VLC with a single file has no next).
- Actions of an app's own beyond MPRIS - such as Audible's 30 s jumps - are
  not bridged by Android App Support; back 30 s is an MPRIS seek instead.
- The media cover lasts only as long as the app keeps its media session. After
  pausing, Audible keeps it for quite a while (seen: roughly 15 to 30
  minutes); then the app closes it or Android suspends the app, the MPRIS
  player has nothing more to report, and the cover is lipstick's usual
  snapshot of the app's last state again. This is intended: the patch shows
  only what the app itself still offers.
- The artwork is the file the apkd bridge writes; if an app changes it under
  the same name, the cover shows the new one only once the tile is rebuilt.

## License

Copyright (C) 2026 Sebastian Wolf

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version. See [LICENSE](LICENSE).

The license covers this project's own work. The patched file,
`SwitcherItem.qml`, belongs to Jolla and is not part of this repository; the
diff only carries the few lines of context it needs to apply.

## Author

Sebastian Wolf.

Created with the help of [Claude Code](https://claude.com/claude-code),
Anthropic's AI coding assistant (Claude Opus 5.5): the patch, the icon, the
tests and the tools were written in conversation with it, and each release was
tested by the author on a Jolla Phone.
