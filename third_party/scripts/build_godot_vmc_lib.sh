#!/bin/bash

cmake -GNinja -S godot-vmc-lib -B build/godot-vmc-lib -DCMAKE_INSTALL_PREFIX=$PWD/install/godot-vmc-lib/bin -DCMAKE_BUILD_TYPE=Release
cmake --build build/godot-vmc-lib
cmake --install build/godot-vmc-lib

