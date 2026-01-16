# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""
Transform class for Lucent canvas items.

This module provides non-destructive 2D transforms that can be applied
to geometry without modifying the original geometry data.
"""

from typing import Dict, Any

from PySide6.QtGui import QTransform, QMatrix4x4


class Transform:
    """Non-destructive 2D transform.

    Transforms are applied in this order: translate, rotate, scale.
    """

    def __init__(
        self,
        translate_x: float = 0,
        translate_y: float = 0,
        rotate: float = 0,
        scale_x: float = 1,
        scale_y: float = 1,
        pivot_x: float = 0,  # Absolute pivot in geometry space
        pivot_y: float = 0,  # Absolute pivot in geometry space
    ) -> None:
        self.translate_x = float(translate_x)
        self.translate_y = float(translate_y)
        self.rotate = float(rotate)  # degrees
        self.scale_x = float(scale_x)
        self.scale_y = float(scale_y)
        self.pivot_x = float(pivot_x)
        self.pivot_y = float(pivot_y)

    def is_identity(self) -> bool:
        """Check if this transform is the identity transform."""
        return (
            self.translate_x == 0
            and self.translate_y == 0
            and self.rotate == 0
            and self.scale_x == 1
            and self.scale_y == 1
        )

    def to_qtransform(self) -> QTransform:
        """Convert to Qt transform matrix.

        Order of operations: translate, then rotate, then scale.
        """
        t = QTransform()
        t.translate(self.translate_x, self.translate_y)
        t.rotate(self.rotate)
        t.scale(self.scale_x, self.scale_y)
        return t

    def to_qtransform_centered(self, center_x: float, center_y: float) -> QTransform:
        """Convert to Qt transform with rotation/scale around a center point.

        Order of operations:
        1. Translate by translate_x/translate_y
        2. Move origin to center
        3. Apply rotation
        4. Apply scale
        5. Move origin back from center

        Args:
            center_x: X coordinate of the center point for rotation/scale.
            center_y: Y coordinate of the center point for rotation/scale.

        Returns:
            QTransform matrix with transforms applied around center.
        """
        if self.is_identity():
            return QTransform()

        t = QTransform()
        # Apply translation
        t.translate(self.translate_x, self.translate_y)
        # Move to center
        t.translate(center_x, center_y)
        # Apply rotation and scale around center
        t.rotate(self.rotate)
        t.scale(self.scale_x, self.scale_y)
        # Move back from center
        t.translate(-center_x, -center_y)
        return t

    def to_qmatrix4x4(self) -> QMatrix4x4:
        """Convert to 4x4 matrix for GPU rendering (QSGTransformNode).

        Order of operations: translate, then rotate, then scale.
        """
        m = QMatrix4x4()
        m.translate(self.translate_x, self.translate_y, 0)
        m.rotate(self.rotate, 0, 0, 1)  # Rotate around Z axis
        m.scale(self.scale_x, self.scale_y, 1)
        return m

    def to_qmatrix4x4_centered(self, center_x: float, center_y: float) -> QMatrix4x4:
        """Convert to 4x4 matrix with rotation/scale around a center point.

        For use with QSGTransformNode in scene graph rendering.

        Args:
            center_x: X coordinate of the center point for rotation/scale.
            center_y: Y coordinate of the center point for rotation/scale.

        Returns:
            QMatrix4x4 with transforms applied around center.
        """
        if self.is_identity():
            return QMatrix4x4()

        m = QMatrix4x4()
        # Apply translation
        m.translate(self.translate_x, self.translate_y, 0)
        # Move to center
        m.translate(center_x, center_y, 0)
        # Apply rotation around Z axis
        m.rotate(self.rotate, 0, 0, 1)
        # Apply scale
        m.scale(self.scale_x, self.scale_y, 1)
        # Move back from center
        m.translate(-center_x, -center_y, 0)
        return m

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dictionary."""
        return {
            "translateX": self.translate_x,
            "translateY": self.translate_y,
            "rotate": self.rotate,
            "scaleX": self.scale_x,
            "scaleY": self.scale_y,
            "pivotX": self.pivot_x,
            "pivotY": self.pivot_y,
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "Transform":
        """Deserialize from dictionary."""
        return Transform(
            translate_x=float(data.get("translateX", 0)),
            translate_y=float(data.get("translateY", 0)),
            rotate=float(data.get("rotate", 0)),
            scale_x=float(data.get("scaleX", 1)),
            scale_y=float(data.get("scaleY", 1)),
            pivot_x=float(data.get("pivotX", 0)),
            pivot_y=float(data.get("pivotY", 0)),
        )


def calculate_scale_for_resize(
    current_scale: float,
    geometry_size: float,
    delta: float,
    from_min_edge: bool,
) -> float:
    """Calculate new scale factor for a resize operation.

    This helper computes the new scale when dragging a resize handle,
    taking into account the current scale and which edge is being dragged.

    Args:
        current_scale: Current scale factor (scaleX or scaleY).
        geometry_size: Original geometry dimension (width or height).
        delta: Mouse movement delta in local (unrotated) coordinates.
        from_min_edge: True if resizing from left/top edge (min edge),
            False if resizing from right/bottom edge (max edge).

    Returns:
        New scale factor, clamped to prevent zero or negative sizes.
    """
    # Handle degenerate case of zero geometry size
    if geometry_size <= 0:
        return current_scale

    # Calculate current displayed size
    displayed_size = geometry_size * current_scale

    # Apply delta based on which edge is being dragged
    if from_min_edge:
        # Dragging min edge: positive delta shrinks, negative delta grows
        new_displayed_size = displayed_size - delta
    else:
        # Dragging max edge: positive delta grows, negative delta shrinks
        new_displayed_size = displayed_size + delta

    # Clamp to minimum displayed size (1 pixel)
    min_displayed = 1.0
    new_displayed_size = max(min_displayed, new_displayed_size)

    # Convert back to scale factor
    return new_displayed_size / geometry_size
