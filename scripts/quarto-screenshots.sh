#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root/src/examples/quarto"

uv run --project "$repo_root" --group screenshots quarto render minimal.qmd
uv run --project "$repo_root" --group screenshots quarto render minimal-R.qmd
uv run --project "$repo_root" --group screenshots quarto render minimal-python.qmd
uv run --project "$repo_root" --group screenshots quarto render parameterized.qmd
uv run --project "$repo_root" --group screenshots quarto render report-R.qmd -P region:South -P year:2025
uv run --project "$repo_root" --group screenshots quarto render report-python.qmd -P region:South -P year:2025

typst compile minimal.typ "minimal-{n}.png" --ppi 200
typst compile minimal-R.typ "minimal-R-{n}.png" --ppi 200
typst compile minimal-python.typ "minimal-python-{n}.png" --ppi 200
typst compile parameterized.typ "parameterized-{n}.png" --ppi 200
typst compile report-R.typ "report-R-{n}.png" --ppi 200
typst compile report-python.typ "report-python-{n}.png" --ppi 200

mv minimal-1.png "$repo_root/src/images/quarto-minimal.png"
mv minimal-R-1.png "$repo_root/src/images/quarto-minimal-R.png"
mv minimal-python-1.png "$repo_root/src/images/quarto-minimal-python.png"
mv parameterized-1.png "$repo_root/src/images/quarto-parameterized.png"
mv report-R-1.png "$repo_root/src/images/quarto-report-R.png"
mv report-python-1.png "$repo_root/src/images/quarto-report-python.png"

rm -f ./*.pdf ./*.typ
rm -rf ./*_files
