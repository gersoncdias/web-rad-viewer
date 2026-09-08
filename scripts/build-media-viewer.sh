#!/usr/bin/env bash
# Run on the destination OS with JDK 25 and an extracted weasis-native.zip.
set -euo pipefail
input=$(cd "${1:?Usage: build-media-viewer.sh extracted-native output}" && pwd)
mkdir -p "${2:?Output directory required}"
output=$(cd "$2" && pwd)
script_dir=$(cd "$(dirname "$0")/../weasis-distributions/script" && pwd)
case "$(uname -s)/$(uname -m)" in
  MINGW*/x86_64|MSYS*/x86_64) platform=windows; arch=windows-x86-64 ;;
  Darwin/arm64) platform=macosx; arch=macosx-aarch64 ;;
  Darwin/x86_64) platform=macosx; arch=macosx-x86-64 ;;
  *) echo 'Build this package on Windows x64 or macOS (Intel/Apple Silicon).' >&2; exit 1 ;;
esac
source "$script_dir/launch-options.sh" "$platform"
job=$(mktemp -d)
trap 'rm -rf "$job"' EXIT
cp -R "$input/bin-dist/weasis" "$job/payload"
cp "$input/bin-dist/Licence.txt" "$job/payload/Licence.txt"
mkdir -p "$job/payload/licenses"
cp "$script_dir/../.."/LICENSE* "$script_dir/../../3rd-party-licenses.md" "$job/payload/licenses/"
# A fresh private payload is used for each architecture.
find "$job/payload/bundle" -name 'weasis-opencv-core-*' ! -name "*-$arch-*" -delete
icon=()
if [[ $platform == windows ]]; then
  icon=(--icon "$script_dir/resources/windows/Weasis.ico")
elif [[ -f "$script_dir/resources/macosx/Weasis.icns" ]]; then
  icon=(--icon "$script_dir/resources/macosx/Weasis.icns")
fi
version=$(sed -n 's/^weasis.version=//p' "$input/build/script/build.properties" | tr -d '\r')
version=${version%%-*}
version=$(printf '%s' "$version" | cut -d. -f1-3)
[[ -n "$version" ]] || { echo 'Missing application version' >&2; exit 1; }
jpackage --app-version "$version" --type app-image --input "$job/payload" --dest "$job/image" \
  --name 'WebRad Viewer' --main-jar weasis-launcher.jar \
  --main-class org.weasis.launcher.AppLauncher --add-modules "$JDK_MODULES" \
  "${icon[@]}" "${customOptions[@]}" "${commonOptions[@]}"
if [[ $platform == windows ]]; then
  mkdir -p "$job/export/windows-x86-64"
  cp -R "$job/image/WebRad Viewer/." "$job/export/windows-x86-64/"
  python - "$job/export" "$output/windows-x86-64.zip" <<'PY'
import pathlib, sys, zipfile
root = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(sys.argv[2], 'w', zipfile.ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file(): z.write(p, p.relative_to(root))
PY
else
  # Keep the .app opaque on Windows, preserving executable modes and symlinks.
  ditto -c -k --sequesterRsrc --keepParent "$job/image/WebRad Viewer.app" "$output/$arch.zip"
fi
