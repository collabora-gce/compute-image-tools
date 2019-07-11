#!/bin/sh
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

# Verify DNS connections

# Verify VM to VM DNS connection
getent hosts $INSTANCE

# Raise error if it occurred
[ $? -ne 0 ] && \
 (logger -p daemon.info "DNS_Failed"; echo "DNS_Failed" > /dev/console)

# Verify VM to external DNS connection
getent hosts www.google.com

# Signalize wait-for-instance that instance is ready or error occurred
[ $? -ne 0 ] && \
 (logger -p daemon.info "DNS_Failed"; echo "DNS_Failed" > /dev/console) || \
 (logger -p daemon.info "DNS_Success"; echo "DNS_Success" > /dev/console)
