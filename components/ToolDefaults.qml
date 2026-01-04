import QtQuick
import "." as DV

QtObject {
    id: toolDefaults

    readonly property color defaultStrokeColor: DV.PaletteBridge.active.text
    readonly property color defaultFillColor: DV.PaletteBridge.active.text
    readonly property real defaultStrokeOpacity: 0
    readonly property real defaultFillOpacity: 0

    function defaults() {
        return {
            "rectangle": {
                strokeWidth: 1,
                strokeColor: defaultStrokeColor,
                fillColor: defaultFillColor,
                fillOpacity: defaultFillOpacity
            },
            "ellipse": {
                strokeWidth: 1,
                strokeColor: defaultStrokeColor,
                fillColor: defaultFillColor,
                fillOpacity: defaultFillOpacity
            },
            "pen": {
                strokeWidth: 1,
                strokeColor: defaultStrokeColor,
                strokeOpacity: defaultStrokeOpacity,
                fillColor: defaultFillColor,
                fillOpacity: defaultFillOpacity
            }
        };
    }
}
