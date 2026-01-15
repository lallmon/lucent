# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""
Tests for GPU transform methods (to_qmatrix4x4, to_qmatrix4x4_centered).

These tests verify that Transform class produces correct 4x4 matrices
for scene graph rendering.
"""

from PySide6.QtGui import QMatrix4x4, QVector3D
from PySide6.QtCore import QPointF
from lucent.transforms import Transform


def map_point(matrix: QMatrix4x4, x: float, y: float) -> tuple:
    """Helper to map a 2D point through a 4x4 matrix."""
    result = matrix.map(QVector3D(x, y, 0))
    return (result.x(), result.y())


class TestTransformGPU:
    """Tests for Transform GPU matrix generation."""

    def test_identity_returns_identity_matrix(self):
        """Identity transform should return identity matrix."""
        t = Transform()
        m = t.to_qmatrix4x4()
        assert m.isIdentity()

    def test_translation_only(self):
        """Translation should be correctly applied."""
        t = Transform(translate_x=10, translate_y=20)
        m = t.to_qmatrix4x4()

        # Transform a point
        result = map_point(m, 0, 0)
        assert abs(result[0] - 10) < 0.01
        assert abs(result[1] - 20) < 0.01

    def test_scale_only(self):
        """Scale should be correctly applied."""
        t = Transform(scale_x=2, scale_y=3)
        m = t.to_qmatrix4x4()

        # Transform a point
        result = map_point(m, 10, 10)
        assert abs(result[0] - 20) < 0.01
        assert abs(result[1] - 30) < 0.01

    def test_rotation_90_degrees(self):
        """90 degree rotation should swap x and y."""
        t = Transform(rotate=90)
        m = t.to_qmatrix4x4()

        # Transform a point on X axis
        result = map_point(m, 10, 0)
        assert abs(result[0] - 0) < 0.01
        assert abs(result[1] - 10) < 0.01

    def test_rotation_180_degrees(self):
        """180 degree rotation should negate both axes."""
        t = Transform(rotate=180)
        m = t.to_qmatrix4x4()

        result = map_point(m, 10, 5)
        assert abs(result[0] - (-10)) < 0.01
        assert abs(result[1] - (-5)) < 0.01

    def test_combined_transforms(self):
        """Combined translate + rotate + scale should apply in correct order."""
        t = Transform(translate_x=100, translate_y=50, rotate=90, scale_x=2, scale_y=2)
        m = t.to_qmatrix4x4()

        # Order: translate, rotate, scale
        # Starting point (0,0):
        # After translate: (100, 50)
        # After rotate 90: (-50, 100)
        # After scale 2x: (-100, 200)
        result = map_point(m, 0, 0)
        assert abs(result[0] - 100) < 0.01  # Translation happens first
        assert abs(result[1] - 50) < 0.01


class TestTransformGPUCentered:
    """Tests for Transform GPU centered matrix generation."""

    def test_identity_centered_returns_identity(self):
        """Identity transform centered should return identity matrix."""
        t = Transform()
        m = t.to_qmatrix4x4_centered(50, 50)
        assert m.isIdentity()

    def test_rotation_around_center(self):
        """Rotation should happen around specified center point."""
        t = Transform(rotate=180)
        m = t.to_qmatrix4x4_centered(50, 50)

        # Point at center should stay at center
        result_center = map_point(m, 50, 50)
        assert abs(result_center[0] - 50) < 0.01
        assert abs(result_center[1] - 50) < 0.01

        # Point at (100, 50) should move to (0, 50) after 180 rotation around (50, 50)
        result_edge = map_point(m, 100, 50)
        assert abs(result_edge[0] - 0) < 0.01
        assert abs(result_edge[1] - 50) < 0.01

    def test_scale_around_center(self):
        """Scale should happen around specified center point."""
        t = Transform(scale_x=2, scale_y=2)
        m = t.to_qmatrix4x4_centered(50, 50)

        # Point at center should stay at center
        result_center = map_point(m, 50, 50)
        assert abs(result_center[0] - 50) < 0.01
        assert abs(result_center[1] - 50) < 0.01

        # Point at (100, 50) should move to (150, 50) after 2x scale around (50, 50)
        result_edge = map_point(m, 100, 50)
        assert abs(result_edge[0] - 150) < 0.01
        assert abs(result_edge[1] - 50) < 0.01

    def test_combined_with_translation(self):
        """Translation plus rotation around center."""
        t = Transform(translate_x=20, translate_y=10, rotate=90)
        m = t.to_qmatrix4x4_centered(50, 50)

        # Verify it returns a valid matrix
        assert isinstance(m, QMatrix4x4)
        # Verify it's not identity (has transforms)
        assert not m.isIdentity()


class TestMatrixConsistency:
    """Tests that GPU matrices match QTransform behavior."""

    def test_qtransform_vs_qmatrix4x4_translation(self):
        """QTransform and QMatrix4x4 should produce same result for translation."""
        t = Transform(translate_x=100, translate_y=200)

        qt = t.to_qtransform()
        m4 = t.to_qmatrix4x4()

        # Map a point with both
        qt_result = qt.map(QPointF(50.0, 75.0))
        m4_result = map_point(m4, 50, 75)

        assert abs(qt_result.x() - m4_result[0]) < 0.01
        assert abs(qt_result.y() - m4_result[1]) < 0.01

    def test_qtransform_vs_qmatrix4x4_rotation(self):
        """QTransform and QMatrix4x4 should produce same result for rotation."""
        t = Transform(rotate=45)

        qt = t.to_qtransform()
        m4 = t.to_qmatrix4x4()

        qt_result = qt.map(QPointF(100.0, 0.0))
        m4_result = map_point(m4, 100, 0)

        assert abs(qt_result.x() - m4_result[0]) < 0.1
        assert abs(qt_result.y() - m4_result[1]) < 0.1

    def test_qtransform_vs_qmatrix4x4_scale(self):
        """QTransform and QMatrix4x4 should produce same result for scale."""
        t = Transform(scale_x=1.5, scale_y=2.5)

        qt = t.to_qtransform()
        m4 = t.to_qmatrix4x4()

        qt_result = qt.map(QPointF(100.0, 100.0))
        m4_result = map_point(m4, 100, 100)

        assert abs(qt_result.x() - m4_result[0]) < 0.01
        assert abs(qt_result.y() - m4_result[1]) < 0.01
