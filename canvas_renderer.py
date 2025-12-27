"""
Canvas renderer component for DesignVibe.

This module provides the CanvasRenderer class, which is a QQuickPaintedItem
that bridges QML and Python, rendering canvas items using QPainter.
"""
from typing import Optional, List, TYPE_CHECKING
from PySide6.QtCore import Property, Signal, Slot, QObject
from PySide6.QtQuick import QQuickPaintedItem
from PySide6.QtGui import QPainter

if TYPE_CHECKING:
    from canvas_model import CanvasModel
    from canvas_items import CanvasItem


class CanvasRenderer(QQuickPaintedItem):
    """Custom QPainter-based renderer for canvas items"""
    
    zoomLevelChanged = Signal()
    
    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._model: Optional['CanvasModel'] = None
        self._zoom_level: float = 1.0
    
    @Slot(QObject)
    def setModel(self, model: QObject) -> None:
        """
        Set the canvas model to render items from.
        
        Args:
            model: CanvasModel instance to get items from
        """
        # Import here to avoid circular dependency
        from canvas_model import CanvasModel
        
        if isinstance(model, CanvasModel):
            self._model = model
            # Connect to model signals for automatic updates
            model.itemAdded.connect(self.update)
            model.itemRemoved.connect(self.update)
            model.itemsCleared.connect(self.update)
            model.itemModified.connect(self.update)
            model.itemsReordered.connect(self.update)
            # Initial render
            self.update()
        
    def paint(self, painter: QPainter) -> None:
        """Render all items from the model using QPainter.
        
        Rendering order respects parent-child relationships:
        - Items are rendered bottom-to-top based on their position in the list
        - When a layer is encountered, its children are rendered immediately after it
        - This groups children visually with their parent layer in Z-order
        """
        if not self._model:
            return
            
        painter.setRenderHint(QPainter.Antialiasing, True)
        
        # Get ordered items respecting parent-child grouping
        ordered_items = self._get_render_order()
        
        # Render each item
        for item in ordered_items:
            item.paint(painter, self._zoom_level)
    
    def _get_render_order(self) -> List['CanvasItem']:
        """Get items in render order - REVERSED from model order.
        
        Z-order convention (matching typical design tools):
        - Items at TOP of layer panel (lower index) are ON TOP visually
        - Items at BOTTOM of layer panel (higher index) are BEHIND
        
        So we render in REVERSE model order:
        - Higher indices render first (behind/bottom)
        - Lower indices render last (in front/top)
        
        Returns:
            List of CanvasItem in the order they should be painted (bottom to top)
        """
        from canvas_items import LayerItem, RectangleItem, EllipseItem
        
        items = self._model.getItems()
        result: List['CanvasItem'] = []
        
        # Render items in REVERSE model order, skipping layers
        for item in reversed(items):
            if isinstance(item, (RectangleItem, EllipseItem)):
                result.append(item)
        
        return result
    
    @Property(float, notify=zoomLevelChanged)
    def zoomLevel(self) -> float:
        return self._zoom_level
    
    @zoomLevel.setter
    def zoomLevel(self, value: float) -> None:
        if self._zoom_level != value:
            self._zoom_level = value
            self.zoomLevelChanged.emit()
            self.update()

