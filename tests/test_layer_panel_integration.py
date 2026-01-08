"""Integration tests for LayerPanel-related model behaviors.

These tests verify the Python-QML contract that LayerPanel.qml depends on.
By testing the model methods LayerPanel calls, we ensure refactoring
the QML won't break functionality as long as these contracts hold.
"""

from pathlib import Path

import pytest
from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlComponent

from lucent.canvas_model import CanvasModel


class TestLayerPanelModelBehaviors:
    """Tests for model behaviors that LayerPanel.qml relies on."""

    @pytest.fixture
    def model(self, qapp):
        return CanvasModel()

    def test_add_layer_creates_layer_item(self, model):
        """LayerPanel calls canvasModel.addLayer() on button tap."""
        model.addLayer()

        assert model.count() == 1
        data = model.getItemData(0)
        assert data is not None
        assert data["type"] == "layer"
        assert "Layer" in data["name"]

    def test_add_group_creates_group_item(self, model):
        """LayerPanel calls canvasModel.addItem({type: 'group'})."""
        model.addItem({"type": "group"})

        assert model.count() == 1
        data = model.getItemData(0)
        assert data is not None
        assert data["type"] == "group"

    def test_toggle_visibility_flips_state(self, model):
        """LayerPanel calls canvasModel.toggleVisibility(index)."""
        model.addLayer()
        data = model.getItemData(0)
        assert data is not None
        assert data["visible"] is True

        model.toggleVisibility(0)
        data = model.getItemData(0)
        assert data is not None
        assert data["visible"] is False

        model.toggleVisibility(0)
        data = model.getItemData(0)
        assert data is not None
        assert data["visible"] is True

    def test_toggle_locked_flips_state(self, model):
        """LayerPanel calls canvasModel.toggleLocked(index)."""
        model.addLayer()
        data = model.getItemData(0)
        assert data is not None
        assert data["locked"] is False

        model.toggleLocked(0)
        data = model.getItemData(0)
        assert data is not None
        assert data["locked"] is True

    def test_rename_item_updates_name(self, model):
        """LayerPanel calls canvasModel.renameItem(index, name)."""
        model.addLayer()
        model.renameItem(0, "My Custom Layer")

        data = model.getItemData(0)
        assert data is not None
        assert data["name"] == "My Custom Layer"

    def test_move_item_reorders(self, model):
        """LayerPanel drag-drop calls canvasModel.moveItem(from, to)."""
        model.addItem({"type": "rectangle", "name": "A"})
        model.addItem({"type": "rectangle", "name": "B"})
        model.addItem({"type": "rectangle", "name": "C"})

        model.moveItem(0, 2)

        data_0 = model.getItemData(0)
        data_2 = model.getItemData(2)
        assert data_0 is not None
        assert data_2 is not None
        assert data_0["name"] == "B"
        assert data_2["name"] == "A"

    def test_group_items_creates_group(self, model):
        """LayerPanel group button calls canvasModel.groupItems(indices)."""
        model.addItem({"type": "rectangle"})
        model.addItem({"type": "ellipse"})

        group_idx = model.groupItems([0, 1])

        assert group_idx >= 0
        group_data = model.getItemData(group_idx)
        assert group_data is not None
        assert group_data["type"] == "group"

    def test_reparent_item_changes_parent(self, model):
        """LayerPanel drag-into-group calls canvasModel.reparentItem()."""
        model.addLayer()
        layer_data = model.getItemData(0)
        assert layer_data is not None
        layer_id = layer_data["id"]

        model.addItem({"type": "rectangle"})

        # reparentItem sets parent and moves item; find rectangle after reparent
        model.reparentItem(1, layer_id)

        # Find the rectangle after reparenting (indices may have shifted)
        rect_data = None
        for i in range(model.count()):
            data = model.getItemData(i)
            if data and data["type"] == "rectangle":
                rect_data = data
                break

        assert rect_data is not None, "Rectangle not found after reparent"
        assert rect_data["parentId"] == layer_id

    def test_remove_item_decreases_count(self, model):
        """LayerPanel delete calls canvasModel.removeItem(index)."""
        model.addLayer()
        model.addItem({"type": "rectangle"})
        assert model.count() == 2

        model.removeItem(1)
        assert model.count() == 1

    def test_model_roles_match_qml_expectations(self, model):
        """Verify model exposes roles that LayerPanel.qml binds to."""
        model.addLayer()
        model.addItem({"type": "rectangle", "parent_id": ""})

        # Check role names exist (LayerPanel binds to these)
        role_names = model.roleNames()
        expected_roles = [
            b"name",
            b"itemType",
            b"itemIndex",
            b"itemId",
            b"parentId",
            b"modelVisible",
            b"modelLocked",
        ]
        for role in expected_roles:
            assert role in role_names.values(), f"Missing role: {role}"


class TestLayerPanelQmlLoads:
    """Smoke test: verify LayerPanel.qml compiles without errors."""

    def test_layer_panel_loads(self, qml_engine, canvas_model):
        """Verify LayerPanel.qml compiles and instantiates."""
        # Register model as context property (same as main.py)
        qml_engine.rootContext().setContextProperty("canvasModel", canvas_model)

        # Add components import path
        components_dir = Path(__file__).parent.parent / "components"
        qml_engine.addImportPath(str(components_dir))

        # Load LayerPanel
        qml_file = components_dir / "panels" / "LayerPanel.qml"
        component = QQmlComponent(qml_engine, QUrl.fromLocalFile(str(qml_file)))

        if component.isError():
            errors = "\n".join(e.toString() for e in component.errors())
            pytest.fail(f"LayerPanel.qml failed to load:\n{errors}")

        obj = component.create()
        assert obj is not None, "Failed to instantiate LayerPanel"

        obj.deleteLater()
