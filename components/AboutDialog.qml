import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as DV

Dialog {
    id: root
    modal: true
    focus: true
    standardButtons: Dialog.Ok

    // Inputs
    property string appVersion: ""
    property string rendererBackend: ""
    property string rendererType: ""
    property string glVendor: ""

    background: Rectangle {
        color: DV.Theme.colors.panelBackground
        radius: DV.Theme.sizes.radiusSm
        border.color: DV.Theme.colors.borderSubtle
        border.width: 1
    }

    contentItem: Item {
        implicitWidth: column.implicitWidth + 28
        implicitHeight: column.implicitHeight + 28

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Label {
                text: qsTr("Lucent")
                font.bold: true
                color: DV.Theme.colors.textSubtle
            }

            Label {
                text: qsTr("Version: %1").arg(root.appVersion || "unknown")
                color: DV.Theme.colors.textSubtle
            }

            Label {
                text: qsTr("Renderer backend: %1").arg(root.rendererBackend || "unknown")
                color: DV.Theme.colors.textSubtle
            }

            Label {
                text: qsTr("Renderer type: %1").arg(root.rendererType || "unknown")
                color: DV.Theme.colors.textSubtle
            }

            Label {
                text: qsTr("GL Vendor: %1").arg(root.glVendor || "unknown")
                color: DV.Theme.colors.textSubtle
            }
        }
    }
}
