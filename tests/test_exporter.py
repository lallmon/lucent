"""Unit tests for exporter module."""

from pathlib import Path
from PySide6.QtCore import QRectF
from PySide6.QtGui import QImage
import xml.etree.ElementTree as ET

from lucent.canvas_items import (
    RectangleItem,
    EllipseItem,
    PathItem,
    TextItem,
    LayerItem,
)
from lucent.exporter import ExportOptions, export_png, export_svg, compute_bounds


class TestExportOptions:
    """Tests for ExportOptions dataclass."""

    def test_default_values(self):
        """ExportOptions has sensible defaults."""
        opts = ExportOptions()
        assert opts.scale == 1.0
        assert opts.padding == 0.0
        assert opts.background is None

    def test_custom_values(self):
        """ExportOptions accepts custom values."""
        opts = ExportOptions(scale=2.0, padding=10.0, background="#ffffff")
        assert opts.scale == 2.0
        assert opts.padding == 10.0
        assert opts.background == "#ffffff"


class TestComputeBounds:
    """Tests for compute_bounds helper function."""

    def test_single_item(self):
        """compute_bounds returns bounds of single item."""
        items = [RectangleItem(x=10, y=20, width=100, height=50)]
        bounds = compute_bounds(items, padding=0)
        assert bounds == QRectF(10, 20, 100, 50)

    def test_multiple_items(self):
        """compute_bounds returns combined bounds of all items."""
        items = [
            RectangleItem(x=0, y=0, width=50, height=50),
            RectangleItem(x=100, y=100, width=50, height=50),
        ]
        bounds = compute_bounds(items, padding=0)
        assert bounds == QRectF(0, 0, 150, 150)

    def test_with_padding(self):
        """compute_bounds adds padding to all sides."""
        items = [RectangleItem(x=10, y=10, width=80, height=80)]
        bounds = compute_bounds(items, padding=10)
        assert bounds == QRectF(0, 0, 100, 100)

    def test_empty_items(self):
        """compute_bounds returns empty rect for no items."""
        bounds = compute_bounds([], padding=0)
        assert bounds.isEmpty()

    def test_items_with_empty_bounds(self):
        """compute_bounds returns empty rect when all items have empty bounds."""
        items = [LayerItem(name="Empty Layer")]
        bounds = compute_bounds(items, padding=0)
        assert bounds.isEmpty()


class TestExportPng:
    """Tests for PNG export functionality."""

    def test_export_creates_file(self, tmp_path, qtbot):
        """export_png creates a PNG file at the specified path."""
        items = [RectangleItem(x=0, y=0, width=100, height=100)]
        bounds = QRectF(0, 0, 100, 100)
        output_path = tmp_path / "test.png"

        result = export_png(items, bounds, output_path, ExportOptions())

        assert result is True
        assert output_path.exists()

    def test_export_correct_dimensions(self, tmp_path, qtbot):
        """export_png creates image with correct dimensions."""
        items = [RectangleItem(x=0, y=0, width=100, height=50)]
        bounds = QRectF(0, 0, 100, 50)
        output_path = tmp_path / "test.png"

        export_png(items, bounds, output_path, ExportOptions())

        img = QImage(str(output_path))
        assert img.width() == 100
        assert img.height() == 50

    def test_export_with_scale(self, tmp_path, qtbot):
        """export_png scales output by scale factor."""
        items = [RectangleItem(x=0, y=0, width=100, height=50)]
        bounds = QRectF(0, 0, 100, 50)
        output_path = tmp_path / "test.png"

        export_png(items, bounds, output_path, ExportOptions(scale=2.0))

        img = QImage(str(output_path))
        assert img.width() == 200
        assert img.height() == 100

    def test_export_transparent_background(self, tmp_path, qtbot):
        """export_png with no background creates transparent image."""
        items = [RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF(0, 0, 50, 50)
        output_path = tmp_path / "test.png"

        export_png(items, bounds, output_path, ExportOptions(background=None))

        img = QImage(str(output_path))
        assert img.hasAlphaChannel()

    def test_export_with_background_color(self, tmp_path, qtbot):
        """export_png with background fills with that color."""
        items = [RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF(0, 0, 50, 50)
        output_path = tmp_path / "test.png"

        export_png(items, bounds, output_path, ExportOptions(background="#ff0000"))

        img = QImage(str(output_path))
        # Check a corner pixel for the background color
        assert img.pixelColor(0, 0).red() == 255

    def test_export_returns_false_on_invalid_path(self, qtbot):
        """export_png returns False when path is invalid."""
        items = [RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF(0, 0, 50, 50)
        invalid_path = Path("/nonexistent/directory/file.png")

        result = export_png(items, bounds, invalid_path, ExportOptions())

        assert result is False

    def test_export_empty_bounds_returns_false(self, qtbot):
        """export_png returns False when bounds are empty."""
        items = [RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF()

        result = export_png(items, bounds, Path("/tmp/test.png"), ExportOptions())

        assert result is False

    def test_export_zero_dimension_returns_false(self, qtbot):
        """export_png returns False when scaled dimensions are zero."""
        items = [RectangleItem(x=0, y=0, width=1, height=1)]
        bounds = QRectF(0, 0, 0.5, 0.5)

        result = export_png(items, bounds, Path("/tmp/test.png"), ExportOptions())

        assert result is False


class TestExportSvg:
    """Tests for SVG export functionality."""

    def test_export_creates_file(self, tmp_path):
        """export_svg creates an SVG file at the specified path."""
        items = [RectangleItem(x=0, y=0, width=100, height=100)]
        bounds = QRectF(0, 0, 100, 100)
        output_path = tmp_path / "test.svg"

        result = export_svg(items, bounds, output_path, ExportOptions())

        assert result is True
        assert output_path.exists()

    def test_export_valid_xml(self, tmp_path):
        """export_svg creates valid XML."""
        items = [RectangleItem(x=0, y=0, width=100, height=50)]
        bounds = QRectF(0, 0, 100, 50)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions())

        # Should parse without error
        tree = ET.parse(output_path)
        root = tree.getroot()
        assert "svg" in root.tag

    def test_export_correct_viewbox(self, tmp_path):
        """export_svg sets correct viewBox attribute."""
        items = [RectangleItem(x=10, y=20, width=100, height=50)]
        bounds = QRectF(10, 20, 100, 50)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions())

        tree = ET.parse(output_path)
        root = tree.getroot()
        assert root.get("viewBox") == "10 20 100 50"

    def test_export_rectangle(self, tmp_path):
        """export_svg renders rectangle as rect element."""
        items = [RectangleItem(x=10, y=20, width=100, height=50, fill_opacity=1.0)]
        bounds = QRectF(10, 20, 100, 50)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions())

        content = output_path.read_text()
        assert "<rect " in content

    def test_export_ellipse(self, tmp_path):
        """export_svg renders ellipse as ellipse element."""
        items = [EllipseItem(center_x=50, center_y=50, radius_x=30, radius_y=20)]
        bounds = QRectF(20, 30, 60, 40)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions())

        content = output_path.read_text()
        assert "<ellipse " in content

    def test_export_path(self, tmp_path):
        """export_svg renders path as path element."""
        items = [PathItem(points=[{"x": 0, "y": 0}, {"x": 50, "y": 50}])]
        bounds = QRectF(0, 0, 50, 50)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions())

        content = output_path.read_text()
        assert "<path " in content

    def test_export_returns_false_on_invalid_path(self):
        """export_svg returns False when path is invalid."""
        items = [RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF(0, 0, 50, 50)
        invalid_path = Path("/nonexistent/directory/file.svg")

        result = export_svg(items, bounds, invalid_path, ExportOptions())

        assert result is False

    def test_export_empty_bounds_returns_false(self):
        """export_svg returns False when bounds are empty."""
        items = [RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF()

        result = export_svg(items, bounds, Path("/tmp/test.svg"), ExportOptions())

        assert result is False

    def test_export_text_item(self, tmp_path):
        """export_svg renders text as text element."""
        items = [TextItem(x=10, y=20, text="Hello World", font_size=16)]
        bounds = QRectF(10, 20, 100, 30)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions())

        content = output_path.read_text()
        assert "<text " in content
        assert "Hello World" in content

    def test_export_closed_path(self, tmp_path):
        """export_svg renders closed path with Z command."""
        items = [
            PathItem(
                points=[{"x": 0, "y": 0}, {"x": 50, "y": 0}, {"x": 25, "y": 50}],
                closed=True,
            )
        ]
        bounds = QRectF(0, 0, 50, 50)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions())

        content = output_path.read_text()
        assert " Z" in content

    def test_export_with_background(self, tmp_path):
        """export_svg adds background rect when background is specified."""
        items = [RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF(0, 0, 50, 50)
        output_path = tmp_path / "test.svg"

        export_svg(items, bounds, output_path, ExportOptions(background="#ff0000"))

        content = output_path.read_text()
        assert 'fill="#ff0000"' in content

    def test_export_unknown_item_type_skipped(self, tmp_path):
        """export_svg skips unknown item types gracefully."""
        items = [LayerItem(name="Layer"), RectangleItem(x=0, y=0, width=50, height=50)]
        bounds = QRectF(0, 0, 50, 50)
        output_path = tmp_path / "test.svg"

        result = export_svg(items, bounds, output_path, ExportOptions())

        assert result is True
        content = output_path.read_text()
        assert "<rect " in content
