#!/usr/bin/env bash
# LICENSE BEGIN
#
# Copyright 2017 William A. Havanki, Jr.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# LICENSE END

JAVA_PACKAGE="${JAVA_PACKAGE:-openjdk-8-jdk}"

PACKAGES=(
  bzip2
  curl
  gzip
  unzip
  wget
  xmlstarlet
  zip
)

echo "Updating apt ..."
sudo apt-get update
echo "Upgrading installed packages ..."
#sudo apt-get -y upgrade

echo "Installing packages: ${PACKAGES[*]}"
sudo apt-get -y install "${PACKAGES[@]}"
echo "Installing Java package: $JAVA_PACKAGE"
sudo apt-get -y install "${JAVA_PACKAGE}"
