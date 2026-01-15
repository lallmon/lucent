// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import ".." as Lucent

Button {
    id: root

    property string iconName: ""
    property string toolTipText: ""
    property int buttonSize: 24
    property int iconSize: 22

    readonly property SystemPalette themePalette: Lucent.Themed.palette

    implicitWidth: buttonSize - 1
    implicitHeight: buttonSize - 2
    checkable: true

    background: Rectangle {
        color: {
            if (root.checked)
                return root.themePalette.highlight;
            if (root.hovered)
                return root.themePalette.midlight;
            return root.themePalette.button;
        }
    }

    contentItem: Lucent.PhIcon {
        name: root.iconName
        weight: "regular"
        size: root.iconSize
        color: root.checked ? root.themePalette.highlightedText : root.themePalette.buttonText
        visible: root.iconName !== ""
    }

    Lucent.ToolTipStyled {
        visible: root.hovered && root.toolTipText !== ""
        text: root.toolTipText
    }
}
