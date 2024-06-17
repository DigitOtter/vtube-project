#!/bin/bash

cmake -GNinja -S gd_texture_share_vk -B build/gd_texture_share_vk -DCMAKE_INSTALL_PREFIX=$PWD/install/gd_texture_share_vk/bin -DCMAKE_BUILD_TYPE=Release
cmake --build build/gd_texture_share_vk
cmake --install build/gd_texture_share_vk
