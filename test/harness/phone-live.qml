    // Against the services on a phone, read-only: nothing here calls a player.
    // Expects an Android app with a media session (PACKAGE) and reports what the
    // cover would show; checks that tiles never latch onto another player.
    readonly property string livePackage: "com.audible.application"

    width: Theme.coverSizeLarge.width * 3
    height: Theme.coverSizeLarge.height

    Row {
        Loader {
            id: live
            width: Theme.coverSizeLarge.width; height: Theme.coverSizeLarge.height
            sourceComponent: tile
            onLoaded: item.launcherItem = harness.launcher(harness.livePackage)
        }
        Loader {
            id: silent
            width: Theme.coverSizeLarge.width; height: Theme.coverSizeLarge.height
            sourceComponent: tile
            onLoaded: item.launcherItem = harness.launcher("org.example.nomedia")
        }
        Loader {
            id: nativeApp
            width: Theme.coverSizeLarge.width; height: Theme.coverSizeLarge.height
            sourceComponent: tile
            onLoaded: item.launcherItem = harness.launcher("")
        }
    }

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            var failures = 0
            function check(what, ok) {
                console.log((ok ? "PASS " : "FAIL ") + what)
                if (!ok)
                    failures++
            }
            var w = live.item
            var player = w.androidPlayer
            console.log("services on the bus:", player ? player.availableServices : "-")
            check("live: service name", w.androidMprisService === "org.mpris.MediaPlayer2.AppSupport." + harness.livePackage)
            check("live: controller locked to it", !!player && player.currentService === w.androidMprisService)
            check("live: androidMedia", w.androidMedia)
            check("live: cover shown", w.mediaCover !== null)
            check("live: actions shown", w.mediaActions !== null)
            if (w.mediaCover) {
                var content = w.mediaCover.children[w.mediaCover.children.length - 1]
                console.log("  status:", player.playbackStatus, "canGoNext:", player.canGoNext)
                console.log("  title:", content.title)
                console.log("  subtitle:", content.subtitle)
                console.log("  art:", content.artUrl)
                check("live: title", content.title !== "")
            }
            if (w.mediaActions) {
                // Audible's own set: back 30 s if its player can seek, and play/pause
                console.log("  actions:", w.mediaActions.actions, "canSeek:", player.canSeek)
                check("live: Audible's actions",
                      w.mediaActions.actions.join(",") === (player.canSeek ? "back30,playPause" : "playPause"))
            }

            var s = silent.item
            check("no media: controller made", s.androidPlayer !== null)
            check("no media: not latched onto another player",
                  !!s.androidPlayer && s.androidPlayer.currentService === "")
            check("no media: nothing shown", !s.androidMedia && s.mediaCover === null && s.mediaActions === null)

            var n = nativeApp.item
            check("native app: no controller", n.androidPlayer === null)
            check("native app: nothing shown", !n.androidMedia && n.mediaCover === null && n.mediaActions === null)

            console.log(failures === 0 ? "ALL PASSED" : failures + " FAILED")
            Qt.quit()
        }
    }
