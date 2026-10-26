# KnightDragonX OS

An Arch-based Linux distribution with Niri, DankLinux, and automatic GPU setup. No bloatware.

**Status: Early development.** Not ready for daily use. Build system and installer are currently being written.

---

## What this is

KDX is a minimal Arch Linux ISO with:

- **Niri** as the Wayland compositor (replacing Hyprland)
- **DankLinux (DMS)** as the desktop shell
- **Automatic GPU detection** for AMD, NVIDIA, and Intel
- **BlackArch repository configured** (no tools installed by default)
- **yay** pre-installed for AUR packages
- **Red/black theme**
- **Offline installation** from a bundled package mirror

Based on the [Omarchy ISO](https://github.com/omacom/omarchy-iso) build system. Omarchy packages and bloatware are completely removed.

---

## Why

I used Omarchy. It worked, but it kept adding things I didn't ask for (AI agents, bloatware). I wanted pure Arch with Niri, zero bloatware, and automatic GPU setup that actually works on hybrid graphics laptops.

This is that.

---

## Requirements

- x86_64 CPU
- 4 GB RAM (8 GB recommended)
- 20 GB disk (40 GB recommended)
- AMD, NVIDIA, or Intel GPU
- UEFI or BIOS

---

## Build from source

### Dependencies

```bash
sudo pacman -S --needed \
  base-devel git archiso \
  docker docker-buildx \
  qemu-full edk2-ovmf \
  jq shellcheck rsync \
  squashfs-tools libisoburn \
  mtools dosfstools gum

sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```

### Build

```bash
git clone https://github.com/sudu-mahaththaya/knightdragonx-os.git
cd knightdragonx-os
./bin/kdx-iso-make
```

Output: `release/kdx-YYYY.MM.DD-x86_64.iso`

Build takes 20–40 minutes. Docker is used to ensure reproducible builds without polluting host dependencies.

### Test

```bash
./bin/kdx-iso-boot release/kdx-*.iso
```

---

## Project structure

```
knightdragonx-os/
├── bin/            # Entry scripts (make, boot, release)
├── builder/        # Build logic (build-iso.sh)
├── configs/        # Real configuration (profiledef.sh, airootfs)
├── manifests/      # Package lists (JSON)
├── test/           # Test scripts
├── LICENSE         # MIT
└── README.md
```

`configs/profiledef.sh` defines ISO name, label, and publisher.  
`configs/airootfs/` contains live system files and custom scripts.  
`manifests/*.json` lists packages installed by default.

---

## Roadmap

- [x] Study Omarchy ISO build system
- [ ] Rebrand build system (`omarchy` → `kdx`)
- [ ] Replace Hyprland with Niri
- [ ] Integrate DankLinux (DMS)
- [ ] Pre-build AUR packages (quickshell, dms-shell, yay)
- [ ] GPU auto-detection script
- [ ] NVIDIA black-screen fixes
- [ ] Session guard (auto-recovery)
- [ ] Red/black theme
- [ ] Arch + BlackArch repos configured
- [ ] First test ISO
- [ ] Physical hardware test (AMD/NVIDIA/Intel)
- [ ] First public release

---

## License

MIT. Based on Omarchy ISO by Anton Hvornum.

Original copyright notices are preserved. See [LICENSE](LICENSE) for details.

---

## Contact

Open an issue: [github.com/sudu-mahaththaya/knightdragonx-os/issues](https://github.com/sudu-mahaththaya/knightdragonx-os/issues)

