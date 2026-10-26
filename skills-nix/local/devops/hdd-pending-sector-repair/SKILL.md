---
name: hdd-pending-sector-repair
description: "Diagnose and repair HDD Current_Pending_Sector issues: locate failing LBA via SMART self-test log, map it through partition/md/LVM/ext4 layers to the owning file, then trigger remapping by overwriting in place via the filesystem path. Includes the LBA translation formulas, debugfs icheck/ncheck workflow, and verification loop."
tags: [hdd, smart, bad-sector, pending-sector, ext4, mdadm, lvm, repair]
---

# HDD Pending Sector Diagnosis & Repair

When SMART reports `Current_Pending_Sector > 0` on a hard drive. Goal: find which file owns each bad sector, overwrite it to make the drive firmware remap or refresh the medium, and iterate until self-test passes clean.

## Safety Rules

- **Never** `dd` directly to a raw block device (`/dev/sdX`) from Hermes — the safety layer hard-blocks it unconditionally. Always write through the filesystem path (a regular file), which lands on the same physical sectors.
- Confirm with the user that the affected file's data is expendable BEFORE overwriting. Repair destroys 4KB at each bad location (leaves a zero hole in the file).
- All diagnosis steps are read-only; only the final overwrite writes.

## Phase 1: Map the Stack

Identify the physical disk behind the failing volume (order: mount → LV → VG/PV → md → partition → disk):

```
findmnt /volX
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
sudo mdadm --detail /dev/mdX
sudo pvs -o +pe_start --units s; sudo lvs --units s; sudo dmsetup table
cat /sys/block/sdX/sdXN/start          # partition start (sectors)
sudo mdadm -E /dev/sdXN | grep -i 'Data Offset'   # md data offset (sectors)
```

Record the per-layer offsets; they feed the LBA translation below.

## Phase 2: Get Failing LBAs from SMART

```
sudo smartctl -a /dev/sdX | grep -E '^  5 |^196|^197|^198'
sudo smartctl -l selftest /dev/sdX
```

The self-test log gives `LBA_of_first_error`. Note: a self-test reports only the FIRST error — after fixing it, rerun the test to surface the next one. Expect to iterate.

If no recent failing LBA, start one short test (`sudo smartctl -t short /dev/sdX`), wait its polling time, read the log.

## Phase 3: Translate LBA → ext4 Block

The failing LBA is a **disk** sector number. Translate to the ext4 filesystem block of the LV:

```
fs_sector = disk_LBA - partition_start - md_data_offset   # if md present
ext4_block = fs_sector / 8 + lvm_pe_start / 8             # 512B sectors → 4K blocks, assumes 512e disk
```

Example (512e disk, partition start 2048, md data offset 264192, LVM pe_start 2048): base = 2048+264192+2048 = 268288 → `ext4_block = (LBA - 268288) / 8`.

Cross-check: bad LBAs usually sit on 4096-byte physical boundaries (`LBA mod 8 == 0`).

## Phase 4: Find the Owning File

```
sudo debugfs -R "icheck <ext4_block>" /dev/mapper/<LV>     # NOTE: no angle brackets, just the number
sudo debugfs -R "ncheck <inode>" /dev/mapper/<LV>
```

Pitfall: `icheck`/`ncheck` take **bare numbers**, not `<n>` syntax — angle brackets are inode-open syntax elsewhere in debugfs.

If icheck returns no inode, the block is free space → repair by writing the raw disk block (user terminal only) or just leave it; the next filesystem write there remaps it.

## Phase 5: Compute In-File Offset & Overwrite

Get the file's extent map and find which extent contains the ext4 block (filefrag's physical column). Then:

```
in_file_logical_block = extent_logical_start + (ext4_block - extent_phys_start)
sudo dd if=/dev/zero of='<file>' bs=4096 seek=<in_file_logical_block> count=1 conv=notrunc
sync
```

Parsing filefrag: columns are `ext: logical_start..logical_end: phys_start..phys_end: length:` — beware variable whitespace between `N..` and the numbers; a regex like `\s*\d+:\s*(\d+)\.\.\s*(\d+):\s*(\d+)\.\.\s*(\d+):` works.

Optional pre-check (read current content, for the record): disk 4K block = `LBA / 8`; `sudo dd if=/dev/sdX bs=4096 skip=<block> count=1 iflag=direct | md5sum`.

## Phase 6: Verify & Iterate

```
sudo dd if=/dev/sdX bs=4096 skip=<block> count=1 iflag=direct 2>/dev/null | md5sum
sudo smartctl -A /dev/sdX | grep -E '^  5 |^196|^197'
```

MD5 cheat sheet:
- `620f0b67a91f7f74151bc5be745b7110` = 4096 zero bytes → **write landed** ✓
- `d41d8cd98f00b204e9800998ecf8427e` = empty input → **read failed** (sector unreadable)
- anything else = old/uncertain content

SMART counters update **lazily**: pending may stay unchanged right after the write. Run a short self-test to force re-evaluation; it often also reveals the NEXT bad LBA. Loop phases 3–6 until `Current_Pending_Sector = 0` and a short test completes without error.

Outcome variants: most drives either remap (`Reallocated_Sector_Ct` +1) or rewrite in place (counters stay 0 — best case, no spare consumed).

## Wrap-Up

- Report every repaired location (file + in-file byte offset) so the user knows where the zero holes are.
- Recommend `sudo smartctl -t long` (full surface scan; several hours) — short tests only cover part of the platter.
- Multiple bad sectors appearing in quick succession, or rising G-Sense/Reallocated → recommend drive replacement.
- Check RAID redundancy: a single-member RAID1 has none; suggest adding a mirror.
