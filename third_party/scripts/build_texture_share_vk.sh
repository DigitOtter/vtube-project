#!/bin/bash

DOWNLOAD_GLAD_SPECS=""
if [ "$1" == "-l" ]
then
	DOWNLOAD_GLAD_SPECS="-DDOWNLOAD_GLAD_SPECS=OFF"
fi

cmake -GNinja -S texture-share-vk -B build/texture_share_vk -DCMAKE_INSTALL_PREFIX=$PWD/install/texture_share_vk -DCMAKE_BUILD_TYPE=Release $DOWNLOAD_GLAD_SPECS
cmake --build   build/texture_share_vk
cmake --install build/texture_share_vk --strip
