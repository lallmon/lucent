pragma Singleton

import QtQuick

QtObject {
    property int selectedItemIndex: -1
    property var selectedItem: null
    
    Component.onCompleted: {
        canvasModel.itemModified.connect(function(index, data) {
            if (index === selectedItemIndex) {
                selectedItem = data
            }
        })
    }
}

