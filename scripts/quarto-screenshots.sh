#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage: quarto-screenshots.sh [--ppi <n>]

Render every .qmd under src/examples/quarto/ with Quarto (format: typst),
then compile the intermediate .typ to PNG with typst. PNGs are moved to
src/images/ as quarto-<name>.png, or quarto-<name>-page-<n>.png when the
document produces multiple pages.

If a sibling file <name>.args exists next to <name>.qmd, its contents are
split on whitespace (with '#' line-comments honoured) and forwarded to
'quarto render'. Typical use: pass '-P region:South -P year:2025' to
override parameters.

Rendering happens in-place inside src/examples/quarto/ so that:
  - The renv project (.Rprofile + renv/) activates for R examples.
  - uv's pyproject.toml at the repo root is honoured for Python examples.
Per-file artefacts (.pdf, .typ, _files/) are cleaned up after each render.

Per-file failures are logged and skipped so that missing optional
runtimes (R, Python, ...) do not abort the whole batch. The script exits
non-zero at the end if any file failed.

Options:
  --ppi <n>   Pixels per inch for the PNG output. Default: 200.
  -h, --help  Show this help and exit.

Notes on optional runtimes:
  - Pure-Markdown .qmd files (no code cells) need only quarto and typst.
  - R examples need R with the packages pinned in
    src/examples/quarto/renv.lock. Run `renv::restore()` in that directory
    to install them.
  - Python examples need the 'screenshots' dependency group from
    pyproject.toml. Install with `uv sync --group screenshots`. When uv
    is available at the repo root, 'quarto render' is invoked through
    'uv run' so the managed env is used.
USAGE
}

ppi=200
while [[ $# -gt 0 ]]; do
	case "$1" in
	--ppi)
		[[ $# -ge 2 ]] || {
			echo "error: --ppi needs a value" >&2
			exit 2
		}
		ppi="$2"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "error: unknown argument: $1" >&2
		usage >&2
		exit 2
		;;
	esac
done

if ! command -v quarto >/dev/null 2>&1; then
	echo "error: 'quarto' not found. Install it from https://quarto.org/docs/get-started/." >&2
	exit 1
fi

if ! command -v typst >/dev/null 2>&1; then
	echo "error: 'typst' not found. Install it from https://github.com/typst/typst#installation." >&2
	exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
examples_dir="$repo_root/src/examples/quarto"
images_dir="$repo_root/src/images"

quarto_cmd=(quarto)
if command -v uv >/dev/null 2>&1 && [[ -f "$repo_root/pyproject.toml" ]]; then
	quarto_cmd=(uv run --project "$repo_root" --group screenshots quarto)
fi

if [[ ! -d "$examples_dir" ]]; then
	echo "error: no examples directory at $examples_dir" >&2
	exit 1
fi

shopt -s nullglob
qmd_files=("$examples_dir"/*.qmd)
shopt -u nullglob

if [[ ${#qmd_files[@]} -eq 0 ]]; then
	echo "no .qmd files found in $examples_dir; nothing to do"
	exit 0
fi

mkdir -p "$images_dir"

read_args_file() {
	local args_file="$1"
	[[ -f "$args_file" ]] || return 0
	local line stripped
	while IFS= read -r line || [[ -n "$line" ]]; do
		stripped="${line%%#*}"
		stripped="${stripped#"${stripped%%[![:space:]]*}"}"
		stripped="${stripped%"${stripped##*[![:space:]]}"}"
		[[ -z "$stripped" ]] && continue
		printf '%s\n' "$stripped"
	done <"$args_file"
}

cleanup_render_artefacts() {
	local name="$1"
	rm -f "$examples_dir/$name.pdf" "$examples_dir/$name.typ"
	rm -rf "$examples_dir/${name}_files"
	shopt -s nullglob
	local leftover_png=("$examples_dir/$name"-*.png)
	shopt -u nullglob
	if ((${#leftover_png[@]} > 0)); then
		rm -f "${leftover_png[@]}"
	fi
}

process_qmd() (
	set -e
	local qmd="$1"
	local name
	name="$(basename "$qmd" .qmd)"

	local args_file
	args_file="$(dirname "$qmd")/$name.args"
	local -a render_args=()
	if [[ -f "$args_file" ]]; then
		local tokens
		tokens="$(read_args_file "$args_file" | tr '\n' ' ')"
		# shellcheck disable=SC2206
		render_args=($tokens)
	fi

	if ((${#render_args[@]} > 0)); then
		echo ">> rendering $name.qmd (${render_args[*]})"
	else
		echo ">> rendering $name.qmd"
	fi
	(cd "$examples_dir" && "${quarto_cmd[@]}" render "$name.qmd" "${render_args[@]}" >/dev/null)

	local typ_file="$examples_dir/$name.typ"
	if [[ ! -f "$typ_file" ]]; then
		echo "error: no intermediate $name.typ produced (keep-typ: true missing?)" >&2
		return 1
	fi

	echo ">> compiling $name.typ to PNG at ${ppi} ppi"
	typst compile "$typ_file" "$examples_dir/$name-{n}.png" --ppi "$ppi"

	shopt -s nullglob
	local pngs=("$examples_dir/$name"-*.png)
	shopt -u nullglob

	if ((${#pngs[@]} == 0)); then
		echo "error: typst produced no PNG for $name" >&2
		return 1
	elif ((${#pngs[@]} == 1)); then
		local dest="$images_dir/quarto-$name.png"
		mv "${pngs[0]}" "$dest"
		echo "   -> $dest"
	else
		local png page dest
		for png in "${pngs[@]}"; do
			page="${png##*-}"
			page="${page%.png}"
			dest="$images_dir/quarto-$name-page-$page.png"
			mv "$png" "$dest"
			echo "   -> $dest"
		done
	fi
)

failed=()
for qmd in "${qmd_files[@]}"; do
	name="$(basename "$qmd" .qmd)"
	cleanup_render_artefacts "$name"
	if ! process_qmd "$qmd"; then
		failed+=("$(basename "$qmd")")
	fi
	cleanup_render_artefacts "$name"
done

if ((${#failed[@]} > 0)); then
	echo >&2
	echo "failed: ${failed[*]}" >&2
	exit 1
fi

echo "done"
