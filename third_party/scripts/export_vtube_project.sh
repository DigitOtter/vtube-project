#!/bin/bash

pushd ..

EXPORT_DIR="./bin"
TSV_LIB_DIR="third_party/install/texture_share_vk/lib"

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$TSV_LIB_DIR"

if [ "$1" != "-t" ]
then
    # Copy tsv libraries to export directory
    cp "$TSV_LIB_DIR"/*.so "$EXPORT_DIR"
fi

# Export project
LD_LIBRARY_PATH=$LD_LIBRARY_PATH ./third_party/godot/bin/godot.linuxbsd.editor.x86_64 --export-release "Linux Export" "$EXPORT_DIR/vtube_project.x86_64"

popd
