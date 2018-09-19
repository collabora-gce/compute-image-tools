#!/bin/bash
# Copyright 2014 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# This script requires expect, growisofs and qemu.

set -e
set -u

if [ "$#" -ne 4 ]; then
	echo "Usage: $0 RELEASE_VERSION ARCHITECTURE MIRROR_ADDRESS OUTPUT_FILE"
	exit 1
fi

readonly VERSION=$1
readonly RELNO="${VERSION/./}"

readonly ARCH=$2
readonly MIRROR=$3
readonly OUTPUT_FILE=$4

if [[ "${ARCH}" != "amd64" && "${ARCH}" != "i386" ]]; then
  echo "Architecture must be amd64 or i386"
  exit 1
fi

readonly ISO="install${RELNO}-${ARCH}.iso"
readonly ISO_PATCHED="install${RELNO}-${ARCH}-patched.iso"

# Download ISO file if it is necessary
if [[ ! -f "${ISO}" ]]; then
  curl -o "${ISO}" "https://${MIRROR}/pub/OpenBSD/${VERSION}/${ARCH}/install${RELNO}.iso"
fi

# Clean up after script ends its execution
function cleanup() {
	rm -f "${ISO_PATCHED}"
	rm -f auto_install.conf
	rm -f boot.conf
	rm -f disk.raw
	rm -f disklabel.template
	rm -f etc/{installurl,rc.local}
	rm -f install.site
	rm -f random.seed
	rm -f site${RELNO}.tgz
	rmdir etc
}
trap cleanup EXIT INT

# Create custom siteXX.tgz set.
mkdir -p etc

cat >install.site <<EOF
#!/bin/sh
syspatch
pkg_add -iv bash curl git

echo 'set tty com0' > boot.conf
EOF

cat >etc/installurl <<EOF
https://${MIRROR}/pub/OpenBSD
EOF

cat >etc/rc.local <<EOF
(
  set -x

  echo "Remounting root with softdep,noatime..."
  mount -o softdep,noatime,update /

  echo "Checking network"
  netstat -rn
  cat /etc/resolv.conf
)
EOF

chmod +x install.site
tar -zcvf site${RELNO}.tgz install.site etc/{installurl,rc.local}

# Autoinstall script.
cat >auto_install.conf <<EOF
System hostname = openbsd
Which network interface = vio0
IPv4 address for vio0 = dhcp
IPv6 address for vio0 = none
Password for root account = root
Do you expect to run the X Window System = no
Change the default console to com0 = yes
Which speed should com0 use = 115200
Setup a user = openbsd
Full name for user openbsd = OpenBSD
Password for user openbsd = openbsd
Allow root ssh login = no
What timezone = US/Pacific
Which disk = sd0
Use (W)hole disk or (E)dit the MBR = whole
Use (A)uto layout, (E)dit auto layout, or create (C)ustom layout = auto
URL to autopartitioning template for disklabel = file://disklabel.template
Set name(s) = +* -x* -game* -man* done
Directory does not contain SHA256.sig. Continue without verification = yes
EOF

# Disklabel template.
cat >disklabel.template <<EOF
/	5G-*	95%
swap	1G
EOF

# Hack install CD a bit.
echo 'set tty com0' > boot.conf
dd if=/dev/urandom of=random.seed bs=4096 count=1
cp "${ISO}" "${ISO_PATCHED}"
growisofs -M "${ISO_PATCHED}" -l -R -graft-points \
  /${VERSION}/${ARCH}/site${RELNO}.tgz=site${RELNO}.tgz \
  /auto_install.conf=auto_install.conf \
  /disklabel.template=disklabel.template \
  /etc/boot.conf=boot.conf \
  /etc/random.seed=random.seed

# Initialize disk image.
rm -f disk.raw
qemu-img create -f raw disk.raw 10G

# Run the installer to create the disk image.
expect <<EOF
set timeout 1800

spawn qemu-system-x86_64 -nographic -smp 2 \
  -drive if=virtio,file=disk.raw,format=raw -cdrom "${ISO_PATCHED}" \
  -net nic,model=virtio -net user -boot once=d

expect timeout { exit 1 } "boot>"
send "\n"

# Need to wait for the kernel to boot.
expect timeout { exit 1 } "\(I\)nstall, \(U\)pgrade, \(A\)utoinstall or \(S\)hell\?"
send "s\n"

expect timeout { exit 1 } "# "
send "mount /dev/cd0c /mnt\n"
send "cp /mnt/auto_install.conf /mnt/disklabel.template /\n"
send "chmod a+r /disklabel.template\n"
send "umount /mnt\n"
send "exit\n"

expect timeout { exit 1 } "\(I\)nstall, \(U\)pgrade, \(A\)utoinstall or \(S\)hell\?"
send "a\n"

expect timeout { exit 1 } "CONGRATULATIONS!"
send "\x01"; send "x\n"
close
EOF

# Create Compute Engine disk image.
echo "Archiving disk.raw... (this may take a while)"
tar -Szcf "${OUTPUT_FILE}" disk.raw

echo "Done. GCE image is ${OUTPUT_FILE}."
