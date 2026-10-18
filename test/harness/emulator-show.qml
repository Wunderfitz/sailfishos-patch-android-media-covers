    // For the emulator, shown on screen: fake players stand in for Android apps
    // (AppSupport.org.example.*) and for a native one, tiles at the sizes the
    // switcher uses. The first tile has Audible's actions (back 30 s, play/pause), the
    // third the default ones (play/pause, next). Presses back 30 s and play/pause on the
    // first and next on the third after 3 s and checks that the player got them; stays
    // up for a screenshot.
    readonly property string artFile: "/usr/share/icons/hicolor/172x172/apps/harbour-lauscher.png"
    readonly property string iconFile: "/usr/share/icons/hicolor/172x172/apps/harbour-chronograph.png"
    property int pauses
    property int nexts
    property var seeks: []

    // Amber's MprisPlayer appends .instance<pid> to its name, unlike the apkd
    // bridge: find the names the fake players got before making the tiles.
    MprisController { id: discovery }
    readonly property bool discovered: discovery.availableServices.length >= 3
    function packageFor(base) {
        var prefix = "org.mpris.MediaPlayer2.AppSupport."
        var services = discovery.availableServices
        for (var i = 0; i < services.length; i++) {
            if (services[i].indexOf(prefix + base) === 0)
                return services[i].substring(prefix.length)
        }
        return base
    }

    MprisPlayer {
        id: audiobook

        serviceName: "AppSupport.org.example.audiobook"
        identity: "Audiobook"
        canControl: true
        canPlay: true
        canPause: true
        canGoNext: true
        canSeek: true
        playbackStatus: Mpris.Playing
        metaData.title: "A Rather Long Book Title That Gets Elided on the Cover"
        metaData.contributingArtist: ["Chapter 43"]
        metaData.albumTitle: "An Author"
        metaData.artUrl: "file://" + harness.artFile

        onPauseRequested: { harness.pauses++; playbackStatus = Mpris.Paused }
        onPlayRequested: playbackStatus = Mpris.Playing
        onNextRequested: harness.nexts++
        onSeekRequested: harness.seeks = harness.seeks.concat([offset])
    }

    MprisPlayer {
        id: podcast

        serviceName: "AppSupport.org.example.podcast"
        identity: "Podcast"
        canControl: true
        canPlay: true
        canPause: true
        canGoNext: false
        playbackStatus: Mpris.Paused
        metaData.title: "Episode 12"
        metaData.albumTitle: "A Podcast With a Name Too Long for One Line"
    }

    MprisPlayer {
        serviceName: "org.example.nativeplayer"
        identity: "Native"
        canControl: true
        canPlay: true
        canPause: true
        playbackStatus: Mpris.Playing
        metaData.title: "Must not show up on an Android cover"
    }

    Flow {
        visible: harness.discovered
        x: Theme.paddingLarge
        y: Theme.paddingLarge
        width: parent.width - 2 * x
        spacing: Theme.paddingLarge

        Loader {
            id: first
            width: Theme.coverSizeLarge.width; height: Theme.coverSizeLarge.height
            sourceComponent: harness.discovered ? tile : undefined
            onLoaded: {
                // Audible's actions for this package, its name having the .instance suffix
                var sets = {}
                sets[harness.packageFor("org.example.audiobook")] = item.androidMediaActionSets["com.audible.application"]
                item.androidMediaActionSets = sets
                item.launcherItem = harness.launcher(harness.packageFor("org.example.audiobook"), harness.iconFile)
            }
        }
        Loader {
            width: Theme.coverSizeLarge.width; height: Theme.coverSizeLarge.height
            sourceComponent: harness.discovered ? tile : undefined
            onLoaded: item.launcherItem = harness.launcher(harness.packageFor("org.example.podcast"), harness.iconFile)
        }
        Loader {
            id: third
            width: Theme.coverSizeLarge.width * 0.66; height: Theme.coverSizeLarge.height * 0.66
            sourceComponent: harness.discovered ? tile : undefined
            onLoaded: item.launcherItem = harness.launcher(harness.packageFor("org.example.audiobook"), harness.iconFile)
        }
        Loader {
            width: Theme.coverSizeLarge.width * 0.66; height: Theme.coverSizeLarge.height * 0.66
            sourceComponent: harness.discovered ? tile : undefined
            onLoaded: item.launcherItem = harness.launcher("org.example.nomedia", harness.iconFile)
        }
        Loader {
            width: Theme.coverSizeLarge.width * 0.66; height: Theme.coverSizeLarge.height * 0.66
            sourceComponent: harness.discovered ? tile : undefined
            onLoaded: item.launcherItem = harness.launcher(harness.packageFor("org.example.podcast"), harness.iconFile)
        }
    }

    function actionButtons(tileItem) {
        var grid = tileItem.mediaActions.children[1]
        var buttons = []
        for (var i = 0; i < grid.children.length; i++) {
            if (grid.children[i].objectName === "SwitcherItem_androidMediaAction")
                buttons.push(grid.children[i])
        }
        return buttons
    }

    Timer {
        id: press

        interval: 3000
        running: harness.discovered
        onTriggered: {
            var actions = function(item) {
                return harness.actionButtons(item).map(function(button) { return button.action }).join(",")
            }
            harness.check("first tile: back30,playPause", actions(first.item) === "back30,playPause")
            harness.check("third tile: playPause,next", actions(third.item) === "playPause,next")
            var buttons = harness.actionButtons(first.item)
            buttons[0].clicked(null)   // back 30 s
            buttons[1].clicked(null)   // play/pause while playing: pause
            harness.actionButtons(third.item)[1].clicked(null)   // next
            result.start()
        }
    }

    function check(what, ok) {
        console.log((ok ? "PASS " : "FAIL ") + what)
    }

    Timer {
        id: result

        interval: 1000
        onTriggered: {
            var playPause = harness.actionButtons(first.item)[1]
            // MprisPlayer reports the offset in ms, as MprisController takes it
            harness.check("back 30 s reached the player: " + harness.seeks,
                  harness.seeks.length === 1 && harness.seeks[0] === -30000)
            harness.check("pause reached the player", harness.pauses === 1)
            harness.check("next reached the player", harness.nexts === 1)
            harness.check("the button turned to play: " + playPause.iconSource,
                  playPause.iconSource === "image://theme/icon-cover-play")
            console.log("READY FOR SCREENSHOT")
        }
    }
