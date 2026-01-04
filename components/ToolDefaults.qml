import QtQuick

// Centralizes default tool settings for canvas tools.
QtObject {
    id: toolDefaults

    property var values: ({
            "rectangle": {
                strokeWidth: 1,
                strokeColor: DV.PaletteBridge.active.text,
                fillColor: DV.PaletteBridge.active.base,
                fillOpacity: 0.0
            },
            "ellipse": {
                strokeWidth: 1,
                strokeColor: DV.PaletteBridge.active.text,
                fillColor: DV.PaletteBridge.active.base,
                fillOpacity: 0.0
            },
            "pen": {
                strokeWidth: 1,
                strokeColor: DV.PaletteBridge.active.text,
                strokeOpacity: 1.0,
                fillColor: DV.PaletteBridge.active.base,
                fillOpacity: 0.0
            }
        })
}
