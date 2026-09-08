#!/usr/bin/env bash

set -euo pipefail

ROOT="/home/gerson/web-rad-viewer"
DIST="$ROOT/weasis-distributions"
JDK="/usr/lib/jvm/java-25-openjdk-amd64"

APP_NAME="WebRad Viewer"

NATIVE_ZIP="$DIST/target/native-dist/weasis-native.zip"
NATIVE_DIR="$DIST/target/native-dist/weasis-native"
BIN_DIST="$NATIVE_DIR/bin-dist"
LITE_DIR="$DIST/target/lite-linux"
APP="$LITE_DIR/$APP_NAME/bin/$APP_NAME"

cd "$ROOT"

echo
echo "========================================"
echo "==> WebRad Viewer Lite Build"
echo "========================================"
echo

echo "==> 1. Build Maven"
mvn clean install -DskipTests

echo
echo "==> 2. Build distribution with XZ"
mvn -f "$DIST/pom.xml" \
  clean package \
  -PcompressXZ \
  -DskipTests

echo
echo "==> 3. Build native ZIP"
mvn -f "$DIST/pom.xml" \
  org.apache.maven.plugins:maven-assembly-plugin:single@native \
  -PcompressXZ \
  -DskipTests

echo
echo "==> 4. Validate native ZIP"

if [ ! -f "$NATIVE_ZIP" ]; then
  echo "ERRO: native ZIP não encontrado:"
  echo "$NATIVE_ZIP"
  exit 1
fi

echo
echo "==> 5. Extract native distribution"

rm -rf "$NATIVE_DIR"
mkdir -p "$NATIVE_DIR"

unzip -q \
  "$NATIVE_ZIP" \
  -d "$NATIVE_DIR"

if [ ! -d "$BIN_DIST" ]; then
  echo "ERRO: bin-dist não foi gerado:"
  echo "$BIN_DIST"
  exit 1
fi

echo
echo "==> 6. Validate XZ bundle"

CORE_IMG=$(find "$BIN_DIST/weasis/bundle" \
  -maxdepth 1 \
  -type f \
  -name "weasis-core-img-*.jar.xz" \
  | head -n 1)

if [ -z "$CORE_IMG" ]; then
  echo "ERRO: weasis-core-img .jar.xz não encontrado."
  exit 1
fi

echo "Bundle encontrado:"
echo "$CORE_IMG"

echo
echo "==> 7. Remove previous Lite build"

rm -rf "$LITE_DIR"

echo
echo "==> 8. Build app image"

"$DIST/script/package-weasis.sh" \
  --jdk "$JDK" \
  --input "$BIN_DIST" \
  --output "$LITE_DIR" \
  --no-installer

echo
echo "==> 9. Validate main application"

if [ ! -x "$APP" ]; then
  echo "ERRO: executável principal não encontrado:"
  echo "$APP"
  echo
  echo "Executáveis encontrados:"
  find "$LITE_DIR" \
    -maxdepth 4 \
    -type f \
    -executable \
    | sort
  exit 1
fi

echo
echo "========================================"
echo "==> Build concluído"
echo "========================================"
echo
echo "Executando:"
echo "$APP"
echo

"$APP"