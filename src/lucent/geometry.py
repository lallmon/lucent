# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""
Geometry classes for Lucent canvas items.

This module provides geometry classes that define shapes independently
of their visual appearance (fill, stroke, etc.).
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, List

from PySide6.QtCore import QRectF, QPointF
from PySide6.QtGui import QPainterPath


class Geometry(ABC):
    """Abstract base class for all geometry types."""

    @abstractmethod
    def to_painter_path(self) -> QPainterPath:
        """Convert geometry to QPainterPath for rendering."""
        pass

    @abstractmethod
    def get_bounds(self) -> QRectF:
        """Return axis-aligned bounding box."""
        pass

    @abstractmethod
    def to_dict(self) -> Dict[str, Any]:
        """Serialize geometry to dictionary."""
        pass

    @staticmethod
    @abstractmethod
    def from_dict(data: Dict[str, Any]) -> "Geometry":
        """Deserialize geometry from dictionary."""
        pass


class RectGeometry(Geometry):
    """Rectangle geometry defined by position and dimensions."""

    def __init__(self, x: float, y: float, width: float, height: float) -> None:
        self.x = float(x)
        self.y = float(y)
        self.width = max(0.0, float(width))
        self.height = max(0.0, float(height))

    def to_painter_path(self) -> QPainterPath:
        """Convert to QPainterPath."""
        path = QPainterPath()
        path.addRect(self.x, self.y, self.width, self.height)
        return path

    def get_bounds(self) -> QRectF:
        """Return bounding rectangle."""
        return QRectF(self.x, self.y, self.width, self.height)

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dictionary."""
        return {
            "x": self.x,
            "y": self.y,
            "width": self.width,
            "height": self.height,
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "RectGeometry":
        """Deserialize from dictionary."""
        return RectGeometry(
            x=float(data.get("x", 0)),
            y=float(data.get("y", 0)),
            width=float(data.get("width", 0)),
            height=float(data.get("height", 0)),
        )


class EllipseGeometry(Geometry):
    """Ellipse geometry defined by center and radii."""

    def __init__(
        self,
        center_x: float,
        center_y: float,
        radius_x: float,
        radius_y: float,
    ) -> None:
        self.center_x = float(center_x)
        self.center_y = float(center_y)
        self.radius_x = max(0.0, float(radius_x))
        self.radius_y = max(0.0, float(radius_y))

    def to_painter_path(self) -> QPainterPath:
        """Convert to QPainterPath."""
        path = QPainterPath()
        path.addEllipse(
            QPointF(self.center_x, self.center_y),
            self.radius_x,
            self.radius_y,
        )
        return path

    def get_bounds(self) -> QRectF:
        """Return bounding rectangle."""
        return QRectF(
            self.center_x - self.radius_x,
            self.center_y - self.radius_y,
            2 * self.radius_x,
            2 * self.radius_y,
        )

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dictionary."""
        return {
            "centerX": self.center_x,
            "centerY": self.center_y,
            "radiusX": self.radius_x,
            "radiusY": self.radius_y,
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "EllipseGeometry":
        """Deserialize from dictionary."""
        return EllipseGeometry(
            center_x=float(data.get("centerX", 0)),
            center_y=float(data.get("centerY", 0)),
            radius_x=float(data.get("radiusX", 0)),
            radius_y=float(data.get("radiusY", 0)),
        )


class PathGeometry(Geometry):
    """Path geometry with bezier curve support.

    Each point can optionally have handleIn and handleOut control points
    for cubic bezier curves. Points without handles render as straight lines.
    """

    def __init__(self, points: List[Dict[str, Any]], closed: bool = False) -> None:
        if len(points) < 2:
            raise ValueError("PathGeometry requires at least two points")

        self.points: List[Dict[str, Any]] = []
        for p in points:
            normalized: Dict[str, Any] = {
                "x": float(p.get("x", 0)),
                "y": float(p.get("y", 0)),
            }
            if p.get("handleIn") is not None:
                h = p["handleIn"]
                normalized["handleIn"] = {
                    "x": float(h.get("x", 0)),
                    "y": float(h.get("y", 0)),
                }
            if p.get("handleOut") is not None:
                h = p["handleOut"]
                normalized["handleOut"] = {
                    "x": float(h.get("x", 0)),
                    "y": float(h.get("y", 0)),
                }
            self.points.append(normalized)

        self.closed = bool(closed)

    def _has_handles(
        self, prev_point: Dict[str, Any], curr_point: Dict[str, Any]
    ) -> bool:
        """Check if a segment between two points should use bezier curve."""
        return (
            prev_point.get("handleOut") is not None
            or curr_point.get("handleIn") is not None
        )

    def _get_control_points(
        self, prev_point: Dict[str, Any], curr_point: Dict[str, Any]
    ) -> tuple[float, float, float, float]:
        """Get control points for cubic bezier between two points.

        Returns (cp1_x, cp1_y, cp2_x, cp2_y) where:
        - cp1 is the outgoing handle from prev_point (or prev anchor if none)
        - cp2 is the incoming handle to curr_point (or curr anchor if none)
        """
        if prev_point.get("handleOut"):
            cp1_x = prev_point["handleOut"]["x"]
            cp1_y = prev_point["handleOut"]["y"]
        else:
            cp1_x = prev_point["x"]
            cp1_y = prev_point["y"]

        if curr_point.get("handleIn"):
            cp2_x = curr_point["handleIn"]["x"]
            cp2_y = curr_point["handleIn"]["y"]
        else:
            cp2_x = curr_point["x"]
            cp2_y = curr_point["y"]

        return (cp1_x, cp1_y, cp2_x, cp2_y)

    def to_painter_path(self) -> QPainterPath:
        """Convert to QPainterPath using cubicTo for segments with handles."""
        if not self.points:
            return QPainterPath()

        first = self.points[0]
        path = QPainterPath(QPointF(first["x"], first["y"]))

        for i in range(1, len(self.points)):
            prev = self.points[i - 1]
            curr = self.points[i]

            if self._has_handles(prev, curr):
                cp1_x, cp1_y, cp2_x, cp2_y = self._get_control_points(prev, curr)
                path.cubicTo(cp1_x, cp1_y, cp2_x, cp2_y, curr["x"], curr["y"])
            else:
                path.lineTo(curr["x"], curr["y"])

        if self.closed and len(self.points) >= 2:
            last = self.points[-1]
            first = self.points[0]

            if self._has_handles(last, first):
                cp1_x, cp1_y, cp2_x, cp2_y = self._get_control_points(last, first)
                path.cubicTo(cp1_x, cp1_y, cp2_x, cp2_y, first["x"], first["y"])
            path.closeSubpath()

        return path

    def get_bounds(self) -> QRectF:
        """Return bounding rectangle using QPainterPath for accurate bezier bounds."""
        if not self.points:
            return QRectF()

        # Use QPainterPath.boundingRect() for accurate bounds including curves
        path = self.to_painter_path()
        return path.boundingRect()

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dictionary, including handle data."""
        return {
            "points": self.points,
            "closed": self.closed,
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "PathGeometry":
        """Deserialize from dictionary."""
        points = data.get("points")
        if not isinstance(points, list):
            raise ValueError("PathGeometry points must be a list")
        if len(points) < 2:
            raise ValueError("PathGeometry requires at least two points")

        return PathGeometry(
            points=points,
            closed=bool(data.get("closed", False)),
        )


# Alias for backward compatibility during transition
PolylineGeometry = PathGeometry


class TextGeometry(Geometry):
    """Text geometry defined by position and dimensions."""

    def __init__(self, x: float, y: float, width: float, height: float) -> None:
        self.x = float(x)
        self.y = float(y)
        self.width = max(1.0, float(width))  # Minimum width of 1
        self.height = max(0.0, float(height))

    def to_painter_path(self) -> QPainterPath:
        """Convert to QPainterPath (rectangle representing text bounds)."""
        path = QPainterPath()
        path.addRect(self.x, self.y, self.width, self.height)
        return path

    def get_bounds(self) -> QRectF:
        """Return bounding rectangle."""
        return QRectF(self.x, self.y, self.width, self.height)

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to dictionary."""
        return {
            "x": self.x,
            "y": self.y,
            "width": self.width,
            "height": self.height,
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "TextGeometry":
        """Deserialize from dictionary."""
        return TextGeometry(
            x=float(data.get("x", 0)),
            y=float(data.get("y", 0)),
            width=float(data.get("width", 1)),  # Default minimum width
            height=float(data.get("height", 0)),
        )
