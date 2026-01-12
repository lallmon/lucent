#!/usr/bin/env bash
set -euo pipefail

# Build Lucent on Linux inside distrobox/container without mutating sources.
# - Installs system deps (APT) unless SKIP_APT=1
# - Recreates/uses .venv in repo
# - Injects version into temp copies of main.py/pysidedeploy.spec
# - Runs pyside6-deploy and drops artifacts into dist/ (gitignored)
#
# Usage:
#   VERSION=0.0.0-dev ./scripts/build_linux.sh
#   REPO=/path/to/lucent ./scripts/build_linux.sh       # source repo path
#   ./scripts/build_linux.sh /path/to/lucent            # source repo as first arg

repo="${REPO:-}"
if [[ -z "$repo" ]]; then
  if [[ $# -gt 0 ]]; then
    repo="$1"
    shift
  else
    repo="$(git rev-parse --show-toplevel)"
  fi
fi
if [[ ! -d "$repo" ]]; then
  echo "ERROR: repo path not found: $repo" >&2
  exit 1
fi

workdir="$repo"
cd "$workdir"

VERSION="${VERSION:-0.0.0-dev}"

apt_install() {
  local pkgs=(
    libgl1 libegl1 libxkbcommon-x11-0
    libxcb-icccm4 libxcb-image0 libxcb-keysyms1
    libxcb-randr0 libxcb-render-util0 libxcb-xinerama0
    libxcb-xfixes0 libxcb-shape0 libxcb-cursor0
    libdbus-1-3 libfontconfig1 libglib2.0-0
    libgssapi-krb5-2 libx11-6 libx11-xcb1
    libxext6 libxrender1 libxkbcommon0
    fuse libfuse2
    build-essential ccache patchelf python3-venv python3-dev
  )
  local missing=()
  for p in "${pkgs[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then
      missing+=("$p")
    fi
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "[deps] All apt packages already present; skipping apt install."
    return
  fi
  echo "[deps] Installing missing packages: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y -qq "${missing[@]}"
}

setup_venv() {
  if [[ ! -d "$workdir/venv" ]]; then
    python3 -m venv "$workdir/venv"
  fi
  # shellcheck source=/dev/null
  source "$workdir/venv/bin/activate"
  python -m pip install --upgrade pip
  pip install -r requirements.txt
  pip install nuitka ordered-set zstandard imageio
  pip install -e .
}

make_temp_sources() {
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  tmp_main="$tmpdir/main.py"
  tmp_spec="$tmpdir/pysidedeploy.spec"

  sed "s|__VERSION__|$VERSION|g" "$repo/main.py" > "$tmp_main"
  sed -e "s|__VERSION__|$VERSION|g" \
      -e "s|^input_file *=.*|input_file = $tmp_main|" \
      -e "s|^project_dir *=.*|project_dir = $repo|" \
      "$repo/pysidedeploy.spec" > "$tmp_spec"
}

build_app() {
  mkdir -p "$workdir/dist"
  pushd "$workdir" >/dev/null
  pyside6-deploy -c "$tmp_spec" --force
  if [[ -f "Lucent.bin" ]]; then
    mv -f Lucent.bin dist/Lucent
    chmod +x dist/Lucent
    tar -czvf "dist/Lucent-${VERSION}-Linux-x86_64.tar.gz" -C dist Lucent
    echo "Build complete: dist/Lucent and dist/Lucent-${VERSION}-Linux-x86_64.tar.gz"
  else
    echo "ERROR: Lucent.bin not produced" >&2
    exit 1
  fi
  popd >/dev/null
}

main() {
  echo "[build] Using version: $VERSION"
  apt_install
  setup_venv
  make_temp_sources
  build_app
}

main "$@"
