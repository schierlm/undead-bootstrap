#!/bin/sh -e
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2022 Michael Schierl <schierlm@gmx.de>
#
[ -d live-bootstrap/sysa/stage0-posix/src/bootstrap-seeds/POSIX/x86 ] || (git submodule init; git submodule update --init --recursive)
rm -rf repo
mkdir -p repo steparchive
cd repo
STEP=$1
while [ "$STEP" -gt 1 ]; do
	STEP=$((STEP-1))
	if ! [ -f ../steparchive/step${STEP}-packages.tar.xz ]; then
		wget -P ../steparchive -nc "https://github.com/schierlm/undead-bootstrap/releases/download/step${STEP}/step${STEP}-packages.tar.xz"
	fi
	tar xfvJ ../steparchive/step${STEP}-packages.tar.xz
done
rm -f tar-1.34_0.tar.bz2 # force rebuilding tar every time
cd ../live-bootstrap
git clean -fdx
git restore --staged --worktree :/
patch -p0 -i ../zombify.patch
STEP=$1
if [ "${STEP}" -eq 1 ]; then
	./rootfs.py --chroot --preserve --external-sources --repo ../repo
	tar cfvJ ../steparchive/distfiles.tar.xz sysa/distfiles sysc/tmp/distfiles
	cd tmp
	mkdir -p usr/src/repo
	tar cfvJ initial-package.tar.xz sysa/bootstrap.cfg tmp usr x86/artifact x86/bin
	mv initial-package.tar.xz usr/src/repo/initial-package.tar.xz
	cd ..
else
	if ! [ -f ../steparchive/distfiles.tar.xz ]; then
		wget -P ../steparchive -nc "https://github.com/schierlm/undead-bootstrap/releases/download/step1/distfiles.tar.xz"
	fi
	mkdir -p tmp sysc/tmp
	mount -t tmpfs tmpfs tmp -o size=8G
	mount -t tmpfs tmpfs sysc/tmp -o size=8G
	tar xfvJ ../steparchive/distfiles.tar.xz
	cd tmp
	mkdir -p usr/src/repo-preseeded
	cp ../../repo/* usr/src/repo-preseeded
	cp -ar ../sysa/stage0-posix/src/* .
	cp -ar ../sysa ../sysb ../sysc .
	cp sysa/stage0-posix/src/bootstrap-seeds/POSIX/x86/kaem-optional-seed init
	cp sysa/after.kaem after.kaem
	echo '#!/bin/bash' >sysc/after.sh
	chmod a+x sysc/after.sh
	mkdir sysc_image
	mv sysc/tmp/distfiles sysc_image/distfiles
	tar xfvJ ../../repo/initial-package.tar.xz
	mkdir bin
	ln -s /usr/bin/bash bin/sh
	echo "export STEPNUMBER=${STEP}" > ./stepnumber.sh
	env - PATH=/bin $(which chroot) . /usr/bin/bash /sysa/rerun.kaem
	cd ..
fi
[ -d tmp/sysc_image/usr/src/repo ] && mv tmp/sysc_image/usr/src/repo tmp/usr/src
cd tmp/usr/src/repo
tar cfvJ ../../../../../steparchive/step${STEP}-packages.tar.xz .
cd ../../../..
umount tmp/sysc_image/proc || true
umount tmp/sysc_image/sys || true
umount sysc/tmp || true
umount tmp || true
cd ..
