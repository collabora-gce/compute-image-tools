#!/usr/bin/env python2
# Copyright 2018 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os

import utils


utils.AptGetInstall(['qemu', 'growisofs', 'expect', 'genisoimage'])


def main():
  # Get Parameters.
  version = utils.GetMetadataAttribute('version', raise_on_not_found=True)
  arch = utils.GetMetadataAttribute('arch', raise_on_not_found=True)
  mirror = utils.GetMetadataAttribute('mirror', raise_on_not_found=True)
  image_dest = utils.GetMetadataAttribute(
      'image_dest', raise_on_not_found=True)

  tarball_output = 'openbsd_image.tar.gz'

  os.chmod('builder.sh', 755)
  utils.Execute(['./builder.sh', version, arch, mirror, tarball_output])

  utils.UploadFile(tarball_output, image_dest)


if __name__ == '__main__':
  utils.RunTest(main)
