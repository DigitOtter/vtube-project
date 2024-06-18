#!/bin/bash

pushd ..

./third_party/godot/bin/godot.linuxbsd.editor.x86_64 --export-release "Linux Export" "./bin/vtube_project.x86_64"

popd
