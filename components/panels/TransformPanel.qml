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
    readonly property int selectedIndex: Lucent.SelectionManager.selectedItemIndex
    readonly property bool hasValidSelection: selectedIndex >= 0 && canvasModel

    readonly property bool hasEditableBounds: selectedItem && ["rectangle", "ellipse", "path", "text"].includes(selectedItem.type)

    readonly property bool isLocked: hasValidSelection && canvasModel.isEffectivelyLocked(selectedIndex)

    property var currentBounds: null
    property var geometryBounds: null
    property var currentTransform: null

    // Helper to access transform properties with defaults
    function tf(prop, fallback) {
        return currentTransform ? (currentTransform[prop] ?? fallback) : fallback;
    }

    function refreshBounds() {
        if (hasValidSelection) {
            currentBounds = canvasModel.getBoundingBox(selectedIndex);
            geometryBounds = canvasModel.getGeometryBounds(selectedIndex);
        } else {
            currentBounds = null;
            geometryBounds = null;
        }
    }

    function refreshTransform() {
        currentTransform = hasValidSelection ? canvasModel.getItemTransform(selectedIndex) : null;
    }

    Connections {
        target: canvasModel
        function onItemTransformChanged(index) {
            if (index === root.selectedIndex) {
                root.refreshTransform();
                root.refreshBounds();
            }
        }
        function onItemModified(index) {
            if (index === root.selectedIndex) {
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
        return geometryBounds.x + geometryBounds.width * tf("originX", 0) + tf("translateX", 0);
    }

    readonly property real displayedY: {
        if (!geometryBounds)
            return 0;
        return geometryBounds.y + geometryBounds.height * tf("originY", 0) + tf("translateY", 0);
    }

    function updatePosition(axis, newValue) {
        if (!hasValidSelection || !geometryBounds)
            return;

        var newTransform = {
            translateX: tf("translateX", 0),
            translateY: tf("translateY", 0),
            rotate: tf("rotate", 0),
            scaleX: tf("scaleX", 1),
            scaleY: tf("scaleY", 1),
            originX: tf("originX", 0),
            originY: tf("originY", 0)
        };

        // translateX = newValue - geometry.x - geometry.width * originX
        if (axis === "x")
            newTransform.translateX = newValue - geometryBounds.x - geometryBounds.width * newTransform.originX;
        else
            newTransform.translateY = newValue - geometryBounds.y - geometryBounds.height * newTransform.originY;

        canvasModel.setItemTransform(selectedIndex, newTransform);
    }

    function updateDisplayedSize(property, value) {
        if (!hasValidSelection || !geometryBounds)
            return;
        if (geometryBounds.width <= 0 || geometryBounds.height <= 0)
            return;

        var currentScaleX = tf("scaleX", 1);
        var currentScaleY = tf("scaleY", 1);
        value = Math.max(1, value);  // Minimum 1px displayed

        if (property === "width") {
            var newScaleX = value / geometryBounds.width;
            if (proportionalScale) {
                var ratio = newScaleX / currentScaleX;
                canvasModel.beginTransaction();
                updateTransform("scaleX", newScaleX);
                updateTransform("scaleY", currentScaleY * ratio);
                canvasModel.endTransaction();
            } else {
                updateTransform("scaleX", newScaleX);
            }
        } else {
            var newScaleY = value / geometryBounds.height;
            if (proportionalScale) {
                var ratio = newScaleY / currentScaleY;
                canvasModel.beginTransaction();
                updateTransform("scaleX", currentScaleX * ratio);
                updateTransform("scaleY", newScaleY);
                canvasModel.endTransaction();
            } else {
                updateTransform("scaleY", newScaleY);
            }
        }
    }

    function updateTransform(property, value) {
        if (hasValidSelection)
            canvasModel.updateTransformProperty(selectedIndex, property, value);
    }

    function setOrigin(newOx, newOy) {
        if (!hasValidSelection)
            return;

        var bounds = canvasModel.getGeometryBounds(selectedIndex);
        if (!bounds)
            return;

        var oldOx = tf("originX", 0);
        var oldOy = tf("originY", 0);
        var rotation = tf("rotate", 0);
        var scaleX = tf("scaleX", 1);
        var scaleY = tf("scaleY", 1);
        var oldTx = tf("translateX", 0);
        var oldTy = tf("translateY", 0);

        // Adjust translation to keep shape visually in place when origin changes
        // Formula: adjustment = delta - R(S(delta))
        var dx = (oldOx - newOx) * bounds.width;
        var dy = (oldOy - newOy) * bounds.height;

        var scaledDx = dx * scaleX;
        var scaledDy = dy * scaleY;

        var radians = rotation * Math.PI / 180;
        var cos = Math.cos(radians);
        var sin = Math.sin(radians);
        var rotatedScaledDx = scaledDx * cos - scaledDy * sin;
        var rotatedScaledDy = scaledDx * sin + scaledDy * cos;

        canvasModel.setItemTransform(selectedIndex, {
            translateX: oldTx + dx - rotatedScaledDx,
            translateY: oldTy + dy - rotatedScaledDy,
            rotate: rotation,
            scaleX: scaleX,
            scaleY: scaleY,
            originX: newOx,
            originY: newOy
        });
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
                    value: root.geometryBounds ? Math.round(root.geometryBounds.width * root.tf("scaleX", 1)) : 0
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
                    value: root.geometryBounds ? Math.round(root.geometryBounds.height * root.tf("scaleY", 1)) : 0
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

                readonly property string expectedText: Math.round(root.tf("rotate", 0)).toString()
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
                value: root.tf("rotate", 0)
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
                    return root.tf("rotate", 0) !== 0 || root.tf("scaleX", 1) !== 1 || root.tf("scaleY", 1) !== 1 || root.tf("translateX", 0) !== 0 || root.tf("translateY", 0) !== 0;
                }
                onClicked: {
                    if (root.hasValidSelection) {
                        canvasModel.bakeTransform(root.selectedIndex);
                        appController.focusCanvas();
                    }
                }
            }
        }
    }
}
