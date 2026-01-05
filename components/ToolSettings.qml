import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "." as DV

ToolBar {
    id: root
    height: 48
    property ToolDefaults toolDefaults: ToolDefaults {}

    property string activeTool: ""  // Current tool ("select", "rectangle", "ellipse", etc.)
    readonly property SystemPalette themePalette: DV.Themed.palette

    property real rectangleStrokeWidth: 1
    property color rectangleStrokeColor: toolDefaults.defaultStrokeColor
    property real rectangleStrokeOpacity: 1.0
    property color rectangleFillColor: toolDefaults.defaultFillColor
    property real rectangleFillOpacity: toolDefaults.defaultFillOpacity

    property real ellipseStrokeWidth: 1
    property color ellipseStrokeColor: toolDefaults.defaultStrokeColor
    property real ellipseStrokeOpacity: 1.0
    property color ellipseFillColor: toolDefaults.defaultFillColor
    property real ellipseFillOpacity: toolDefaults.defaultFillOpacity

    property real penStrokeWidth: 1
    property color penStrokeColor: toolDefaults.defaultStrokeColor
    property real penStrokeOpacity: 1.0
    property color penFillColor: toolDefaults.defaultFillColor
    property real penFillOpacity: toolDefaults.defaultFillOpacity

    property string textFontFamily: "Sans Serif"
    property real textFontSize: 16
    property color textColor: toolDefaults.defaultStrokeColor
    property real textOpacity: 1.0

    readonly property var toolSettings: ({
            "rectangle": {
                strokeWidth: rectangleStrokeWidth,
                strokeColor: rectangleStrokeColor,
                strokeOpacity: rectangleStrokeOpacity,
                fillColor: rectangleFillColor,
                fillOpacity: rectangleFillOpacity
            },
            "ellipse": {
                strokeWidth: ellipseStrokeWidth,
                strokeColor: ellipseStrokeColor,
                strokeOpacity: ellipseStrokeOpacity,
                fillColor: ellipseFillColor,
                fillOpacity: ellipseFillOpacity
            },
            "pen": {
                strokeWidth: penStrokeWidth,
                strokeColor: penStrokeColor,
                strokeOpacity: penStrokeOpacity,
                fillColor: penFillColor,
                fillOpacity: penFillOpacity
            },
            "text": {
                fontFamily: textFontFamily,
                fontSize: textFontSize,
                textColor: textColor,
                textOpacity: textOpacity
            }
        })

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // Rectangle tool settings
        RowLayout {
            id: rectangleSettings
            visible: root.activeTool === "rectangle"
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            DV.LabeledNumericField {
                labelText: qsTr("Stroke Width:")
                value: root.rectangleStrokeWidth
                minimum: 0.1
                maximum: 100.0
                decimals: 1
                suffix: qsTr("px")
                onCommitted: function (newValue) {
                    root.rectangleStrokeWidth = newValue;
                }
            }

            ToolSeparator {}

            Label {
                text: qsTr("Stroke Color:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                id: strokeColorButton
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                onClicked: {
                    strokeColorDialog.open();
                }

                background: Rectangle {
                    border.color: themePalette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                    color: "transparent"
                    clip: true

                    // Checkerboard pattern to show transparency
                    Canvas {
                        anchors.fill: parent
                        z: 0
                        property color checkerLight: palette.midlight
                        property color checkerDark: palette.mid
                        onCheckerLightChanged: requestPaint()
                        onCheckerDarkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var size = 4;
                            for (var y = 0; y < height; y += size) {
                                for (var x = 0; x < width; x += size) {
                                    if ((Math.floor(x / size) + Math.floor(y / size)) % 2 === 0) {
                                        ctx.fillStyle = checkerLight;
                                    } else {
                                        ctx.fillStyle = checkerDark;
                                    }
                                    ctx.fillRect(x, y, size, size);
                                }
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    // Stroke color with opacity applied
                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        color: root.rectangleStrokeColor
                        opacity: root.rectangleStrokeOpacity
                    }
                }
            }

            Label {
                text: qsTr("Opacity:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            DV.OpacitySlider {
                id: strokeOpacitySlider
                opacityValue: root.rectangleStrokeOpacity
                onValueUpdated: newOpacity => root.rectangleStrokeOpacity = newOpacity
            }

            DV.LabeledNumericField {
                labelText: ""
                value: Math.round(root.rectangleStrokeOpacity * 100)
                minimum: 0
                maximum: 100
                decimals: 0
                fieldWidth: 35
                suffix: qsTr("%")
                onCommitted: function (newValue) {
                    root.rectangleStrokeOpacity = newValue / 100.0;
                }
            }

            ToolSeparator {}

            Label {
                text: qsTr("Fill Color:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                id: fillColorButton
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                onClicked: {
                    fillColorDialog.open();
                }

                background: Rectangle {
                    border.color: palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                    color: "transparent"
                    clip: true

                    // Checkerboard pattern to show transparency
                    Canvas {
                        anchors.fill: parent
                        z: 0
                        property color checkerLight: palette.midlight
                        property color checkerDark: palette.mid
                        onCheckerLightChanged: requestPaint()
                        onCheckerDarkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            // Draw checkerboard
                            var size = 4;
                            for (var y = 0; y < height; y += size) {
                                for (var x = 0; x < width; x += size) {
                                    if ((Math.floor(x / size) + Math.floor(y / size)) % 2 === 0) {
                                        ctx.fillStyle = checkerLight;
                                    } else {
                                        ctx.fillStyle = checkerDark;
                                    }
                                    ctx.fillRect(x, y, size, size);
                                }
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    // Fill color with opacity applied
                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        color: root.rectangleFillColor
                        opacity: root.rectangleFillOpacity
                    }
                }
            }

            Label {
                text: qsTr("Opacity:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            DV.OpacitySlider {
                id: opacitySlider
                opacityValue: root.rectangleFillOpacity
                onValueUpdated: newOpacity => root.rectangleFillOpacity = newOpacity
            }

            DV.LabeledNumericField {
                labelText: ""
                value: Math.round(root.rectangleFillOpacity * 100)
                minimum: 0
                maximum: 100
                decimals: 0
                fieldWidth: 35
                suffix: qsTr("%")
                onCommitted: function (newValue) {
                    root.rectangleFillOpacity = newValue / 100.0;
                }
            }
        }

        // Pen tool settings
        RowLayout {
            id: penSettings
            visible: root.activeTool === "pen"
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            DV.LabeledNumericField {
                labelText: qsTr("Stroke Width:")
                value: root.penStrokeWidth
                minimum: 0.1
                maximum: 100.0
                decimals: 1
                suffix: qsTr("px")
                onCommitted: function (newValue) {
                    root.penStrokeWidth = newValue;
                }
            }

            ToolSeparator {}

            Label {
                text: qsTr("Stroke Color:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                id: penStrokeColorButton
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                onClicked: penStrokeColorDialog.open()

                background: Rectangle {
                    border.color: palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                    color: "transparent"
                    clip: true

                    Canvas {
                        anchors.fill: parent
                        z: 0
                        property color checkerLight: palette.midlight
                        property color checkerDark: palette.mid
                        onCheckerLightChanged: requestPaint()
                        onCheckerDarkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var size = 4;
                            for (var y = 0; y < height; y += size) {
                                for (var x = 0; x < width; x += size) {
                                    if ((Math.floor(x / size) + Math.floor(y / size)) % 2 === 0) {
                                        ctx.fillStyle = checkerLight;
                                    } else {
                                        ctx.fillStyle = checkerDark;
                                    }
                                    ctx.fillRect(x, y, size, size);
                                }
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        color: root.penStrokeColor
                        opacity: root.penStrokeOpacity
                    }
                }
            }

            Label {
                text: qsTr("Opacity:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            DV.OpacitySlider {
                id: penStrokeOpacitySlider
                opacityValue: root.penStrokeOpacity
                onValueUpdated: newOpacity => root.penStrokeOpacity = newOpacity
            }

            DV.LabeledNumericField {
                labelText: ""
                value: Math.round(root.penStrokeOpacity * 100)
                minimum: 0
                maximum: 100
                decimals: 0
                fieldWidth: 35
                suffix: qsTr("%")
                onCommitted: function (newValue) {
                    root.penStrokeOpacity = newValue / 100.0;
                }
            }

            ToolSeparator {}

            Label {
                text: qsTr("Fill Color:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                id: penFillColorButton
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                onClicked: penFillColorDialog.open()

                background: Rectangle {
                    border.color: palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                    color: "transparent"
                    clip: true

                    // Checkerboard
                    Canvas {
                        anchors.fill: parent
                        z: 0
                        property color checkerLight: palette.midlight
                        property color checkerDark: palette.mid
                        onCheckerLightChanged: requestPaint()
                        onCheckerDarkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var size = 4;
                            for (var y = 0; y < height; y += size) {
                                for (var x = 0; x < width; x += size) {
                                    if ((Math.floor(x / size) + Math.floor(y / size)) % 2 === 0) {
                                        ctx.fillStyle = checkerLight;
                                    } else {
                                        ctx.fillStyle = checkerDark;
                                    }
                                    ctx.fillRect(x, y, size, size);
                                }
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        color: root.penFillColor
                        opacity: root.penFillOpacity
                    }
                }
            }

            Label {
                text: qsTr("Fill Opacity:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            DV.OpacitySlider {
                id: penFillOpacitySlider
                opacityValue: root.penFillOpacity
                onValueUpdated: newOpacity => root.penFillOpacity = newOpacity
            }

            DV.LabeledNumericField {
                labelText: ""
                value: Math.round(root.penFillOpacity * 100)
                minimum: 0
                maximum: 100
                decimals: 0
                fieldWidth: 35
                suffix: qsTr("%")
                onCommitted: function (newValue) {
                    root.penFillOpacity = newValue / 100.0;
                }
            }
        }

        // Stroke color picker dialog
        ColorDialog {
            id: strokeColorDialog
            title: qsTr("Choose Stroke Color")
            selectedColor: root.rectangleStrokeColor

            onAccepted: {
                root.rectangleStrokeColor = selectedColor;
            }
        }

        // Fill color picker dialog
        ColorDialog {
            id: fillColorDialog
            title: qsTr("Choose Fill Color")
            selectedColor: root.rectangleFillColor

            onAccepted: {
                root.rectangleFillColor = selectedColor;
            }
        }

        // Ellipse tool settings
        RowLayout {
            id: ellipseSettings
            visible: root.activeTool === "ellipse"
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            DV.LabeledNumericField {
                labelText: qsTr("Stroke Width:")
                value: root.ellipseStrokeWidth
                minimum: 0.1
                maximum: 100.0
                decimals: 1
                suffix: qsTr("px")
                onCommitted: function (newValue) {
                    root.ellipseStrokeWidth = newValue;
                }
            }

            ToolSeparator {}

            Label {
                text: qsTr("Stroke Color:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                id: ellipseStrokeColorButton
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                onClicked: {
                    ellipseStrokeColorDialog.open();
                }

                background: Rectangle {
                    border.color: palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                    color: "transparent"
                    clip: true

                    Canvas {
                        anchors.fill: parent
                        z: 0
                        property color checkerLight: palette.midlight
                        property color checkerDark: palette.mid
                        onCheckerLightChanged: requestPaint()
                        onCheckerDarkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var size = 4;
                            for (var y = 0; y < height; y += size) {
                                for (var x = 0; x < width; x += size) {
                                    if ((Math.floor(x / size) + Math.floor(y / size)) % 2 === 0) {
                                        ctx.fillStyle = checkerLight;
                                    } else {
                                        ctx.fillStyle = checkerDark;
                                    }
                                    ctx.fillRect(x, y, size, size);
                                }
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        color: root.ellipseStrokeColor
                        opacity: root.ellipseStrokeOpacity
                    }
                }
            }

            Label {
                text: qsTr("Opacity:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            DV.OpacitySlider {
                id: ellipseStrokeOpacitySlider
                opacityValue: root.ellipseStrokeOpacity
                onValueUpdated: newOpacity => root.ellipseStrokeOpacity = newOpacity
            }

            DV.LabeledNumericField {
                labelText: ""
                value: Math.round(root.ellipseStrokeOpacity * 100)
                minimum: 0
                maximum: 100
                decimals: 0
                fieldWidth: 35
                suffix: qsTr("%")
                onCommitted: function (newValue) {
                    root.ellipseStrokeOpacity = newValue / 100.0;
                }
            }

            ToolSeparator {}

            Label {
                text: qsTr("Fill Color:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                id: ellipseFillColorButton
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                onClicked: {
                    ellipseFillColorDialog.open();
                }

                background: Rectangle {
                    border.color: palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                    color: "transparent"
                    clip: true

                    // Checkerboard pattern to show transparency
                    Canvas {
                        anchors.fill: parent
                        z: 0
                        property color checkerLight: palette.midlight
                        property color checkerDark: palette.mid
                        onCheckerLightChanged: requestPaint()
                        onCheckerDarkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            // Draw checkerboard
                            var size = 4;
                            for (var y = 0; y < height; y += size) {
                                for (var x = 0; x < width; x += size) {
                                    if ((Math.floor(x / size) + Math.floor(y / size)) % 2 === 0) {
                                        ctx.fillStyle = checkerLight;
                                    } else {
                                        ctx.fillStyle = checkerDark;
                                    }
                                    ctx.fillRect(x, y, size, size);
                                }
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    // Fill color with opacity applied
                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        color: root.ellipseFillColor
                        opacity: root.ellipseFillOpacity
                    }
                }
            }

            Label {
                text: qsTr("Opacity:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            DV.OpacitySlider {
                id: ellipseOpacitySlider
                opacityValue: root.ellipseFillOpacity
                onValueUpdated: newOpacity => root.ellipseFillOpacity = newOpacity
            }

            DV.LabeledNumericField {
                labelText: ""
                value: Math.round(root.ellipseFillOpacity * 100)
                minimum: 0
                maximum: 100
                decimals: 0
                fieldWidth: 35
                suffix: qsTr("%")
                onCommitted: function (newValue) {
                    root.ellipseFillOpacity = newValue / 100.0;
                }
            }
        }

        // Ellipse stroke color picker dialog
        ColorDialog {
            id: ellipseStrokeColorDialog
            title: qsTr("Choose Ellipse Stroke Color")
            selectedColor: root.ellipseStrokeColor

            onAccepted: {
                root.ellipseStrokeColor = selectedColor;
            }
        }

        // Ellipse fill color picker dialog
        ColorDialog {
            id: ellipseFillColorDialog
            title: qsTr("Choose Ellipse Fill Color")
            selectedColor: root.ellipseFillColor

            onAccepted: {
                root.ellipseFillColor = selectedColor;
            }
        }

        // Pen stroke color picker dialog
        ColorDialog {
            id: penStrokeColorDialog
            title: qsTr("Choose Pen Stroke Color")
            selectedColor: root.penStrokeColor

            onAccepted: {
                root.penStrokeColor = selectedColor;
            }
        }

        // Pen fill color picker dialog
        ColorDialog {
            id: penFillColorDialog
            title: qsTr("Choose Pen Fill Color")
            selectedColor: root.penFillColor

            onAccepted: {
                root.penFillColor = selectedColor;
            }
        }

        // Text tool settings
        RowLayout {
            id: textSettings
            visible: root.activeTool === "text"
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Label {
                text: qsTr("Font:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            ComboBox {
                id: fontFamilyCombo
                Layout.preferredWidth: 160
                Layout.preferredHeight: DV.Styles.height.md
                Layout.alignment: Qt.AlignVCenter
                model: fontProvider ? fontProvider.fonts : []
                currentIndex: fontProvider ? fontProvider.indexOf(root.textFontFamily) : 0

                onCurrentTextChanged: {
                    if (currentText && currentText.length > 0) {
                        root.textFontFamily = currentText;
                    }
                }

                Component.onCompleted: {
                    // Set default font if not already set
                    if (fontProvider && (!root.textFontFamily || root.textFontFamily === "Sans Serif")) {
                        root.textFontFamily = fontProvider.defaultFont();
                    }
                }

                background: Rectangle {
                    color: palette.base
                    border.color: fontFamilyCombo.activeFocus ? palette.highlight : palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                }

                contentItem: Text {
                    text: fontFamilyCombo.displayText
                    color: palette.text
                    font.pixelSize: 11
                    font.family: fontFamilyCombo.displayText
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 6
                    elide: Text.ElideRight
                }
            }

            ToolSeparator {}

            Label {
                text: qsTr("Size:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            ComboBox {
                id: textFontSizeCombo
                Layout.preferredWidth: 70
                Layout.preferredHeight: DV.Styles.height.md
                Layout.alignment: Qt.AlignVCenter
                editable: true
                model: [8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 64, 72, 96, 128]

                // Find current index or -1 for custom values
                currentIndex: {
                    var idx = model.indexOf(Math.round(root.textFontSize));
                    return idx >= 0 ? idx : -1;
                }

                // Update text field to show current size
                Component.onCompleted: {
                    editText = Math.round(root.textFontSize).toString();
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        root.textFontSize = model[currentIndex];
                    }
                }

                onAccepted: {
                    var value = parseFloat(editText);
                    if (!isNaN(value) && value >= 8 && value <= 200) {
                        root.textFontSize = Math.round(value);
                    }
                    editText = Math.round(root.textFontSize).toString();
                }

                // Sync editText when textFontSize changes externally
                Connections {
                    target: root
                    function onTextFontSizeChanged() {
                        if (!textFontSizeCombo.activeFocus) {
                            textFontSizeCombo.editText = Math.round(root.textFontSize).toString();
                        }
                    }
                }

                validator: IntValidator {
                    bottom: 8
                    top: 200
                }

                background: Rectangle {
                    color: palette.base
                    border.color: textFontSizeCombo.activeFocus ? palette.highlight : palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                }

                contentItem: TextInput {
                    text: textFontSizeCombo.editText
                    font.pixelSize: 11
                    color: palette.text
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding: 6
                    rightPadding: 6
                    selectByMouse: true
                    validator: textFontSizeCombo.validator

                    onTextChanged: textFontSizeCombo.editText = text
                    onAccepted: textFontSizeCombo.accepted()
                }
            }

            Label {
                text: qsTr("pt")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            ToolSeparator {}

            Label {
                text: qsTr("Color:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                id: textColorButton
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter

                onClicked: textColorDialog.open()

                background: Rectangle {
                    border.color: palette.mid
                    border.width: 1
                    radius: DV.Styles.rad.sm
                    color: "transparent"
                    clip: true

                    Canvas {
                        anchors.fill: parent
                        z: 0
                        property color checkerLight: palette.midlight
                        property color checkerDark: palette.mid
                        onCheckerLightChanged: requestPaint()
                        onCheckerDarkChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var size = 4;
                            for (var y = 0; y < height; y += size) {
                                for (var x = 0; x < width; x += size) {
                                    if ((Math.floor(x / size) + Math.floor(y / size)) % 2 === 0) {
                                        ctx.fillStyle = checkerLight;
                                    } else {
                                        ctx.fillStyle = checkerDark;
                                    }
                                    ctx.fillRect(x, y, size, size);
                                }
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        color: root.textColor
                        opacity: root.textOpacity
                    }
                }
            }

            Label {
                text: qsTr("Opacity:")
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            DV.OpacitySlider {
                id: textOpacitySlider
                opacityValue: root.textOpacity
                onValueUpdated: newOpacity => root.textOpacity = newOpacity
            }

            DV.LabeledNumericField {
                labelText: ""
                value: Math.round(root.textOpacity * 100)
                minimum: 0
                maximum: 100
                decimals: 0
                fieldWidth: 35
                suffix: qsTr("%")
                onCommitted: function (newValue) {
                    root.textOpacity = newValue / 100.0;
                }
            }
        }

        // Text color picker dialog
        ColorDialog {
            id: textColorDialog
            title: qsTr("Choose Text Color")
            selectedColor: root.textColor

            onAccepted: {
                root.textColor = selectedColor;
            }
        }

        // Select tool settings (empty for now)
        Item {
            visible: root.activeTool === "select" || root.activeTool === ""
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        // Spacer
        Item {
            Layout.fillWidth: true
        }
    }
}
