#!/usr/bin/env bash
set -euo pipefail

typage_version="${TYPAGE_VERSION:-0.2.1}"
typage_path="${TYPAGE_PATH:-}"
typage_git="${TYPAGE_GIT:-}"
typage_branch="${TYPAGE_BRANCH:-}"

# Pin the Japanese fonts used by the CV so Linux builds match local output.
font_dir=".cache/fonts"
font_base_url="https://raw.githubusercontent.com/notofonts/noto-cjk/Serif2.003/Serif"
mkdir -p "$font_dir"
for weight in Regular Bold; do
  curl -fsSL --retry 3 "${font_base_url}/OTF/Japanese/NotoSerifCJKjp-${weight}.otf" -o "${font_dir}/NotoSerifCJKjp-${weight}.otf"
done
curl -fsSL --retry 3 "${font_base_url}/LICENSE" -o "${font_dir}/LICENSE"

if [[ -n "$typage_path" ]]; then
  echo "[setup] installing Typage from ${typage_path}"
  cargo install --path "$typage_path" --locked
elif [[ -n "$typage_git" ]]; then
  if [[ -n "$typage_branch" ]]; then
    echo "[setup] installing Typage from ${typage_git} (${typage_branch})"
    cargo install --git "$typage_git" --branch "$typage_branch" --locked
  else
    echo "[setup] installing Typage from ${typage_git}"
    cargo install --git "$typage_git" --locked
  fi
else
  echo "[setup] installing Typage ${typage_version}"
  cargo install typage --version "$typage_version" --locked
fi
