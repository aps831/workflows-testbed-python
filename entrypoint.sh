#! /bin/bash
python -m venv .venv-container
source .venv-container/bin/activate
ls -la
poetry install -v --no-ansi
exec "$@"
