#!/bin/bash

BUILD_DIR="$PWD/build/gdmp"
INSTALL_DIR="$PWD/install/gdmp"

pushd GDMP

mkdir -p "$BUILD_DIR"

# Setup opencv
pushd mediapipe
git apply ../opencv_path.patch
popd

# Setup compilation
python setup.py

python -m venv venv

# Build
source "venv/bin/activate"
python build.py --type release desktop --output "$BUILD_DIR"
deactivate

# Setup godot addons dir
mkdir -p "$INSTALL_DIR"
cp -r addons/GDMP/* "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR/libs/x86_64"
cp "$BUILD_DIR/libGDMP.linux.so" "$INSTALL_DIR/libs/x86_64/libGDMP.linux.so"

popd
