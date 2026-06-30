#!/usr/bin/env bash
set -euo pipefail

typst_version="${TYPST_VERSION:-0.15.0}"
typage_version="${TYPAGE_VERSION:-0.1.2}"

case "$(uname -m)" in
  x86_64 | amd64)
    typst_target="x86_64-unknown-linux-musl"
    ;;
  aarch64 | arm64)
    typst_target="aarch64-unknown-linux-musl"
    ;;
  *)
    echo "Unsupported Vercel architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

typst_dir=".cache/typst/v${typst_version}"
typst_archive="${typst_dir}/typst-${typst_target}.tar.xz"
typst_url="https://github.com/typst/typst/releases/download/v${typst_version}/typst-${typst_target}.tar.xz"

mkdir -p .bin "$typst_dir"

echo "[setup] installing Typst ${typst_version} for ${typst_target}"
curl -fsSL "$typst_url" -o "$typst_archive"
tar -xJf "$typst_archive" -C "$typst_dir"
cp "${typst_dir}/typst-${typst_target}/typst" .bin/typst
chmod +x .bin/typst

echo "[setup] installing Typage ${typage_version}"
cargo install typage --version "$typage_version" --locked
