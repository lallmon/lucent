// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import ".." as Lucent

Rectangle {
    id: root

    default property alias buttons: buttonRow.children
    property int buttonSize: 24

    readonly property SystemPalette themePalette: Lucent.Themed.palette

    implicitWidth: buttonRow.implicitWidth + 2
    implicitHeight: buttonSize
    radius: Lucent.Styles.rad.sm
    color: themePalette.mid
    border.color: themePalette.mid
    border.width: 1

    ButtonGroup {
        exclusive: true
        buttons: buttonRow.children
    }

    Row {
        id: buttonRow
        anchors.fill: parent
        anchors.margins: 1
        spacing: 1
    }
}
