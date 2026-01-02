import QtQuick
import QtQuick.Controls

// Ellipse drawing tool component
Item {
    id: tool

    // Properties passed from Canvas
    property real zoomLevel: 1.0
    property bool active: false
    property var settings: null  // Tool settings object

    // Internal state
    property bool isDrawing: false
    property real drawStartX: 0
    property real drawStartY: 0
    property var currentEllipse: null

    // Signal emitted when an item is completed
    signal itemCompleted(var itemData)

    // Starting point indicator (black dot shown during ellipse drawing)
    Rectangle {
        id: startPointIndicator
        visible: tool.isDrawing
        x: tool.drawStartX - (6 / tool.zoomLevel)
        y: tool.drawStartY - (6 / tool.zoomLevel)
        width: 12 / tool.zoomLevel
        height: 12 / tool.zoomLevel
        radius: 6 / tool.zoomLevel
        color: "black"
        border.color: "white"
        border.width: 1 / tool.zoomLevel
    }

    // Preview ellipse (shown while drawing)
    Item {
        id: previewEllipse

        // Enable layer smoothing to match QPainter antialiasing
        layer.enabled: true
        layer.smooth: true

        property real strokeW: (settings ? settings.strokeWidth : 1) / tool.zoomLevel
        property real halfStroke: strokeW / 2

        visible: tool.currentEllipse !== null && tool.currentEllipse !== undefined && tool.currentEllipse.width > 0 && tool.currentEllipse.height > 0

        // Position accounts for stroke extending outward
        x: (tool.currentEllipse ? tool.currentEllipse.x : 0) - halfStroke
        y: (tool.currentEllipse ? tool.currentEllipse.y : 0) - halfStroke
        width: (tool.currentEllipse ? tool.currentEllipse.width : 0) + strokeW
        height: (tool.currentEllipse ? tool.currentEllipse.height : 0) + strokeW

        // Ellipse drawn with Canvas
        Canvas {
            id: dashedCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (width > 0 && height > 0 && settings) {
                    var centerX = width / 2;
                    var centerY = height / 2;
                    // Radii account for the stroke width being part of the parent size
                    var radiusX = (width - previewEllipse.strokeW) / 2;
                    var radiusY = (height - previewEllipse.strokeW) / 2;

                    ctx.save();
                    ctx.translate(centerX, centerY);
                    ctx.scale(radiusX, radiusY);
                    ctx.beginPath();
                    ctx.arc(0, 0, 1, 0, 2 * Math.PI, false);
                    ctx.restore();

                    var fillColor = Qt.color(settings.fillColor);
                    fillColor.a = settings.fillOpacity;
                    ctx.fillStyle = fillColor;
                    ctx.fill();

                    var strokeColor = Qt.color(settings.strokeColor);
                    strokeColor.a = settings.strokeOpacity !== undefined ? settings.strokeOpacity : 1.0;
                    ctx.strokeStyle = strokeColor;
                    ctx.lineWidth = previewEllipse.strokeW;
                    ctx.stroke();
                }
            }

            Component.onCompleted: requestPaint()

            Connections {
                target: previewEllipse
                function onWidthChanged() {
                    dashedCanvas.requestPaint();
                }
                function onHeightChanged() {
                    dashedCanvas.requestPaint();
                }
                function onVisibleChanged() {
                    if (previewEllipse.visible)
                        dashedCanvas.requestPaint();
                }
            }

            Connections {
                target: tool
                function onZoomLevelChanged() {
                    dashedCanvas.requestPaint();
                }
                function onSettingsChanged() {
                    dashedCanvas.requestPaint();
                }
            }
        }
    }

    // Handle clicks for ellipse drawing (two-click pattern like rectangle tool)
    function handleClick(canvasX, canvasY) {
        if (!tool.active)
            return;

        if (!isDrawing) {
            // First click: Start drawing an ellipse
            isDrawing = true;
            drawStartX = canvasX;
            drawStartY = canvasY;

            // Initialize ellipse at start point with minimal size
            currentEllipse = {
                x: drawStartX,
                y: drawStartY,
                width: 1,
                height: 1
            };
        } else {
            // Second click: Finalize the ellipse
            if (currentEllipse && currentEllipse.width > 1 && currentEllipse.height > 1) {

                // Convert bounding box to center and radii
                var centerX = currentEllipse.x + currentEllipse.width / 2;
                var centerY = currentEllipse.y + currentEllipse.height / 2;
                var radiusX = currentEllipse.width / 2;
                var radiusY = currentEllipse.height / 2;

                // Force value evaluation by storing in local variables first
                // This prevents QML from creating bindings to the settings object
                var sw = settings ? settings.strokeWidth : 1;
                var sc = settings ? settings.strokeColor.toString() : "#ffffff";
                var so = settings ? (settings.strokeOpacity !== undefined ? settings.strokeOpacity : 1.0) : 1.0;
                var fc = settings ? settings.fillColor.toString() : "#ffffff";
                var fo = settings ? settings.fillOpacity : 0.0;

                // Create complete item data object
                var itemData = {
                    type: "ellipse",
                    centerX: centerX,
                    centerY: centerY,
                    radiusX: radiusX,
                    radiusY: radiusY,
                    strokeWidth: sw,
                    strokeColor: sc,
                    strokeOpacity: so,
                    fillColor: fc,
                    fillOpacity: fo
                };

                // Emit signal with complete item data
                itemCompleted(itemData);
            }

            // Clear current ellipse and reset drawing state
            currentEllipse = null;
            isDrawing = false;
        }
    }

    // Update preview during mouse movement
    function handleMouseMove(canvasX, canvasY, modifiers) {
        if (!tool.active || !isDrawing)
            return;

        // Calculate distance from start point to current point
        var deltaX = canvasX - drawStartX;
        var deltaY = canvasY - drawStartY;
        var ellipseWidth = Math.abs(deltaX);
        var ellipseHeight = Math.abs(deltaY);

        // Constrain to circle when Shift is held
        if (modifiers & Qt.ShiftModifier) {
            var size = Math.max(ellipseWidth, ellipseHeight);
            ellipseWidth = size;
            ellipseHeight = size;
        }

        // Calculate position based on Alt (center mode) or corner mode
        var ellipseX, ellipseY;
        if (modifiers & Qt.AltModifier) {
            // Alt: draw from center - double the dimensions
            ellipseWidth *= 2;
            ellipseHeight *= 2;
            ellipseX = drawStartX - ellipseWidth / 2;
            ellipseY = drawStartY - ellipseHeight / 2;
        } else {
            // Normal: draw from corner
            ellipseX = deltaX >= 0 ? drawStartX : drawStartX - ellipseWidth;
            ellipseY = deltaY >= 0 ? drawStartY : drawStartY - ellipseHeight;
        }

        // Update current ellipse (create new object to trigger binding)
        currentEllipse = {
            x: ellipseX,
            y: ellipseY,
            width: ellipseWidth,
            height: ellipseHeight
        };
    }

    // Reset tool state (called when switching tools)
    function reset() {
        isDrawing = false;
        currentEllipse = null;
    }
}
