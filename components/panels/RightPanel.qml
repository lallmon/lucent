import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Lucent

Pane {
    id: root
    padding: 0
    readonly property SystemPalette themePalette: Lucent.Themed.palette

    signal exportLayerRequested(string layerId, string layerName)
    signal focusCanvasRequested

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Pane {
            Layout.fillWidth: true

            TransformPanel {
                id: transformPanel
                anchors.left: parent.left
                anchors.right: parent.right
                onFocusCanvasRequested: root.focusCanvasRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: themePalette.mid
        }

        Pane {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150

            LayerPanel {
                anchors.fill: parent
                onExportLayerRequested: (layerId, layerName) => root.exportLayerRequested(layerId, layerName)
            }
        }
    }
}
