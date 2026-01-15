# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

# This Python file uses the following encoding: utf-8
"""
Lucent - Main application entry point.

This module initializes the Qt application, registers QML components,
and launches the main window.
"""

import sys
import os
from pathlib import Path

from typing import cast
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QFont, QFontDatabase, QIcon
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtCore import QObject, Property, Signal
from PySide6.QtQuick import QQuickWindow
from lucent.scene_graph_renderer import SceneGraphRenderer
from lucent.canvas_model import CanvasModel
from lucent.history_manager import HistoryManager
from lucent.document_manager import DocumentManager
from lucent.font_provider import FontProvider
from lucent.app_controller import AppController
from lucent.unit_settings import UnitSettings

# Version placeholder - replaced by GitHub Actions during release builds
__version__ = "__VERSION__"


def _get_preferred_backends() -> list[str]:
    if sys.platform == "darwin":
        return ["metal", "opengl"]
    elif sys.platform == "win32":
        return ["d3d11", "opengl"]
    else:
        return ["vulkan", "opengl"]


def _set_rhi_backend(backend: str) -> None:
    os.environ["QSG_RHI_BACKEND"] = backend


def _check_vulkan_available() -> bool:
    vulkan_paths = [
        "/usr/lib/libvulkan.so",
        "/usr/lib/x86_64-linux-gnu/libvulkan.so",
        "/usr/lib64/libvulkan.so",
    ]
    for path in vulkan_paths:
        if Path(path).exists():
            return True
    import shutil

    return shutil.which("vulkaninfo") is not None


def _set_default_rhi_backend() -> None:
    """Configure Qt's RHI backend with automatic fallback."""
    if os.environ.get("QSG_RHI_BACKEND"):
        return

    backends = _get_preferred_backends()
    preferred, fallback = backends[0], backends[-1]

    if sys.platform not in ("darwin", "win32") and preferred == "vulkan":
        _set_rhi_backend("vulkan" if _check_vulkan_available() else fallback)
    else:
        _set_rhi_backend(preferred)


def _get_renderer_info(window: QQuickWindow) -> tuple[str, str, str]:
    """Get renderer backend and type (hardware/software) from window."""
    try:
        ri = window.rendererInterface()
        api = ri.graphicsApi() if ri else QQuickWindow.graphicsApi()
        name = getattr(api, "name", "").lower() if hasattr(api, "name") else ""
        backend = name if name in ("opengl", "vulkan", "metal", "d3d11") else "unknown"
        renderer_type = (
            "software" if backend in ("software", "unknown", "") else "hardware"
        )
        return backend or "unknown", "", renderer_type
    except Exception:
        return "unknown", "", "unknown"


if __name__ == "__main__":
    _set_default_rhi_backend()

    # Use threaded render loop for proper VSync at display refresh rate
    os.environ.setdefault("QSG_RENDER_LOOP", "threaded")

    # Use QApplication (not QGuiApplication) to support Qt.labs.platform native dialogs
    app = QApplication(sys.argv)

    icon_path = Path(__file__).resolve().parent / "assets" / "appIcon.png"
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

    # Use fusion style on Windows to match Linux
    if sys.platform == "win32":
        from PySide6.QtQuickControls2 import QQuickStyle

        QQuickStyle.setStyle("Fusion")

    # Load custom bundled fonts from assets/fonts/
    fonts_dir = Path(__file__).resolve().parent / "assets" / "fonts"
    if fonts_dir.exists():
        for font_file in fonts_dir.glob("*.ttf"):
            QFontDatabase.addApplicationFont(str(font_file))
        for font_file in fonts_dir.glob("*.otf"):
            QFontDatabase.addApplicationFont(str(font_file))

    app_font = QFont()
    app_font.setFamilies(
        ["Inter", "Cantarell", "Segoe UI", "Ubuntu", "Roboto", "sans-serif"]
    )
    app.setFont(app_font)

    class AppInfo(QObject):
        """Exposes app version and renderer info to QML for About dialog."""

        infoChanged = Signal()

        def __init__(self, version: str) -> None:
            super().__init__()
            self._app_version = version
            self._renderer_backend = "unknown"
            self._gl_vendor = "unknown"
            self._renderer_type = "unknown"

        def setRendererInfo(
            self, backend: str, vendor: str, renderer_type: str
        ) -> None:
            """Set all renderer info at once and notify QML."""
            self._renderer_backend = backend
            self._gl_vendor = vendor
            self._renderer_type = renderer_type
            self.infoChanged.emit()

        @Property(str, constant=True)
        def appVersion(self) -> str:
            return self._app_version

        @Property(str, notify=infoChanged)
        def rendererBackend(self) -> str:
            return self._renderer_backend

        @Property(str, notify=infoChanged)
        def glVendor(self) -> str:
            return self._gl_vendor

        @Property(str, notify=infoChanged)
        def rendererType(self) -> str:
            return self._renderer_type

    qmlRegisterType(
        cast(type, SceneGraphRenderer), "CanvasRendering", 1, 0, "SceneGraphRenderer"
    )  # type: ignore[call-overload]

    engine = QQmlApplicationEngine()

    # Create history manager and expose to QML
    history_manager = HistoryManager()
    engine.rootContext().setContextProperty("historyManager", history_manager)

    # Create canvas model with injected history manager
    canvas_model = CanvasModel(history_manager)
    engine.rootContext().setContextProperty("canvasModel", canvas_model)

    # Unit and DPI settings exposed to QML
    unit_settings = UnitSettings()
    engine.rootContext().setContextProperty("unitSettings", unit_settings)

    # Create and register document manager for file operations
    document_manager = DocumentManager(canvas_model, unit_settings)
    engine.rootContext().setContextProperty("documentManager", document_manager)

    # Create and register font provider for dynamic font lists
    font_provider = FontProvider()
    engine.rootContext().setContextProperty("fontProvider", font_provider)

    app_info = AppInfo(__version__)
    engine.rootContext().setContextProperty("appInfo", app_info)

    # App controller for cross-cutting UI actions
    app_controller = AppController()
    engine.rootContext().setContextProperty("appController", app_controller)

    qml_file = Path(__file__).resolve().parent / "App.qml"
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)

    # Collect and set renderer info for About dialog
    root_window = cast(QQuickWindow, engine.rootObjects()[0])
    app_info.setRendererInfo(*_get_renderer_info(root_window))

    sys.exit(app.exec())
