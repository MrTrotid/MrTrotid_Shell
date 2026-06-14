import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../services"

Item {
    id: root

    implicitWidth: 380

    readonly property color colLayer0: ColorService.surface
    readonly property color colLayer1: ColorService.surfaceContainer
    readonly property color colLayer2: ColorService.surfaceContainerHigh
    readonly property color colLayer3: ColorService.surfaceContainerHighest
    readonly property color colOnSurface: ColorService.surfaceText
    readonly property color colOnSurfaceVar: ColorService.surfaceVariantText
    readonly property color colSubtext: ColorService.surfaceVariantText
    readonly property color colPrimary: ColorService.primary
    readonly property color colPrimaryContainer: ColorService.primaryContainer
    readonly property color colOnPrimaryContainer: ColorService.primaryContainerText
    readonly property color colOutline: ColorService.outlineVariant

    property string filterText: ""
    property int selectedCategory: 0
    property var recentEmojis: []

    readonly property var categories: [
        { name: "Smileys", icon: "\uf118", emojis: [
            "\u{1F600}", "\u{1F601}", "\u{1F602}", "\u{1F603}", "\u{1F604}", "\u{1F605}", "\u{1F606}", "\u{1F607}",
            "\u{1F608}", "\u{1F609}", "\u{1F60A}", "\u{1F60B}", "\u{1F60C}", "\u{1F60D}", "\u{1F60E}", "\u{1F60F}",
            "\u{1F610}", "\u{1F611}", "\u{1F612}", "\u{1F613}", "\u{1F614}", "\u{1F615}", "\u{1F616}", "\u{1F617}",
            "\u{1F618}", "\u{1F619}", "\u{1F61A}", "\u{1F61B}", "\u{1F61C}", "\u{1F61D}", "\u{1F61E}", "\u{1F61F}",
            "\u{1F620}", "\u{1F621}", "\u{1F622}", "\u{1F623}", "\u{1F624}", "\u{1F625}", "\u{1F626}", "\u{1F627}",
            "\u{1F628}", "\u{1F629}", "\u{1F62A}", "\u{1F62B}", "\u{1F62C}", "\u{1F62D}", "\u{1F62E}", "\u{1F62F}",
            "\u{1F630}", "\u{1F631}", "\u{1F632}", "\u{1F633}", "\u{1F634}", "\u{1F635}", "\u{1F636}", "\u{1F637}",
            "\u{1F910}", "\u{1F911}", "\u{1F912}", "\u{1F913}", "\u{1F914}", "\u{1F915}", "\u{1F916}", "\u{1F917}",
            "\u{1F918}", "\u{1F919}", "\u{1F91A}", "\u{1F91B}", "\u{1F91C}", "\u{1F91D}", "\u{1F91E}", "\u{1F91F}",
            "\u{1F920}", "\u{1F921}", "\u{1F922}", "\u{1F923}", "\u{1F924}", "\u{1F925}", "\u{1F926}", "\u{1F927}",
            "\u{1F928}", "\u{1F929}", "\u{1F92A}", "\u{1F92B}", "\u{1F92C}", "\u{1F92D}", "\u{1F92E}", "\u{1F92F}",
            "\u{1F970}", "\u{1F973}", "\u{1F975}", "\u{1F976}", "\u{1F978}", "\u{1F97A}", "\u{1F97D}", "\u{1F97E}",
            "\u{1F985}", "\u{1F986}", "\u{1F987}", "\u{1F988}", "\u{1F989}", "\u{1F98A}", "\u{1F98B}", "\u{1F98C}"
        ]},
        { name: "Gestures", icon: "\uf087", emojis: [
            "\u{1F44B}", "\u{1F44C}", "\u{1F44D}", "\u{1F44E}", "\u{1F44F}", "\u{1F450}", "\u{1F590}",
            "\u{1F595}", "\u{1F596}", "\u{270A}", "\u{270B}", "\u{1F44A}", "\u{1F448}", "\u{1F449}",
            "\u{261D}", "\u{1F446}", "\u{1F447}", "\u{1F440}", "\u{1F442}", "\u{1F443}", "\u{1F445}",
            "\u{1F48B}", "\u{1F48C}", "\u{1F495}", "\u{1F496}", "\u{1F497}", "\u{1F498}", "\u{1F499}",
            "\u{1F49A}", "\u{1F49B}", "\u{1F49C}", "\u{1F5A4}", "\u{2764}", "\u{1F493}", "\u{1F494}",
            "\u{1F49D}", "\u{1F49E}", "\u{1F49F}", "\u{2665}", "\u{2716}", "\u{2714}", "\u{2705}",
            "\u{274C}", "\u{274E}", "\u{2B55}", "\u{267E}", "\u{267F}", "\u{231A}", "\u{231B}",
            "\u{23F0}", "\u{23F3}", "\u{2602}", "\u{2614}", "\u{2615}", "\u{2648}", "\u{2649}", "\u{264A}"
        ]},
        { name: "Nature", icon: "\uf185", emojis: [
            "\u{1F331}", "\u{1F33B}", "\u{1F334}", "\u{1F335}", "\u{1F337}", "\u{1F338}", "\u{1F339}",
            "\u{1F33A}", "\u{1F33C}", "\u{1F33E}", "\u{1F33F}", "\u{1F340}", "\u{1F341}", "\u{1F342}",
            "\u{1F343}", "\u{1F344}", "\u{1F345}", "\u{1F346}", "\u{1F347}", "\u{1F348}", "\u{1F349}",
            "\u{1F34A}", "\u{1F34B}", "\u{1F34C}", "\u{1F34D}", "\u{1F34E}", "\u{1F34F}", "\u{1F350}",
            "\u{1F351}", "\u{1F352}", "\u{1F353}", "\u{1F354}", "\u{1F355}", "\u{1F356}", "\u{1F357}",
            "\u{1F358}", "\u{1F359}", "\u{1F35A}", "\u{1F35B}", "\u{1F35C}", "\u{1F35D}", "\u{1F35E}",
            "\u{1F35F}", "\u{1F360}", "\u{1F361}", "\u{1F362}", "\u{1F363}", "\u{1F364}", "\u{1F365}",
            "\u{2600}", "\u{2601}", "\u{26C5}", "\u{2744}", "\u{2602}", "\u{2614}", "\u{26C4}", "\u{2603}"
        ]},
        { name: "Objects", icon: "\uf0d1", emojis: [
            "\u{1F4A1}", "\u{1F4A2}", "\u{1F4A3}", "\u{1F4A4}", "\u{1F4A5}", "\u{1F4A6}", "\u{1F4A7}",
            "\u{1F4A8}", "\u{1F4A9}", "\u{1F4AA}", "\u{1F4AB}", "\u{1F4AC}", "\u{1F4AD}", "\u{1F4AE}",
            "\u{1F4AF}", "\u{1F4B0}", "\u{1F4B1}", "\u{1F4B2}", "\u{1F4B3}", "\u{1F4B4}", "\u{1F4B5}",
            "\u{1F4B6}", "\u{1F4B7}", "\u{1F4B8}", "\u{1F4B9}", "\u{1F4BA}", "\u{1F4BB}", "\u{1F4BC}",
            "\u{1F4BD}", "\u{1F4BE}", "\u{1F4BF}", "\u{1F4C0}", "\u{1F4C1}", "\u{1F4C2}", "\u{1F4C3}",
            "\u{1F4C4}", "\u{1F4C5}", "\u{1F4C6}", "\u{1F4C7}", "\u{1F4C8}", "\u{1F4C9}", "\u{1F4CA}",
            "\u{1F50D}", "\u{1F50E}", "\u{1F50F}", "\u{1F510}", "\u{1F511}", "\u{1F512}", "\u{1F513}",
            "\u{1F514}", "\u{1F515}", "\u{1F516}", "\u{1F517}", "\u{1F518}", "\u{1F519}", "\u{1F51A}"
        ]},
        { name: "Symbols", icon: "\uf27a", emojis: [
            "\u{2764}", "\u{1F494}", "\u{1F495}", "\u{1F496}", "\u{1F497}", "\u{1F498}", "\u{1F499}",
            "\u{1F49A}", "\u{1F49B}", "\u{1F49C}", "\u{1F5A4}", "\u{2665}", "\u{2666}", "\u{2660}",
            "\u{2663}", "\u{2714}", "\u{2716}", "\u{2705}", "\u{274C}", "\u{274E}", "\u{2B55}",
            "\u{2714}", "\u{2716}", "\u{270A}", "\u{270B}", "\u{1F44D}", "\u{1F44E}", "\u{261D}",
            "\u{1F446}", "\u{1F447}", "\u{2B05}", "\u{27A1}", "\u{2B06}", "\u{2B07}", "\u{2197}",
            "\u{2198}", "\u{2196}", "\u{2199}", "\u{2194}", "\u{2195}", "\u{26CE}", "\u{26D4}",
            "\u{26A0}", "\u{267B}", "\u{2733}", "\u{2734}", "\u{2747}", "\u{203C}", "\u{2049}"
        ]}
    ]

    readonly property var emojiNames: ({
        "\u{1F600}": "grinning face", "\u{1F601}": "beaming face", "\u{1F602}": "face with tears of joy",
        "\u{1F603}": "smiling face", "\u{1F604}": "smiling face eyes", "\u{1F605}": "smiling sweat",
        "\u{1F606}": "sleeping smile", "\u{1F607}": "innocent", "\u{1F608}": "smiling horns",
        "\u{1F609}": "winking", "\u{1F60A}": "smiling hearts", "\u{1F60B}": "yum",
        "\u{1F60C}": "relieved", "\u{1F60D}": "heart eyes", "\u{1F60E}": "sunglasses",
        "\u{1F60F}": "smirk", "\u{1F610}": "neutral", "\u{1F611}": "expressionless",
        "\u{1F612}": "unamused", "\u{1F613}": "cold sweat", "\u{1F614}": "pensive",
        "\u{1F615}": "confused", "\u{1F616}": "confounded", "\u{1F617}": "kissing",
        "\u{1F618}": "kissing heart", "\u{1F619}": "kissing smile", "\u{1F61A}": "kissing closed",
        "\u{1F61B}": "tongue", "\u{1F61C}": "winking tongue", "\u{1F61D}": "tongue closed",
        "\u{1F61E}": "disappointed", "\u{1F61F}": "worried", "\u{1F620}": "angry",
        "\u{1F621}": "pouting", "\u{1F622}": "crying", "\u{1F623}": "persevere",
        "\u{1F624}": "triumph", "\u{1F625}": "disappointed relived", "\u{1F626}": "open mouth frown",
        "\u{1F627}": "anguished", "\u{1F628}": "fearful", "\u{1F629}": "weary",
        "\u{1F62A}": "sleepy", "\u{1F62B}": "tired", "\u{1F62C}": "grimacing",
        "\u{1F62D}": "loudly crying", "\u{1F62E}": "open mouth", "\u{1F62F}": "hushed",
        "\u{1F630}": "cold mouth", "\u{1F631}": "screaming", "\u{1F632}": "astonished",
        "\u{1F633}": "flushed", "\u{1F634}": "sleeping", "\u{1F635}": "dizzy",
        "\u{1F636}": "no mouth", "\u{1F637}": "mask", "\u{1F910}": "zipper face",
        "\u{1F911}": "money mouth", "\u{1F912}": "thermometer face", "\u{1F913}": "nerd",
        "\u{1F914}": "thinking", "\u{1F915}": "bandage face", "\u{1F916}": "robot",
        "\u{1F917}": "hugging", "\u{1F918}": "rock on", "\u{1F919}": "call me",
        "\u{1F91A}": "raised back", "\u{1F91B}": "left fist", "\u{1F91C}": "right fist",
        "\u{1F91D}": "handshake", "\u{1F91E}": "crossed fingers", "\u{1F91F}": "love you",
        "\u{1F920}": "cowboy", "\u{1F921}": "clown", "\u{1F922}": "nauseated",
        "\u{1F923}": "rolling laughter", "\u{1F924}": "drooling", "\u{1F925}": "lying face",
        "\u{1F926}": "facepalm", "\u{1F927}": "sneezing", "\u{1F928}": "raised eyebrow",
        "\u{1F929}": "star struck", "\u{1F92A}": "crazy", "\u{1F92B}": "shushing",
        "\u{1F92C}": "symbols mouth", "\u{1F92D}": "hand over mouth", "\u{1F92E}": "vomiting",
        "\u{1F92F}": "exploding head", "\u{1F970}": "smiling hearts", "\u{1F973}": "partying",
        "\u{1F975}": "cold face", "\u{1F976}": "hot face", "\u{1F978}": "devil smile",
        "\u{1F97A}": "pleading", "\u{1F97D}": "disguised", "\u{1F97E}": "explorer",
        "\u{1F985}": "eagle", "\u{1F986}": "duck", "\u{1F987}": "bat",
        "\u{1F988}": "squid", "\u{1F989}": "flamingo", "\u{1F98A}": "fox",
        "\u{1F98B}": "butterfly", "\u{1F98C}": "deer",
        "\u{1F44B}": "wave", "\u{1F44C}": "ok hand", "\u{1F44D}": "thumbs up",
        "\u{1F44E}": "thumbs down", "\u{1F44F}": "clapping", "\u{1F450}": "open hands",
        "\u{1F590}": "raised hand", "\u{1F595}": "middle finger", "\u{1F596}": "vulcan",
        "\u{270A}": "fist", "\u{270B}": "raised hand", "\u{1F44A}": "punch",
        "\u{1F448}": "point left", "\u{1F449}": "point right", "\u{261D}": "point up",
        "\u{1F446}": "point up 2", "\u{1F447}": "point down", "\u{1F440}": "glasses",
        "\u{1F442}": "ear", "\u{1F443}": "nose", "\u{1F445}": "tongue",
        "\u{1F48B}": "kiss", "\u{1F48C}": "love letter", "\u{1F495}": "two hearts",
        "\u{1F496}": "sparkling heart", "\u{1F497}": "growing heart", "\u{1F498}": "heart arrow",
        "\u{1F499}": "blue heart", "\u{1F49A}": "green heart", "\u{1F49B}": "yellow heart",
        "\u{1F49C}": "purple heart", "\u{1F5A4}": "black heart", "\u{2764}": "red heart",
        "\u{1F493}": "beating heart", "\u{1F494}": "broken heart", "\u{1F49D}": "heart ribbon",
        "\u{1F49E}": "revolving hearts", "\u{1F49F}": "heart decoration", "\u{2665}": "heart suit",
        "\u{2716}": "heavy times", "\u{2714}": "check mark", "\u{2705}": "green check",
        "\u{274C}": "red cross", "\u{274E}": "cross mark", "\u{2B55}": "circle",
        "\u{267E}": "infinity", "\u{267F}": "wheelchair", "\u{231A}": "watch",
        "\u{231B}": "hourglass", "\u{23F0}": "alarm clock", "\u{23F3}": "hourglass done",
        "\u{2602}": "umbrella", "\u{2614}": "umbrella rain", "\u{2615}": "coffee",
        "\u{2648}": "aries", "\u{2649}": "taurus", "\u{264A}": "gemini",
        "\u{1F331}": "seedling", "\u{1F33B}": "sunflower", "\u{1F334}": "palm tree",
        "\u{1F335}": "cactus", "\u{1F337}": "tulip", "\u{1F338}": "cherry blossom",
        "\u{1F339}": "rose", "\u{1F33A}": "hibiscus", "\u{1F33C}": "blossom",
        "\u{1F33E}": "rice", "\u{1F33F}": "herb", "\u{1F340}": "four leaf clover",
        "\u{1F341}": "maple leaf", "\u{1F342}": "fallen leaf", "\u{1F343}": "leaves",
        "\u{1F344}": "mushroom", "\u{1F345}": "tomato", "\u{1F346}": "eggplant",
        "\u{1F347}": "grapes", "\u{1F348}": "melon", "\u{1F349}": "watermelon",
        "\u{1F34A}": "tangerine", "\u{1F34B}": "lemon", "\u{1F34C}": "banana",
        "\u{1F34D}": "pineapple", "\u{1F34E}": "apple red", "\u{1F34F}": "apple green",
        "\u{1F350}": "pear", "\u{1F351}": "peach", "\u{1F352}": "cherries",
        "\u{1F353}": "strawberry", "\u{1F354}": "hamburger", "\u{1F355}": "pizza",
        "\u{1F356}": "meat", "\u{1F357}": "poultry", "\u{1F358}": "rice cracker",
        "\u{1F359}": "rice ball", "\u{1F35A}": "cooked rice", "\u{1F35B}": "curry",
        "\u{1F35C}": "steaming bowl", "\u{1F35D}": "spaghetti", "\u{1F35E}": "bread",
        "\u{1F35F}": "fries", "\u{1F360}": "roasted potato", "\u{1F361}": "dango",
        "\u{1F362}": "oden", "\u{1F363}": "sushi", "\u{1F364}": "fried shrimp",
        "\u{1F365}": "fish cake", "\u{2600}": "sun", "\u{2601}": "cloud",
        "\u{26C5}": "sun cloud", "\u{2744}": "snowflake", "\u{2614}": "umbrella rain",
        "\u{26C4}": "snowman", "\u{2603}": "snowman snow",
        "\u{1F4A1}": "light bulb", "\u{1F4A2}": "anger", "\u{1F4A3}": "bomb",
        "\u{1F4A4}": "sleeping", "\u{1F4A5}": "boom", "\u{1F4A6}": "sweat droplets",
        "\u{1F4A7}": "droplet", "\u{1F4A8}": "dash", "\u{1F4A9}": "pile of poo",
        "\u{1F4AA}": "flexed biceps", "\u{1F4AB}": "dizzy", "\u{1F4AC}": "speech bubble",
        "\u{1F4AD}": "thought bubble", "\u{1F4AE}": "white flower", "\u{1F4AF}": "100 points",
        "\u{1F4B0}": "money bag", "\u{1F4B1}": "currency exchange", "\u{1F4B2}": "heavy dollar",
        "\u{1F4B3}": "dollar", "\u{1F4B4}": "yen", "\u{1F4B5}": "euro",
        "\u{1F4B6}": "pound", "\u{1F4B7}": "money wings", "\u{1F4B8}": "money chart",
        "\u{1F4B9}": "chart up", "\u{1F4BA}": "seat", "\u{1F4BB}": "laptop",
        "\u{1F4BC}": "briefcase", "\u{1F4BD}": "minidisc", "\u{1F4BE}": "floppy",
        "\u{1F4BF}": "cd", "\u{1F4C0}": "dvd", "\u{1F4C1}": "folder",
        "\u{1F4C2}": "open folder", "\u{1F4C3}": "page curl", "\u{1F4C4}": "page facing up",
        "\u{1F4C5}": "calendar", "\u{1F4C6}": "calendar tear", "\u{1F4C7}": "card index",
        "\u{1F4C8}": "chart up", "\u{1F4C9}": "chart down", "\u{1F4CA}": "bar chart",
        "\u{1F50D}": "magnifying glass left", "\u{1F50E}": "magnifying glass right",
        "\u{1F50F}": "locked pen", "\u{1F510}": "locked pen", "\u{1F511}": "key",
        "\u{1F512}": "locked", "\u{1F513}": "unlocked", "\u{1F514}": "bell",
        "\u{1F515}": "no bell", "\u{1F516}": "bookmark", "\u{1F517}": "link",
        "\u{1F518}": "radio button", "\u{1F519}": "back arrow", "\u{1F51A}": "end",
        "\u{2764}": "red heart", "\u{1F494}": "broken heart", "\u{1F495}": "two hearts",
        "\u{1F496}": "sparkling heart", "\u{1F497}": "growing heart", "\u{1F498}": "heart arrow",
        "\u{2665}": "heart suit", "\u{2666}": "diamond suit", "\u{2660}": "spade suit",
        "\u{2663}": "club suit", "\u{2705}": "green check", "\u{274C}": "red cross",
        "\u{274E}": "cross mark", "\u{2B55}": "hollow circle", "\u{270A}": "fist",
        "\u{270B}": "raised hand", "\u{1F44D}": "thumbs up", "\u{1F44E}": "thumbs down",
        "\u{261D}": "point up", "\u{1F446}": "point up 2", "\u{1F447}": "point down",
        "\u{2B05}": "left arrow", "\u{27A1}": "right arrow", "\u{2B06}": "up arrow",
        "\u{2B07}": "down arrow", "\u{2197}": "up right", "\u{2198}": "down right",
        "\u{2196}": "up left", "\u{2199}": "down left", "\u{2194}": "left right",
        "\u{2195}": "up down", "\u{26CE}": "ophiuchus", "\u{26D4}": "no entry",
        "\u{26A0}": "warning", "\u{267B}": "recycle", "\u{2733}": "eight sparkle",
        "\u{2734}": "eight sparkle", "\u{2747}": "sparkle", "\u{203C}": "double exclamation",
        "\u{2049}": "exclamation question"
    })

    readonly property var filteredEmojis: {
        var cat = categories[selectedCategory];
        if (!cat) return [];
        if (filterText === "") return cat.emojis;
        var lower = filterText.toLowerCase();
        var result = [];
        // Search across all categories by name
        for (var c = 0; c < categories.length; c++) {
            var emojis = categories[c].emojis;
            for (var i = 0; i < emojis.length; i++) {
                var name = emojiNames[emojis[i]] || "";
                if (name.indexOf(lower) !== -1) {
                    result.push(emojis[i]);
                }
            }
        }
        return result;
    }

    function close() {
        ShellState.closePopup()
    }

    function copyEmoji(emoji) {
        copyProc.command = ["sh", "-c", "printf '%s' '" + emoji + "' | wl-copy"];
        copyProc.running = true;
        // Add to recent
        var recent = recentEmojis.slice();
        var idx = recent.indexOf(emoji);
        if (idx !== -1) recent.splice(idx, 1);
        recent.unshift(emoji);
        if (recent.length > 24) recent = recent.slice(0, 24);
        recentEmojis = recent;
        close();
    }

    Process {
        id: copyProc
        running: false
    }

    // Main container — flush with left edge
    Rectangle {
        anchors.fill: parent
        color: colLayer0
        topLeftRadius: 0
        bottomLeftRadius: 0
        topRightRadius: 20
        bottomRightRadius: 20

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            anchors.leftMargin: 16
            spacing: 12

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 30; height: 30; radius: 9
                    color: colPrimaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: "\uf118"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: colOnPrimaryContainer
                    }
                }

                Text {
                    text: "Emoji"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: colOnSurface
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 24; height: 24; radius: 7
                    color: closeArea.containsMouse ? colLayer3 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: colOnSurfaceVar
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: close()
                    }
                }
            }

            // ── Search ──
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 12
                color: emojiSearch.activeFocus ? Qt.alpha(colPrimary, 0.1) : colLayer2
                border.width: emojiSearch.activeFocus ? 1 : 0
                border.color: Qt.alpha(colPrimary, 0.35)

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "\uf002"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: emojiSearch.activeFocus ? colPrimary : colSubtext
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 22

                        TextInput {
                            id: emojiSearch
                            anchors.fill: parent
                            color: colOnSurface
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            clip: true
                            selectByMouse: true
                            selectionColor: Qt.alpha(colPrimary, 0.3)
                            focus: true
                            cursorVisible: false
                            verticalAlignment: TextInput.AlignVCenter

                            onActiveFocusChanged: {
                                if (activeFocus) cursorVisible = true;
                            }

                            onTextChanged: root.filterText = text

                            Keys.onEscapePressed: root.close()
                        }

                        Text {
                            visible: emojiSearch.text === "" && !emojiSearch.activeFocus
                            text: "Search emoji..."
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: colSubtext
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // ── Category Tabs ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.categories

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: index === root.selectedCategory ? colPrimaryContainer : (catHover.containsMouse ? colLayer2 : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: index === root.selectedCategory ? colOnPrimaryContainer : colOnSurfaceVar
                        }

                        MouseArea {
                            id: catHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedCategory = index
                        }
                    }
                }
            }

            // ── Emoji Grid ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: colLayer1
                topLeftRadius: 14
                topRightRadius: 14
                bottomLeftRadius: 14
                bottomRightRadius: 14
                clip: true

                GridView {
                    id: emojiGrid
                    anchors.fill: parent
                    anchors.margins: 8
                    cellWidth: 44
                    cellHeight: 44
                    model: root.filteredEmojis
                    clip: true

                    delegate: Rectangle {
                        width: 40
                        height: 40
                        radius: 10
                        color: emojiHover.containsMouse ? colLayer2 : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 22
                        }

                        MouseArea {
                            id: emojiHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyEmoji(modelData)
                        }
                    }
                }
            }

            // ── Footer ──
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.filteredEmojis.length + " emojis"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: colSubtext
                    Layout.fillWidth: true
                }

                Text {
                    text: "Click to copy"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Qt.alpha(colSubtext, 0.5)
                }
            }
        }
    }

    function show() {
        filterText = "";
        emojiSearch.text = "";
        emojiSearch.cursorVisible = false;
        selectedCategory = 0;
        Qt.callLater(function() {
            emojiSearch.forceActiveFocus();
            emojiSearch.cursorVisible = true;
        });
        Qt.callLater(function() {
            Qt.callLater(function() {
                emojiSearch.forceActiveFocus();
                emojiSearch.cursorVisible = true;
            });
        });
    }
}
