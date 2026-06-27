# Linux Memory Management: Swap & ZRAM Complete Guide

> A practical guide for developers running heavy workloads on Linux (Fedora / Btrfs)

---

## Table of Contents

1. [How Linux Uses Memory](#1-how-linux-uses-memory)
2. [What is Swap?](#2-what-is-swap)
3. [What is ZRAM?](#3-what-is-zram)
4. [ZRAM vs Swapfile — Key Differences](#4-zram-vs-swapfile--key-differences)
5. [The Hybrid Setup (Best Practice)](#5-the-hybrid-setup-best-practice)
6. [Best Combinations by RAM Size](#6-best-combinations-by-ram-size)
7. [How to Create a Swapfile on Btrfs (Fedora)](#7-how-to-create-a-swapfile-on-btrfs-fedora)
8. [How to Resize the Swapfile](#8-how-to-resize-the-swapfile)
9. [How to Configure ZRAM](#9-how-to-configure-zram)
10. [How to Make Everything Persist After Reboot](#10-how-to-make-everything-persist-after-reboot)
11. [Monitoring Memory & Swap Health](#11-monitoring-memory--swap-health)
12. [SSD Health & Swap Impact](#12-ssd-health--swap-impact)
13. [The Real Ceiling — Know Your Limits](#13-the-real-ceiling--know-your-limits)
14. [Quick Reference Cheat Sheet](#14-quick-reference-cheat-sheet)

---

## 1. How Linux Uses Memory

Linux memory priority order (fastest to slowest):

```
Physical RAM → ZRAM (compressed RAM) → Swapfile/Partition (SSD/HDD)
```

When RAM fills up, Linux doesn't crash immediately. It starts moving **least recently used** pages to swap space. The kernel decides what to move based on a setting called **swappiness**.

### Swappiness

```bash
# Check current swappiness
cat /proc/sys/vm/swappiness
```

- Default: `60` (tends to swap too eagerly)
- Recommended for desktops/dev machines: `10`

```bash
# Set temporarily
sudo sysctl vm.swappiness=10

# Set permanently
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
```

---

## 2. What is Swap?

Swap is **overflow space** for when your physical RAM is full. It can be:

- **Swap Partition** — a dedicated disk partition (old school)
- **Swap File** — a regular file on your filesystem (modern, flexible)

### How a Swapfile Works

```
Your apps need 18GB RAM
You only have 16GB physical RAM
→ Linux pushes 2GB of cold/idle data to swapfile on SSD
→ Apps continue running (slower, but alive)
```

### Swapfile Pros & Cons

| Pros | Cons |
|------|------|
| Easy to resize anytime | Slower than RAM |
| No partition needed | Writes to SSD (wear) |
| Works as emergency buffer | Very slow if constantly hit |
| Prevents OOM crashes | Not a RAM replacement |

---

## 3. What is ZRAM?

ZRAM is a **compressed RAM disk** used as swap. Instead of writing to disk, it compresses idle memory pages and stores them **back in RAM**.

### How ZRAM Works

```
RAM is 90% full
→ ZRAM compresses idle pages at ~2.5:1 ratio
→ 8GB ZRAM can hold ~16-20GB of data
→ System keeps running fast without touching SSD
```

### ZRAM Pros & Cons

| Pros | Cons |
|------|------|
| Extremely fast (RAM speed) | Uses real RAM for itself |
| Protects SSD from wear | Can't exceed physical RAM |
| Great compression ratios | CPU overhead for compression |
| Transparent to apps | Not unlimited capacity |

---

## 4. ZRAM vs Swapfile — Key Differences

| Feature | ZRAM | Swapfile |
|---------|------|----------|
| Location | RAM | SSD/HDD |
| Speed | ~10,000 MB/s | ~500-3000 MB/s |
| SSD wear | None | Yes |
| Capacity limit | Your RAM size | Your disk space |
| Best for | Everyday overflow | Emergency buffer |
| Priority | High (100) | Low (-1 or -2) |

**They are not competitors — they work together.**

---

## 5. The Hybrid Setup (Best Practice)

The optimal modern Linux memory setup:

```
┌─────────────────────────────────────────┐
│           Application Memory            │
├─────────────────────────────────────────┤
│     Physical RAM (fastest, priority 1)  │
├─────────────────────────────────────────┤
│  ZRAM (compressed RAM, priority 2) ←── used first when RAM fills
├─────────────────────────────────────────┤
│  Swapfile on SSD (priority 3) ←─────── last resort
└─────────────────────────────────────────┘
```

- System uses RAM normally
- When RAM fills → ZRAM absorbs overflow (fast, no SSD writes)
- When ZRAM fills → Swapfile catches the rest (slow, SSD writes)
- Result: System stays alive, SSD is protected, performance stays reasonable

---

## 6. Best Combinations by RAM Size

### 8GB RAM
```
ZRAM:     4GB  (ram * 0.5)
Swapfile: 8GB
Total:    ~20GB effective
```

### 16GB RAM ← (Your Setup)
```
ZRAM:     8GB  (ram * 0.5)
Swapfile: 20GB
Total:    ~40GB effective
Best for: 4x VS Code + heavy browser + Next.js dev
```

### 32GB RAM
```
ZRAM:     8GB  (ram * 0.25, diminishing returns above this)
Swapfile: 8GB
Total:    ~48GB effective
Note:     Swap barely needed at this level
```

### 64GB RAM
```
ZRAM:     Optional (maybe 4GB)
Swapfile: 4-8GB (just for safety)
Note:     You're basically free at this point
```

### General Rules
- ZRAM sweet spot: **50% of RAM** (never exceed 75%)
- Swapfile: **1x to 1.5x your RAM** for dev workloads
- Never increase ZRAM if RAM is already tight — it makes things worse

---

## 7. How to Create a Swapfile on Btrfs (Fedora)

> **Important:** Standard `fallocate` swap files don't work on Btrfs. You must disable Copy-on-Write first.

```bash
# Step 1: Create empty file
sudo touch /swapfile

# Step 2: Disable Copy-on-Write (CRITICAL for Btrfs)
sudo chattr +C /swapfile

# Step 3: Allocate size (change 20G to your desired size)
sudo fallocate -l 20G /swapfile

# Step 4: Lock permissions
sudo chmod 600 /swapfile

# Step 5: Format as swap
sudo mkswap /swapfile

# Step 6: Activate
sudo swapon /swapfile

# Step 7: Verify
swapon --show
```

---

## 8. How to Resize the Swapfile

```bash
# Step 1: Turn off swapfile
sudo swapoff /swapfile

# Step 2: Delete old file
sudo rm /swapfile

# Step 3: Recreate with Btrfs-safe method (change 20G to new size)
sudo touch /swapfile
sudo chattr +C /swapfile
sudo fallocate -l 20G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Step 4: Verify
swapon --show
```

> fstab does NOT need to be changed — the path `/swapfile` stays the same.

---

## 9. How to Configure ZRAM

### Check current config

```bash
cat /usr/lib/systemd/zram-generator.conf
# or
cat /etc/systemd/zram-generator.conf
```

### Modify ZRAM size

```bash
sudo nano /etc/systemd/zram-generator.conf
```

```ini
[zram0]
zram-size = ram / 2
# or hardcode:
# zram-size = 8192  (in MB)
```

### Apply changes

```bash
# Reboot is the cleanest way
sudo reboot

# Or manually (risky if RAM is tight):
sudo systemctl stop systemd-zram-setup@zram0
sudo zramctl --reset /dev/zram0
sudo systemctl start systemd-zram-setup@zram0
```

### ZRAM size recommendations

```ini
# Conservative (safe, RAM-friendly)
zram-size = ram / 2

# Moderate (good for dev machines)
zram-size = ram * 0.6

# Aggressive (only if you have headroom)
zram-size = ram * 0.75
```

> **Warning:** Never set ZRAM above 75% of RAM. You'll starve your actual running processes.

---

## 10. How to Make Everything Persist After Reboot

### Swapfile persistence

```bash
# Check if already added
grep swapfile /etc/fstab

# Add if missing
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### ZRAM persistence

ZRAM is handled by `systemd-zram-generator` automatically on Fedora — it persists via the config file at `/etc/systemd/zram-generator.conf`. No fstab entry needed.

### Swappiness persistence

```bash
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
```

---

## 11. Monitoring Memory & Swap Health

### Quick overview

```bash
free -h
```

### Detailed swap info

```bash
swapon --show
```

### What's eating memory

```bash
ps aux --sort=-%mem | head -15
```

### Live memory monitor

```bash
watch -n 2 'free -h && echo "---" && swapon --show'
```

### ZRAM stats

```bash
zramctl
```

### Check if OOM killer fired (process was killed due to memory)

```bash
sudo dmesg | grep -i "oom\|killed process" | tail -20
```

---

## 12. SSD Health & Swap Impact

### Check NVMe SSD health

```bash
sudo dnf install smartmontools -y
sudo smartctl -a /dev/nvme0n1
```

### Key metrics to watch

| Metric | Healthy | Warning |
|--------|---------|---------|
| Percentage Used | < 50% | > 80% |
| Available Spare | 100% | < 20% |
| Critical Warning | 0x00 | anything else |
| Media Errors | 0 | any |
| Temperature | < 60°C | > 80°C |

### How ZRAM protects your SSD

```
Without ZRAM:  Every RAM overflow → SSD write → wear
With ZRAM:     RAM overflow → ZRAM (no SSD write)
               Only ZRAM overflow → SSD write
Result:        SSD writes reduced by ~70-80% in typical dev use
```

---

## 13. The Real Ceiling — Know Your Limits

Swap is **not free memory**. It's a survival mechanism.

```
Physical RAM:    Full speed (DDR4 ~40,000 MB/s)
ZRAM:            Fast (limited by CPU compression ~3,000-8,000 MB/s)
Swapfile (NVMe): Slow (500-3,500 MB/s)
Swapfile (HDD):  Very slow (~100 MB/s) — basically unusable for dev
```

### Signs you're hitting the ceiling

- System feels sluggish/choppy
- Builds take much longer than usual
- Apps freeze momentarily
- `swapon --show` shows swapfile nearly full

### What actually happens at the limit

If all swap fills up → Linux **OOM Killer** activates → randomly kills processes to free memory. It will kill your VS Code, terminals, or Next.js dev server without warning.

### The permanent fix

More physical RAM. For a heavy dev workload (4x VS Code, browsers, multiple Next.js):

- **16GB** — workable with good swap setup
- **32GB** — comfortable, swap rarely needed
- **64GB** — no limits for typical dev work

---

## 14. Quick Reference Cheat Sheet

```bash
# View all swap
swapon --show

# View memory
free -h

# Turn off swapfile temporarily
sudo swapoff /swapfile

# Turn on swapfile
sudo swapon /swapfile

# Check swappiness
cat /proc/sys/vm/swappiness

# Set swappiness to 10 (permanent)
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf

# Check fstab for swapfile entry
grep swapfile /etc/fstab

# Check ZRAM
zramctl

# Check SSD health
sudo smartctl -a /dev/nvme0n1

# Find memory hogs
ps aux --sort=-%mem | head -15

# Check if OOM killer fired
sudo dmesg | grep -i "oom\|killed process" | tail -20
```

---

## Your Current Optimal Setup (16GB RAM)

```
Physical RAM:  16GB
ZRAM:           8GB  (priority 100) ← hits first
Swapfile:      20GB  (priority -1)  ← emergency buffer
─────────────────────────────────
Effective:    ~44GB total headroom
```

```bash
# Verify your setup anytime
swapon --show && free -h
```

---

*Guide written for Fedora Linux with Btrfs filesystem and NVMe SSD.*
*Last updated: June 2026*
