#!/bin/bash

set -e
set -o pipefail
set -u

finalize() {
	set +e
	docker stop gentoo portage
	docker rm portage
	docker volume prune --force
}

trap finalize EXIT
trap exit ERR

readonly nproc=$(nproc)
readonly emerge="emerge --quiet=y --jobs=$nproc --load-average=$nproc"

readonly hardware=$(cat << END
virtual/linux-sources
sys-firmware/intel-microcode
net-wireless/broadcom-sta
sys-apps/usbutils
media-sound/alsa-utils
END
)

readonly desktop=$(cat << END
${hardware}
media-libs/vulkan-loader
app-arch/lzop
END
)

docker create -v /usr/portage --name portage gentoo/portage
docker run --rm --volumes-from portage --name gentoo -itd gentoo/stage3-amd64 /bin/bash

docker exec gentoo /bin/bash -c 'mv /etc/portage/make.conf /etc/portage/make.conf_old'
docker exec gentoo /bin/bash -c 'echo "dev-vcs/git -curl -pcre -perl -webdav" > /etc/portage/package.use/git'
docker exec gentoo ${emerge} layman
docker exec gentoo sed -i 's/check_official : Yes/check_official : No/g' /etc/layman/layman.cfg
docker exec gentoo layman -o https://raw.github.com/dkorotych/dell-vostro-3560/master/repositories.xml -f -a dell-vostro-3560

docker exec gentoo eselect profile set 21
docker exec gentoo /bin/bash -c 'eselect profile show | grep -q dell-vostro-3560:default/linux/amd64/13\.0$'

docker exec gentoo eselect profile set 22
docker exec gentoo /bin/bash -c "eselect profile show | grep -q dell-vostro-3560:default/linux/amd64/13\.0/native$"
docker exec gentoo /bin/bash -c "$emerge --info | grep -q ^CFLAGS=\".*native.*\"$"
docker exec gentoo /bin/bash -c "$emerge --info | grep -q 'VIDEO_CARDS=\"intel i965\"'"

for set in hardware desktop
do
	docker exec gentoo /bin/bash -c "$emerge -pv @dell-vostro-3560-$set > /tmp/$set"
	eval packages=\$${set}
	for package in ${packages}
	do
		docker exec gentoo /bin/bash -c "grep -q '^\[ebuild  N    \] $package' /tmp/$set"
	done
done

exit 0

