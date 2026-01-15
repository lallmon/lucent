# Copyright (C) 2026 The Culture List, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

"""Pytest configuration and shared fixtures for Lucent tests."""

import pytest
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from lucent.canvas_model import CanvasModel
from lucent.scene_graph_renderer import SceneGraphRenderer
from lucent.history_manager import HistoryManager


@pytest.fixture(scope="session")
def qapp():
    """Create a QApplication instance for the test session.

    Qt requires a QApplication instance to be created before any Qt objects.
    This fixture creates one that lasts for the entire test session.
    """
    app = QApplication.instance()
    if app is None:
        app = QApplication([])
    yield app
    # Note: Don't call app.quit() here as it can cause issues with pytest-qt


@pytest.fixture
def history_manager(qapp):
    """Create a fresh HistoryManager instance for each test."""
    return HistoryManager()


@pytest.fixture
def canvas_model(history_manager):
    """Create a fresh CanvasModel instance for each test."""
    return CanvasModel(history_manager)


@pytest.fixture
def scene_graph_renderer(qapp):
    """Create a fresh SceneGraphRenderer instance for each test."""
    return SceneGraphRenderer()


@pytest.fixture
def qml_engine(qapp):
    """Create a QQmlApplicationEngine instance for integration tests."""
    engine = QQmlApplicationEngine()
    yield engine
    engine.deleteLater()
