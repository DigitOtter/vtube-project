#!/bin/bash

pushd godot

git apply large_file.patch
git apply modules/gd_module_triangle_ray_select/mesh_storage.patch

scons target=editor           production=yes -j$(nproc)
scons target=template_release production=yes -j$(nproc)

popd

