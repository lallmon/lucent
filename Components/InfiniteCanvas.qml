import QtQuick
import QtQuick.Controls

// Infinite Canvas component with pan and zoom capabilities
Item {
    id: root
    
    // Public properties
    property real zoomLevel: 0.5  // Start zoomed out
    readonly property real minZoom: 0.1
    readonly property real maxZoom: 10.0
    readonly property real zoomStep: 1.2
    
    // Canvas offset for panning (represents camera position)
    property real offsetX: 0
    property real offsetY: 0
    
    // Drawing mode
    property string drawingMode: ""  // "" for pan, "rectangle" for drawing rectangles
    
    // List to store drawn rectangles
    property var rectangles: []
    
    // Current rectangle being drawn
    property var currentRect: null
    
    // Background color
    Rectangle {
        anchors.fill: parent
        color: "#2b2b2b"
    }
    
    // The main canvas surface that can be panned and zoomed
    Item {
        id: canvasContent
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        
        // Apply transformations for zoom and pan
        transform: [
            Scale {
                origin.x: canvasContent.width / 2
                origin.y: canvasContent.height / 2
                xScale: root.zoomLevel
                yScale: root.zoomLevel
            },
            Translate {
                x: root.offsetX / root.zoomLevel
                y: root.offsetY / root.zoomLevel
            }
        ]
        
        // Grid background for visual reference
        Canvas {
            id: gridCanvas
            anchors.centerIn: parent
            width: 36000   // Large size for "infinite" feel
            height: 36000
            
            property real gridSize: 32  // Grid cell size in pixels
            property color gridColor: "#3a3a3a"
            property color majorGridColor: "#4a4a4a"
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                
                // Calculate visible grid bounds
                var startX = 0;
                var startY = 0;
                var endX = width;
                var endY = height;
                
                // Draw minor grid lines
                ctx.strokeStyle = gridColor;
                ctx.lineWidth = 1;
                ctx.beginPath();
                
                // Vertical lines
                for (var x = startX; x <= endX; x += gridSize) {
                    ctx.moveTo(x, startY);
                    ctx.lineTo(x, endY);
                }
                
                // Horizontal lines
                for (var y = startY; y <= endY; y += gridSize) {
                    ctx.moveTo(startX, y);
                    ctx.lineTo(endX, y);
                }
                
                ctx.stroke();
                
                // Draw major grid lines (every 5 cells)
                ctx.strokeStyle = majorGridColor;
                ctx.lineWidth = 2;
                ctx.beginPath();
                
                var majorGridSize = gridSize * 5;
                
                // Vertical major lines
                for (x = startX; x <= endX; x += majorGridSize) {
                    ctx.moveTo(x, startY);
                    ctx.lineTo(x, endY);
                }
                
                // Horizontal major lines
                for (y = startY; y <= endY; y += majorGridSize) {
                    ctx.moveTo(startX, y);
                    ctx.lineTo(endX, y);
                }
                
                ctx.stroke();
            }
            
            Component.onCompleted: requestPaint()
        }
        
        // Layer for drawn shapes - positioned at grid center
        Item {
            id: shapesLayer
            anchors.centerIn: gridCanvas
            width: 0
            height: 0
            
            // Repeater to render all finalized rectangles
            Repeater {
                model: root.rectangles
                delegate: Rectangle {
                    x: modelData.x
                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    color: "transparent"
                    border.color: "red"
                    border.width: 2 / root.zoomLevel
                }
            }
            
            // Preview rectangle with dashed border (shown while drawing)
            Item {
                id: previewRect
                visible: root.currentRect !== null && 
                         root.currentRect !== undefined &&
                         root.currentRect.width > 0 &&
                         root.currentRect.height > 0
                x: root.currentRect ? root.currentRect.x : 0
                y: root.currentRect ? root.currentRect.y : 0
                width: root.currentRect ? root.currentRect.width : 0
                height: root.currentRect ? root.currentRect.height : 0
                
                // Dashed border drawn with Canvas
                Canvas {
                    id: dashedCanvas
                    anchors.fill: parent
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        
                        if (width > 0 && height > 0) {
                            ctx.strokeStyle = "red";
                            ctx.lineWidth = 2 / root.zoomLevel;
                            ctx.setLineDash([8 / root.zoomLevel, 4 / root.zoomLevel]);
                            ctx.strokeRect(0, 0, width, height);
                        }
                    }
                    
                    Component.onCompleted: requestPaint()
                    
                    Connections {
                        target: previewRect
                        function onWidthChanged() { dashedCanvas.requestPaint() }
                        function onHeightChanged() { dashedCanvas.requestPaint() }
                        function onVisibleChanged() { if (previewRect.visible) dashedCanvas.requestPaint() }
                    }
                    
                    Connections {
                        target: root
                        function onZoomLevelChanged() { dashedCanvas.requestPaint() }
                    }
                }
            }
        }
    }
    
    // Mouse area for panning and drawing
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        
        property real lastX: 0
        property real lastY: 0
        property bool isPanning: false
        property bool isDrawing: false
        property real drawStartX: 0
        property real drawStartY: 0
        
        onPressed: (mouse) => {
            if (root.drawingMode === "rectangle" && mouse.button === Qt.LeftButton) {
                // Start drawing a rectangle
                isDrawing = true;
                
                // Convert screen coordinates to canvas coordinates
                var canvasCoords = screenToCanvas(mouse.x, mouse.y);
                drawStartX = canvasCoords.x;
                drawStartY = canvasCoords.y;
                
                console.log("Draw start:", drawStartX, drawStartY);
                
                // Initialize rectangle at start point with 0 size
                root.currentRect = {
                    x: drawStartX,
                    y: drawStartY,
                    width: 1,
                    height: 1
                };
                
                cursorShape = Qt.CrossCursor;
            } else if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                // Pan with left or middle button when not in drawing mode
                isPanning = true;
                lastX = mouse.x;
                lastY = mouse.y;
                cursorShape = Qt.ClosedHandCursor;
            }
        }
        
        onReleased: (mouse) => {
            if (isDrawing && mouse.button === Qt.LeftButton) {
                // Finalize the rectangle if it has size
                if (root.currentRect && 
                    root.currentRect.width > 1 && 
                    root.currentRect.height > 1) {
                    
                    console.log("Finalizing rect:", root.currentRect.x, root.currentRect.y, 
                               root.currentRect.width, root.currentRect.height);
                    
                    // Add the rectangle to the list (create new array to trigger binding)
                    var rects = root.rectangles.slice();
                    rects.push({
                        x: root.currentRect.x,
                        y: root.currentRect.y,
                        width: root.currentRect.width,
                        height: root.currentRect.height
                    });
                    root.rectangles = rects;
                    
                    console.log("Total rectangles:", root.rectangles.length);
                }
                
                // Clear current rectangle and reset drawing state
                root.currentRect = null;
                isDrawing = false;
                cursorShape = Qt.CrossCursor;
            } else {
                isPanning = false;
                cursorShape = root.drawingMode === "rectangle" ? Qt.CrossCursor : Qt.ArrowCursor;
            }
        }
        
        onPositionChanged: (mouse) => {
            if (isDrawing) {
                // Update the current rectangle being drawn
                var canvasCoords = screenToCanvas(mouse.x, mouse.y);
                
                // Calculate width and height from start point to current point
                var width = canvasCoords.x - drawStartX;
                var height = canvasCoords.y - drawStartY;
                
                // Handle dragging in any direction (normalize rectangle)
                var rectX = width >= 0 ? drawStartX : canvasCoords.x;
                var rectY = height >= 0 ? drawStartY : canvasCoords.y;
                var rectWidth = Math.abs(width);
                var rectHeight = Math.abs(height);
                
                console.log("Drawing rect:", rectX, rectY, rectWidth, rectHeight);
                
                // Update current rectangle (create new object to trigger binding)
                root.currentRect = {
                    x: rectX,
                    y: rectY,
                    width: rectWidth,
                    height: rectHeight
                };
            } else if (isPanning) {
                var dx = mouse.x - lastX;
                var dy = mouse.y - lastY;
                
                root.offsetX += dx;
                root.offsetY += dy;
                
                lastX = mouse.x;
                lastY = mouse.y;
            }
        }
        
        // Zoom with mouse wheel
        onWheel: (wheel) => {
            var factor = wheel.angleDelta.y > 0 ? root.zoomStep : 1.0 / root.zoomStep;
            var newZoom = root.zoomLevel * factor;
            
            // Clamp zoom level
            if (newZoom >= root.minZoom && newZoom <= root.maxZoom) {
                root.zoomLevel = newZoom;
            }
        }
        
        // Convert screen coordinates to canvas coordinates
        function screenToCanvas(screenX, screenY) {
            // Get the center of the viewport
            var centerX = root.width / 2;
            var centerY = root.height / 2;
            
            // The canvasContent has these transforms:
            // 1. Scale by zoomLevel around center
            // 2. Translate by (offsetX/zoomLevel, offsetY/zoomLevel) in canvas space
            //
            // In screen space, the translate is: (offsetX/zoomLevel) * zoomLevel = offsetX
            // So to reverse:
            // 1. Subtract center and offset from screen position
            // 2. Divide by zoom level
            
            var canvasX = (screenX - centerX - root.offsetX) / root.zoomLevel;
            var canvasY = (screenY - centerY - root.offsetY) / root.zoomLevel;
            
            return { x: canvasX, y: canvasY };
        }
    }
    
    // Public functions for zoom control
    function zoomIn() {
        var newZoom = zoomLevel * zoomStep;
        if (newZoom <= maxZoom) {
            zoomLevel = newZoom;
        }
    }
    
    function zoomOut() {
        var newZoom = zoomLevel / zoomStep;
        if (newZoom >= minZoom) {
            zoomLevel = newZoom;
        }
    }
    
    function resetZoom() {
        zoomLevel = 1.0;
        offsetX = 0;
        offsetY = 0;
    }
    
    // Set the drawing mode
    function setDrawingMode(mode) {
        console.log("Setting drawing mode to:", mode);
        // "select" mode is the same as no mode (pan/zoom)
        if (mode === "select") {
            drawingMode = "";
        } else {
            drawingMode = mode;
        }
        
        if (mode === "rectangle") {
            mouseArea.cursorShape = Qt.CrossCursor;
        } else {
            mouseArea.cursorShape = Qt.ArrowCursor;
        }
    }
}

