# DesignVibe

[![Tests](https://github.com/lallmon/designvibe/actions/workflows/test.yml/badge.svg)](https://github.com/lallmon/designvibe/actions)
[![codecov](https://codecov.io/gh/lallmon/designvibe/branch/main/graph/badge.svg)](https://codecov.io/gh/lallmon/designvibe)

## What
A modern, open source hybrid vector/raster digital design application, built with QT. Taking a Linux first approach, but planning to be multi-platform.

## Why
Mainly because there isn't a good alternative to Affinity Designer on Linux honestly, and with their purchase by Canva and the quick enshittification of that software, it's pushed me to at least take a stab at something.

# Architecture 

I am currently learing both QTQuick and Python, so we don't have a solid architecture yet, but am open to suggestions and best practices.

## Contributing
There's plenty to do but the end goal is pretty clear for me, so if you want to help out, I'd love it anything I can do.

### Getting Started

## Local setup
- Install Python 3.10
- Create/activate the project venv: `python -m venv .venv && source .venv/bin/activate`
- Install deps: `pip install -r requirements.txt -r requirements-dev.txt`
- Install the app package (src layout): `pip install -e .`
- Install hooks: `pre-commit install`

Run the app: `python main.py`

Run tests: `pytest -q`

#### AI Contributions
I have used AI on this project, so I am not against it, but you definitely need to wrangle that slop machine. LOL. Just straight vibe coding is definitely not something that will work in the long run.

