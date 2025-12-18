# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from canvas_renderer import CanvasRenderer


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    
    qmlRegisterType(CanvasRenderer, "DesignVibe", 1, 0, "CanvasRenderer")
    
    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
