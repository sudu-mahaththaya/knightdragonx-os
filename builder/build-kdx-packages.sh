#!/bin/bash
# Build KDX packages from mounted source (/kdx-source + /kdx-pkgs)
# and place the resulting .pkg.tar.zst files in the offline mirror.

set -e

offline_mirror_dir="$1"
if [[ -z $offline_mirror_dir ]]; then
  echo "Usage: build-kdx-packages.sh <offline-mirror-dir>" >&2
  exit 1
fi

if [[ ! -d /kdx-source ]]; then
  echo "ERROR: /kdx-source not mounted (pass --local-source)" >&2
  exit 1
fi
if [[ ! -d /kdx-pkgs ]]; then
  echo "ERROR: /kdx-pkgs not mounted (pass --local-source)" >&2
  exit 1
fi

work_dir=/tmp/kdx-pkg-build
rm -rf "$work_dir"
mkdir -p "$work_dir"

if ! id builder &>/dev/null; then
  useradd -m -s /bin/bash builder
fi
# Parallel compression for the package archives; the defaults are single-threaded.
cat > /home/builder/.makepkg.conf <<'CONF'
COMPRESSXZ=(xz -c -z -T0 -)
COMPRESSZST=(zstd -c -z -q -T0 -)
CONF
chown builder:builder /home/builder/.makepkg.conf
echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/99-kdx-pkg-builder
chmod 440 /etc/sudoers.d/99-kdx-pkg-builder
chown builder:builder "$work_dir"

pacman -Sy --noconfirm

: "${KDX_RUNTIME_PACKAGE:=kdx-dev}"
: "${KDX_SETTINGS_PACKAGE:=kdx-settings-dev}"
: "${KDX_NVIM_PACKAGE:=kdx-nvim}"

packages=(
  "$KDX_SETTINGS_PACKAGE"
  "$KDX_RUNTIME_PACKAGE"
  "$KDX_NVIM_PACKAGE"
)

# Local-source packages must replace every cached build of the same package,
# even when the checkout's generated pkgver sorts below a published build.
# Otherwise the later generic cache pruning can silently keep edge instead.
for pkg in "${packages[@]}"; do
  rm -f "$offline_mirror_dir/$pkg-"*.pkg.tar.*
done

for pkg in "${packages[@]}"; do
  echo "----------------------------------------"
  echo "Building $pkg"
  echo "----------------------------------------"
  pkg_work="$work_dir/$pkg"
  if [[ ! -d "/kdx-pkgs/pkgbuilds/$pkg" ]]; then
    echo "ERROR: package source not found: /kdx-pkgs/pkgbuilds/$pkg" >&2
    exit 1
  fi
  cp -a "/kdx-pkgs/pkgbuilds/$pkg" "$pkg_work"
  chown -R builder:builder "$pkg_work"

  # The container's makepkg.conf compresses single-threaded and makes with one
  # job; use every core of the build host for both. su resets the environment,
  # so the source path is passed explicitly.
  su builder -c "
    cd '$pkg_work' &&
    PKGDEST='$work_dir' \
    KDX_SRC=/kdx-source \
    MAKEFLAGS='-j$(nproc)' \
    makepkg --noconfirm --skippgpcheck --skipchecksums --nodeps -f
  "
done

mkdir -p "$offline_mirror_dir"
# Arch Linux ARM's makepkg.conf still produces .pkg.tar.xz, so match every
# archive extension rather than assuming zstd.
shopt -s nullglob
package_files=("$work_dir"/*.pkg.tar.*)
shopt -u nullglob
if (( ${#package_files[@]} == 0 )); then
  echo "ERROR: makepkg produced no package archives in $work_dir" >&2
  exit 1
fi
for package_file in "${package_files[@]}"; do
  [[ $package_file == *.sig ]] && continue
  destination="$offline_mirror_dir/$(basename "$package_file")"

  # A cached signature belongs to the previously downloaded or locally built
  # package. Keeping it beside a newly built package makes pacman reject the
  # otherwise valid local-source build.
  rm -f "$destination" "$destination.sig"
  mv "$package_file" "$destination"
done

echo
echo "Built KDX packages, placed in $offline_mirror_dir:"
ls "$offline_mirror_dir"/kdx*.pkg.tar.* | grep -v '\.sig$' | sed 's|^|  |'
