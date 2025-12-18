from abc import ABC, abstractmethod
from PySide6.QtGui import QPainter, QPen, QBrush, QColor
from PySide6.QtCore import QRectF


class CanvasItem(ABC):
    """Base class for all canvas items"""
    
    @abstractmethod
    def paint(self, painter, zoom_level, offset_x=5000, offset_y=5000):
        """Paint this item using the provided QPainter"""
        pass
    
    @staticmethod
    @abstractmethod
    def from_dict(data):
        """Factory method to create item from QML data dictionary"""
        pass


class RectangleItem(CanvasItem):
    """Rectangle canvas item"""
    
    def __init__(self, x, y, width, height, stroke_width=1, 
                 stroke_color="#ffffff", fill_color="#ffffff", fill_opacity=0.0):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.stroke_width = stroke_width
        self.stroke_color = stroke_color
        self.fill_color = fill_color
        self.fill_opacity = fill_opacity
    
    def paint(self, painter, zoom_level, offset_x=5000, offset_y=5000):
        """Render this rectangle using QPainter"""
        # Transform from canvas coordinates to CanvasRenderer local coordinates
        # CanvasRenderer is positioned at (-5000, -5000) with size 10000x10000
        # Canvas coordinate (0, 0) maps to local coordinate (5000, 5000)
        local_x = self.x + offset_x
        local_y = self.y + offset_y
        
        # Scale stroke width by zoom level
        scaled_stroke_width = self.stroke_width / zoom_level
        
        # Set up pen for stroke
        pen = QPen(QColor(self.stroke_color))
        pen.setWidthF(scaled_stroke_width)
        painter.setPen(pen)
        
        # Set up brush for fill
        fill_qcolor = QColor(self.fill_color)
        fill_qcolor.setAlphaF(self.fill_opacity)
        brush = QBrush(fill_qcolor)
        painter.setBrush(brush)
        
        # Draw rectangle
        painter.drawRect(QRectF(local_x, local_y, self.width, self.height))
    
    @staticmethod
    def from_dict(data):
        """Create RectangleItem from QML data dictionary"""
        return RectangleItem(
            x=float(data.get("x", 0)),
            y=float(data.get("y", 0)),
            width=float(data.get("width", 0)),
            height=float(data.get("height", 0)),
            stroke_width=float(data.get("strokeWidth", 1)),
            stroke_color=data.get("strokeColor", "#ffffff"),
            fill_color=data.get("fillColor", "#ffffff"),
            fill_opacity=float(data.get("fillOpacity", 0.0))
        )

