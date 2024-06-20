#!/bin/bash

TSV_INSTALL_DIR="$PWD/install/texture_share_vk"
TSV_DEPENDENCIES="-DTextureShareVk_ROOT=$TSV_INSTALL_DIR/lib/cmake/TextureShareVk"
LIBRARY_PATH="$TSV_INSTALL_DIR/lib"

INSTALL_DIR="$PWD/install/gd_texture_share_vk"

if [ "$1" = "-t" ]
then
    # Use globally installed texture_share_vk instead of local version
    TSV_DEPENDENCIES=""
    LIBRARY_PATH=""
fi

cmake -GNinja -S gd_texture_share_vk -B build/gd_texture_share_vk -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/bin -DCMAKE_BUILD_TYPE=Release $TSV_DEPENDENCIES
LIBRARY_PATH=$LIBRARY_PATH cmake --build build/gd_texture_share_vk
cmake --install build/gd_texture_share_vk --strip

if [ "$1" != "-t" ]
then
    # Add dependencies to gdextension
    cat scripts/gd_texture_share_deps.txt >> $INSTALL_DIR/bin/gd_texture_share_vk.gdextension
fi
