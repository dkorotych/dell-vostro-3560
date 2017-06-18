#!/bin/bash

set -e
set -o pipefail
set -u
set -x

finalize() {
	set +e
	docker stop gentoo portage
	docker rm gentoo portage
	docker volume rm $(docker volume ls -q)
}

trap finalize EXIT
trap exit ERR

readonly nproc=$(nproc)
readonly emerge="emerge --jobs=$nproc --load-average=$nproc"

readonly hardware=$(cat sets/dell-vostro-3560-hardware)

readonly desktop=$(cat << END
${hardware}
media-libs/vulkan-loader
app-arch/lzop
x11-apps/intel-gpu-tools
END
)

docker create -v /usr/portage --name portage gentoo/portage
docker run --volumes-from portage --name gentoo -itd gentoo/stage3-amd64 /bin/bash

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
	docker exec gentoo /bin/bash -c "$emerge -pv @dell-vostro-3560-$set | tee /tmp/$set"
	eval packages=\$${set}
	for package in ${packages}
	do
		docker exec gentoo /bin/bash -c "grep -qE '^\[ebuild\s+N\s+(~?)\] $package' /tmp/$set"
	done
done

exit 0

