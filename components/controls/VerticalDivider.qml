// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import ".." as Lucent

// Vertical divider line for separating control groups in panels
Rectangle {
    id: root

    property real verticalMargin: 4

    Layout.preferredWidth: 1
    Layout.fillHeight: true
    Layout.topMargin: verticalMargin
    Layout.bottomMargin: verticalMargin

    color: Lucent.Themed.palette.mid
}
