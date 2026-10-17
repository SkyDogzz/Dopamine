#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
	cat <<'EOF'
Usage: tools/profile_linux.sh [GodotExecutable] [OutputPath]

Builds the Debug GDExtension, runs CTest, then starts an isolated Survival
profile and writes the interactive capture CSV to OutputPath.
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -gt 2 ]]; then
	usage
	exit 0
fi

repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
project_path="$repository_root/game"
build_path="$repository_root/build/linux-profiling"
godot_input=${1:-${GODOT_EXECUTABLE:-}}
output_input=${2:-docs/qa/data/linux_survival_profile.csv}

if [[ -z "$godot_input" ]]; then
	local_godot="$repository_root/tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"
	if [[ -x "$local_godot" ]]; then
		godot_input=$local_godot
	else
		godot_input=$(command -v godot || command -v godot4 || true)
	fi
fi
if [[ -z "$godot_input" ]]; then
	echo "Godot executable not found; pass it as the first argument or set GODOT_EXECUTABLE." >&2
	exit 2
fi
if [[ "$godot_input" == */* ]]; then
	[[ -x "$godot_input" ]] || { echo "Godot executable is not executable: $godot_input" >&2; exit 2; }
	godot_path=$(cd -- "$(dirname -- "$godot_input")" && pwd)/$(basename -- "$godot_input")
else
	godot_path=$(command -v -- "$godot_input" || true)
	[[ -n "$godot_path" && -x "$godot_path" ]] || { echo "Godot executable not found: $godot_input" >&2; exit 2; }
fi

if [[ "$output_input" == /* ]]; then
	output_path=$output_input
else
	output_path="$repository_root/$output_input"
fi
mkdir -p -- "$(dirname -- "$output_path")"

temporary_profile=$(mktemp -d "${TMPDIR:-/tmp}/dopamine-linux-profile.XXXXXX")
cleanup() {
	find "$temporary_profile" -mindepth 1 -delete
	rmdir "$temporary_profile"
}
trap cleanup EXIT
export XDG_DATA_HOME="$temporary_profile/test-xdg"
export XDG_CONFIG_HOME="$temporary_profile/test-config"
export XDG_CACHE_HOME="$temporary_profile/test-cache"
export XDG_STATE_HOME="$temporary_profile/test-state"

cmake -S "$repository_root" -B "$build_path" \
	-DCMAKE_BUILD_TYPE=Debug \
	-DBUILD_TESTING=ON \
	-DGODOTCPP_TARGET=template_debug \
	-DDOPAMINE_GODOT_EXECUTABLE="$godot_path" \
	-DDOPAMINE_GAME_PROJECT_DIR="$project_path"
cmake --build "$build_path" --parallel "${DOPAMINE_BUILD_JOBS:-4}"
ctest --test-dir "$build_path" --output-on-failure -j1

export XDG_DATA_HOME="$temporary_profile/profile-xdg"
export XDG_CONFIG_HOME="$temporary_profile/profile-config"
export XDG_CACHE_HOME="$temporary_profile/profile-cache"
export XDG_STATE_HOME="$temporary_profile/profile-state"
printf 'Starting the isolated project. Play a temporary Survival run at speed ×1, then close the game.\nCSV: %s\n' "$output_path"
"$godot_path" --path "$project_path" -- "--profile-output=$output_path"

if [[ ! -s "$output_path" ]] || [[ $(wc -l < "$output_path") -lt 2 ]] || ! head -n 1 "$output_path" | grep -q '^elapsed_s,os,cpu,gpu,'; then
	echo "Godot did not produce a profiling CSV with at least one sample: $output_path" >&2
	exit 1
fi
printf 'Profile capture complete: %s\n' "$output_path"
