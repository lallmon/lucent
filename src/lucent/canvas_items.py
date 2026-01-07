"""
Canvas item classes for Lucent.

This module defines the canvas item hierarchy, including:
- CanvasItem: Abstract base class for all drawable items
- ShapeItem: Base class for items with geometry + appearances
- RectangleItem: Rectangular shapes
- EllipseItem: Elliptical shapes
- PathItem: Polyline/path shapes
- LayerItem: Organizational layers for grouping items
- GroupItem: Grouping container for shapes
- TextItem: Text rendering

All shape items use a geometry + appearances architecture for clean separation.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
import uuid
from PySide6.QtGui import (
    QPainter,
    QColor,
    QFont,
    QTextDocument,
    QTextOption,
)
from PySide6.QtCore import QRectF

from lucent.geometry import Geometry, RectGeometry, EllipseGeometry, PolylineGeometry
from lucent.appearances import Appearance, Fill, Stroke
from lucent.transforms import Transform

# Canvas coordinate system defaults.
CANVAS_OFFSET_X = 5000
CANVAS_OFFSET_Y = 5000


class CanvasItem(ABC):
    """Base class for all canvas items"""

    @abstractmethod
    def paint(
        self,
        painter: QPainter,
        zoom_level: float,
        offset_x: float = CANVAS_OFFSET_X,
        offset_y: float = CANVAS_OFFSET_Y,
    ) -> None:
        """Paint this item using the provided QPainter"""
        pass

    @abstractmethod
    def get_bounds(self) -> QRectF:
        """Return bounding rectangle in canvas coordinates."""
        pass

    @staticmethod
    @abstractmethod
    def from_dict(data: Dict[str, Any]) -> "CanvasItem":
        """Factory method to create item from QML data dictionary"""
        pass


class ShapeItem(CanvasItem):
    """Base class for items with geometry + appearances."""

    def __init__(
        self,
        geometry: Geometry,
        appearances: List[Appearance],
        transform: Optional[Transform] = None,
        name: str = "",
        parent_id: Optional[str] = None,
        visible: bool = True,
        locked: bool = False,
    ) -> None:
        self.geometry = geometry
        self.appearances = appearances
        self.transform = transform or Transform()
        self.name = name
        self.parent_id = parent_id
        self.visible = bool(visible)
        self.locked = bool(locked)

    @property
    def fill(self) -> Optional[Fill]:
        """Get first fill appearance."""
        for app in self.appearances:
            if isinstance(app, Fill):
                return app
        return None

    @property
    def stroke(self) -> Optional[Stroke]:
        """Get first stroke appearance."""
        for app in self.appearances:
            if isinstance(app, Stroke):
                return app
        return None

    def paint(
        self,
        painter: QPainter,
        zoom_level: float,
        offset_x: float = CANVAS_OFFSET_X,
        offset_y: float = CANVAS_OFFSET_Y,
    ) -> None:
        """Render this shape using QPainter."""
        if not self.visible:
            return

        path = self.geometry.to_painter_path()
        if not self.transform.is_identity():
            path = self.transform.to_qtransform().map(path)

        for appearance in self.appearances:
            appearance.render(painter, path, zoom_level, offset_x, offset_y)

    def get_bounds(self) -> QRectF:
        """Return bounding rectangle in canvas coordinates."""
        bounds = self.geometry.get_bounds()
        if not self.transform.is_identity():
            return self.transform.to_qtransform().mapRect(bounds)
        return bounds

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "ShapeItem":
        """Factory method - subclasses must override."""
        raise NotImplementedError("ShapeItem.from_dict must be overridden")


class RectangleItem(ShapeItem):
    """Rectangle canvas item."""

    def __init__(
        self,
        geometry: RectGeometry,
        appearances: List[Appearance],
        transform: Optional[Transform] = None,
        name: str = "",
        parent_id: Optional[str] = None,
        visible: bool = True,
        locked: bool = False,
    ) -> None:
        super().__init__(
            geometry=geometry,
            appearances=appearances,
            transform=transform,
            name=name,
            parent_id=parent_id,
            visible=visible,
            locked=locked,
        )

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "RectangleItem":
        """Create RectangleItem from dictionary."""
        geom = data["geometry"]
        geometry = RectGeometry(
            x=float(geom.get("x", 0)),
            y=float(geom.get("y", 0)),
            width=float(geom.get("width", 0)),
            height=float(geom.get("height", 0)),
        )
        appearances = [Appearance.from_dict(a) for a in data.get("appearances", [])]
        transform = (
            Transform.from_dict(data["transform"]) if "transform" in data else None
        )
        return RectangleItem(
            geometry=geometry,
            appearances=appearances,
            transform=transform,
            name=data.get("name", ""),
            parent_id=data.get("parentId"),
            visible=data.get("visible", True),
            locked=data.get("locked", False),
        )


class EllipseItem(ShapeItem):
    """Ellipse canvas item."""

    def __init__(
        self,
        geometry: EllipseGeometry,
        appearances: List[Appearance],
        transform: Optional[Transform] = None,
        name: str = "",
        parent_id: Optional[str] = None,
        visible: bool = True,
        locked: bool = False,
    ) -> None:
        super().__init__(
            geometry=geometry,
            appearances=appearances,
            transform=transform,
            name=name,
            parent_id=parent_id,
            visible=visible,
            locked=locked,
        )

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "EllipseItem":
        """Create EllipseItem from dictionary."""
        geom = data["geometry"]
        geometry = EllipseGeometry(
            center_x=float(geom.get("centerX", 0)),
            center_y=float(geom.get("centerY", 0)),
            radius_x=float(geom.get("radiusX", 0)),
            radius_y=float(geom.get("radiusY", 0)),
        )
        appearances = [Appearance.from_dict(a) for a in data.get("appearances", [])]
        transform = (
            Transform.from_dict(data["transform"]) if "transform" in data else None
        )
        return EllipseItem(
            geometry=geometry,
            appearances=appearances,
            transform=transform,
            name=data.get("name", ""),
            parent_id=data.get("parentId"),
            visible=data.get("visible", True),
            locked=data.get("locked", False),
        )


class PathItem(ShapeItem):
    """Polyline/path canvas item."""

    def __init__(
        self,
        geometry: PolylineGeometry,
        appearances: List[Appearance],
        transform: Optional[Transform] = None,
        name: str = "",
        parent_id: Optional[str] = None,
        visible: bool = True,
        locked: bool = False,
    ) -> None:
        super().__init__(
            geometry=geometry,
            appearances=appearances,
            transform=transform,
            name=name,
            parent_id=parent_id,
            visible=visible,
            locked=locked,
        )

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "PathItem":
        """Create PathItem from dictionary."""
        geom = data["geometry"]
        geometry = PolylineGeometry(
            points=geom.get("points", []),
            closed=bool(geom.get("closed", False)),
        )
        appearances = [Appearance.from_dict(a) for a in data.get("appearances", [])]
        transform = (
            Transform.from_dict(data["transform"]) if "transform" in data else None
        )
        return PathItem(
            geometry=geometry,
            appearances=appearances,
            transform=transform,
            name=data.get("name", ""),
            parent_id=data.get("parentId"),
            visible=data.get("visible", True),
            locked=data.get("locked", False),
        )


class LayerItem(CanvasItem):
    """Layer item for organizing canvas items."""

    def __init__(
        self,
        name: str = "",
        layer_id: Optional[str] = None,
        visible: bool = True,
        locked: bool = False,
    ) -> None:
        self.name = name
        self.visible = bool(visible)
        self.locked = bool(locked)
        self.id = layer_id if layer_id else str(uuid.uuid4())

    def paint(
        self,
        painter: QPainter,
        zoom_level: float,
        offset_x: float = CANVAS_OFFSET_X,
        offset_y: float = CANVAS_OFFSET_Y,
    ) -> None:
        """Layers don't render directly."""
        pass

    def get_bounds(self) -> QRectF:
        """Layers have no intrinsic bounds."""
        return QRectF()

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "LayerItem":
        """Create LayerItem from dictionary."""
        return LayerItem(
            name=data.get("name", ""),
            layer_id=data.get("id"),
            visible=data.get("visible", True),
            locked=data.get("locked", False),
        )


class GroupItem(CanvasItem):
    """Group item for nesting shapes."""

    def __init__(
        self,
        name: str = "",
        group_id: Optional[str] = None,
        parent_id: Optional[str] = None,
        visible: bool = True,
        locked: bool = False,
    ) -> None:
        self.name = name
        self.visible = bool(visible)
        self.locked = bool(locked)
        self.parent_id = parent_id
        self.id = group_id if group_id else str(uuid.uuid4())

    def paint(
        self,
        painter: QPainter,
        zoom_level: float,
        offset_x: float = CANVAS_OFFSET_X,
        offset_y: float = CANVAS_OFFSET_Y,
    ) -> None:
        """Groups do not render directly."""
        pass

    def get_bounds(self) -> QRectF:
        """Groups have no intrinsic bounds."""
        return QRectF()

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "GroupItem":
        """Create GroupItem from dictionary."""
        return GroupItem(
            name=data.get("name", ""),
            group_id=data.get("id"),
            parent_id=data.get("parentId"),
            visible=data.get("visible", True),
            locked=data.get("locked", False),
        )


class TextItem(CanvasItem):
    """Text canvas item."""

    def __init__(
        self,
        x: float,
        y: float,
        text: str,
        font_family: str = "Sans Serif",
        font_size: float = 16,
        text_color: str = "#ffffff",
        text_opacity: float = 1.0,
        width: float = 100,
        height: float = 0,
        name: str = "",
        parent_id: Optional[str] = None,
        visible: bool = True,
        locked: bool = False,
    ) -> None:
        self.name = name
        self.parent_id = parent_id
        self.visible = bool(visible)
        self.locked = bool(locked)
        self.x = x
        self.y = y
        self.text = text
        self.font_family = font_family
        self.font_size = max(8.0, min(200.0, font_size))
        self.text_color = text_color
        self.text_opacity = max(0.0, min(1.0, text_opacity))
        self.width = max(1.0, width)
        self.height = max(0.0, height)

    def paint(
        self,
        painter: QPainter,
        zoom_level: float,
        offset_x: float = CANVAS_OFFSET_X,
        offset_y: float = CANVAS_OFFSET_Y,
    ) -> None:
        """Render this text item."""
        if not self.text:
            return

        local_x = self.x + offset_x
        local_y = self.y + offset_y

        font = QFont(self.font_family)
        font.setPointSizeF(self.font_size)

        text_qcolor = QColor(self.text_color)
        text_qcolor.setAlphaF(self.text_opacity)

        doc = QTextDocument()
        doc.setDocumentMargin(0)
        doc.setDefaultFont(font)
        if self.width > 0:
            doc.setTextWidth(self.width)

        option = QTextOption()
        option.setWrapMode(QTextOption.WrapMode.WordWrap)
        doc.setDefaultTextOption(option)

        doc.setDefaultStyleSheet(
            f"body {{ color: {text_qcolor.name(QColor.NameFormat.HexArgb)}; }}"
        )
        doc.setHtml(f"<body>{self.text.replace(chr(10), '<br>')}</body>")

        painter.save()
        painter.translate(local_x, local_y)
        doc.drawContents(painter)
        painter.restore()

    def get_bounds(self) -> QRectF:
        """Return bounding rectangle in canvas coordinates."""
        if self.height > 0:
            return QRectF(self.x, self.y, self.width, self.height)
        doc = QTextDocument()
        doc.setDocumentMargin(0)
        font = QFont(self.font_family)
        font.setPointSizeF(self.font_size)
        doc.setDefaultFont(font)
        if self.width > 0:
            doc.setTextWidth(self.width)
        doc.setPlainText(self.text or " ")
        return QRectF(self.x, self.y, self.width, doc.size().height())

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> "TextItem":
        """Create TextItem from dictionary."""
        return TextItem(
            x=float(data.get("x", 0)),
            y=float(data.get("y", 0)),
            text=str(data.get("text", "")),
            font_family=str(data.get("fontFamily", "Sans Serif")),
            font_size=float(data.get("fontSize", 16)),
            text_color=str(data.get("textColor", "#ffffff")),
            text_opacity=float(data.get("textOpacity", 1.0)),
            width=float(data.get("width", 100)),
            height=float(data.get("height", 0)),
            name=str(data.get("name", "")),
            parent_id=data.get("parentId"),
            visible=data.get("visible", True),
            locked=data.get("locked", False),
        )
