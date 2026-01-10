import QtQuick
import QtQuick.Controls
import ".." as Lucent

// Select tool component - handles panning and object selection
Item {
    id: tool

    property bool active: false
    property var hitTestCallback: null
    property var viewportToCanvasCallback: null
    property var getBoundsCallback: null
    property var canvasToViewportCallback: null

    // Overlay geometry for manual hit testing of handles
    property var overlayGeometry: null

    // When true, overlay handles are being used - don't interfere with dragging
    property bool overlayActive: false

    // Calculate overlay position and dimensions accounting for origin and scale
    function getOverlayBounds(geom) {
        var displayedWidth = geom.geomWidth * geom.scaleX;
        var displayedHeight = geom.geomHeight * geom.scaleY;

        var overlayX = geom.geomX + geom.translateX + (geom.geomWidth * geom.originX) - (displayedWidth * geom.originX);
        var overlayY = geom.geomY + geom.translateY + (geom.geomHeight * geom.originY) - (displayedHeight * geom.originY);

        var pivotX = overlayX + displayedWidth * geom.originX;
        var pivotY = overlayY + displayedHeight * geom.originY;

        return {
            x: overlayX,
            y: overlayY,
            width: displayedWidth,
            height: displayedHeight,
            pivotX: pivotX,
            pivotY: pivotY
        };
    }

    // Transform a point from overlay-local coords to canvas coords
    function overlayToCanvas(localX, localY, bounds, geom) {
        var dx = localX - bounds.width * geom.originX;
        var dy = localY - bounds.height * geom.originY;
        var angleRad = geom.rotation * Math.PI / 180;
        var rotatedX = dx * Math.cos(angleRad) - dy * Math.sin(angleRad);
        var rotatedY = dx * Math.sin(angleRad) + dy * Math.cos(angleRad);
        return {
            x: bounds.pivotX + rotatedX,
            y: bounds.pivotY + rotatedY
        };
    }

    // Check if viewport coordinates are near the rotation handle
    function isNearRotationHandle(viewportX, viewportY) {
        if (!overlayGeometry || !canvasToViewportCallback)
            return false;

        var geom = overlayGeometry;
        var bounds = getOverlayBounds(geom);

        // Rotation grip is at top-center of overlay, extending upward
        var localX = bounds.width / 2;
        var localY = -geom.armLength - geom.handleSize / 2;

        var handleCanvas = overlayToCanvas(localX, localY, bounds, geom);
        var handleViewport = canvasToViewportCallback(handleCanvas.x, handleCanvas.y);

        var dx = viewportX - handleViewport.x;
        var dy = viewportY - handleViewport.y;
        var dist = Math.sqrt(dx * dx + dy * dy);

        var hitRadius = (geom.handleSize + geom.armLength) * geom.zoomLevel;
        return dist < hitRadius;
    }

    // Check if viewport coordinates are near any resize handle
    function isNearResizeHandle(viewportX, viewportY) {
        if (!overlayGeometry || !canvasToViewportCallback)
            return false;

        var geom = overlayGeometry;
        var bounds = getOverlayBounds(geom);

        var w = bounds.width;
        var h = bounds.height;

        var handlePositions = [
            {
                x: 0,
                y: 0
            },
            {
                x: w / 2,
                y: 0
            },
            {
                x: w,
                y: 0
            },
            {
                x: w,
                y: h / 2
            },
            {
                x: w,
                y: h
            },
            {
                x: w / 2,
                y: h
            },
            {
                x: 0,
                y: h
            },
            {
                x: 0,
                y: h / 2
            }
        ];

        var hitRadius = geom.handleSize * geom.zoomLevel * 2;

        for (var i = 0; i < handlePositions.length; i++) {
            var pos = handlePositions[i];
            var handleCanvas = overlayToCanvas(pos.x, pos.y, bounds, geom);
            var handleViewport = canvasToViewportCallback(handleCanvas.x, handleCanvas.y);

            var dx = viewportX - handleViewport.x;
            var dy = viewportY - handleViewport.y;
            var dist = Math.sqrt(dx * dx + dy * dy);

            if (dist < hitRadius)
                return true;
        }
        return false;
    }

    onOverlayActiveChanged: {
        if (overlayActive) {
            clickedOnSelectedObject = false;
            isDraggingObject = false;
        }
    }

    property bool isPanning: false
    property bool isSelecting: false
    property bool isDraggingObject: false
    property bool clickedOnSelectedObject: false
    property real lastX: 0
    property real lastY: 0
    property real selectPressX: 0
    property real selectPressY: 0
    property int lastModifiers: Qt.NoModifier

    property var deltaBufferX: []
    property var deltaBufferY: []
    property int bufferSize: 3
    property real clickThreshold: 5

    signal panDelta(real dx, real dy)
    signal cursorShapeChanged(int shape)
    signal objectClicked(real viewportX, real viewportY, int modifiers)
    signal objectDragged(real canvasDx, real canvasDy)

    function handlePress(screenX, screenY, button, modifiers) {
        if (!tool.active)
            return false;

        if (button === Qt.MiddleButton) {
            isPanning = true;
            lastX = screenX;
            lastY = screenY;
            deltaBufferX = [];
            deltaBufferY = [];
            cursorShapeChanged(Qt.ClosedHandCursor);
            return true;
        }

        if (button === Qt.LeftButton) {
            isSelecting = true;
            selectPressX = screenX;
            selectPressY = screenY;
            lastX = screenX;
            lastY = screenY;
            clickedOnSelectedObject = false;
            lastModifiers = modifiers;

            // Don't initiate object drag if cursor is over an overlay handle
            var nearAnyHandle = isNearRotationHandle(screenX, screenY) || isNearResizeHandle(screenX, screenY);

            if (!nearAnyHandle && hitTestCallback && viewportToCanvasCallback && Lucent.SelectionManager.selectedItemIndex >= 0) {
                var canvasCoords = viewportToCanvasCallback(screenX, screenY);
                var hitIndex = hitTestCallback(canvasCoords.x, canvasCoords.y);
                if (hitIndex === Lucent.SelectionManager.selectedItemIndex) {
                    clickedOnSelectedObject = true;
                }
                if (!clickedOnSelectedObject && getBoundsCallback) {
                    var selectedItem = Lucent.SelectionManager.selectedItem;
                    if (selectedItem) {
                        var bounds = getBoundsCallback(Lucent.SelectionManager.selectedItemIndex);
                        if (bounds && bounds.width >= 0 && bounds.height >= 0) {
                            if (canvasCoords.x >= bounds.x && canvasCoords.x <= bounds.x + bounds.width && canvasCoords.y >= bounds.y && canvasCoords.y <= bounds.y + bounds.height) {
                                clickedOnSelectedObject = true;
                            }
                        }
                    }
                }
            }

            return true;
        }

        return false;
    }

    function handleRelease(screenX, screenY, button, modifiers) {
        if (!tool.active)
            return false;

        if (isPanning && button === Qt.MiddleButton) {
            isPanning = false;
            cursorShapeChanged(Qt.OpenHandCursor);
            return true;
        }

        if (isSelecting && button === Qt.LeftButton) {
            if (isDraggingObject) {
                canvasModel.endTransaction();
                isDraggingObject = false;
                isSelecting = false;
                cursorShapeChanged(Qt.OpenHandCursor);
                return true;
            }

            isSelecting = false;
            var dx = Math.abs(screenX - selectPressX);
            var dy = Math.abs(screenY - selectPressY);

            if (dx < clickThreshold && dy < clickThreshold) {
                objectClicked(screenX, screenY, modifiers);
            }

            return true;
        }

        return false;
    }

    function handleMouseMove(screenX, screenY) {
        if (!tool.active)
            return false;

        if (isPanning) {
            var dx = screenX - lastX;
            var dy = screenY - lastY;

            var maxDelta = 200;
            if (Math.abs(dx) > maxDelta || Math.abs(dy) > maxDelta) {
                dx = Math.max(-maxDelta, Math.min(maxDelta, dx));
                dy = Math.max(-maxDelta, Math.min(maxDelta, dy));
            }

            deltaBufferX.push(dx);
            deltaBufferY.push(dy);

            if (deltaBufferX.length > bufferSize) {
                deltaBufferX.shift();
                deltaBufferY.shift();
            }

            var sumX = 0, sumY = 0;
            for (var i = 0; i < deltaBufferX.length; i++) {
                sumX += deltaBufferX[i];
                sumY += deltaBufferY[i];
            }
            var avgDx = sumX / deltaBufferX.length;
            var avgDy = sumY / deltaBufferY.length;

            panDelta(avgDx, avgDy);

            lastX = screenX;
            lastY = screenY;
            return true;
        }

        if (isSelecting && clickedOnSelectedObject && !overlayActive && Lucent.SelectionManager.selectedItemIndex >= 0) {
            var dx = Math.abs(screenX - selectPressX);
            var dy = Math.abs(screenY - selectPressY);

            if (!isDraggingObject && (dx >= clickThreshold || dy >= clickThreshold)) {
                isDraggingObject = true;
                canvasModel.beginTransaction();
                cursorShapeChanged(Qt.ClosedHandCursor);
            }

            if (isDraggingObject) {
                objectDragged(screenX - lastX, screenY - lastY);
                lastX = screenX;
                lastY = screenY;
                return true;
            }
        }

        return false;
    }

    function reset() {
        isPanning = false;
        isSelecting = false;
        isDraggingObject = false;
        clickedOnSelectedObject = false;
    }
}
