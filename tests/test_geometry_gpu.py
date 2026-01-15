# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""
Tests for GPU geometry generation (to_fill_vertices, to_stroke_vertices).

These tests verify that geometry classes produce correct vertex data
for scene graph rendering.
"""

import math
import pytest
from lucent.geometry import (
    RectGeometry,
    EllipseGeometry,
    PathGeometry,
    TextGeometry,
)


class TestRectGeometryGPU:
    """Tests for RectGeometry GPU vertex generation."""

    def test_fill_vertices_count(self):
        """Rectangle fill should produce 4 vertices (triangle strip quad)."""
        rect = RectGeometry(x=0, y=0, width=100, height=50)
        vertices = rect.to_fill_vertices()
        assert len(vertices) == 4

    def test_fill_vertices_positions(self):
        """Rectangle fill vertices should be at correct positions."""
        rect = RectGeometry(x=10, y=20, width=100, height=50)
        vertices = rect.to_fill_vertices()

        # Triangle strip order: TL, BL, TR, BR
        assert vertices[0] == (10, 20)  # Top-left
        assert vertices[1] == (10, 70)  # Bottom-left
        assert vertices[2] == (110, 20)  # Top-right
        assert vertices[3] == (110, 70)  # Bottom-right

    def test_fill_vertices_zero_size(self):
        """Zero-size rectangle should still produce valid vertices."""
        rect = RectGeometry(x=50, y=50, width=0, height=0)
        vertices = rect.to_fill_vertices()
        assert len(vertices) == 4
        # All corners at same point
        assert all(v == (50, 50) for v in vertices)

    def test_stroke_vertices_count(self):
        """Rectangle stroke should produce 10 vertices (closed outline)."""
        rect = RectGeometry(x=0, y=0, width=100, height=50)
        vertices = rect.to_stroke_vertices(stroke_width=2.0)
        assert len(vertices) == 10  # 5 corners × 2 (inner/outer)

    def test_stroke_vertices_expands_bounds(self):
        """Stroke vertices should extend beyond geometry bounds."""
        rect = RectGeometry(x=10, y=10, width=100, height=50)
        vertices = rect.to_stroke_vertices(stroke_width=4.0)

        # Outer vertices should be at bounds - 2 (half stroke width)
        outer_x_values = [v[0] for i, v in enumerate(vertices) if i % 2 == 0]
        inner_x_values = [v[0] for i, v in enumerate(vertices) if i % 2 == 1]

        assert min(outer_x_values) == 8  # 10 - 2
        assert min(inner_x_values) == 12  # 10 + 2


class TestEllipseGeometryGPU:
    """Tests for EllipseGeometry GPU vertex generation."""

    def test_fill_vertices_has_center(self):
        """Ellipse fill should start with center point (for triangle fan)."""
        ellipse = EllipseGeometry(center_x=50, center_y=50, radius_x=30, radius_y=20)
        vertices = ellipse.to_fill_vertices()

        # First vertex is center
        assert vertices[0] == (50, 50)

    def test_fill_vertices_count_reasonable(self):
        """Ellipse fill should have 16-64+ vertices depending on size."""
        small = EllipseGeometry(center_x=0, center_y=0, radius_x=10, radius_y=10)
        large = EllipseGeometry(center_x=0, center_y=0, radius_x=200, radius_y=200)

        small_verts = small.to_fill_vertices()
        large_verts = large.to_fill_vertices()

        # At least 16 segments + center + closing point
        assert len(small_verts) >= 18
        # Larger ellipse should have more segments
        assert len(large_verts) >= len(small_verts)

    def test_fill_vertices_first_and_last_close_loop(self):
        """Ellipse fill should close the loop (last vertex ~= first)."""
        ellipse = EllipseGeometry(center_x=50, center_y=50, radius_x=30, radius_y=20)
        vertices = ellipse.to_fill_vertices()

        # vertices[1] is first edge point, vertices[-1] should be same to close
        # Use approximate comparison due to floating-point precision
        assert abs(vertices[1][0] - vertices[-1][0]) < 1e-10
        assert abs(vertices[1][1] - vertices[-1][1]) < 1e-10

    def test_fill_vertices_on_ellipse_boundary(self):
        """Edge vertices should lie on the ellipse boundary."""
        ellipse = EllipseGeometry(center_x=100, center_y=100, radius_x=50, radius_y=30)
        vertices = ellipse.to_fill_vertices()

        # Skip center (index 0), check some edge vertices
        for x, y in vertices[1:]:
            # Point should satisfy ellipse equation (within tolerance)
            normalized = ((x - 100) / 50) ** 2 + ((y - 100) / 30) ** 2
            assert abs(normalized - 1.0) < 0.01

    def test_stroke_vertices_count(self):
        """Ellipse stroke should have paired inner/outer vertices."""
        ellipse = EllipseGeometry(center_x=0, center_y=0, radius_x=50, radius_y=50)
        vertices = ellipse.to_stroke_vertices(stroke_width=2.0)

        # Should be even (pairs of inner/outer)
        assert len(vertices) % 2 == 0
        # At least 16 segments × 2 + closing
        assert len(vertices) >= 34


class TestPathGeometryGPU:
    """Tests for PathGeometry GPU vertex generation."""

    def test_simple_line_stroke(self):
        """Simple two-point path should produce stroke vertices."""
        path = PathGeometry(
            points=[{"x": 0, "y": 0}, {"x": 100, "y": 0}],
            closed=False,
        )
        vertices = path.to_stroke_vertices(stroke_width=4.0)

        # 2 points × 2 (left/right offset) = 4 vertices
        assert len(vertices) == 4

        # Horizontal line with 4px stroke: offsets should be ±2 in y
        assert vertices[0] == (0, 2)  # Start, offset up
        assert vertices[1] == (0, -2)  # Start, offset down
        assert vertices[2] == (100, 2)  # End, offset up
        assert vertices[3] == (100, -2)  # End, offset down

    def test_closed_path_fill(self):
        """Closed triangle should produce fill vertices."""
        path = PathGeometry(
            points=[
                {"x": 0, "y": 0},
                {"x": 100, "y": 0},
                {"x": 50, "y": 100},
            ],
            closed=True,
        )
        vertices = path.to_fill_vertices()

        # Should have center + 3 points + closing point
        assert len(vertices) >= 5

    def test_open_path_no_fill(self):
        """Open path should return empty fill vertices."""
        path = PathGeometry(
            points=[{"x": 0, "y": 0}, {"x": 100, "y": 0}],
            closed=False,
        )
        vertices = path.to_fill_vertices()
        assert vertices == []

    def test_bezier_flattening(self):
        """Path with bezier handles should produce more vertices than point count."""
        path = PathGeometry(
            points=[
                {"x": 0, "y": 0, "handleOut": {"x": 50, "y": 0}},
                {"x": 100, "y": 100, "handleIn": {"x": 50, "y": 100}},
            ],
            closed=False,
        )
        vertices = path.to_stroke_vertices(stroke_width=2.0)

        # Bezier curve should be tessellated into multiple segments
        # More than just 2 points × 2 = 4 vertices
        assert len(vertices) > 4


class TestTextGeometryGPU:
    """Tests for TextGeometry GPU vertex generation."""

    def test_fill_vertices_like_rect(self):
        """Text fill should produce same structure as rectangle."""
        text = TextGeometry(x=10, y=20, width=100, height=30)
        vertices = text.to_fill_vertices()

        assert len(vertices) == 4
        assert vertices[0] == (10, 20)  # Top-left
        assert vertices[3] == (110, 50)  # Bottom-right

    def test_stroke_vertices_count(self):
        """Text stroke should produce outline vertices."""
        text = TextGeometry(x=0, y=0, width=100, height=50)
        vertices = text.to_stroke_vertices(stroke_width=2.0)
        assert len(vertices) == 10


class TestVertexDataValidity:
    """Cross-cutting tests for vertex data validity."""

    @pytest.mark.parametrize(
        "geometry",
        [
            RectGeometry(x=0, y=0, width=100, height=50),
            EllipseGeometry(center_x=50, center_y=50, radius_x=30, radius_y=20),
            PathGeometry(
                points=[{"x": 0, "y": 0}, {"x": 100, "y": 50}, {"x": 50, "y": 100}],
                closed=True,
            ),
            TextGeometry(x=0, y=0, width=100, height=30),
        ],
    )
    def test_fill_vertices_are_tuples(self, geometry):
        """All fill vertices should be (x, y) tuples of floats."""
        vertices = geometry.to_fill_vertices()
        for v in vertices:
            assert isinstance(v, tuple)
            assert len(v) == 2
            assert isinstance(v[0], (int, float))
            assert isinstance(v[1], (int, float))

    @pytest.mark.parametrize(
        "geometry",
        [
            RectGeometry(x=0, y=0, width=100, height=50),
            EllipseGeometry(center_x=50, center_y=50, radius_x=30, radius_y=20),
            PathGeometry(
                points=[{"x": 0, "y": 0}, {"x": 100, "y": 50}],
                closed=False,
            ),
            TextGeometry(x=0, y=0, width=100, height=30),
        ],
    )
    def test_stroke_vertices_are_tuples(self, geometry):
        """All stroke vertices should be (x, y) tuples of floats."""
        vertices = geometry.to_stroke_vertices(stroke_width=2.0)
        for v in vertices:
            assert isinstance(v, tuple)
            assert len(v) == 2
            assert isinstance(v[0], (int, float))
            assert isinstance(v[1], (int, float))

    @pytest.mark.parametrize(
        "geometry",
        [
            RectGeometry(x=0, y=0, width=100, height=50),
            EllipseGeometry(center_x=50, center_y=50, radius_x=30, radius_y=20),
            TextGeometry(x=0, y=0, width=100, height=30),
        ],
    )
    def test_no_nan_or_inf(self, geometry):
        """Vertices should not contain NaN or Inf."""
        for v in geometry.to_fill_vertices():
            assert math.isfinite(v[0]) and math.isfinite(v[1])
        for v in geometry.to_stroke_vertices():
            assert math.isfinite(v[0]) and math.isfinite(v[1])
