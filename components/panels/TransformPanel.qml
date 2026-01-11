// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Lucent

// Panel displaying unified transform properties (X, Y, Width, Height) for selected items
Item {
    id: root
    readonly property SystemPalette themePalette: Lucent.Themed.palette

    readonly property var selectedItem: Lucent.SelectionManager.selectedItem

    readonly property bool hasEditableBounds: {
        if (!selectedItem)
            return false;
        var t = selectedItem.type;
        return t === "rectangle" || t === "ellipse" || t === "path" || t === "text";
    }

    readonly property bool isLocked: (Lucent.SelectionManager.selectedItemIndex >= 0) && canvasModel && canvasModel.isEffectivelyLocked(Lucent.SelectionManager.selectedItemIndex)

    property var currentBounds: null
    property var geometryBounds: null
    property var currentTransform: null

    function refreshBounds() {
        var idx = Lucent.SelectionManager.selectedItemIndex;
        if (idx >= 0 && canvasModel) {
            currentBounds = canvasModel.getBoundingBox(idx);
            geometryBounds = canvasModel.getGeometryBounds(idx);
        } else {
            currentBounds = null;
            geometryBounds = null;
        }
    }

    function refreshTransform() {
        var idx = Lucent.SelectionManager.selectedItemIndex;
        if (idx >= 0 && canvasModel) {
            currentTransform = canvasModel.getItemTransform(idx);
        } else {
            currentTransform = null;
        }
    }

    Connections {
        target: canvasModel
        function onItemTransformChanged(index) {
            if (index === Lucent.SelectionManager.selectedItemIndex) {
                root.refreshTransform();
                root.refreshBounds();
            }
        }
        function onItemModified(index) {
            if (index === Lucent.SelectionManager.selectedItemIndex) {
                root.refreshTransform();
                root.refreshBounds();
            }
        }
    }

    Connections {
        target: Lucent.SelectionManager
        function onSelectedItemIndexChanged() {
            root.refreshTransform();
            root.refreshBounds();
        }
    }

    Component.onCompleted: {
        refreshTransform();
        refreshBounds();
    }

    readonly property bool controlsEnabled: hasEditableBounds && !isLocked

    readonly property int labelSize: 10
    readonly property color labelColor: themePalette.text

    property bool proportionalScale: false

    readonly property real displayedX: {
        if (!geometryBounds)
            return 0;
        var t = currentTransform;
        var originX = t ? (t.originX || 0) : 0;
        var translateX = t ? (t.translateX || 0) : 0;
        return geometryBounds.x + geometryBounds.width * originX + translateX;
    }

    readonly property real displayedY: {
        if (!geometryBounds)
            return 0;
        var t = currentTransform;
        var originY = t ? (t.originY || 0) : 0;
        var translateY = t ? (t.translateY || 0) : 0;
        return geometryBounds.y + geometryBounds.height * originY + translateY;
    }

    function updatePosition(axis, newValue) {
        var idx = Lucent.SelectionManager.selectedItemIndex;
        if (idx < 0 || !canvasModel || !geometryBounds)
            return;

        var t = currentTransform || {};
        var originX = t.originX || 0;
        var originY = t.originY || 0;

        var newTransform = {
            translateX: t.translateX || 0,
            translateY: t.translateY || 0,
            rotate: t.rotate || 0,
            scaleX: t.scaleX || 1,
            scaleY: t.scaleY || 1,
            originX: originX,
            originY: originY
        };

        if (axis === "x") {
            // newValue = geometry.x + geometry.width * originX + translateX
            // So: translateX = newValue - geometry.x - geometry.width * originX
            newTransform.translateX = newValue - geometryBounds.x - geometryBounds.width * originX;
        } else if (axis === "y") {
            newTransform.translateY = newValue - geometryBounds.y - geometryBounds.height * originY;
        }

        canvasModel.setItemTransform(idx, newTransform);
    }

    function updateDisplayedSize(property, value) {
        var idx = Lucent.SelectionManager.selectedItemIndex;
        if (idx < 0 || !canvasModel || !geometryBounds)
            return;

        var t = currentTransform || {};
        var currentScaleX = t.scaleX || 1;
        var currentScaleY = t.scaleY || 1;

        if (geometryBounds.width <= 0 || geometryBounds.height <= 0)
            return;

        var minDisplayed = 1;
        value = Math.max(minDisplayed, value);

        if (property === "width") {
            var newScaleX = value / geometryBounds.width;
            if (proportionalScale) {
                var ratio = newScaleX / currentScaleX;
                var newScaleY = currentScaleY * ratio;
                canvasModel.beginTransaction();
                updateTransform("scaleX", newScaleX);
                updateTransform("scaleY", newScaleY);
                canvasModel.endTransaction();
            } else {
                updateTransform("scaleX", newScaleX);
            }
        } else if (property === "height") {
            var newScaleY = value / geometryBounds.height;
            if (proportionalScale) {
                var ratio = newScaleY / currentScaleY;
                var newScaleX = currentScaleX * ratio;
                canvasModel.beginTransaction();
                updateTransform("scaleX", newScaleX);
                updateTransform("scaleY", newScaleY);
                canvasModel.endTransaction();
            } else {
                updateTransform("scaleY", newScaleY);
            }
        }
    }

    function updateTransform(property, value) {
        var idx = Lucent.SelectionManager.selectedItemIndex;
        if (idx >= 0 && canvasModel) {
            canvasModel.updateTransformProperty(idx, property, value);
        }
    }

    function setOrigin(newOx, newOy) {
        var idx = Lucent.SelectionManager.selectedItemIndex;
        if (idx < 0 || !canvasModel)
            return;

        var bounds = canvasModel.getGeometryBounds(idx);
        if (!bounds)
            return;

        var oldOx = currentTransform ? (currentTransform.originX || 0) : 0;
        var oldOy = currentTransform ? (currentTransform.originY || 0) : 0;
        var rotation = currentTransform ? (currentTransform.rotate || 0) : 0;
        var scaleX = currentTransform ? (currentTransform.scaleX || 1) : 1;
        var scaleY = currentTransform ? (currentTransform.scaleY || 1) : 1;
        var oldTx = currentTransform ? (currentTransform.translateX || 0) : 0;
        var oldTy = currentTransform ? (currentTransform.translateY || 0) : 0;

        // Adjust translation to keep shape visually in place when origin changes
        // Formula: adjustment = delta - R(S(delta))
        // Where delta is unscaled displacement, R is rotation, S is scale
        var dx = (oldOx - newOx) * bounds.width;
        var dy = (oldOy - newOy) * bounds.height;

        var scaledDx = dx * scaleX;
        var scaledDy = dy * scaleY;

        var radians = rotation * Math.PI / 180;
        var cos = Math.cos(radians);
        var sin = Math.sin(radians);
        var rotatedScaledDx = scaledDx * cos - scaledDy * sin;
        var rotatedScaledDy = scaledDx * sin + scaledDy * cos;

        var adjustX = dx - rotatedScaledDx;
        var adjustY = dy - rotatedScaledDy;

        var newTransform = {
            translateX: oldTx + adjustX,
            translateY: oldTy + adjustY,
            rotate: rotation,
            scaleX: scaleX,
            scaleY: currentTransform ? (currentTransform.scaleY || 1) : 1,
            originX: newOx,
            originY: newOy
        };

        canvasModel.setItemTransform(idx, newTransform);
        refreshTransform();
    }

    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Lucent.Styles.pad.sm
            Layout.rightMargin: Lucent.Styles.pad.sm

            Label {
                text: qsTr("Transform")
                font.pixelSize: 12
                color: themePalette.text
                Layout.fillWidth: true
            }
        }

        ToolSeparator {
            Layout.fillWidth: true
            orientation: Qt.Horizontal
            contentItem: Rectangle {
                implicitHeight: 1
                color: themePalette.mid
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            Layout.leftMargin: Lucent.Styles.pad.sm
            Layout.rightMargin: Lucent.Styles.pad.sm
            spacing: 8
            enabled: root.controlsEnabled
            opacity: root.controlsEnabled ? 1.0 : 0.5

            ButtonGroup {
                id: originGroup
                exclusive: true
            }

            Grid {
                columns: 3
                spacing: 2

                Repeater {
                    // Generate 3x3 origin grid: (0, 0.5, 1) × (0, 0.5, 1)
                    model: {
                        var points = [];
                        for (var row = 0; row <= 1; row += 0.5)
                            for (var col = 0; col <= 1; col += 0.5)
                                points.push({
                                    ox: col,
                                    oy: row
                                });
                        return points;
                    }

                    delegate: Button {
                        required property var modelData
                        required property int index

                        width: 16
                        height: 16
                        checkable: true
                        checked: {
                            var t = root.currentTransform;
                            var curX = t ? (t.originX !== undefined ? t.originX : 0) : 0;
                            var curY = t ? (t.originY !== undefined ? t.originY : 0) : 0;
                            return curX === modelData.ox && curY === modelData.oy;
                        }
                        ButtonGroup.group: originGroup

                        onClicked: root.setOrigin(modelData.ox, modelData.oy)

                        background: Rectangle {
                            color: parent.checked ? root.themePalette.highlight : root.themePalette.button
                            border.color: root.themePalette.mid
                            border.width: 1
                            radius: 2
                        }
                    }
                }
            }

            Lucent.VerticalDivider {}

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Lucent.SpinBoxLabeled {
                    label: qsTr("X:")
                    labelSize: root.labelSize
                    labelColor: root.labelColor
                    from: -100000
                    to: 100000
                    value: Math.round(root.displayedX)
                    Layout.fillWidth: true
                    onValueModified: newValue => {
                        root.updatePosition("x", newValue);
                        appController.focusCanvas();
                    }
                }

                Lucent.SpinBoxLabeled {
                    label: qsTr("Y:")
                    labelSize: root.labelSize
                    labelColor: root.labelColor
                    from: -100000
                    to: 100000
                    value: Math.round(root.displayedY)
                    Layout.fillWidth: true
                    onValueModified: newValue => {
                        root.updatePosition("y", newValue);
                        appController.focusCanvas();
                    }
                }
            }

            Lucent.VerticalDivider {}

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Lucent.SpinBoxLabeled {
                    label: qsTr("W:")
                    labelSize: root.labelSize
                    labelColor: root.labelColor
                    from: 0
                    to: 100000
                    value: {
                        if (!root.geometryBounds)
                            return 0;
                        var scaleX = root.currentTransform ? (root.currentTransform.scaleX || 1) : 1;
                        return Math.round(root.geometryBounds.width * scaleX);
                    }
                    Layout.fillWidth: true
                    onValueModified: newValue => {
                        root.updateDisplayedSize("width", newValue);
                        appController.focusCanvas();
                    }
                }

                Lucent.SpinBoxLabeled {
                    label: qsTr("H:")
                    labelSize: root.labelSize
                    labelColor: root.labelColor
                    from: 0
                    to: 100000
                    value: {
                        if (!root.geometryBounds)
                            return 0;
                        var scaleY = root.currentTransform ? (root.currentTransform.scaleY || 1) : 1;
                        return Math.round(root.geometryBounds.height * scaleY);
                    }
                    Layout.fillWidth: true
                    onValueModified: newValue => {
                        root.updateDisplayedSize("height", newValue);
                        appController.focusCanvas();
                    }
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 8
                    Layout.alignment: Qt.AlignHCenter
                    color: proportionalToggle.checked ? root.themePalette.highlight : root.themePalette.mid
                }

                Button {
                    id: proportionalToggle
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    checkable: true
                    checked: root.proportionalScale
                    onCheckedChanged: root.proportionalScale = checked

                    background: Rectangle {
                        color: proportionalToggle.checked ? root.themePalette.highlight : root.themePalette.button
                        border.color: root.themePalette.mid
                        border.width: 1
                        radius: 2
                    }

                    contentItem: Lucent.PhIcon {
                        name: proportionalToggle.checked ? "lock" : "lock-open"
                        size: 14
                        color: proportionalToggle.checked ? root.themePalette.highlightedText : root.themePalette.buttonText
                        anchors.centerIn: parent
                    }

                    Lucent.ToolTipStyled {
                        visible: proportionalToggle.hovered
                        text: proportionalToggle.checked ? qsTr("Constrain proportions") : qsTr("Free resize")
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 8
                    Layout.alignment: Qt.AlignHCenter
                    color: proportionalToggle.checked ? root.themePalette.highlight : root.themePalette.mid
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            Layout.leftMargin: Lucent.Styles.pad.xsm
            Layout.rightMargin: Lucent.Styles.pad.xsm
            spacing: 8
            enabled: root.controlsEnabled
            opacity: root.controlsEnabled ? 1.0 : 0.5

            Label {
                text: qsTr("Rotate:")
                font.pixelSize: root.labelSize
                color: root.labelColor
            }
            TextField {
                id: rotationField
                horizontalAlignment: TextInput.AlignHCenter
                Layout.preferredWidth: 50
                validator: IntValidator {
                    bottom: -360
                    top: 360
                }

                readonly property string expectedText: root.currentTransform ? Math.round(root.currentTransform.rotate).toString() : "0"
                property bool isCommitting: false

                Component.onCompleted: text = expectedText

                // Sync with undo/redo; skip during commit to prevent double-fire
                onExpectedTextChanged: {
                    if (!isCommitting) {
                        text = expectedText;
                    }
                }

                onEditingFinished: {
                    if (isCommitting)
                        return;
                    isCommitting = true;

                    var val = parseInt(text) || 0;
                    val = Math.max(-360, Math.min(360, val));
                    root.updateTransform("rotate", val);
                    appController.focusCanvas();

                    isCommitting = false;
                }
            }
            Label {
                text: "°"
                font.pixelSize: root.labelSize
                color: root.labelColor
            }
            Slider {
                id: rotationSlider
                from: -180
                to: 180
                value: root.currentTransform ? root.currentTransform.rotate : 0
                Layout.fillWidth: true

                onPressedChanged: {
                    if (pressed) {
                        canvasModel.beginTransaction();
                    } else {
                        canvasModel.endTransaction();
                    }
                }

                onMoved: root.updateTransform("rotate", value)

                handle: Rectangle {
                    x: rotationSlider.leftPadding + rotationSlider.visualPosition * (rotationSlider.availableWidth - width)
                    y: rotationSlider.topPadding + rotationSlider.availableHeight / 2 - height / 2
                    width: Lucent.Styles.height.xs
                    height: Lucent.Styles.height.xs
                    radius: Lucent.Styles.rad.lg
                    color: rotationSlider.pressed ? root.themePalette.highlight : root.themePalette.button
                    border.color: root.themePalette.mid
                    border.width: 1
                }
            }

            Lucent.IconButton {
                iconName: "stack-simple-fill"
                iconWeight: "fill"
                iconSize: 14
                tooltipText: qsTr("Flatten Transform")
                enabled: {
                    if (!root.controlsEnabled || !root.currentTransform)
                        return false;
                    var t = root.currentTransform;
                    var isIdentity = (t.rotate === 0 || t.rotate === undefined) && (t.scaleX === 1 || t.scaleX === undefined) && (t.scaleY === 1 || t.scaleY === undefined) && (t.translateX === 0 || t.translateX === undefined) && (t.translateY === 0 || t.translateY === undefined);
                    return !isIdentity;
                }
                onClicked: {
                    var idx = Lucent.SelectionManager.selectedItemIndex;
                    if (idx >= 0 && canvasModel) {
                        canvasModel.bakeTransform(idx);
                        appController.focusCanvas();
                    }
                }
            }
        }
    }
}
