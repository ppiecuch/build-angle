#!/bin/bash

set -e

command -v "git" >/dev/null 2>&1 || { echo >&2 "'git' is required, but it's not installed.  Aborting."; exit 1; }
command -v "curl" >/dev/null 2>&1 || { echo >&2 "'curl' is required, but it's not installed.  Aborting."; exit 1; }
command -v "unzip" >/dev/null 2>&1 || { echo >&2 "'unzip' is required, but it's not installed.  Aborting."; exit 1; }

# *** download depot_tools ***

export PATH=$PWD/depot_tools:$PATH

if [ ! -d depot_tools ]; then
  mkdir depot_tools
  pushd depot_tools
  curl -LOsf https://storage.googleapis.com/chrome-infra/depot_tools.zip
  unzip depot_tools.zip
  rm depot_tools.zip
  popd
fi


# *** downlaod angle source ***

if [ -d angle.src ]; then
  pushd angle.src
  pushd build
  git reset --hard HEAD
  popd
  git reset --hard HEAD
  popd
else
  git clone --single-branch --no-tags --depth 1 https://chromium.googlesource.com/angle/angle angle.src
  pushd angle.src
  python scripts/bootstrap.py
  popd
fi


# *** build angle ***

pushd angle.src

export DEPOT_TOOLS_WIN_TOOLCHAIN=0
gclient sync
rm -rf out/Release
gn gen out/Release --args="angle_build_all=false is_debug=false angle_has_frame_capture=false angle_enable_gl=false angle_enable_vulkan=false angle_enable_d3d9=false angle_enable_null=false"
git apply -p0 ../angle.patch
autoninja -C out/Release libEGL_static libGLESv2_static libGLESv1_CM angle_shader_translator
popd

# *** prepare output folder ***

mkdir -p angle
mkdir -p angle/bin
mkdir -p angle/lib
mkdir -p angle/include

cp -v angle.src/.git/refs/heads/main angle/commit.txt

cp -v angle.src/out/Release/angle_shader_translator                            angle/bin
find angle.src/out/Release -iname '*.so' -or -iname '*.dylib' -exec cp -v '{}' angle/bin \;
find angle.src/out/Release/obj -iname '*.a' -exec cp -v '{}'                   angle/lib \;

cp -r angle.src/include/KHR   angle/include/KHR
cp -r angle.src/include/EGL   angle/include/EGL
cp -r angle.src/include/GLES  angle/include/GLES
cp -r angle.src/include/GLES2 angle/include/GLES2
cp -r angle.src/include/GLES3 angle/include/GLES3

rm -f angle/include/*.clang-format

# *** done ***
# output is in angle folder

ANGLE_COMMIT=$(cat angle/commit.txt)
BUILD_DATE=$(date +'%Y%m%d%H%M')

rm -f angle-${BUILD_DATE}.zip && zip -ro9 -z angle-${BUILD_DATE}.zip angle <<END
ANGLE - Almost Native Graphics Layer Engine
 Build from commit $ANGLE_COMMIT
 Build date $(date)
 Build host $(uname -a)
.
END

if [ -n "$GITHUB_WORKFLOW" ]; then
  echo "ANGLE_COMMIT=$ANGLE_COMMIT" >> $GITHUB_OUTPUT
  echo "BUILD_DATE=$BUILD_DATE" >> $GITHUB_OUTPUT
fi
