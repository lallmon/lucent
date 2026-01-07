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

            // Use bounding box for all item types - this correctly accounts for transforms
            if (!boundingBoxCallback)
                continue;

            var bounds = boundingBoxCallback(bbIndex);
            if (!bounds || bounds.width < 0 || bounds.height < 0)
                continue;

            // Expand hit area slightly for paths (stroke width + tolerance)
            var expand = 0;
            if (item.type === "path") {
                var strokeWidth = getStrokeWidth(item);
                expand = strokeWidth * 0.5 + 2;
            }

            if (canvasX >= bounds.x - expand && canvasX <= bounds.x + bounds.width + expand && canvasY >= bounds.y - expand && canvasY <= bounds.y + bounds.height + expand) {
                return resultIndex;
            }
            // Groups and layers are not hit-testable on canvas - select via Layer Panel
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
