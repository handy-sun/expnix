# Essential btrfs Commands

Quick reference for btrfs subvolume management, snapshots, and maintenance.

## Subvolume management
```bash
btrfs subvolume create /mnt/@new       # create subvolume
btrfs subvolume list /mnt              # list all subvolumes
btrfs subvolume delete /mnt/@old       # delete subvolume
btrfs subvolume show /mnt/@            # show details (UUID, path)
```

## Snapshots (COW — instant, zero extra space until data diverges)
```bash
btrfs subvolume snapshot /mnt/@ /mnt/@snapshots/@-2026-05-03        # read-write
btrfs subvolume snapshot -r /mnt/@ /mnt/@snapshots/@-readonly       # read-only
```

## Filesystem info
```bash
btrfs filesystem usage /mnt            # disk usage overview (most useful)
btrfs filesystem df /mnt               # allocation type breakdown
btrfs device usage /mnt                # per-device usage
```

Note: `df -h` and `btrfs filesystem usage` will show different numbers. This is normal — btrfs reserves space for metadata/COW that `df` doesn't account for.

## Space reclamation
```bash
btrfs filesystem defragment -r /mnt    # defragment (careful with compressed volumes)
btrfs balance start /mnt               # rebalance data blocks
btrfs balance start -dusage=50 /mnt    # only balance blocks with <50% usage
```

## Compression
```bash
btrfs filesystem defragment -r -czstd /mnt   # compress existing data with zstd
# New data auto-compresses if mount option has compress=zstd
```

## Scrub (data integrity verification — run monthly)
```bash
btrfs scrub start /mnt                 # verify all data checksums
btrfs scrub status /mnt                # check progress/results
```

## Send/receive (incremental backup)
```bash
btrfs send /mnt/@snapshots/@-2026-05-03 | btrfs receive /backup/
btrfs send -p /mnt/@snapshots/@-old /mnt/@snapshots/@-new | btrfs receive /backup/  # incremental
```

## @ Naming Convention

The `@`, `@home`, `@nix`, `@swap` prefix is a community convention (popularized by Timeshift and snapper). Not required by btrfs — the kernel doesn't treat `@` specially. Common names:
- `@` — root filesystem `/`
- `@home` — `/home`
- `@nix` — `/nix` (NixOS-specific)
- `@log` — `/var/log`
- `@snapshots` — snapshot storage
- `@swap` — swapfile location
