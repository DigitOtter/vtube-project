#!/bin/bash

# Build godot
scripts/build_godot.sh

# Build VMC lib
scripts/build_godot_vmc_lib.sh

# Build texture sharing lib
scripts/build_gd_texture_share_vk.sh

# Guild GDMP
scripts/build_gdmp.sh

