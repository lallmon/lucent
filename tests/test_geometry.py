# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""Unit tests for geometry module."""

import pytest
from PySide6.QtCore import QRectF
from PySide6.QtGui import QPainterPath

from lucent.geometry import (
    Geometry,
    RectGeometry,
    EllipseGeometry,
    TextGeometry,
)


class TestRectGeometry:
    """Tests for RectGeometry class."""

    def test_basic_creation(self):
        """Test creating a basic rectangle geometry."""
        rect = RectGeometry(x=10, y=20, width=100, height=50)
        assert rect.x == 10
        assert rect.y == 20
        assert rect.width == 100
        assert rect.height == 50

    def test_negative_width_clamped_to_zero(self):
        """Test that negative width is clamped to 0."""
        rect = RectGeometry(x=0, y=0, width=-10, height=20)
        assert rect.width == 0.0

    def test_negative_height_clamped_to_zero(self):
        """Test that negative height is clamped to 0."""
        rect = RectGeometry(x=0, y=0, width=20, height=-15)
        assert rect.height == 0.0

    def test_get_bounds(self):
        """Test get_bounds returns correct bounding rectangle."""
        rect = RectGeometry(x=10, y=20, width=100, height=50)
        bounds = rect.get_bounds()
        assert bounds == QRectF(10, 20, 100, 50)

    def test_get_bounds_at_origin(self):
        """Test get_bounds at origin."""
        rect = RectGeometry(x=0, y=0, width=50, height=30)
        bounds = rect.get_bounds()
        assert bounds == QRectF(0, 0, 50, 30)

    def test_get_bounds_negative_position(self):
        """Test get_bounds with negative position."""
        rect = RectGeometry(x=-50, y=-25, width=100, height=50)
        bounds = rect.get_bounds()
        assert bounds == QRectF(-50, -25, 100, 50)

    def test_to_painter_path(self):
        """Test to_painter_path creates correct path."""
        rect = RectGeometry(x=10, y=20, width=100, height=50)
        path = rect.to_painter_path()
        assert isinstance(path, QPainterPath)
        assert path.boundingRect() == QRectF(10, 20, 100, 50)

    def test_to_painter_path_zero_size(self):
        """Test to_painter_path with zero dimensions."""
        rect = RectGeometry(x=10, y=20, width=0, height=0)
        path = rect.to_painter_path()
        assert isinstance(path, QPainterPath)

    def test_to_dict(self):
        """Test serialization to dictionary."""
        rect = RectGeometry(x=10, y=20, width=100, height=50)
        data = rect.to_dict()
        assert data == {"x": 10, "y": 20, "width": 100, "height": 50}

    def test_from_dict(self):
        """Test deserialization from dictionary."""
        data = {"x": 15, "y": 25, "width": 80, "height": 60}
        rect = RectGeometry.from_dict(data)
        assert rect.x == 15
        assert rect.y == 25
        assert rect.width == 80
        assert rect.height == 60

    def test_from_dict_missing_fields_use_defaults(self):
        """Test from_dict uses defaults for missing fields."""
        data = {}
        rect = RectGeometry.from_dict(data)
        assert rect.x == 0
        assert rect.y == 0
        assert rect.width == 0
        assert rect.height == 0

    def test_from_dict_clamps_negative_dimensions(self):
        """Test from_dict clamps negative dimensions."""
        data = {"x": 0, "y": 0, "width": -20, "height": -30}
        rect = RectGeometry.from_dict(data)
        assert rect.width == 0.0
        assert rect.height == 0.0

    def test_round_trip(self):
        """Test serialization round-trip."""
        original = RectGeometry(x=10, y=20, width=100, height=50)
        data = original.to_dict()
        restored = RectGeometry.from_dict(data)
        assert restored.x == original.x
        assert restored.y == original.y
        assert restored.width == original.width
        assert restored.height == original.height


class TestEllipseGeometry:
    """Tests for EllipseGeometry class."""

    def test_basic_creation(self):
        """Test creating a basic ellipse geometry."""
        ellipse = EllipseGeometry(center_x=50, center_y=75, radius_x=30, radius_y=20)
        assert ellipse.center_x == 50
        assert ellipse.center_y == 75
        assert ellipse.radius_x == 30
        assert ellipse.radius_y == 20

    def test_negative_radius_x_clamped_to_zero(self):
        """Test that negative radius_x is clamped to 0."""
        ellipse = EllipseGeometry(center_x=0, center_y=0, radius_x=-15, radius_y=20)
        assert ellipse.radius_x == 0.0

    def test_negative_radius_y_clamped_to_zero(self):
        """Test that negative radius_y is clamped to 0."""
        ellipse = EllipseGeometry(center_x=0, center_y=0, radius_x=20, radius_y=-10)
        assert ellipse.radius_y == 0.0

    def test_get_bounds(self):
        """Test get_bounds returns correct bounding rectangle."""
        ellipse = EllipseGeometry(center_x=100, center_y=100, radius_x=50, radius_y=30)
        bounds = ellipse.get_bounds()
        assert bounds == QRectF(50, 70, 100, 60)

    def test_get_bounds_at_origin(self):
        """Test get_bounds for ellipse centered at origin."""
        ellipse = EllipseGeometry(center_x=0, center_y=0, radius_x=25, radius_y=25)
        bounds = ellipse.get_bounds()
        assert bounds == QRectF(-25, -25, 50, 50)

    def test_to_painter_path(self):
        """Test to_painter_path creates correct path."""
        ellipse = EllipseGeometry(center_x=50, center_y=50, radius_x=30, radius_y=20)
        path = ellipse.to_painter_path()
        assert isinstance(path, QPainterPath)
        bounds = path.boundingRect()
        assert abs(bounds.x() - 20) < 0.01
        assert abs(bounds.y() - 30) < 0.01
        assert abs(bounds.width() - 60) < 0.01
        assert abs(bounds.height() - 40) < 0.01

    def test_to_dict(self):
        """Test serialization to dictionary."""
        ellipse = EllipseGeometry(center_x=50, center_y=75, radius_x=30, radius_y=20)
        data = ellipse.to_dict()
        assert data == {
            "centerX": 50,
            "centerY": 75,
            "radiusX": 30,
            "radiusY": 20,
        }

    def test_from_dict(self):
        """Test deserialization from dictionary."""
        data = {"centerX": 100, "centerY": 150, "radiusX": 40, "radiusY": 30}
        ellipse = EllipseGeometry.from_dict(data)
        assert ellipse.center_x == 100
        assert ellipse.center_y == 150
        assert ellipse.radius_x == 40
        assert ellipse.radius_y == 30

    def test_from_dict_missing_fields_use_defaults(self):
        """Test from_dict uses defaults for missing fields."""
        data = {}
        ellipse = EllipseGeometry.from_dict(data)
        assert ellipse.center_x == 0
        assert ellipse.center_y == 0
        assert ellipse.radius_x == 0
        assert ellipse.radius_y == 0

    def test_from_dict_clamps_negative_radii(self):
        """Test from_dict clamps negative radii."""
        data = {"centerX": 0, "centerY": 0, "radiusX": -50, "radiusY": -40}
        ellipse = EllipseGeometry.from_dict(data)
        assert ellipse.radius_x == 0.0
        assert ellipse.radius_y == 0.0

    def test_round_trip(self):
        """Test serialization round-trip."""
        original = EllipseGeometry(center_x=50, center_y=75, radius_x=30, radius_y=20)
        data = original.to_dict()
        restored = EllipseGeometry.from_dict(data)
        assert restored.center_x == original.center_x
        assert restored.center_y == original.center_y
        assert restored.radius_x == original.radius_x
        assert restored.radius_y == original.radius_y


# TestPolylineGeometry deleted - replaced by TestPathGeometry below


class TestPathGeometry:
    """Tests for PathGeometry class with bezier curve support."""

    def test_basic_creation_corner_points(self):
        """Test creating a path with corner points (no handles)."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0},
            {"x": 100, "y": 0},
        ]
        path = PathGeometry(points=points)
        assert len(path.points) == 2
        assert path.points[0]["x"] == 0.0
        assert path.points[0]["y"] == 0.0
        assert path.closed is False

    def test_creation_with_handles(self):
        """Test creating a path with bezier handles."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0, "handleOut": {"x": 30, "y": 0}},
            {"x": 100, "y": 0, "handleIn": {"x": 70, "y": 0}},
        ]
        path = PathGeometry(points=points)
        assert path.points[0]["handleOut"] == {"x": 30.0, "y": 0.0}
        assert path.points[1]["handleIn"] == {"x": 70.0, "y": 0.0}

    def test_creation_with_closed_flag(self):
        """Test creating a closed path."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0},
            {"x": 100, "y": 0},
            {"x": 100, "y": 100},
        ]
        path = PathGeometry(points=points, closed=True)
        assert path.closed is True

    def test_requires_at_least_two_points(self):
        """Test that constructor requires at least two points."""
        from lucent.geometry import PathGeometry

        with pytest.raises(ValueError, match="at least two points"):
            PathGeometry(points=[{"x": 0, "y": 0}])

    def test_to_painter_path_without_handles_uses_line_to(self):
        """Test that segments without handles use lineTo (straight lines)."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0},
            {"x": 100, "y": 0},
            {"x": 100, "y": 100},
        ]
        path_geom = PathGeometry(points=points, closed=False)
        painter_path = path_geom.to_painter_path()

        # Path should have: moveTo + 2 lineTo = 3 elements
        assert painter_path.elementCount() == 3
        # Verify these are line elements (not curves)
        elem1 = painter_path.elementAt(1)
        elem2 = painter_path.elementAt(2)
        # QPainterPath.ElementType: LineToElement=1, CurveToElement=2
        assert elem1.type == QPainterPath.ElementType.LineToElement
        assert elem2.type == QPainterPath.ElementType.LineToElement

    def test_to_painter_path_with_handles_uses_cubic_to(self):
        """Test that segments with handles use cubicTo (bezier curves)."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0, "handleOut": {"x": 30, "y": 0}},
            {"x": 100, "y": 0, "handleIn": {"x": 70, "y": 0}},
        ]
        path_geom = PathGeometry(points=points, closed=False)
        painter_path = path_geom.to_painter_path()

        # moveTo + cubicTo (3 elements: curveTo + 2 curveToData) = 4
        assert painter_path.elementCount() == 4
        # Element 1 should be CurveTo (control point 1)
        elem1 = painter_path.elementAt(1)
        assert elem1.type == QPainterPath.ElementType.CurveToElement

    def test_to_painter_path_mixed_segments(self):
        """Test path with both curved and straight segments."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0, "handleOut": {"x": 30, "y": 0}},
            {"x": 100, "y": 0, "handleIn": {"x": 70, "y": 0}},  # Curve to here
            {"x": 200, "y": 0},  # Straight line to here (no handles)
        ]
        path_geom = PathGeometry(points=points, closed=False)
        painter_path = path_geom.to_painter_path()

        # moveTo + cubicTo (3 elems) + lineTo = 5 elements
        assert painter_path.elementCount() == 5

    def test_to_painter_path_closed_with_handles(self):
        """Test closed path uses curve for closing segment when handles present."""
        from lucent.geometry import PathGeometry

        points = [
            {
                "x": 0,
                "y": 0,
                "handleIn": {"x": -30, "y": 0},
                "handleOut": {"x": 30, "y": 0},
            },
            {
                "x": 100,
                "y": 0,
                "handleIn": {"x": 70, "y": 0},
                "handleOut": {"x": 130, "y": 0},
            },
        ]
        path_geom = PathGeometry(points=points, closed=True)
        painter_path = path_geom.to_painter_path()

        # moveTo + cubicTo(3) + cubicTo(3) = 7 (closeSubpath adds no element)
        assert painter_path.elementCount() == 7
        # Verify closing segment uses cubicTo (element 4 = CurveToElement)
        elem4 = painter_path.elementAt(4)
        assert elem4.type == QPainterPath.ElementType.CurveToElement

    def test_get_bounds(self):
        """Test get_bounds returns correct bounding rectangle."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 10, "y": 20},
            {"x": 50, "y": 10},
            {"x": 30, "y": 60},
        ]
        path = PathGeometry(points=points)
        bounds = path.get_bounds()
        assert bounds == QRectF(10, 10, 40, 50)

    def test_to_dict_includes_handles(self):
        """Test serialization includes handle data."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0, "handleOut": {"x": 30, "y": 0}},
            {
                "x": 100,
                "y": 50,
                "handleIn": {"x": 70, "y": 50},
                "handleOut": {"x": 130, "y": 50},
            },
        ]
        path = PathGeometry(points=points, closed=True)
        data = path.to_dict()

        assert data["closed"] is True
        assert data["points"][0]["handleOut"] == {"x": 30.0, "y": 0.0}
        assert data["points"][1]["handleIn"] == {"x": 70.0, "y": 50.0}
        assert data["points"][1]["handleOut"] == {"x": 130.0, "y": 50.0}

    def test_from_dict_with_handles(self):
        """Test deserialization from dictionary with handles."""
        from lucent.geometry import PathGeometry

        data = {
            "points": [
                {"x": 0, "y": 0, "handleOut": {"x": 30, "y": 0}},
                {"x": 100, "y": 0, "handleIn": {"x": 70, "y": 0}},
            ],
            "closed": False,
        }
        path = PathGeometry.from_dict(data)
        assert path.points[0]["handleOut"] == {"x": 30.0, "y": 0.0}
        assert path.points[1]["handleIn"] == {"x": 70.0, "y": 0.0}

    def test_from_dict_without_handles(self):
        """Test deserialization works for corner points (no handles)."""
        from lucent.geometry import PathGeometry

        data = {
            "points": [{"x": 0, "y": 0}, {"x": 100, "y": 100}],
            "closed": False,
        }
        path = PathGeometry.from_dict(data)
        assert path.points[0].get("handleIn") is None
        assert path.points[0].get("handleOut") is None

    def test_round_trip_with_handles(self):
        """Test serialization round-trip preserves handles."""
        from lucent.geometry import PathGeometry

        points = [
            {"x": 0, "y": 0, "handleOut": {"x": 30, "y": 10}},
            {"x": 100, "y": 50, "handleIn": {"x": 70, "y": 40}},
        ]
        original = PathGeometry(points=points, closed=True)
        data = original.to_dict()
        restored = PathGeometry.from_dict(data)

        assert restored.points[0]["handleOut"] == original.points[0]["handleOut"]
        assert restored.points[1]["handleIn"] == original.points[1]["handleIn"]
        assert restored.closed == original.closed


class TestTextGeometry:
    """Tests for TextGeometry class."""

    def test_basic_creation(self):
        """Test creating a basic text geometry."""
        text_geom = TextGeometry(x=10, y=20, width=200, height=50)
        assert text_geom.x == 10
        assert text_geom.y == 20
        assert text_geom.width == 200
        assert text_geom.height == 50

    def test_width_clamped_to_minimum(self):
        """Test that width below minimum is clamped to 1."""
        text_geom = TextGeometry(x=0, y=0, width=0, height=20)
        assert text_geom.width == 1.0

    def test_height_clamped_to_zero(self):
        """Test that negative height is clamped to 0."""
        text_geom = TextGeometry(x=0, y=0, width=100, height=-15)
        assert text_geom.height == 0.0

    def test_get_bounds(self):
        """Test get_bounds returns correct bounding rectangle."""
        text_geom = TextGeometry(x=10, y=20, width=200, height=50)
        bounds = text_geom.get_bounds()
        assert bounds == QRectF(10, 20, 200, 50)

    def test_to_painter_path(self):
        """Test to_painter_path creates correct path."""
        text_geom = TextGeometry(x=10, y=20, width=200, height=50)
        path = text_geom.to_painter_path()
        assert isinstance(path, QPainterPath)
        # Path bounding rect should match geometry bounds
        assert path.boundingRect() == QRectF(10, 20, 200, 50)

    def test_to_dict(self):
        """Test serialization to dictionary."""
        text_geom = TextGeometry(x=10, y=20, width=200, height=50)
        data = text_geom.to_dict()
        assert data == {"x": 10, "y": 20, "width": 200, "height": 50}

    def test_from_dict(self):
        """Test deserialization from dictionary."""
        data = {"x": 15, "y": 25, "width": 180, "height": 60}
        text_geom = TextGeometry.from_dict(data)
        assert text_geom.x == 15
        assert text_geom.y == 25
        assert text_geom.width == 180
        assert text_geom.height == 60

    def test_from_dict_missing_fields_use_defaults(self):
        """Test from_dict uses defaults for missing fields."""
        data = {}
        text_geom = TextGeometry.from_dict(data)
        assert text_geom.x == 0
        assert text_geom.y == 0
        assert text_geom.width == 1  # Minimum width
        assert text_geom.height == 0

    def test_round_trip(self):
        """Test serialization round-trip."""
        original = TextGeometry(x=10, y=20, width=200, height=50)
        data = original.to_dict()
        restored = TextGeometry.from_dict(data)
        assert restored.x == original.x
        assert restored.y == original.y
        assert restored.width == original.width
        assert restored.height == original.height


class TestGeometryIsAbstract:
    """Tests to verify Geometry is properly abstract."""

    def test_cannot_instantiate_geometry_directly(self):
        """Test that Geometry cannot be instantiated directly."""
        with pytest.raises(TypeError):
            Geometry()  # type: ignore
