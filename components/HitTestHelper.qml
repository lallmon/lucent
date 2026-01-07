import QtQuick

// Stateless helper for canvas hit-testing and selection updates.
QtObject {
    id: helper

    // Get stroke width from appearances array
    function getStrokeWidth(item) {
        if (!item.appearances)
            return 1;
        for (var i = 0; i < item.appearances.length; i++) {
            if (item.appearances[i].type === "stroke")
                return item.appearances[i].width || 1;
        }
        return 1;
    }

    function hitTest(items, canvasX, canvasY, boundingBoxCallback) {
        if (!items)
            return -1;

        // Iterate backwards so topmost items hit first.
        for (var i = items.length - 1; i >= 0; i--) {
            var item = items[i];
            if (!item || !item.type)
                continue;

            // Use modelIndex from item if available, otherwise fall back to array index
            var resultIndex = (item.modelIndex !== undefined) ? item.modelIndex : i;
            // For boundingBoxCallback, always use modelIndex since it expects model indices
            var bbIndex = (item.modelIndex !== undefined) ? item.modelIndex : i;

            // Get geometry (new nested format)
            var geom = item.geometry;

            if (item.type === "rectangle" && geom) {
                if (canvasX >= geom.x && canvasX <= geom.x + geom.width && canvasY >= geom.y && canvasY <= geom.y + geom.height) {
                    return resultIndex;
                }
            } else if (item.type === "ellipse" && geom) {
                var dx = (canvasX - geom.centerX) / geom.radiusX;
                var dy = (canvasY - geom.centerY) / geom.radiusY;
                if (dx * dx + dy * dy <= 1.0) {
                    return resultIndex;
                }
            } else if (item.type === "path") {
                // Hit test path using bounding box (consistent with text/group/layer)
                if (boundingBoxCallback) {
                    var pathBounds = boundingBoxCallback(bbIndex);
                    if (pathBounds && pathBounds.width >= 0 && pathBounds.height >= 0) {
                        var strokeWidth = getStrokeWidth(item);
                        var pathExpand = strokeWidth * 0.5 + 2;
                        if (canvasX >= pathBounds.x - pathExpand && canvasX <= pathBounds.x + pathBounds.width + pathExpand && canvasY >= pathBounds.y - pathExpand && canvasY <= pathBounds.y + pathBounds.height + pathExpand) {
                            return resultIndex;
                        }
                    }
                }
            } else if (item.type === "text") {
                // Hit test text using bounding box from model
                if (boundingBoxCallback) {
                    var textBounds = boundingBoxCallback(bbIndex);
                    if (textBounds && textBounds.width >= 0 && textBounds.height >= 0) {
                        if (canvasX >= textBounds.x && canvasX <= textBounds.x + textBounds.width && canvasY >= textBounds.y && canvasY <= textBounds.y + textBounds.height) {
                            return resultIndex;
                        }
                    }
                }
            }
            // Groups and layers are not hit-testable on canvas - select via Layer Panel
            // This allows clicking on shapes inside groups to select them directly
        }
        return -1;
    }

    function applySelection(selectionManager, canvasModel, index) {
        if (!selectionManager || !canvasModel)
            return;

        selectionManager.selectedItemIndex = index;
        selectionManager.selectedItem = (index >= 0) ? canvasModel.getItemData(index) : null;
    }
}
