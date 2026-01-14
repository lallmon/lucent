// Copyright (C) 2026 The Culture List, Inc.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import CanvasRendering 1.0

// Manages rendering of canvas items with CPU tiled or GPU full-viewport modes
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

    // GPU rendering feature flag - uses single viewport renderer (Option C)
    property bool useGpuRendering: false

    // ========== CPU TILED RENDERING (default) ==========
    // Adaptive tile size based on zoom level to limit tile count
    readonly property int baseTileSize: 1024
    readonly property int maxTileCount: 16

    property int _lastTileSize: baseTileSize
    property int tileSize: baseTileSize
    property var _tiles: []

    function _getAdaptiveTileSize() {
        var zs = Math.max(zoomLevel, 0.0001);
        var viewCanvasW = viewportWidth / zs;
        var viewCanvasH = viewportHeight / zs;

        var tilesX = Math.ceil(viewCanvasW / baseTileSize);
        var tilesY = Math.ceil(viewCanvasH / baseTileSize);
        var tileCount = tilesX * tilesY;

        var ts = baseTileSize;
        while (tileCount > maxTileCount && ts < 16384) {
            ts *= 2;
            tilesX = Math.ceil(viewCanvasW / ts);
            tilesY = Math.ceil(viewCanvasH / ts);
            tileCount = tilesX * tilesY;
        }

        if (_lastTileSize > ts) {
            var currentTilesX = Math.ceil(viewCanvasW / _lastTileSize);
            var currentTilesY = Math.ceil(viewCanvasH / _lastTileSize);
            var currentCount = currentTilesX * currentTilesY;
            if (currentCount <= maxTileCount) {
                return _lastTileSize;
            }
        }

        _lastTileSize = ts;
        return ts;
    }

    function _updateTiles() {
        if (useGpuRendering) {
            _tiles = [];  // GPU mode doesn't use tiles
            return;
        }

        if (!isFinite(viewportWidth) || !isFinite(viewportHeight) || viewportWidth <= 0 || viewportHeight <= 0) {
            _tiles = [];
            return;
        }

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

    Timer {
        id: tileUpdateDebounce
        interval: 50
        repeat: false
        onTriggered: tiledLayer._updateTiles()
    }

    onZoomLevelChanged: tileUpdateDebounce.restart()
    onOffsetXChanged: _updateTiles()
    onOffsetYChanged: _updateTiles()
    onViewportWidthChanged: _updateTiles()
    onViewportHeightChanged: _updateTiles()
    onUseGpuRenderingChanged: _updateTiles()

    Component.onCompleted: _updateTiles()

    // CPU renderer tiles (default mode - multiple tiles for viewport culling)
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

    // ========== GPU SINGLE RENDERER (Option C) ==========
    // Single persistent SceneGraphRenderer covering entire viewport.
    // This avoids the tile creation/destruction that causes PySide6 QSGNode crashes.
    SceneGraphRenderer {
        id: gpuRenderer
        visible: tiledLayer.useGpuRendering

        // Cover a large canvas area (we render all items, no culling in Option C)
        width: 16384
        height: 16384
        x: -width / 2
        y: -height / 2

        zoomLevel: tiledLayer.zoomLevel
        // Origin at center of our large canvas
        tileOriginX: 0
        tileOriginY: 0

        Component.onCompleted: setModel(canvasModel)
    }
}
