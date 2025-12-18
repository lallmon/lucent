import QtQuick
import QtQuick.Controls
import DesignVibe 1.0
import "." as DV

// Infinite Canvas component with pan and zoom capabilities
Item {
    id: root
    clip: true  // Constrain rendering to viewport boundaries
    
    // Public properties
    property real zoomLevel: 1.0  // Start at 100%
    readonly property real minZoom: 0.1
    readonly property real maxZoom: 10.0
    readonly property real zoomStep: 1.05  // 5% zoom increments
    
    // Canvas offset for panning (represents camera position)
    property real offsetX: 0
    property real offsetY: 0
    
    // Cursor position in canvas coordinates
    property real cursorX: 0
    property real cursorY: 0
    
    // Drawing mode
    property string drawingMode: ""  // "" for pan, "rectangle" for drawing rectangles
    
    // Tool settings
    property real rectangleStrokeWidth: 1
    property color rectangleStrokeColor: "#ffffff"  // White by default
    property color rectangleFillColor: "#ffffff"  // White by default
    property real rectangleFillOpacity: 0.0  // Transparent by default
    
    // List to store drawn items
    property var items: []
    
    // Background color
    Rectangle {
        anchors.fill: parent
        color: DV.Theme.colors.canvasBackground
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
        
        // Grid background using vector-based rectangles for performance
        Item {
            id: gridCanvas
            anchors.centerIn: parent
            width: 36000   // Large size for "infinite" feel
            height: 36000
            
            property real gridSize: 32  // Grid cell size in pixels
            property color gridColor: DV.Theme.colors.gridMinor
            property color majorGridColor: DV.Theme.colors.gridMajor  // Lighter grey for major lines
            property int majorGridMultiplier: 5
            
            // Minor grid lines - vertical
            Repeater {
                model: Math.ceil(gridCanvas.width / gridCanvas.gridSize) + 1
                Rectangle {
                    x: index * gridCanvas.gridSize
                    y: 0
                    width: 1
                    height: gridCanvas.height
                    color: (index % gridCanvas.majorGridMultiplier === 0) ? gridCanvas.majorGridColor : gridCanvas.gridColor
                    antialiasing: false
                }
            }
            
            // Minor grid lines - horizontal
            Repeater {
                model: Math.ceil(gridCanvas.height / gridCanvas.gridSize) + 1
                Rectangle {
                    x: 0
                    y: index * gridCanvas.gridSize
                    width: gridCanvas.width
                    height: 1
                    color: (index % gridCanvas.majorGridMultiplier === 0) ? gridCanvas.majorGridColor : gridCanvas.gridColor
                    antialiasing: false
                }
            }
        }
        
        // Layer for drawn shapes - positioned at grid center
        Item {
            id: shapesLayer
            anchors.centerIn: gridCanvas
            width: 0
            height: 0
            
            CanvasRenderer {
                x: -5000
                y: -5000
                width: 10000
                height: 10000
                items: root.items
                zoomLevel: root.zoomLevel
            }
            
            // Select tool for panning and selection
            SelectTool {
                id: selectTool
                active: root.drawingMode === ""
                
                onPanDelta: (dx, dy) => {
                    root.offsetX += dx;
                    root.offsetY += dy;
                }
                
                onCursorShapeChanged: (shape) => {
                    mouseArea.cursorShape = shape;
                }
            }
            
            // Rectangle drawing tool
            RectangleTool {
                id: rectangleTool
                zoomLevel: root.zoomLevel
                active: root.drawingMode === "rectangle"
                
                onRectangleCompleted: (x, y, width, height) => {
                    // Copy values (not bindings) to ensure each rectangle has independent properties
                    var strokeWidth = Number(root.rectangleStrokeWidth);
                    var strokeColorString = root.rectangleStrokeColor.toString();
                    var fillColorString = root.rectangleFillColor.toString();
                    var fillOpacity = Number(root.rectangleFillOpacity);
                    console.log("Creating rectangle with stroke width:", strokeWidth, "stroke color:", strokeColorString, 
                               "fill color:", fillColorString, "fill opacity:", fillOpacity);
                    var newItems = root.items.slice();
                    newItems.push({
                        type: "rectangle",
                        x: x,
                        y: y,
                        width: width,
                        height: height,
                        strokeWidth: strokeWidth,
                        strokeColor: strokeColorString,
                        fillColor: fillColorString,
                        fillOpacity: fillOpacity
                    });
                    root.items = newItems;
                    console.log("Total items:", root.items.length);
                }
            }
        }
    }
    
    // Mouse area for tool interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true  // Track mouse position even when not pressed
        
        onPressed: (mouse) => {
            // Delegate to active tool
            if (root.drawingMode === "") {
                selectTool.handlePress(mouse.x, mouse.y, mouse.button);
            }
        }
        
        onReleased: (mouse) => {
            // Delegate to active tool
            if (root.drawingMode === "") {
                selectTool.handleRelease(mouse.x, mouse.y, mouse.button);
            }
        }
        
        onClicked: (mouse) => {
            if (root.drawingMode === "rectangle" && mouse.button === Qt.LeftButton) {
                // Delegate to rectangle tool
                var canvasCoords = screenToCanvas(mouse.x, mouse.y);
                rectangleTool.handleClick(canvasCoords.x, canvasCoords.y);
            }
        }
        
        onPositionChanged: (mouse) => {
            // Always update cursor position in canvas coordinates
            var canvasCoords = screenToCanvas(mouse.x, mouse.y);
            root.cursorX = canvasCoords.x;
            root.cursorY = canvasCoords.y;
            
            // Delegate to active tool
            if (root.drawingMode === "") {
                selectTool.handleMouseMove(mouse.x, mouse.y);
            } else if (root.drawingMode === "rectangle") {
                rectangleTool.handleMouseMove(canvasCoords.x, canvasCoords.y);
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
        
        // Reset any active tool
        if (drawingMode === "") {
            selectTool.reset();
        } else if (drawingMode === "rectangle") {
            rectangleTool.reset();
        }
        
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

