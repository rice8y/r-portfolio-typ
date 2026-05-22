build:
  node scripts/ensure-typst.mjs
  node scripts/build.mjs

# Ctrl+C is handled by scripts/dev.sh + scripts/dev.mjs and exits cleanly.
dev:
  @bash scripts/dev.sh
