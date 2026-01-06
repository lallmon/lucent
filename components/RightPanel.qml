import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Lucent

Pane {
    id: root
    padding: 0
    readonly property SystemPalette themePalette: Lucent.Themed.palette

    signal exportLayerRequested(string layerId, string layerName)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Properties section
        Pane {
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.35
            Layout.minimumHeight: 150
            padding: 12

            ObjectPropertiesInspector {
                id: propertiesInspector
                anchors.fill: parent
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: themePalette.mid
        }

        // Layers section
        Pane {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            padding: 12

            LayerPanel {
                anchors.fill: parent
                onExportLayerRequested: (layerId, layerName) => root.exportLayerRequested(layerId, layerName)
            }
        }
    }

    // Keep inspector selection in sync without introducing a binding loop
    Component.onCompleted: {
        propertiesInspector.selectedItem = Lucent.SelectionManager.selectedItem;
    }
    Connections {
        target: Lucent.SelectionManager
        function onSelectedItemChanged() {
            propertiesInspector.selectedItem = Lucent.SelectionManager.selectedItem;
        }
        function onSelectedItemIndexChanged() {
            propertiesInspector.selectedItem = Lucent.SelectionManager.selectedItem;
        }
        function onSelectedIndicesChanged() {
            propertiesInspector.selectedItem = Lucent.SelectionManager.selectedItem;
        }
    }
}
