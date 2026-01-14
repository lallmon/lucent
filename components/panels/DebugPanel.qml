// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls

// Toggle with F12
Rectangle {
    id: root
    width: 140
    height: contentColumn.height + 16
    color: "#CC000000"
    radius: 4
    visible: false

    property int frameCount: 0
    property real fps: 0

    // GPU rendering toggle - emitted when user clicks the toggle
    signal gpuRenderingToggled(bool enabled)
    property bool gpuRenderingEnabled: false

    FrameAnimation {
        running: root.visible
        onTriggered: root.frameCount++
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: {
            root.fps = root.frameCount;
            root.frameCount = 0;
        }
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 8

        Row {
            spacing: 6

            Text {
                text: "FPS:"
                color: "#AAAAAA"
                font.pixelSize: 11
                font.family: "monospace"
            }

            Text {
                text: root.fps.toFixed(0)
                color: root.fps < 30 ? "#FF6B6B" : root.fps < 55 ? "#FFE66D" : "#4ECDC4"
                font.pixelSize: 11
                font.bold: true
                font.family: "monospace"
            }
        }

        Row {
            spacing: 6

            Text {
                text: "GPU:"
                color: "#AAAAAA"
                font.pixelSize: 11
                font.family: "monospace"
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 40
                height: 18
                radius: 9
                color: root.gpuRenderingEnabled ? "#4ECDC4" : "#555555"
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.gpuRenderingEnabled ? parent.width - width - 2 : 2

                    Behavior on x {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.gpuRenderingEnabled = !root.gpuRenderingEnabled;
                        root.gpuRenderingToggled(root.gpuRenderingEnabled);
                    }
                }
            }

            Text {
                text: root.gpuRenderingEnabled ? "ON" : "OFF"
                color: root.gpuRenderingEnabled ? "#4ECDC4" : "#888888"
                font.pixelSize: 10
                font.bold: true
                font.family: "monospace"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
