# ✅ Fix Bluetooth Low-Quality Audio on Ubuntu

This guide fixes low-quality Bluetooth audio (especially for AfterShokz bone-conduction devices) and forces Ubuntu to use high-quality A2DP mode with better codecs.

---

## ✔ Step 1: Install Bluetooth Codec Support

```bash
sudo apt install wireplumber libspa-0.2-bluetooth
```

This enables:

- AAC
- LDAC
- aptX / aptX-HD
- SBC-XQ  
  and other high-quality codecs (if supported by the headset).

---

## ✔ Step 2: Configure WirePlumber (Correct Way for Ubuntu 22.04+)

### Create config folder:

```bash
mkdir -p ~/.config/wireplumber/bluetooth.lua.d
```

### Create configuration file:

```bash
nano ~/.config/wireplumber/bluetooth.lua.d/51-bluez-config.lua
```

### Paste the following:

```lua
bluez_monitor.properties = {
    ["bluez5.enable-sbc-xq"] = true,
    ["bluez5.enable-msbc"] = true,
    ["bluez5.enable-hw-volume"] = true,
    ["bluez5.enable-hfp"] = false, -- Disable low-quality phone mode
    ["bluez5.enable-a2dp"] = true,
    ["bluez5.codecs"] = { "aac", "ldac", "aptx", "aptx-hd", "sbc", "sbc-xq" }
}
```

Save and exit:

- **CTRL + O**
- **ENTER**
- **CTRL + X**

---

## ✔ Step 3: Restart PipeWire + Bluetooth

```bash
systemctl --user restart wireplumber
systemctl --user restart pipewire pipewire-pulse
sudo systemctl restart bluetooth
```

---

## ✔ Step 4: Reconnect Headset & Select High-Fidelity Mode

Open:
**Settings → Sound → Your Bluetooth Device → Choose "A2DP High-Fidelity Playback"**

This ensures maximum audio quality.

---

## ✔ Step 5: Verify Active Codec (Optional)

```bash
pactl list cards | grep -A20 bluez
```

Look for:

- `LDAC`
- `AAC`
- `aptX / aptX-HD`
- `SBC-XQ`

If only `SBC` is shown, your device may not support higher codecs.

---

## 🎧 Notes for Bone-Conduction (AfterShokz) Users

Most AfterShokz models support:

- **SBC**
- **AAC** (some models)

They _usually do NOT_ support:

- aptX
- LDAC

The config above forces Ubuntu to always use the best available codec.

---

## 👍 Result

✔ High-resolution A2DP audio  
✔ No more low-quality HSP/HFP "telephone mode"  
✔ Consistent high-quality output after reconnecting
