"""
Canvas model for DesignVibe.

This module provides the CanvasModel class, which manages canvas items
as a proper Qt model with incremental updates and proper change signals.
"""
from typing import List, Optional, Dict, Any
from PySide6.QtCore import QObject, Signal, Slot, Property
from canvas_items import CanvasItem, RectangleItem, EllipseItem


class CanvasModel(QObject):
    """
    Canvas model that manages CanvasItem objects.
    
    Provides efficient incremental updates by converting items once
    and emitting granular change signals. Acts as single source of truth
    for canvas items.
    """
    
    itemAdded = Signal(int)
    itemRemoved = Signal(int)
    itemsCleared = Signal()
    itemModified = Signal(int)
    undoStackChanged = Signal()
    redoStackChanged = Signal()

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._items: List[CanvasItem] = []
        self._undo_stack: List[tuple] = []
        self._redo_stack: List[tuple] = []
        self._undoing = False
        self._redoing = False
        self._transaction_active = False
        self._transaction_snapshot: Dict[int, Dict[str, Any]] = {}
    
    def _push_undo(self, command: tuple) -> None:
        self._undo_stack.append(command)
        if self._redo_stack and not self._undoing and not self._redoing:
            self._redo_stack.clear()
            self.redoStackChanged.emit()
        self.undoStackChanged.emit()

    def _push_redo(self, command: tuple) -> None:
        self._redo_stack.append(command)
        self.redoStackChanged.emit()

    @Slot()
    def beginTransaction(self) -> None:
        if self._transaction_active:
            return
        self._transaction_active = True
        self._transaction_snapshot = {
            i: self._itemToDict(item) for i, item in enumerate(self._items)
        }

    @Slot()
    def endTransaction(self) -> None:
        if not self._transaction_active:
            return
        self._transaction_active = False

        changes: Dict[int, Dict[str, Any]] = {}
        for index, old_data in self._transaction_snapshot.items():
            if index < len(self._items):
                current_data = self._itemToDict(self._items[index])
                if current_data != old_data:
                    changes[index] = old_data

        self._transaction_snapshot = {}

        if changes:
            self._push_undo(("transaction", changes))

    @Slot(dict)
    def addItem(self, item_data: Dict[str, Any]) -> None:
        """
        Add a new item to the canvas.
        
        Args:
            item_data: Dictionary containing item properties from QML
                      Must include 'type' field ('rectangle' or 'ellipse')
        
        Emits:
            itemAdded: Signal with the index of the newly added item
        """
        try:
            item_type = item_data.get("type", "")
            item: Optional[CanvasItem] = None
            
            if item_type == "rectangle":
                item = RectangleItem.from_dict(item_data)
            elif item_type == "ellipse":
                item = EllipseItem.from_dict(item_data)
            else:
                print(f"Warning: Unknown item type '{item_type}'")
                return
            
            self._items.append(item)
            new_index = len(self._items) - 1
            if not self._undoing and not self._redoing:
                self._push_undo(("remove", new_index, self._itemToDict(item)))
            self.itemAdded.emit(new_index)
            
        except (KeyError, ValueError, TypeError) as e:
            print(f"Warning: Failed to create item: {type(e).__name__}: {e}")
    
    @Slot(int)
    def removeItem(self, index: int) -> None:
        """
        Remove an item from the canvas by index.
        
        Args:
            index: Index of the item to remove
        
        Emits:
            itemRemoved: Signal with the index of the removed item
        """
        if 0 <= index < len(self._items):
            item_data = self._itemToDict(self._items[index])
            if not self._undoing and not self._redoing:
                self._push_undo(("add", index, item_data))
            del self._items[index]
            self.itemRemoved.emit(index)
        else:
            print(f"Warning: Cannot remove item at invalid index {index}")
    
    @Slot()
    def clear(self) -> None:
        """
        Clear all items from the canvas.
        
        Emits:
            itemsCleared: Signal indicating all items were cleared
        """
        if not self._undoing and not self._redoing and self._items:
            snapshot = [self._itemToDict(item) for item in self._items]
            self._push_undo(("restore_all", snapshot))
        self._items.clear()
        self.itemsCleared.emit()
    
    @Slot(int, dict)
    def updateItem(self, index: int, properties: Dict[str, Any]) -> None:
        """
        Update properties of an existing item.
        
        Args:
            index: Index of the item to update
            properties: Dictionary of properties to update
        
        Emits:
            itemModified: Signal with the index of the modified item
        """
        if not (0 <= index < len(self._items)):
            print(f"Warning: Cannot update item at invalid index {index}")
            return
        
        item = self._items[index]
        old_props = self._itemToDict(item)
        
        try:
            if isinstance(item, RectangleItem):
                if "x" in properties:
                    item.x = float(properties["x"])
                if "y" in properties:
                    item.y = float(properties["y"])
                if "width" in properties:
                    item.width = max(0.0, float(properties["width"]))
                if "height" in properties:
                    item.height = max(0.0, float(properties["height"]))
            elif isinstance(item, EllipseItem):
                if "centerX" in properties:
                    item.center_x = float(properties["centerX"])
                if "centerY" in properties:
                    item.center_y = float(properties["centerY"])
                if "radiusX" in properties:
                    item.radius_x = max(0.0, float(properties["radiusX"]))
                if "radiusY" in properties:
                    item.radius_y = max(0.0, float(properties["radiusY"]))
            
            if "strokeWidth" in properties:
                item.stroke_width = max(0.1, min(100.0, float(properties["strokeWidth"])))
            if "strokeColor" in properties:
                item.stroke_color = str(properties["strokeColor"])
            if "strokeOpacity" in properties:
                item.stroke_opacity = max(0.0, min(1.0, float(properties["strokeOpacity"])))
            if "fillColor" in properties:
                item.fill_color = str(properties["fillColor"])
            if "fillOpacity" in properties:
                item.fill_opacity = max(0.0, min(1.0, float(properties["fillOpacity"])))
            
            if not self._undoing and not self._redoing and not self._transaction_active:
                self._push_undo(("update", index, old_props))
            self.itemModified.emit(index)
            
        except (ValueError, TypeError) as e:
            print(f"Warning: Failed to update item: {type(e).__name__}: {e}")
    
    @Slot(result=int)
    def count(self) -> int:
        """
        Get the number of items in the canvas.
        
        Returns:
            Number of items
        """
        return len(self._items)

    def _canUndo(self) -> bool:
        """Check if there are actions to undo."""
        return len(self._undo_stack) > 0

    canUndo = Property(bool, _canUndo, notify=undoStackChanged)

    @Slot(result=bool)
    def undo(self) -> bool:
        if not self._undo_stack:
            return False

        command = self._undo_stack.pop()
        self._undoing = True
        try:
            action = command[0]
            if action == "remove":
                index, item_data = command[1], command[2]
                del self._items[index]
                self._push_redo(("add", index, item_data))
                self.itemRemoved.emit(index)
            elif action == "add":
                index, item_data = command[1], command[2]
                item = self._createItem(item_data)
                self._items.insert(index, item)
                self._push_redo(("remove", index, item_data))
                self.itemAdded.emit(index)
            elif action == "update":
                index, old_props = command[1], command[2]
                current_props = self._itemToDict(self._items[index])
                self._items[index] = self._createItem(old_props)
                self._push_redo(("update", index, current_props))
                self.itemModified.emit(index)
            elif action == "transaction":
                changes = command[1]
                redo_changes: Dict[int, Dict[str, Any]] = {}
                for index, old_props in changes.items():
                    redo_changes[index] = self._itemToDict(self._items[index])
                    self._items[index] = self._createItem(old_props)
                    self.itemModified.emit(index)
                self._push_redo(("transaction", redo_changes))
            elif action == "restore_all":
                current_snapshot = [self._itemToDict(item) for item in self._items]
                self._items.clear()
                snapshot = command[1]
                for item_data in snapshot:
                    self._items.append(self._createItem(item_data))
                self._push_redo(("clear_all", current_snapshot))
                for i in range(len(self._items)):
                    self.itemAdded.emit(i)
            elif action == "clear_all":
                current_snapshot = [self._itemToDict(item) for item in self._items]
                self._items.clear()
                self._push_redo(("restore_all", current_snapshot))
                self.itemsCleared.emit()
        finally:
            self._undoing = False
            self.undoStackChanged.emit()
        return True

    def _createItem(self, item_data: Dict[str, Any]) -> CanvasItem:
        item_type = item_data.get("type", "")
        if item_type == "rectangle":
            return RectangleItem.from_dict(item_data)
        return EllipseItem.from_dict(item_data)

    def _canRedo(self) -> bool:
        return len(self._redo_stack) > 0

    canRedo = Property(bool, _canRedo, notify=redoStackChanged)

    @Slot(result=bool)
    def redo(self) -> bool:
        if not self._redo_stack:
            return False

        command = self._redo_stack.pop()
        self._redoing = True
        try:
            action = command[0]
            if action == "add":
                index, item_data = command[1], command[2]
                item = self._createItem(item_data)
                self._items.insert(index, item)
                self._push_undo(("remove", index, item_data))
                self.itemAdded.emit(index)
            elif action == "remove":
                index, item_data = command[1], command[2]
                del self._items[index]
                self._push_undo(("add", index, item_data))
                self.itemRemoved.emit(index)
            elif action == "update":
                index, new_props = command[1], command[2]
                old_props = self._itemToDict(self._items[index])
                self._items[index] = self._createItem(new_props)
                self._push_undo(("update", index, old_props))
                self.itemModified.emit(index)
            elif action == "transaction":
                changes = command[1]
                undo_changes: Dict[int, Dict[str, Any]] = {}
                for index, new_props in changes.items():
                    undo_changes[index] = self._itemToDict(self._items[index])
                    self._items[index] = self._createItem(new_props)
                    self.itemModified.emit(index)
                self._push_undo(("transaction", undo_changes))
            elif action == "restore_all":
                current_snapshot = [self._itemToDict(item) for item in self._items]
                self._items.clear()
                snapshot = command[1]
                for item_data in snapshot:
                    self._items.append(self._createItem(item_data))
                self._push_undo(("clear_all", current_snapshot))
                for i in range(len(self._items)):
                    self.itemAdded.emit(i)
            elif action == "clear_all":
                current_snapshot = [self._itemToDict(item) for item in self._items]
                self._items.clear()
                self._push_undo(("restore_all", current_snapshot))
                self.itemsCleared.emit()
        finally:
            self._redoing = False
            self.redoStackChanged.emit()
        return True

    def getItems(self) -> List[CanvasItem]:
        """
        Get all canvas items for rendering.
        
        Returns:
            List of CanvasItem objects
        """
        return self._items
    
    @Slot(int, result='QVariant')
    def getItemData(self, index: int) -> Optional[Dict[str, Any]]:
        """
        Get item data as a dictionary for QML queries.
        
        Args:
            index: Index of the item to retrieve
        
        Returns:
            Dictionary representation of the item, or None if invalid index
        """
        if 0 <= index < len(self._items):
            item = self._items[index]
            return self._itemToDict(item)
        return None
    
    @Slot(result='QVariantList')
    def getItemsForHitTest(self) -> List[Dict[str, Any]]:
        """
        Get all items as dictionaries for hit testing in QML.
        
        Returns:
            List of dictionaries representing all items
        """
        return [self._itemToDict(item) for item in self._items]
    
    def _itemToDict(self, item: CanvasItem) -> Dict[str, Any]:
        """
        Convert a CanvasItem to a dictionary for QML.
        
        Args:
            item: CanvasItem to convert
        
        Returns:
            Dictionary representation of the item
        """
        if isinstance(item, RectangleItem):
            return {
                "type": "rectangle",
                "x": item.x,
                "y": item.y,
                "width": item.width,
                "height": item.height,
                "strokeWidth": item.stroke_width,
                "strokeColor": item.stroke_color,
                "strokeOpacity": item.stroke_opacity,
                "fillColor": item.fill_color,
                "fillOpacity": item.fill_opacity
            }
        elif isinstance(item, EllipseItem):
            return {
                "type": "ellipse",
                "centerX": item.center_x,
                "centerY": item.center_y,
                "radiusX": item.radius_x,
                "radiusY": item.radius_y,
                "strokeWidth": item.stroke_width,
                "strokeColor": item.stroke_color,
                "strokeOpacity": item.stroke_opacity,
                "fillColor": item.fill_color,
                "fillOpacity": item.fill_opacity
            }
        return {}

