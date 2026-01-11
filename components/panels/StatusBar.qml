// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Lucent

ToolBar {
    id: root
    implicitHeight: 32
    property real zoomLevel: 1.0
    property real cursorX: 0
    property real cursorY: 0

    readonly property bool hasUnitSettings: typeof unitSettings !== "undefined" && unitSettings !== null
    readonly property real displayCursorX: hasUnitSettings ? unitSettings.canvasToDisplay(root.cursorX) : root.cursorX
    readonly property real displayCursorY: hasUnitSettings ? unitSettings.canvasToDisplay(root.cursorY) : root.cursorY
    readonly property string displayUnitLabel: hasUnitSettings ? unitSettings.displayUnit : "px"

    RowLayout {
        anchors.fill: parent
        spacing: 12
        Layout.alignment: Qt.AlignVCenter

        // Left cluster: unit + DPI controls
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 4
                Label {
                    text: qsTr("Unit")
                    color: "white"
                }
                ComboBox {
                    id: unitPicker
                    visible: root.hasUnitSettings
                    model: [
                        {
                            label: "PX",
                            value: "px"
                        },
                        {
                            label: "MM",
                            value: "mm"
                        },
                        {
                            label: "IN",
                            value: "in"
                        },
                        {
                            label: "PT",
                            value: "pt"
                        }
                    ]
                    textRole: "label"
                    valueRole: "value"
                    implicitWidth: 72
                    currentIndex: Math.max(0, model.findIndex(m => m.value === unitSettings.displayUnit))
                    onActivated: index => {
                        if (index >= 0) {
                            unitSettings.displayUnit = model[index].value;
                        }
                    }
                }
            }

            Lucent.VerticalDivider {}

            RowLayout {
                spacing: 4
                Label {
                    text: qsTr("DPI")
                    color: "white"
                }
                ComboBox {
                    id: dpiPicker
                    visible: root.hasUnitSettings
                    model: [72, 96, 300]
                    implicitWidth: 72
                    currentIndex: {
                        var i = model.indexOf(unitSettings.dpi);
                        return i >= 0 ? i : 1; // default to 96 if not matched
                    }
                    onActivated: index => {
                        if (!root.hasUnitSettings || index < 0)
                            return;
                        var val = model[index];
                        unitSettings.dpi = val;
                        if (typeof documentManager !== "undefined" && documentManager) {
                            documentManager.setDocumentDPI(val);
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Cursor readout (center)
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6
            Lucent.PhIcon {
                name: "crosshair-simple"
                size: 16
                color: "white"
            }
            Label {
                text: qsTr("X: %1  Y: %2 %3").arg(root.displayCursorX.toFixed(1)).arg(root.displayCursorY.toFixed(1)).arg(displayUnitLabel)
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Zoom readout
        RowLayout {
            spacing: 6
            Layout.rightMargin: 10
            Lucent.PhIcon {
                name: "magnifying-glass"
                size: 16
                color: "white"
            }
            Label {
                text: qsTr("Zoom: %1%").arg(Math.round(root.zoomLevel * 100))
            }
        }
    }
}
