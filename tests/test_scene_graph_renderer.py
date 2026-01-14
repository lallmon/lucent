# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""Tests for SceneGraphRenderer Phase 5 - incremental updates and caching."""


class TestCanvasModelGetItem:
    """Tests for getItem and getItemIndex methods added for SceneGraphRenderer."""

    def test_get_item_valid_index(self, canvas_model, history_manager):
        """getItem returns the CanvasItem at a valid index."""
        from test_helpers import make_rectangle

        canvas_model.addItem(make_rectangle())
        item = canvas_model.getItem(0)
        assert item is not None
        assert hasattr(item, "geometry")

    def test_get_item_invalid_index_negative(self, canvas_model):
        """getItem returns None for negative index."""
        assert canvas_model.getItem(-1) is None

    def test_get_item_invalid_index_out_of_bounds(self, canvas_model):
        """getItem returns None for out-of-bounds index."""
        from test_helpers import make_rectangle

        canvas_model.addItem(make_rectangle())
        assert canvas_model.getItem(5) is None

    def test_get_item_empty_model(self, canvas_model):
        """getItem returns None on empty model."""
        assert canvas_model.getItem(0) is None

    def test_get_item_index_valid(self, canvas_model):
        """getItemIndex returns correct index for item in model."""
        from test_helpers import make_rectangle

        canvas_model.addItem(make_rectangle(x=10))
        canvas_model.addItem(make_rectangle(x=20))
        canvas_model.addItem(make_rectangle(x=30))

        item = canvas_model.getItem(1)
        assert canvas_model.getItemIndex(item) == 1

    def test_get_item_index_not_found(self, canvas_model):
        """getItemIndex returns -1 for item not in model."""
        from test_helpers import make_rectangle
        from lucent.canvas_items import RectangleItem
        from lucent.geometry import RectGeometry
        from lucent.transforms import Transform
        from lucent.appearances import Fill

        canvas_model.addItem(make_rectangle())

        # Create an item that's not in the model
        orphan_item = RectangleItem(
            name="Orphan",
            geometry=RectGeometry(0, 0, 100, 100),
            appearances=[Fill(color="#000000")],
            transform=Transform(),
            visible=True,
            locked=False,
        )
        assert canvas_model.getItemIndex(orphan_item) == -1


class TestSceneGraphRendererImport:
    """Basic import/instantiation tests for SceneGraphRenderer."""

    def test_import(self):
        """SceneGraphRenderer can be imported."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        assert SceneGraphRenderer is not None

    def test_has_texture_cache(self, qapp):
        """SceneGraphRenderer has texture cache for rasterized shapes."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        # Texture-based approach uses a texture cache
        assert hasattr(renderer, "_texture_cache")
        assert hasattr(renderer, "_textures")
        assert hasattr(renderer, "_texture_nodes")
        assert hasattr(renderer, "_transform_nodes")

    def test_initial_state_needs_rebuild(self, qapp):
        """SceneGraphRenderer starts with needs_full_rebuild True."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        assert renderer._needs_full_rebuild is True


class TestSceneGraphRendererSignalHandling:
    """Tests for how SceneGraphRenderer responds to model signals."""

    def test_item_modified_triggers_rebuild(self, qapp, canvas_model):
        """itemModified signal triggers full rebuild (Option C behavior)."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        renderer.setModel(canvas_model)

        # Reset state after setModel
        renderer._needs_full_rebuild = False

        # Simulate item modification (signal takes index and changed properties)
        canvas_model.itemModified.emit(0, {"visible": True})

        # Option C simplifies by doing full rebuild on any change
        assert renderer._needs_full_rebuild is True

    def test_item_added_triggers_rebuild(self, qapp, canvas_model):
        """itemAdded signal triggers full rebuild."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        renderer.setModel(canvas_model)

        renderer._needs_full_rebuild = False

        canvas_model.itemAdded.emit(0)

        assert renderer._needs_full_rebuild is True

    def test_item_removed_triggers_rebuild(self, qapp, canvas_model):
        """itemRemoved signal triggers full rebuild."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        renderer.setModel(canvas_model)

        renderer._needs_full_rebuild = False

        canvas_model.itemRemoved.emit(0)

        assert renderer._needs_full_rebuild is True

    def test_items_cleared_triggers_rebuild(self, qapp, canvas_model):
        """itemsCleared signal triggers full rebuild and clears texture cache."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        renderer.setModel(canvas_model)

        # Reset rebuild flag
        renderer._needs_full_rebuild = False

        canvas_model.itemsCleared.emit()

        # Should trigger rebuild
        assert renderer._needs_full_rebuild is True


class TestSceneGraphRendererZoomPanning:
    """Tests for zoom and pan property handling."""

    def test_zoom_change_triggers_rebuild(self, qapp):
        """Changing zoomLevel triggers full rebuild for stroke widths."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        renderer._needs_full_rebuild = False

        renderer.zoomLevel = 2.0

        assert renderer._needs_full_rebuild is True
        assert renderer.zoomLevel == 2.0

    def test_tile_origin_change_triggers_rebuild(self, qapp):
        """Changing tile origin triggers rebuild for coordinate offsets."""
        from lucent.scene_graph_renderer import SceneGraphRenderer

        renderer = SceneGraphRenderer()
        renderer._needs_full_rebuild = False

        renderer.tileOriginX = 100.0
        renderer._needs_full_rebuild = False  # Reset after first change

        renderer.tileOriginY = 200.0

        assert renderer._needs_full_rebuild is True
        assert renderer.tileOriginX == 100.0
        assert renderer.tileOriginY == 200.0
