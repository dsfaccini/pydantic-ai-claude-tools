pydantic-reinstall() {
  deactivate 2>/dev/null
  unset VIRTUAL_ENV
  rm -rf .venv
  make install
  source .venv/bin/activate
}
