#! /bin/bash
python -m venv .venv-container
source .venv-container/bin/activate
poetry install --no-ansi
exec "$@"
