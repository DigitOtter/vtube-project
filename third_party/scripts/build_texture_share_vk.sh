#!/bin/bash

cmake -GNinja -S texture-share-vk -B build/texture_share_vk -DCMAKE_INSTALL_PREFIX=$PWD/install/texture_share_vk -DCMAKE_BUILD_TYPE=Release
cmake --build   build/texture_share_vk
cmake --install build/texture_share_vk --strip
