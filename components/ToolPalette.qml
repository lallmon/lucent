import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as DV

Pane {
    id: root
    width: 48
    padding: DV.Styles.pad.md

    signal toolSelected(string toolName)
    property string activeTool: ""
    readonly property SystemPalette palette: DV.PaletteBridge.active

    ButtonGroup {
        id: toolButtonGroup
        exclusive: true
    }

    contentItem: ColumnLayout {
        // Selection tool button
        ToolButton {
            id: selButton
            Layout.preferredWidth: DV.Styles.height.xlg
            Layout.preferredHeight: DV.Styles.height.xlg
            Layout.alignment: Qt.AlignHCenter
            checkable: true
            checked: root.activeTool === "select" || root.activeTool === ""
            ButtonGroup.group: toolButtonGroup

            contentItem: Item {
                anchors.fill: parent
                PhIcon {
                    anchors.centerIn: parent
                    name: "hand-pointing"
                    color: palette.buttonText
                }
            }

            onClicked: {
                root.toolSelected(checked ? "select" : "");
            }

            // No custom background; rely on default ToolButton visuals
        }

        // Rectangle tool button
        ToolButton {
            id: rectButton
            Layout.preferredWidth: DV.Styles.height.xlg
            Layout.preferredHeight: DV.Styles.height.xlg
            Layout.alignment: Qt.AlignHCenter
            checkable: true
            checked: root.activeTool === "rectangle"
            ButtonGroup.group: toolButtonGroup

            ToolTip.visible: rectButton.hovered
            ToolTip.delay: 500
            ToolTip.text: "Rectangle Tool\n\nShift: Constrain to square\nAlt: Draw from center"

            contentItem: Item {
                anchors.fill: parent
                PhIcon {
                    anchors.centerIn: parent
                    name: "rectangle"
                    color: palette.buttonText
                }
            }
            onClicked: {
                root.toolSelected(checked ? "rectangle" : "");
            }
            // No custom background; rely on default ToolButton visuals
        }

        ToolButton {
            id: ellipseButton
            Layout.preferredWidth: DV.Styles.height.xlg
            Layout.preferredHeight: DV.Styles.height.xlg
            Layout.alignment: Qt.AlignHCenter
            checkable: true
            checked: root.activeTool === "ellipse"
            ButtonGroup.group: toolButtonGroup

            ToolTip.visible: ellipseButton.hovered
            ToolTip.delay: 500
            ToolTip.text: "Ellipse Tool\n\nShift: Constrain to circle\nAlt: Draw from center"

            contentItem: Item {
                anchors.fill: parent
                PhIcon {
                    anchors.centerIn: parent
                    name: "circle"
                    color: palette.buttonText
                }
            }

            onClicked: {
                root.toolSelected(checked ? "ellipse" : "");
            }

            // No custom background; rely on default ToolButton visuals
        }
        // Pen tool button (bottom)
        ToolButton {
            id: penButton
            Layout.preferredWidth: DV.Styles.height.xlg
            Layout.preferredHeight: DV.Styles.height.xlg
            Layout.alignment: Qt.AlignHCenter
            checkable: true
            checked: root.activeTool === "pen"
            ButtonGroup.group: toolButtonGroup

            ToolTip.visible: penButton.hovered
            ToolTip.delay: 500
            ToolTip.text: "Pen Tool\n\nClick to add points, click first point to close"

            contentItem: Item {
                anchors.fill: parent
                PhIcon {
                    anchors.centerIn: parent
                    name: "pen-nib"
                    color: palette.buttonText
                }
            }

            onClicked: {
                root.toolSelected(checked ? "pen" : "");
            }

            // No custom background; rely on default ToolButton visuals
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
