# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""
Texture cache for GPU-accelerated rendering.

Rasterizes canvas items to textures (QImage) which can then be displayed
on the GPU using QSGSimpleTextureNode. This allows transforms to be applied
on the GPU without re-rasterizing the shape.

Key benefits:
- Non-destructive transforms apply as GPU matrix operations (fast)
- Only re-rasterize when appearance changes (fill, stroke, geometry resize)
- Smooth pan/zoom/rotate/scale during interaction
"""

from typing import Dict, Optional, Tuple, TYPE_CHECKING
from PySide6.QtCore import QRectF
from PySide6.QtGui import QImage, QPainter, QColor

if TYPE_CHECKING:
    from lucent.canvas_items import CanvasItem


class TextureCacheEntry:
    """Cached texture for a single canvas item."""

    def __init__(
        self,
        image: QImage,
        bounds: QRectF,
        item_version: int,
    ) -> None:
        self.image = image
        self.bounds = bounds  # Original geometry bounds (before transform)
        self.item_version = item_version  # Track when to invalidate

    @property
    def width(self) -> int:
        return self.image.width()

    @property
    def height(self) -> int:
        return self.image.height()


class TextureCache:
    """Cache of rasterized item textures for GPU rendering.

    Items are rasterized at a base scale, then GPU transforms handle
    rotation, scaling, and translation without re-rasterization.
    """

    # Padding around shapes to prevent clipping during rotation
    PADDING = 4

    # Scale factor for high-DPI rendering (2x for retina-quality)
    RENDER_SCALE = 2.0

    def __init__(self) -> None:
        self._cache: Dict[str, TextureCacheEntry] = {}
        self._item_versions: Dict[str, int] = {}

    def get_or_create(
        self,
        item: "CanvasItem",
        item_id: str,
    ) -> Optional[TextureCacheEntry]:
        """Get cached texture or create a new one.

        Returns None for items that can't be textured (layers, groups, etc.)
        """
        from lucent.canvas_items import ShapeItem, TextItem

        # Only shape items can be textured
        if not isinstance(item, (ShapeItem, TextItem)):
            return None

        # Check if we have a valid cached entry
        current_version = self._get_item_version(item)
        cached = self._cache.get(item_id)

        if cached and cached.item_version == current_version:
            return cached

        # Need to create/update the texture
        entry = self._rasterize_item(item, current_version)
        if entry:
            self._cache[item_id] = entry
            self._item_versions[item_id] = current_version

        return entry

    def invalidate(self, item_id: str) -> None:
        """Invalidate cached texture for an item."""
        self._cache.pop(item_id, None)
        self._item_versions.pop(item_id, None)

    def clear(self) -> None:
        """Clear all cached textures."""
        self._cache.clear()
        self._item_versions.clear()

    def _get_item_version(self, item: "CanvasItem") -> int:
        """Compute a version hash for cache invalidation.

        Changes to geometry or appearance invalidate the cache.
        Transform changes do NOT invalidate (handled by GPU).
        """
        # Use a simple hash of appearance properties
        version = 0

        if hasattr(item, "geometry"):
            bounds = item.geometry.get_bounds()
            version ^= hash((bounds.x(), bounds.y(), bounds.width(), bounds.height()))

        if hasattr(item, "fill") and item.fill:
            version ^= hash(item.fill.color)

        if hasattr(item, "stroke") and item.stroke:
            version ^= hash((item.stroke.color, item.stroke.width))

        return version

    def _rasterize_item(
        self,
        item: "CanvasItem",
        version: int,
    ) -> Optional[TextureCacheEntry]:
        """Rasterize an item to a QImage texture."""
        from lucent.canvas_items import ShapeItem, TextItem

        if not isinstance(item, (ShapeItem, TextItem)):
            return None

        # Get the item's base geometry bounds (before transform)
        bounds = item.geometry.get_bounds()
        if bounds.isEmpty():
            return None

        # Calculate texture size with padding and scale
        padding = self.PADDING
        scale = self.RENDER_SCALE

        tex_width = int((bounds.width() + padding * 2) * scale)
        tex_height = int((bounds.height() + padding * 2) * scale)

        # Minimum size to avoid issues
        tex_width = max(tex_width, 4)
        tex_height = max(tex_height, 4)

        # Create image with transparency
        image = QImage(tex_width, tex_height, QImage.Format.Format_ARGB32_Premultiplied)
        image.fill(QColor(0, 0, 0, 0))  # Transparent

        # Paint the item
        painter = QPainter(image)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)
        painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform, True)

        # Scale and translate to center the shape in the texture
        painter.scale(scale, scale)
        painter.translate(padding - bounds.x(), padding - bounds.y())

        # Paint using the item's existing paint method
        # Pass zoom_level=1.0 (we render at base size, GPU handles zoom)
        # Pass offset 0,0 since we've already translated the painter
        item.paint(painter, zoom_level=1.0, offset_x=0.0, offset_y=0.0)

        painter.end()

        return TextureCacheEntry(
            image=image,
            bounds=bounds,
            item_version=version,
        )

    def get_texture_offset(self, entry: TextureCacheEntry) -> Tuple[float, float]:
        """Get the offset to apply when positioning the texture.

        The texture includes padding, so we need to offset by the padding
        amount to align correctly.
        """
        return (
            entry.bounds.x() - self.PADDING,
            entry.bounds.y() - self.PADDING,
        )

    def get_texture_size(self, entry: TextureCacheEntry) -> Tuple[float, float]:
        """Get the display size of the texture (accounting for render scale)."""
        return (
            entry.width / self.RENDER_SCALE,
            entry.height / self.RENDER_SCALE,
        )
