// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import CanvasRendering 1.0

// Manages tiled rendering of canvas items for efficient viewport updates
Item {
    id: tiledLayer

    anchors.centerIn: parent
    width: 0
    height: 0

    // Required properties from parent Canvas
    required property real zoomLevel
    required property real offsetX
    required property real offsetY
    required property real viewportWidth
    required property real viewportHeight

    // Adaptive tile size based on zoom level to limit tile count
    readonly property int baseTileSize: 1024
    readonly property int maxTileCount: 16  // Target max tiles for smooth panning

    // Expose current tile size for debugging/monitoring
    readonly property int currentTileSize: tileSize

    // Cached tile size to enable hysteresis (avoid binding loop)
    property int _lastTileSize: baseTileSize

    function _getAdaptiveTileSize() {
        var zs = Math.max(zoomLevel, 0.0001);
        var viewCanvasW = viewportWidth / zs;
        var viewCanvasH = viewportHeight / zs;

        // Calculate how many base tiles would cover the viewport
        var tilesX = Math.ceil(viewCanvasW / baseTileSize);
        var tilesY = Math.ceil(viewCanvasH / baseTileSize);
        var tileCount = tilesX * tilesY;

        // If too many tiles, double tile size until acceptable
        var ts = baseTileSize;
        while (tileCount > maxTileCount && ts < 16384) {
            ts *= 2;
            tilesX = Math.ceil(viewCanvasW / ts);
            tilesY = Math.ceil(viewCanvasH / ts);
            tileCount = tilesX * tilesY;
        }

        // Hysteresis: prefer keeping current size unless forced to change
        if (_lastTileSize > ts) {
            var currentTilesX = Math.ceil(viewCanvasW / _lastTileSize);
            var currentTilesY = Math.ceil(viewCanvasH / _lastTileSize);
            var currentCount = currentTilesX * currentTilesY;
            // Keep current larger size unless it would exceed max
            if (currentCount <= maxTileCount) {
                return _lastTileSize;
            }
        }

        _lastTileSize = ts;
        return ts;
    }

    property int tileSize: baseTileSize
    property var _tiles: []

    function _updateTiles() {
        if (!isFinite(viewportWidth) || !isFinite(viewportHeight) || viewportWidth <= 0 || viewportHeight <= 0) {
            _tiles = [];
            return;
        }

        // Recalculate adaptive tile size
        tileSize = _getAdaptiveTileSize();

        var zs = Math.max(zoomLevel, 0.0001);
        var halfW = viewportWidth / zs / 2;
        var halfH = viewportHeight / zs / 2;
        var minX = (-offsetX - halfW);
        var maxX = (-offsetX + halfW);
        var minY = (-offsetY - halfH);
        var maxY = (-offsetY + halfH);

        var ts = tileSize;
        var startX = Math.floor(minX / ts);
        var endX = Math.floor(maxX / ts);
        var startY = Math.floor(minY / ts);
        var endY = Math.floor(maxY / ts);

        var list = [];
        for (var ix = startX; ix <= endX; ix++) {
            for (var iy = startY; iy <= endY; iy++) {
                list.push({
                    cx: (ix + 0.5) * ts,
                    cy: (iy + 0.5) * ts
                });
            }
        }
        _tiles = list;
    }

    // Debounce timer for tile updates during zoom to prevent churn
    Timer {
        id: tileUpdateDebounce
        interval: 50  // Wait 50ms after last zoom change
        repeat: false
        onTriggered: tiledLayer._updateTiles()
    }

    onZoomLevelChanged: tileUpdateDebounce.restart()
    onOffsetXChanged: _updateTiles()
    onOffsetYChanged: _updateTiles()
    onViewportWidthChanged: _updateTiles()
    onViewportHeightChanged: _updateTiles()

    Component.onCompleted: _updateTiles()

    Repeater {
        model: tiledLayer._tiles
        delegate: CanvasRenderer {
            required property var modelData

            width: tiledLayer.tileSize
            height: tiledLayer.tileSize
            x: modelData.cx - width / 2
            y: modelData.cy - height / 2
            zoomLevel: tiledLayer.zoomLevel
            tileOriginX: modelData.cx
            tileOriginY: modelData.cy

            Component.onCompleted: setModel(canvasModel)
        }
    }
}
