"""Unit tests for canvas_renderer module."""
import pytest
from unittest.mock import MagicMock, patch
from canvas_renderer import CanvasRenderer
from canvas_model import CanvasModel
from canvas_items import RectangleItem, EllipseItem, LayerItem


class TestCanvasRendererZOrder:
    """Tests for z-order (render order) in CanvasRenderer."""

    @pytest.fixture
    def canvas_model(self, qtbot):
        """Create a fresh CanvasModel for each test."""
        model = CanvasModel()
        qtbot.addWidget  # Register for cleanup
        return model

    @pytest.fixture
    def canvas_renderer(self, qtbot, canvas_model):
        """Create a CanvasRenderer with a model."""
        renderer = CanvasRenderer()
        renderer.setModel(canvas_model)
        return renderer

    def test_render_order_reverses_model_order(self, canvas_renderer, canvas_model):
        """Render order should be reversed from model order (lower index = on top)."""
        canvas_model.addItem({"type": "rectangle", "x": 0, "y": 0, "width": 10, "height": 10, "name": "First"})
        canvas_model.addItem({"type": "rectangle", "x": 5, "y": 5, "width": 10, "height": 10, "name": "Second"})
        canvas_model.addItem({"type": "rectangle", "x": 10, "y": 10, "width": 10, "height": 10, "name": "Third"})
        
        # Model order: [First (0), Second (1), Third (2)]
        render_order = canvas_renderer._get_render_order()
        
        # Render order should be reversed: Third rendered first (behind), First rendered last (on top)
        assert len(render_order) == 3
        assert render_order[0].name == "Third"
        assert render_order[1].name == "Second"
        assert render_order[2].name == "First"

    def test_render_order_skips_layers(self, canvas_renderer, canvas_model):
        """Layers should be skipped in render order (they're organizational only)."""
        canvas_model.addLayer()
        canvas_model.addItem({"type": "rectangle", "x": 0, "y": 0, "width": 10, "height": 10, "name": "Rect1"})
        canvas_model.addLayer()
        canvas_model.addItem({"type": "ellipse", "centerX": 5, "centerY": 5, "radiusX": 5, "radiusY": 5, "name": "Ellipse1"})
        
        # Model: [Layer1, Rect1, Layer2, Ellipse1]
        render_order = canvas_renderer._get_render_order()
        
        # Should only contain shapes, not layers, in reversed order
        assert len(render_order) == 2
        assert render_order[0].name == "Ellipse1"  # Last in model, first to render (behind)
        assert render_order[1].name == "Rect1"     # Second in model, second to render (on top)

    def test_render_order_with_parented_items(self, canvas_renderer, canvas_model):
        """Parented items should render in reversed model order."""
        canvas_model.addLayer()
        layer = canvas_model.getItems()[0]
        canvas_model.addItem({"type": "rectangle", "x": 0, "y": 0, "width": 10, "height": 10, "name": "Child1"})
        canvas_model.setParent(1, layer.id)
        canvas_model.addItem({"type": "rectangle", "x": 10, "y": 0, "width": 10, "height": 10, "name": "Child2"})
        canvas_model.setParent(2, layer.id)
        
        # Model: [Layer, Child1, Child2]
        render_order = canvas_renderer._get_render_order()
        
        # Reversed: Child2 renders first (behind), Child1 renders last (on top)
        assert len(render_order) == 2
        assert render_order[0].name == "Child2"
        assert render_order[1].name == "Child1"

    def test_render_order_after_layer_move(self, canvas_renderer, canvas_model):
        """After moving a layer, render order should reflect new model order."""
        # Create two layers with children
        canvas_model.addLayer()
        layer1 = canvas_model.getItems()[0]
        canvas_model.addItem({"type": "rectangle", "x": 0, "y": 0, "width": 10, "height": 10, "name": "L1Child"})
        canvas_model.setParent(1, layer1.id)
        
        canvas_model.addLayer()
        layer2 = canvas_model.getItems()[2]
        canvas_model.addItem({"type": "rectangle", "x": 20, "y": 0, "width": 10, "height": 10, "name": "L2Child"})
        canvas_model.setParent(3, layer2.id)
        
        # Model: [Layer1, L1Child, Layer2, L2Child]
        # Initially: L2Child behind, L1Child on top
        render_order = canvas_renderer._get_render_order()
        assert render_order[0].name == "L2Child"
        assert render_order[1].name == "L1Child"
        
        # Move Layer2 to top (index 2 -> 0)
        canvas_model.moveItem(2, 0)
        
        # New model: [Layer2, L2Child, Layer1, L1Child]
        # Now: L1Child behind, L2Child on top
        render_order = canvas_renderer._get_render_order()
        assert render_order[0].name == "L1Child"
        assert render_order[1].name == "L2Child"

    def test_empty_model_returns_empty_render_order(self, canvas_renderer, canvas_model):
        """Empty model should return empty render order."""
        render_order = canvas_renderer._get_render_order()
        assert render_order == []

    def test_only_layers_returns_empty_render_order(self, canvas_renderer, canvas_model):
        """Model with only layers should return empty render order."""
        canvas_model.addLayer()
        canvas_model.addLayer()
        
        render_order = canvas_renderer._get_render_order()
        assert render_order == []

