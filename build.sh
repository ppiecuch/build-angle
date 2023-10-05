#!/bin/bash

set -e

command -v "git" >/dev/null 2>&1 || { echo >&2 "'git' is required, but it's not installed.  Aborting."; exit 1; }
command -v "curl" >/dev/null 2>&1 || { echo >&2 "'curl' is required, but it's not installed.  Aborting."; exit 1; }
command -v "unzip" >/dev/null 2>&1 || { echo >&2 "'unzip' is required, but it's not installed.  Aborting."; exit 1; }

# *** download depot_tools ***

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
  git pull --force --no-tags --depth 1
  popd
else
  git clone --single-branch --no-tags --depth 1 https://chromium.googlesource.com/angle/angle angle.src
  pushd angle.src
  python scripts/bootstrap.py
  popd
fi
