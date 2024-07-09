#!/bin/bash

# Build godot
scripts/build_godot.sh "$@"

# Build VMC lib
scripts/build_godot_vmc_lib.sh "$@"

# Build texture sharing lib
if [ "$1" != "-t" ]
then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" "$@"
    scripts/build_texture_share_vk.sh "$@"
fi

# Build gd addon for texture sharing
scripts/build_gd_texture_share_vk.sh "$@"

# Guild GDMP
scripts/build_gdmp.sh "$@"
