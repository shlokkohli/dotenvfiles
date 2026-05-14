#!/bin/bash
# Run this once after cloning dotfiles and running `stow .`
# It compiles all treesitter parsers and copies queries so Neovim colors work immediately.
#
# Usage: bash ~/dotfiles/nvim-setup.sh

set -e

PARSER_DIR="$HOME/.local/share/nvim/site/parser"
QUERY_DST="$HOME/.local/share/nvim/site/queries"
NTS_DIR="$HOME/.local/share/nvim/lazy/nvim-treesitter"
QUERY_SRC="$NTS_DIR/runtime/queries"
TMP="/tmp/nvim_ts_build"

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

# ── prerequisites ─────────────────────────────────────────────────────────────
for cmd in nvim clang clang++ curl; do
  command -v "$cmd" >/dev/null 2>&1 || { fail "Missing required tool: $cmd"; exit 1; }
done

# ── step 1: install plugins via lazy ─────────────────────────────────────────
info "Installing Neovim plugins (lazy.nvim)..."
nvim --headless -c "Lazy! sync" -c "qa" 2>/dev/null || true

if [ ! -d "$NTS_DIR" ]; then
  fail "nvim-treesitter not found at $NTS_DIR — run Neovim once and try again"
  exit 1
fi

mkdir -p "$PARSER_DIR" "$QUERY_DST" "$TMP"

# ── helpers ───────────────────────────────────────────────────────────────────
dl() { curl -sf "https://raw.githubusercontent.com/$1" -o "$2" 2>/dev/null && ! grep -q "404: Not Found" "$2" 2>/dev/null; }

compile_parser() {
  local lang="$1" repo="$2" rev="$3" src="${4:-src}"
  local dir="$TMP/$lang"
  mkdir -p "$dir/tree_sitter"

  echo -n "  $lang ... "

  dl "$repo/$rev/$src/tree_sitter/parser.h" "$dir/tree_sitter/parser.h" || { fail "no parser.h"; return; }
  dl "$repo/$rev/$src/parser.c"             "$dir/parser.c"             || { fail "no parser.c"; return; }

  for h in alloc.h array.h; do
    dl "$repo/$rev/$src/tree_sitter/$h" "$dir/tree_sitter/$h" 2>/dev/null || true
  done

  local srcs="$dir/parser.c"
  local extra_c="" extra_cc=""

  dl "$repo/$rev/$src/scanner.c"  "$dir/scanner.c"  && extra_c="$dir/scanner.c"
  dl "$repo/$rev/$src/scanner.cc" "$dir/scanner.cc" && extra_cc="$dir/scanner.cc"

  local out="$PARSER_DIR/$lang.so"
  local compiled=false

  if [ -n "$extra_cc" ]; then
    clang++ -shared -fPIC -I"$dir" -o "$out" $srcs "$extra_cc" 2>/dev/null && compiled=true
  fi
  if [ "$compiled" = false ] && [ -n "$extra_c" ]; then
    clang -shared -fPIC -I"$dir" -o "$out" $srcs "$extra_c" 2>/dev/null && compiled=true
  fi
  if [ "$compiled" = false ]; then
    clang -shared -fPIC -I"$dir" -o "$out" $srcs 2>/dev/null && compiled=true
  fi

  if [ "$compiled" = true ] && [ -f "$out" ]; then
    ok "$lang"
  else
    fail "$lang"
  fi
}

# ── step 2: compile parsers ───────────────────────────────────────────────────
echo ""
info "Compiling treesitter parsers..."

compile_parser lua        tree-sitter/tree-sitter-lua        a4922f7ceef6258ec09acec5cb4b84d33e2e2a9e
compile_parser python     tree-sitter/tree-sitter-python     v0.25.0
compile_parser javascript tree-sitter/tree-sitter-javascript f772967f7b7bc7c28f845be2420a38472b16a8df
compile_parser typescript tree-sitter/tree-sitter-typescript 75b3874edb2dc714fb1fd77a32013d0f8699989f  typescript/src
compile_parser go         tree-sitter/tree-sitter-go         2346a3ab1bb3857b48b29d779a1ef9799a248cd7
compile_parser gomod      camdencheek/tree-sitter-go-mod     2e886870578eeba1927a2dc4bd2e2b3f598c5f9a
compile_parser gosum      tree-sitter-grammars/tree-sitter-go-sum  27816eb6b7315746ae9fcf711e4e1396dc1cf237
compile_parser rust       tree-sitter/tree-sitter-rust       261b20226c04ef601adbdf185a800512a5f66291
compile_parser bash       tree-sitter/tree-sitter-bash       a06c2e4415e9bc0346c6b86d401879ffb44058f7
compile_parser regex      tree-sitter/tree-sitter-regex      b2ac15e27fce703d2f37a79ccd94a5c0cbe9720b
compile_parser json       tree-sitter/tree-sitter-json       001c28d7a29832b06b0e831ec77845553c89b56d
compile_parser html       tree-sitter/tree-sitter-html       eb7eb808b9f745c4c8aa5f0649e66b5f928e26ee
compile_parser css        tree-sitter/tree-sitter-css        b250a2f72f3f6b4ffe69a4c25fe5776f21cd7ec1
compile_parser vue        ikatyang/tree-sitter-vue           91fe2754796cd8fba5f229505a23fa08174a3eff
compile_parser toml       tree-sitter-grammars/tree-sitter-toml    64b56832c2cffe41758f28e05c756a3a98d16f41
compile_parser yaml       tree-sitter-grammars/tree-sitter-yaml    4463985dfccc640f3d6991e3396a2047610cf5f8
compile_parser terraform  MichaHoffmann/tree-sitter-hcl     64ad62785d442eb4d45df3a1764962dafd5bc98b  dialects/terraform/src
compile_parser hcl        MichaHoffmann/tree-sitter-hcl     64ad62785d442eb4d45df3a1764962dafd5bc98b
compile_parser sql        derekstride/tree-sitter-sql        851e9cb257ba7c66cc8c14214a31c44d2f1e954e
compile_parser dockerfile camdencheek/tree-sitter-dockerfile 971acdd908568b4531b0ba28a445bf0bb720aba5
compile_parser java       tree-sitter/tree-sitter-java       e10607b45ff745f5f876bfa3e94fbcc6b44bdc11
compile_parser groovy     murtaza64/tree-sitter-groovy       a88865a3301a538e2060af5b401f4f431f71406e
compile_parser graphql    bkegley/tree-sitter-graphql        5e66e961eee421786bdda8495ed1db045e06b5fe
compile_parser cmake      uyha/tree-sitter-cmake             c7b2a71e7f8ecb167fad4c97227c838439280175
compile_parser make       tree-sitter-grammars/tree-sitter-make    70613f3d812cbabbd7f38d104d60a409c4008b43
compile_parser gitignore  shunsambongi/tree-sitter-gitignore f4685bf11ac466dd278449bcfe5fd014e94aa504
compile_parser prisma     victorhqc/tree-sitter-prisma       3556b2c1f20ec9ac91e92d32c43d9d2a0ca3cc49
compile_parser markdown   tree-sitter-grammars/tree-sitter-markdown  d4f418c5a21fd05e4c7699a67742e07c0e5b17e5
compile_parser vim        tree-sitter-grammars/tree-sitter-vim       1e1782f5c72c3a99be052e39f7a99f3f70c4a11f

# tsx needs the shared common/scanner.h
echo -n "  tsx ... "
REV="75b3874edb2dc714fb1fd77a32013d0f8699989f"
REPO="tree-sitter/tree-sitter-typescript"
dir="$TMP/tsx_full"
mkdir -p "$dir/tsx/src/tree_sitter" "$dir/common"
for h in parser.h alloc.h array.h; do
  dl "$REPO/$REV/tsx/src/tree_sitter/$h" "$dir/tsx/src/tree_sitter/$h" || true
done
dl "$REPO/$REV/tsx/src/parser.c"  "$dir/tsx/src/parser.c"
dl "$REPO/$REV/tsx/src/scanner.c" "$dir/tsx/src/scanner.c"
dl "$REPO/$REV/common/scanner.h"  "$dir/common/scanner.h"
clang -shared -fPIC \
  -I"$dir/tsx/src" -I"$dir" \
  -o "$PARSER_DIR/tsx.so" \
  "$dir/tsx/src/parser.c" "$dir/tsx/src/scanner.c" 2>/dev/null \
  && ok "tsx" || fail "tsx"

# yaml needs schema.core.c
echo -n "  yaml (extra) ... "
dir="$TMP/yaml"
REV="4463985dfccc640f3d6991e3396a2047610cf5f8"
dl "tree-sitter-grammars/tree-sitter-yaml/$REV/src/schema.core.c" "$dir/schema.core.c" || true
clang -shared -fPIC -I"$dir" \
  -o "$PARSER_DIR/yaml.so" \
  "$dir/parser.c" "$dir/scanner.c" 2>/dev/null \
  && ok "yaml (recompiled)" || fail "yaml"

# ── step 3: copy all queries ──────────────────────────────────────────────────
echo ""
info "Copying treesitter queries..."
if [ -d "$QUERY_SRC" ]; then
  for lang_dir in "$QUERY_SRC"/*/; do
    lang=$(basename "$lang_dir")
    mkdir -p "$QUERY_DST/$lang"
    cp "$lang_dir"*.scm "$QUERY_DST/$lang/" 2>/dev/null || true
  done
  ok "All queries copied from nvim-treesitter"
else
  fail "nvim-treesitter queries not found — open Neovim once to install plugins, then re-run"
fi

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
ok "Done! Restart Neovim — colors and LSP will work immediately."
echo "   LSP servers (gopls, rust_analyzer, etc.) auto-install via Mason on first file open."
