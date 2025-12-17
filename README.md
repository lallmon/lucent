# DesignVibe

A digital design application built with PySide6 and Qt Quick.

## Features

### Rendering Canvas
- **Infinite canvas** (36,000 x 36,000 pixels) with pan and zoom capabilities
- **Grid system** with minor and major gridlines for visual reference
- **Zoom controls**: Mouse wheel, keyboard shortcuts (Ctrl+/Ctrl-/Ctrl+0), and menu options
- **Pan navigation**: Click and drag with left mouse button
- **Crisp rendering** with smooth transformations
- Starts with a zoomed-out view for better overview

### Drawing Tools
- **Rectangle tool**: Draw vector rectangles on the canvas
  - Red stroke (2px width) for finalized shapes
  - Dotted red preview while dragging
  - Click and drag to create rectangles
  - Proper coordinate transformation with zoom and pan
  - Stroke width scales inversely with zoom for consistent appearance

### User Interface
- Menu bar with File and View menus
- Left vertical toolbar with drawing tools
- Status bar with real-time zoom level indicator


## Controls

### Navigation
- **Pan**: Click and drag with left mouse button (when no tool is selected)
- **Zoom**: Mouse wheel or Ctrl+Plus/Ctrl+Minus
- **Reset view**: Ctrl+0
- **Quit**: Ctrl+Q

### Tools
- **Select tool**: Click the "Sel" button to enable pan and zoom mode
- **Rectangle tool**: Click the "Rect" button to draw rectangles
  - Click and drag on the canvas to draw
  - Rectangle appears with dotted preview while dragging
  - Solid red outline when finalized

## Project Structure

- `main.py` - Application entry point
- `main.qml` - Main application window with menu bar
- `Components/` - QML components directory
  - `InfiniteCanvas.qml` - Infinite canvas component with pan/zoom and drawing
  - `StatusBar.qml` - Status bar component with zoom level display
  - `ToolBar.qml` - Left toolbar with drawing tool buttons
- `pyproject.toml` - Project configuration
- `requirements.txt` - Python dependencies

