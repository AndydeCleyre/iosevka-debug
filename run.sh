#!/bin/sh -e

# -- create and update build ctnr from official repos --
buildah from --name ctnr docker.io/library/archlinux:base-devel
buildah copy ctnr 'https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on' /tmp/mirrorlist
buildah run ctnr sh -c "sed 's/^#Server =/Server =/g' /tmp/mirrorlist | shuf >/etc/pacman.d/mirrorlist"
buildah run ctnr chmod 0644 /etc/pacman.d/mirrorlist
buildah run ctnr pacman --noconfirm -Syu
buildah run ctnr pacman --noconfirm -S --needed git

# -- add non-root user to build ctnr --
buildah run ctnr useradd -m dev
buildah run ctnr sh -c 'printf "%s\n" "dev ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers.d/dev'

# -- build and install AUR dep ttfautohint --
buildah config -u dev ctnr
buildah run ctnr gpg --keyserver keyserver.ubuntu.com --recv-keys 58E0C111E39F5408C5D3EC76C1A60EACE707FDA5
buildah run ctnr git clone https://aur.archlinux.org/ttfautohint /home/dev/ttfautohint
buildah run --workingdir /home/dev/ttfautohint ctnr makepkg --noconfirm -si

# -- copy ttf-iosevka-term-custom-git PKGBUILD into build ctnr --
buildah copy --chown dev ctnr ttf-iosevka-term-custom-git /home/dev/ttf-iosevka-term-custom-git
buildah config --workingdir /home/dev/ttf-iosevka-term-custom-git ctnr

# -- build and siphon ttf-iosevka-term-custom-git from build ctnr --
buildah run ctnr makepkg --noconfirm -s
pkg="$(buildah run ctnr sh -c "printf '%s\n' *.pkg.*")"
tmp="$(mktemp -d)"
mkdir -p "${tmp}/dist"
buildah run ctnr cat "$pkg" >"${tmp}/dist/${pkg}"
printf '%s\n' "${tmp}/dist/"
ls -lh "${tmp}/dist/"
tar tf "${tmp}/dist/${pkg}" | grep 'ttf$'
