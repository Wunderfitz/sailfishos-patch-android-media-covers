# sailfishos-patch-android-media-covers

A Patchmanager patch for Sailfish OS: the app switcher's covers of Android
apps (Android App Support) show what the app plays - artwork, title, chapter
or artist - with play/pause and next as cover actions (Audible: back 30 s
and play/pause). What it does, the
layout, building and testing are in `README.md`; this file holds the rules and
what is not obvious from the code.

## Ground rules

- **Never edit installed system files in place** (the project owner's
  instruction). The installed `SwitcherItem.qml` is changed only by
  Patchmanager applying the patch. Development happens in `work/patched/`;
  tests run on copies under `/tmp` on the device.
- **Jolla's files are proprietary and never committed.** `work/` (originals
  and the patched copy) is git-ignored and rebuilt from a device with
  `tools/prepare.sh`. Only the diff, its metadata, the RPM files, the tools
  and the tests are tracked.
- **Never call play, pause or next on the phone's real players** in a test:
  that would start or stop the owner's audiobook. The phone scenario
  (`test/harness/phone-live.qml`) is read-only; actions are tested in the
  emulator against fake players.
- Keep each block of the patch introduced by a `// android-media-covers:`
  comment at the item's top level: `make-harness.py` finds the blocks by it
  and expects exactly four.
- Commit and push only when asked. Remote `origin` is
  `git@github.com:Wunderfitz/sailfishos-patch-android-media-covers.git`,
  branch `master` (first commit: 0.2.1, 2026-10-18).

## Devices

Registered in the local SDK (`~/SailfishOS/bin/sfdk device list`); keep
addresses and keys out of this repository.

- **Jolla Phone (2026)**: Sailfish OS 5.2.0.22 (since 2026-10-26, before
  5.2.0.20), `lipstick-jolla-home-qt5` 1.27.18.2, Android App Support 15, Patchmanager 3.2.12 (Chum), Audible
  installed. `sfdk device exec "Jolla Phone (2026)" -- sh -c '...'` runs as
  `defaultuser`; stdin passes through, so `... -- sh -c 'cat > /tmp/x' < file`
  copies a file over. **No root** over SSH (`devel-su` needs the owner's
  password) and the journal is not readable, so `patchmanager` itself cannot
  be run from here.
- **Sailfish OS Emulator 5.1.0.11** (i486): root over
  `ssh -p 2223 -i ~/SailfishOS/vmshare/ssh/private_keys/sdk root@127.0.0.1`;
  screenshots as in harbour-chronograph's CLAUDE.md (`su -g privileged
  defaultuser -c '... saveScreenshot ...'`). No Android App Support there.

## Decisions

- **The service name is exact**: `org.mpris.MediaPlayer2.AppSupport.` + the
  launcher entry's `X-apkd-packageName`, as the apkd bridge registers it on
  5.2 (seen on the phone). No `.instance<pid>` suffix handling: only Amber's
  own `MprisPlayer` adds one, which matters for the emulator's fake players
  only.
- **One `MprisController` per Android tile, `singleService: true`** with
  `currentService` set: Amber then never moves it to another player. Visibility
  also requires `currentService === androidMprisService`, in case it ever
  latches onto something else. Native tiles get no controller (the Loader is
  inactive without a package).
- **Shown while** the tile's app is running and the player is not `Stopped`
  or has a title. The overlay and the actions are Loaders, so Android tiles
  without media cost nothing but their controller.
- **The cover ends with the app's media session**, which is intended (the
  owner: "great, doesn't need to change"). Audible keeps its session for a
  while after pausing (the owner saw roughly 15 to 30 minutes), then it is
  closed or the app suspended, and the tile shows lipstick's snapshot of the
  app's last state again. Not checked whether the bridge then removes the
  player or reports it `Stopped` without a title; either way `androidMedia`
  turns false.
- **Laid out at `Theme.coverSizeLarge` and scaled** to the tile, as lipstick
  scales its launcher icon; the action row is not scaled, like lipstick's own
  (`loader`, which the patch reuses with a second `sourceComponent`).
- **The artwork is square at the full width**, inside a padding of
  `paddingMedium + paddingSmall` (30 px on the phone, `paddingLarge` was found
  too wide); the title and subtitle get one line each, elided right, centred
  in the space left above the action row. Fonts, chosen by the owner: title
  Small (42 px), subtitle Tiny (30 px), on both tile sizes, so large tiles
  look like small ones scaled up (Medium/Small was too large, ExtraSmall/Tiny
  too small for the title). The title steps down to ExtraSmall, then Tiny,
  only if its line does not fit (measured with `FontMetrics`; the phone's
  small tiles have 110 units free, 104 needed, as the unscaled action row
  takes more).
- A solid `Theme.highlightDimmerColor` base under lipstick's
  `CoverBackground`, so the Android window never shows through should the
  ambience background be transparent.
- **Two actions at most**, as native covers. By default play/pause, and
  next when `canGoNext`. Apps can have their own pair in
  `androidMediaActionSets` (package -> actions, left to right): Audible gets
  `back30` (only when `canSeek`) and play/pause, the owner's choice. A new
  action needs its name in `actions`, `iconSource` and `onClicked`.
- `androidMediaActionSets` is a plain (not readonly) property so that
  `emulator-show.qml` can map Audible's set onto a fake player's package,
  which has Amber's `.instance<pid>` suffix.
- **Back 30 s** is `MprisController.seek(-30000)`: Amber's offset is in
  **milliseconds** and goes out as MPRIS' microseconds (seen with
  `dbus-monitor` in the emulator; amber-mpris 1.2.10 on the phone only adds
  Qt 6 support over the emulator's 1.2.9).
- **The icon** `icons/icon-cover-replay-30.svg` is the project's own (no
  rewind icon in the theme), drawn as strokes in the theme's style: 48 px box,
  translucent (0.6) arrow, solid "30". The RPM installs it to
  `/usr/share/sailfishos-patch-android-media-covers/`; the action icons are
  `HighlightImage`s, which colour a file icon on press like theme icons.
- **Light ambiences**: the theme provider draws its monochrome icons in the
  ambience's colour, a file icon keeps its own white. So the action icons get
  `color: Theme.primaryColor` (black on light, white on dark; the translucent
  parts stay translucent). Checked in the emulator with the light ambience
  Airy: `setAmbience` on `com.jolla.ambienced` with the `.ambience` file's URL
  (the emulator's usual one is Ruska).
- `patch.json` `compatible` lists only the releases actually tested (now
  5.2.0.20 and 5.2.0.22). The RPM requires `patchmanager >= 3.0`, `lipstick-jolla-home-qt5`,
  `amber-qml-plugin-mpris` and `qt5-qtsvg-plugin-imageformat-svg` (the icon),
  and unapplies the patch in `%pre` (upgrade)
  and `%preun` with `/usr/sbin/patchmanager -u`.

## Checking a change on the phone

After `tools/make-diff.sh`, from the repository root. `/tmp/amc` on the phone
holds `qmlrun` and the stubs and is gone after a reboot; recreate it then:

```sh
P="Jolla Phone (2026)"; SFDK=~/SailfishOS/bin/sfdk
B=~/git/build-sailfishos-patch-android-media-covers-qmlrun-5.1.0.11-aarch64
$SFDK device exec "$P" -- sh -c 'mkdir -p /tmp/amc && cat > /tmp/amc/qmlrun && chmod +x /tmp/amc/qmlrun' < $B/qmlrun
$SFDK device exec "$P" -- sh -c '
cd /tmp/amc && mkdir -p stubs/com/jolla/coveractions stubs/com/jolla/lipstick
printf "module com.jolla.coveractions\nCoverActionModel 0.1 CoverActionModel.qml\n" > stubs/com/jolla/coveractions/qmldir
printf "import QtQuick 2.6\nListModel { property var window; property bool background; function trigger(id) {} }\n" > stubs/com/jolla/coveractions/CoverActionModel.qml
printf "module com.jolla.lipstick\nsingleton JollaSystemInfo 0.1 JollaSystemInfo.qml\n" > stubs/com/jolla/lipstick/qmldir
printf "pragma Singleton\nimport QtQuick 2.6\nQtObject { function matchingPidForCommand(a, b, c) { return -1 } }\n" > stubs/com/jolla/lipstick/JollaSystemInfo.qml'
```

Then the three checks - dry run, compile, live (the live one needs an Android
app with a media session, e.g. Audible opened once):

```sh
F=usr/share/lipstick-jolla-home-qt5/switcher/SwitcherItem.qml
H=<session scratchpad>/PhoneLive.qml
python3 test/harness/make-harness.py work/patched/$F test/harness/phone-live.qml > $H
$SFDK device exec "$P" -- sh -c 'cat > /tmp/amc/unified_diff.patch' < patch/unified_diff.patch
$SFDK device exec "$P" -- sh -c 'cat > /tmp/amc/PhoneLive.qml' < $H
$SFDK device exec "$P" -- sh -c '
cd /tmp/amc && patch --dry-run -p1 -d / < unified_diff.patch
R=root-$(date +%s); mkdir -p $R/usr/share && cp -r /usr/share/lipstick-jolla-home-qt5 $R/usr/share/ && patch -s -p1 -d $R < unified_diff.patch
export QT_QPA_PLATFORM=minimal QT_LOGGING_TO_CONSOLE=1
QML2_IMPORT_PATH=/tmp/amc/stubs ./qmlrun --compile /tmp/amc/$R/usr/share/lipstick-jolla-home-qt5/switcher/SwitcherItem.qml
./qmlrun --run /tmp/amc/PhoneLive.qml 2>&1 | grep -E "PASS|FAIL|PASSED|ERROR"'
```

Each run copies into a fresh `root-<time>` directory: Claude Code's safety
check blocks `rm -rf` inside a remote `sh -c`, so do not clean up that way.
Write generated harnesses to the session's scratchpad rather than `/tmp`.

The emulator check is the same with the i486 `qmlrun`,
`emulator-show.qml` and `qmlrun --show` started in the background
(`(nohup ./qmlrun --show ... > show.log 2>&1 &)`), then a screenshot and
`pkill qmlrun`.

## Audible's MPRIS player (read on the phone, 2026-10-18)

Only the standard `org.mpris.MediaPlayer2` and `.Player` interfaces, no
others: Android's custom actions (Audible's own 30 s jumps) are not bridged.
Read-only with `GetAll`/`Introspect`, never a method call:

```sh
$SFDK device exec "$P" -- sh -c '
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/dbus/user_bus_socket
dbus-send --session --print-reply --dest=org.mpris.MediaPlayer2.AppSupport.com.audible.application \
    /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.GetAll string:org.mpris.MediaPlayer2.Player'
```

- Reports `CanPlay`, `CanPause`, `CanGoNext`, `CanGoPrevious`, `CanSeek`,
  `CanControl` all true; `Rate` 1 (range -16 to 16); `Volume` 0 (likely
  unsupported); `CanRaise`, `CanQuit` false; `DesktopEntry`
  `com_audible_application-`.
- Metadata: `xesam:title` the book, `xesam:artist` the chapter ("Chapter
  43"), `xesam:album` the author, `mpris:artUrl` a PNG under
  `~/.cache/apkd-bridge/mpris/covers/<package>/`, `mpris:length`, a trackid.
  So the cover's subtitle (artist first) shows the chapter; the author would be
  available for a third line.
- Amber's `MprisController` (libambermpris 1.2.10) has `previous()`,
  `seek(offset)`, `setPosition()`, `setRate()`, `stop()`.
- Cover icons in the theme (`icon-cover-*`): `play`, `pause`, `next`,
  `next-song`, `previous`, `previous-song`, `shuffle`, `timer`, ... - **no
  rewind/replay icon**, so a "back 30 s" action needs `icon-cover-previous`
  reused or an icon shipped by the RPM.
- Alternative pairs for the two actions: previous + play/pause (previous
  chapter, presumably), or play/pause + back 30 s via `seek` (chosen, 0.2.0).
  Rate and stop make poor cover actions.
- The bridge reports `Position` (microseconds) and introspects `Seek`,
  `SetPosition`, `Previous`. Seek reaches Audible (back 30 s confirmed by the
  owner, 0.2.1); **untested** whether previous does: only the owner can try
  it on the phone (it moves their audiobook).

## Gotchas

- `QT_LOGGING_TO_CONSOLE=1`, or `console.log` goes to the journal and a test
  seems to print nothing.
- Qt 5.6: no `QQmlEngine::exit`/`Qt.exit()`; tests report `PASS`/`FAIL` lines
  and end with `Qt.quit()`.
- An import of an absolute directory needs a URL: `import
  "file:///usr/share/lipstick-jolla-home-qt5/main"`.
- `qmlrun` has no spec, so `sfdk qmake`/`make` refuse it; build through
  `sfdk engine exec sb2 -t <target> -m sdk-build` (README).
- The RPM's `%install` runs in the out-of-tree build directory: sources are
  reached through `%{_sourcedir}/..`. This is a git repository without tags,
  so build with `-c no-fix-version`.
- Deploying: `sfdk deploy --pkcon` fails ("Failed to obtain authentication");
  `--sdk` asks for confirmation on the phone and fails if it is not given.
  Otherwise the owner installs with `devel-su pkcon install-local`.
- In a `Repeater` delegate over an integer model, use `index`, not
  `model.index`; a `Grid`'s `children` include the `Repeater` itself.
- A binding that reads Amber's `canGoNext`/`canSeek` inside an
  `Array.filter` callback reports a binding loop; read them into locals first.
- The emulator has no `minimal` platform plugin: run `qmlrun` there with
  `QT_QPA_PLATFORM=wayland` (and `XDG_RUNTIME_DIR=/run/user/100000`).
- On the phone, `qmlrun --run` with `QT_QPA_PLATFORM=wayland` (no window)
  gives the real screen's `Theme` values; `minimal` fakes a 240x320 screen.

## Status

0.1.0 (2026-10-18): built, all checks above pass, installed and applied on
the Jolla Phone (2026) by the owner. Tested there with the real Audible app
(2026-10-18), everything confirmed by the owner:

- [x] Lipstick starts with the patch applied, and the switcher works as before.
- [x] Audible's cover: artwork, title and chapter, on the translucent ambience
      background - exactly as expected.
- [x] Play/pause and next on the cover work; tapping the rest of the cover
      opens the app, long-press enters close mode.
- [x] Next in Audible jumps to the next chapter.
- [x] Covers of Android apps without media and of native apps unchanged.

0.1.1 (2026-10-18): full-width artwork, one-line title and subtitle with
fitted font sizes. Tried by the owner: small tiles fine, padding and the large
tiles' fonts too large.

0.1.2 (2026-10-18): padding 30 px instead of 40, ExtraSmall/Tiny fonts on all
tiles. Tried by the owner: the title now too small, the subtitle fine.

0.1.3 (2026-10-18): title one size larger (Small). Confirmed by the owner
("great now").

0.2.0 (2026-10-18): per-app cover actions, Audible with back 30 s (own icon)
and play/pause. Built, all checks pass (emulator: back 30 s, pause and next
reach the fake player; phone, read-only: Audible's cover offers back30 and
playPause), RPM copied to the phone's `~/Downloads`. Superseded by 0.2.1:
the icon stayed white in light ambiences.

0.2.1 (2026-10-18): the action icons in the ambience's colour. Built, all
checks pass, emulator screenshots in a light and a dark ambience. Installed
and applied on the phone by the owner, everything confirmed (2026-10-18):

- [x] Audible's cover shows the back 30 s icon and play/pause.
- [x] Back 30 s jumps 30 s back in Audible; play/pause still works.
- [x] Other Android apps with media keep play/pause and next: tried with
      VLC, whose cover also drops next with a single file in the playlist
      (`canGoNext` false).
- [x] The 30 s icon shows properly in light and dark ambiences.

0.2.2 (2026-10-26): compatible with 5.2.0.22, nothing else changed. The
phone's update brought `lipstick-jolla-home-qt5` 1.27.18.2 with a
byte-identical `SwitcherItem.qml`, so the diff is the same; Amber MPRIS
(1.2.10), Patchmanager and Audible's service name are unchanged too. Dry run,
compile and the live checks pass on 5.2.0.22.
Installed and applied on the phone by the owner, everything confirmed
(2026-10-26): runs smoothly, works with Audible and VLC.
