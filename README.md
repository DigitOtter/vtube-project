# VtubeProject

# Available Features

## Model loading

- Models can be loaded from the `Model Control` tab in the configuration menu
- VtubeProject can currently only load `.vrm` files

## Trackers

- Trackers can be started from the configuration menu using the `Trackers` tab in the configuration menu
- Available trackers:
  - `MediaPipe`: Uses local camera to detect and track a person
  - `VmcReceiver`: Starts a VMC server and waits for external tracker. Can be used with VSeeFace

## Ascii Shader

- Enable Ascii shader from the `Ascii Shader` tab in the configuration menu

## External Lighting

- Enable external lighting using the `External Lighting` tab in the configuration menu
- NOTE: Only works if there's a different program sending a lighting texture with [texture-share-vk](https://github.com/DigitOtter/texture-share-vk)
- The sending texture must be called `obs_shared`

# Keybindings

- `Ctrl-e` to open configuration menu

## Camera Control
- `<Middle Mouse>` to move camera
- `<Scroll Wheel` zoom in/out

## Props Control
- In configuration menu, use `Props` menu to select prop to load
- `Ctrl-Alt-<Right Mouse>` to add prop at mouse position
- `<Left Mouse>` on prop to select it
- `Alt-<Mouse Wheel>` to increase/decrease prop size
- `Ctrl-Alt-<Left Mouse>` to move prop and attach it to avatar at mouse position
- `Ctrl-Alt-Shift-<Left Mouse>` to move prop without changing attachment point
- `Ctrl-<Mouse Wheel>` to move prop away from/to attachment point

# Build

## Required Dependencies

- `Godot` dependencies can be found here: [https://docs.godotengine.org/en/4.2/contributing/development/compiling/compiling_for_linuxbsd.html#requirements]()
- `GDMP` dependencies: `OpenCV`, `FFMPEG`
- `texture-share-vk` dependencies: `boost`

For Archlinux:
``` sh
sudo pacman -S \
    scons \
    pkgconf \
    gcc \
    libxcursor \
    libxinerama \
    libxi \
    libxrandr \
    mesa \
    glu \
    libglvnd \
    alsa-lib \
    pulseaudio \
    opencv \
    boost
```

## Build instructions

- Download all submodules:
``` sh
git submodule update --init --recursive --depth=1
```

- Compile all dependencies:
``` sh
./CI/build_dependencies.sh
```

- Export `vtube_project`:

``` sh
./CI/build_executable.sh
```

- The program should be installed in the `bin` directory and can be launched using `./bin/vtube_project.sh`
