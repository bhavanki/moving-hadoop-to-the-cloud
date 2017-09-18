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

echo "Creating hadoop group ..."
sudo groupadd hadoop
for u in hdfs yarn; do
  echo "Creating $u user ..."
  sudo useradd -G hadoop -m -s /bin/bash "${u}"
  sudo mkdir "/home/${u}/.ssh"
  sudo cp ~/.ssh/authorized_keys "/home/${u}/.ssh"
  sudo chmod 700 "/home/${u}/.ssh"
  sudo chown -R "${u}" "/home/${u}/.ssh"
done
