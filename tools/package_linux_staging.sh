#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
commit="$(git -C "$repo_root" rev-parse HEAD)"
short_commit="${commit:0:7}"
godot="${GODOT_EXECUTABLE:-}"

if [[ -z "$godot" ]]; then
	for candidate in godot godot4; do
		if command -v "$candidate" >/dev/null 2>&1; then
			godot="$(command -v "$candidate")"
			break
		fi
	done
fi
if [[ -z "$godot" && -x "$repo_root/tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64" ]]; then
	godot="$repo_root/tools/local/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"
fi
if [[ -z "$godot" || ! -x "$godot" ]]; then
	echo "Set GODOT_EXECUTABLE to a Godot 4.7.2 executable." >&2
	exit 1
fi
if [[ "$(uname -s) $(uname -m)" != "Linux x86_64" ]]; then
	echo "This staging script targets Linux x86_64." >&2
	exit 1
fi
godot_version="$("$godot" --version)"
if [[ "$godot_version" != 4.7.2* ]]; then
	echo "Godot 4.7.2 is required: $godot" >&2
	exit 1
fi

tmp_dir="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/dopamine-linux-staging.XXXXXX")" && pwd -P)"
trap 'rm -rf "$tmp_dir"' EXIT
source_dir="$tmp_dir/source"
build_dir="$tmp_dir/cmake-release"
export_dir="$tmp_dir/export"
package_dir="$tmp_dir/package"
verify_dir="$tmp_dir/verify"
mkdir -p "$source_dir" "$export_dir"
git -C "$repo_root" archive "$commit" | tar -x -C "$source_dir"

cmake -S "$source_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DGODOTCPP_TARGET=template_release
cmake --build "$build_dir" --parallel "${BUILD_JOBS:-4}"

release_extension="$source_dir/game/bin/linux/libdopamine.linux.template_release.x86_64.so"
cp "$release_extension" "$source_dir/game/bin/linux/libdopamine.linux.template_debug.x86_64.so"
"$godot" --headless --editor --path "$source_dir/game" --quit
export_log="$tmp_dir/export.log"
"$godot" --headless --path "$source_dir/game" --export-release "Linux/X11" \
	"$export_dir/DopamineSurvivor.x86_64" >"$export_log" 2>&1

for required_path in 'res://scenes/' 'res://scripts/' 'res://data/' 'res://assets/sprites/' 'res://assets/fonts/' 'res://assets/audio/'; do
	if ! grep -Fq "$required_path" "$export_log"; then
		echo "Export did not include expected resources: $required_path" >&2
		exit 1
	fi
done
if grep -Eq 'res://(tests|tools|assets/source)/' "$export_log"; then
	echo "Export contains development-only resources." >&2
	exit 1
fi

mkdir -p "$package_dir/docs/release/licenses"
cp "$export_dir/DopamineSurvivor.x86_64" "$package_dir/"
cp "$export_dir/libdopamine.linux.template_release.x86_64.so" "$package_dir/"
cp "$source_dir/THIRD_PARTY_NOTICES.md" "$package_dir/"
cp "$source_dir/docs/release/licenses/godot-4.7.2-copyright-info.json" \
	"$source_dir/docs/release/licenses/godot-4.7.2-license-info.json" \
	"$package_dir/docs/release/licenses/"
cat >"$package_dir/README.txt" <<EOF
DOPAMINE SURVIVOR — LINUX VALIDATION STAGING

This is a non-versioned validation package. It is not a release and is not
for distribution. The game version remains unassigned.

Source commit: $commit
Platform: Linux x86_64
Godot: $godot_version
Native toolchain: $(c++ --version | sed -n '1p'), $(cmake --version | sed -n '1p')
Native dependency: godot-cpp b8530af7546a3fcae80cef2477526569fd42ffc2

Keep the GDExtension next to the executable. Third-party notices are in
THIRD_PARTY_NOTICES.md; referenced Godot license data is included at the
paths used by that notice. Runtime fonts are original repository assets.

Launch with ./DopamineSurvivor.x86_64.
Godot user:// data is stored under app_userdata beneath XDG_DATA_HOME,
or the platform default when XDG_DATA_HOME is unset.
EOF

source_date_epoch="$(git -C "$repo_root" show -s --format=%ct "$commit")"
artifact_name="DopamineSurvivor-linux-${short_commit}-staging.tar.gz"
output_dir="$repo_root/build/linux/staging"
mkdir -p "$output_dir"
tar --sort=name --mtime="@$source_date_epoch" --owner=0 --group=0 --numeric-owner \
	-cf - -C "$package_dir" . | gzip -n >"$output_dir/$artifact_name"

mkdir -p "$verify_dir"
tar -xzf "$output_dir/$artifact_name" -C "$verify_dir"
for required_file in \
	'DopamineSurvivor.x86_64' \
	'libdopamine.linux.template_release.x86_64.so' \
	'THIRD_PARTY_NOTICES.md' \
	'docs/release/licenses/godot-4.7.2-copyright-info.json' \
	'docs/release/licenses/godot-4.7.2-license-info.json' \
	'README.txt'; do
	if [[ ! -f "$verify_dir/$required_file" ]]; then
		echo "The extracted staging package is missing: $required_file" >&2
		exit 1
	fi
done
package_file_list="$tmp_dir/package-files.txt"
tar -tzf "$output_dir/$artifact_name" >"$package_file_list"
if grep -Eq '(^|/)(tests|tools|assets/source)/' "$package_file_list"; then
	echo "The staging archive contains development-only files." >&2
	exit 1
fi
ldd "$verify_dir/DopamineSurvivor.x86_64" "$verify_dir/libdopamine.linux.template_release.x86_64.so" >"$tmp_dir/ldd.log"
if grep -q 'not found' "$tmp_dir/ldd.log"; then
	echo "The staged binaries have unresolved shared-library dependencies." >&2
	exit 1
fi
run_log="$tmp_dir/run.log"
loader_log="$tmp_dir/loader.log"
(
	cd "$verify_dir"
	XDG_DATA_HOME="$tmp_dir/user-data" LD_DEBUG=files ./DopamineSurvivor.x86_64 \
		--headless --audio-driver Dummy --quit-after 3 >"$run_log" 2>"$loader_log"
)
if ! grep -Fq "$verify_dir/libdopamine.linux.template_release.x86_64.so" "$loader_log"; then
	echo "The staged game did not load its adjacent Release GDExtension." >&2
	exit 1
fi
if grep -q '^ERROR:' "$run_log"; then
	cat "$run_log" >&2
	exit 1
fi

(
	cd "$output_dir"
	sha256sum "$artifact_name" >"$artifact_name.sha256"
)
echo "Staging artifact: $output_dir/$artifact_name"
cat "$output_dir/$artifact_name.sha256"
