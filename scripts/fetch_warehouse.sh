#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$ROOT_DIR/harvest/model"
mkdir -p "$ROOT_DIR/data_renamed/test"

if ! command -v gdown >/dev/null 2>&1; then
  echo "[ERROR] gdown is not installed."
  echo "Install: pip install gdown"
  exit 1
fi

echo "Downloading warehouse files from Google Drive..."

gdown --fuzzy "https://drive.google.com/file/d/16px659Yi_f4xCMaPp7ycbbsfYbVlmVtx/view?usp=sharing" -O "$ROOT_DIR/harvest/model/trees.warehouse"
gdown --fuzzy "https://drive.google.com/file/d/16iRfsEtfnXyJgMzqnV-keBujfMCAyys_/view?usp=sharing" -O "$ROOT_DIR/harvest/model/_trees_90.warehouse"
gdown --fuzzy "https://drive.google.com/file/d/18lPKjIJ7LRJt2MEScFa1tF-KNub_p2rP/view?usp=sharing" -O "$ROOT_DIR/data_renamed/test/trees.warehouse"

echo "Done."
