// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import ".." as Lucent

// Simple icon button for action triggers (non-checkable)
Rectangle {
    id: root

    property string iconName: ""
    property string iconWeight: "fill"
    property string tooltipText: ""
    property int size: 24
    property int iconSize: 20
    property bool enabled: true
    // Base icon color when not hovered (e.g. based on selection state)
    property color iconBaseColor: themePalette.text
    // Final icon color: disabled uses mid, hover uses highlight, otherwise base
    readonly property color iconColor: {
        if (!enabled)
            return themePalette.mid;
        return hovered ? themePalette.highlight : iconBaseColor;
    }

    signal clicked

    readonly property SystemPalette themePalette: Lucent.Themed.palette
    readonly property bool hovered: enabled && hoverHandler.hovered

    width: size
    height: size
    radius: Lucent.Styles.rad.sm
    color: enabled && hovered ? themePalette.midlight : "transparent"
    opacity: enabled ? 1.0 : 0.6

    Lucent.PhIcon {
        anchors.centerIn: parent
        name: root.iconName
        weight: root.iconWeight
        size: root.iconSize
        color: root.iconColor
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.clicked()
    }

    Lucent.ToolTipStyled {
        visible: root.hovered && root.tooltipText !== ""
        text: root.tooltipText
    }
}
