# Media Compression Guide for Ubuntu

Complete guide for compressing images and videos using terminal commands and bash scripts.

---

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Image Compression](#image-compression)
3. [Video Compression](#video-compression)
4. [Bash Script Method](#bash-script-method)
5. [Terminal Function Method](#terminal-function-method)
6. [Quick Reference](#quick-reference)

---

## Initial Setup

### Install Required Tools

```bash
# Update package list
sudo apt update

# Install ImageMagick (for images)
sudo apt install imagemagick

# Install FFmpeg (for videos)
sudo apt install ffmpeg

# Optional: Install additional image tools
sudo apt install jpegoptim optipng pngquant
```

### Verify Installation

```bash
# Check ImageMagick
convert --version

# Check FFmpeg
ffmpeg -version
```

---

## Image Compression

### Single Image Compression

#### Convert PNG to JPG (Best for photos)
```bash
# Basic conversion with quality
convert input.png -quality 75 output.jpg

# With quality levels:
convert input.png -quality 85 output.jpg  # High quality
convert input.png -quality 75 output.jpg  # Good balance
convert input.png -quality 60 output.jpg  # Smaller size
```

#### Compress PNG (Keep as PNG)
```bash
# Using ImageMagick
convert input.png -quality 85 -strip output.png

# Using pngquant (better compression)
pngquant --quality=65-80 input.png
```

#### Compress JPEG
```bash
# Using ImageMagick
convert input.jpg -quality 75 -strip output.jpg

# Using jpegoptim
jpegoptim --max=75 input.jpg
```

### Batch Image Compression

#### All PNGs to JPG
```bash
for img in *.png; do 
    convert "$img" -quality 75 "${img%.png}.jpg"
done
```

#### Compress all PNGs (keep as PNG)
```bash
for img in *.png; do 
    convert "$img" -quality 85 -strip "$img"
done
```

#### Create compressed versions in new folder
```bash
# Create output folder
mkdir compressed

# Compress all images
for img in *.{png,jpg,jpeg}; do 
    [ -f "$img" ] || continue
    convert "$img" -quality 75 -strip "compressed/$img"
done
```

### Quality Guide for Images
- **85-90**: High quality, minimal compression (good for portfolios)
- **75-85**: Good balance (recommended for most websites)
- **60-75**: Noticeable compression but acceptable
- **Below 60**: Significant quality loss

---

## Video Compression

### Single Video Compression

#### Basic MP4 Compression
```bash
# Standard compression (CRF 23 = default)
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k output.mp4

# High quality (CRF 18)
ffmpeg -i input.mp4 -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 192k output.mp4

# Smaller file size (CRF 28)
ffmpeg -i input.mp4 -c:v libx264 -crf 28 -preset fast -c:a aac -b:a 128k output.mp4
```

#### Convert to WebM (Better compression)
```bash
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 output.webm
```

#### Resize Video (Reduce resolution)
```bash
# 720p
ffmpeg -i input.mp4 -vf scale=1280:720 -c:v libx264 -crf 23 output.mp4

# 480p
ffmpeg -i input.mp4 -vf scale=854:480 -c:v libx264 -crf 23 output.mp4
```

### Batch Video Compression

```bash
# Create output folder
mkdir compressed

# Compress all MP4 files
for vid in *.mp4; do
    [ -f "$vid" ] || continue
    ffmpeg -i "$vid" -c:v libx264 -crf 28 -preset medium -c:a aac -b:a 128k "compressed/${vid%.mp4}_compressed.mp4" -y
done
```

### CRF Scale for Videos
- **CRF 18-22**: Very high quality (large files)
- **CRF 23**: Default, good quality
- **CRF 24-28**: Good for web (recommended)
- **CRF 28-32**: Smaller files, acceptable quality
- **CRF 32+**: Significant quality loss

### Preset Options
- **ultrafast**: Fastest encoding, larger files
- **fast**: Quick encoding
- **medium**: Default, good balance
- **slow**: Better compression, takes longer
- **veryslow**: Best compression, very slow

---

## Bash Script Method

### Complete Media Compression Script

Create file: `compress_media.sh`

```bash
#!/bin/bash

# Media Compression Script for Images and Videos
# Usage: ./compress_media.sh [quality] [format]
# Example: ./compress_media.sh 75 jpg

# Default settings
QUALITY=${1:-75}  # Default quality 75 for images
FORMAT=${2:-auto}  # auto, jpg, png, mp4, webm

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Media Compression Script${NC}"
echo -e "${BLUE}==================================${NC}"
echo -e "Quality: ${GREEN}${QUALITY}${NC}"
echo ""

# Check if required tools are installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed${NC}"
    echo "Install it with: sudo apt install imagemagick"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}Warning: FFmpeg is not installed (needed for videos)${NC}"
    echo "Install it with: sudo apt install ffmpeg"
fi

# Create output directory
OUTPUT_DIR="compressed"
mkdir -p "$OUTPUT_DIR"

# Counters
img_count=0
vid_count=0

# Process Images (PNG/JPG)
echo -e "${BLUE}Processing Images...${NC}"
for img in *.{png,jpg,jpeg,PNG,JPG,JPEG} 2>/dev/null; do
    if [ -f "$img" ]; then
        original_size=$(du -h "$img" | cut -f1)
        base_name="${img%.*}"
        ext="${img##*.}"
        
        # Determine output format
        if [ "$FORMAT" == "auto" ]; then
            if [[ "$ext" =~ ^(png|PNG)$ ]]; then
                out_format="jpg"
            else
                out_format="$ext"
            fi
        else
            out_format="$FORMAT"
        fi
        
        output_file="${OUTPUT_DIR}/${base_name}.${out_format}"
        
        echo -e "  ${img} (${original_size})"
        convert "$img" -quality "$QUALITY" -strip "$output_file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            compressed_size=$(du -h "$output_file" | cut -f1)
            echo -e "  → ${GREEN}Saved: ${output_file}${NC} (${compressed_size})"
            ((img_count++))
        else
            echo -e "  → ${RED}Failed${NC}"
        fi
    fi
done

echo ""

# Process Videos (MP4/MOV/AVI/MKV/WEBM)
if command -v ffmpeg &> /dev/null; then
    echo -e "${BLUE}Processing Videos...${NC}"
    for vid in *.{mp4,mov,avi,mkv,webm,MP4,MOV,AVI,MKV,WEBM} 2>/dev/null; do
        if [ -f "$vid" ]; then
            original_size=$(du -h "$vid" | cut -f1)
            base_name="${vid%.*}"
            
            # Output format
            if [ "$FORMAT" == "auto" ] || [ "$FORMAT" == "jpg" ] || [ "$FORMAT" == "png" ]; then
                out_format="mp4"
            else
                out_format="$FORMAT"
            fi
            
            output_file="${OUTPUT_DIR}/${base_name}_compressed.${out_format}"
            
            echo -e "  ${vid} (${original_size})"
            
            # Video compression with ffmpeg
            # CRF scale: 18-28 (lower = better quality, 23 is default)
            CRF=$((51 - QUALITY * 28 / 100))  # Convert 0-100 scale to CRF 51-23
            
            ffmpeg -i "$vid" -c:v libx264 -crf $CRF -preset medium -c:a aac -b:a 128k "$output_file" -y 2>&1 | grep -v "frame=" | grep -v "time=" | tail -5
            
            if [ $? -eq 0 ]; then
                compressed_size=$(du -h "$output_file" | cut -f1)
                echo -e "  → ${GREEN}Saved: ${output_file}${NC} (${compressed_size})"
                ((vid_count++))
            else
                echo -e "  → ${RED}Failed${NC}"
            fi
            echo ""
        fi
    done
else
    echo -e "${YELLOW}Skipping videos (ffmpeg not installed)${NC}"
    echo ""
fi

# Summary
echo -e "${BLUE}==================================${NC}"
echo -e "${GREEN}Compression Complete!${NC}"
echo -e "Images processed: ${img_count}"
echo -e "Videos processed: ${vid_count}"
echo -e "Output directory: ${GREEN}${OUTPUT_DIR}/${NC}"
echo -e "${BLUE}==================================${NC}"
```

### How to Use the Script

#### 1. Create the Script
```bash
# Create and edit the file
nano compress_media.sh

# Paste the script above
# Save with Ctrl+X, then Y, then Enter
```

#### 2. Make it Executable
```bash
chmod +x compress_media.sh
```

#### 3. Run the Script

```bash
# Default compression (quality 75, auto format)
./compress_media.sh

# Custom quality (80)
./compress_media.sh 80

# Low quality for smaller files (60)
./compress_media.sh 60

# Keep images as PNG
./compress_media.sh 75 png

# Convert videos to WebM
./compress_media.sh 75 webm
```

#### 4. Results
- All compressed files will be in the `compressed/` folder
- Original files remain untouched
- Script shows file size before and after

---

## Terminal Function Method

### Add Permanent Command to Terminal

#### 1. Open Bash Configuration
```bash
nano ~/.bashrc
```

#### 2. Add Function to Bottom of File

```bash
# Media Compression Function
compress_media() {
    QUALITY=${1:-75}
    OUTPUT_DIR="compressed"
    mkdir -p "$OUTPUT_DIR"
    
    echo "Compressing media with quality: $QUALITY"
    echo "Output directory: $OUTPUT_DIR"
    echo ""
    
    # Compress images
    img_count=0
    for img in *.{png,jpg,jpeg,PNG,JPG,JPEG} 2>/dev/null; do
        [ -f "$img" ] || continue
        echo "Compressing image: $img"
        convert "$img" -quality "$QUALITY" -strip "${OUTPUT_DIR}/${img}"
        if [ $? -eq 0 ]; then
            ((img_count++))
        fi
    done
    
    # Compress videos
    vid_count=0
    for vid in *.{mp4,mov,avi,mkv,MP4,MOV,AVI,MKV} 2>/dev/null; do
        [ -f "$vid" ] || continue
        base="${vid%.*}"
        echo "Compressing video: $vid"
        CRF=$((51 - QUALITY * 28 / 100))
        ffmpeg -i "$vid" -c:v libx264 -crf $CRF -preset medium -c:a aac -b:a 128k "${OUTPUT_DIR}/${base}_compressed.mp4" -y -loglevel error
        if [ $? -eq 0 ]; then
            ((vid_count++))
        fi
    done
    
    echo ""
    echo "Done! Compressed $img_count images and $vid_count videos"
    echo "Check the $OUTPUT_DIR/ folder"
}

# Quick image compression only
compress_images() {
    QUALITY=${1:-75}
    mkdir -p compressed
    for img in *.{png,jpg,jpeg,PNG,JPG,JPEG} 2>/dev/null; do
        [ -f "$img" ] || continue
        echo "Compressing: $img"
        convert "$img" -quality "$QUALITY" -strip "compressed/${img}"
    done
    echo "Done! Check compressed/ folder"
}

# Quick video compression only
compress_videos() {
    QUALITY=${1:-75}
    CRF=$((51 - QUALITY * 28 / 100))
    mkdir -p compressed
    for vid in *.{mp4,mov,avi,mkv} 2>/dev/null; do
        [ -f "$vid" ] || continue
        base="${vid%.*}"
        echo "Compressing: $vid"
        ffmpeg -i "$vid" -c:v libx264 -crf $CRF -preset medium -c:a aac -b:a 128k "compressed/${base}_compressed.mp4" -y -loglevel error
    done
    echo "Done! Check compressed/ folder"
}
```

#### 3. Save and Reload
```bash
# Save with Ctrl+X, Y, Enter

# Reload bash configuration
source ~/.bashrc
```

#### 4. Use Commands Anywhere

```bash
# Compress both images and videos
compress_media
compress_media 80      # Higher quality
compress_media 60      # Smaller files

# Images only
compress_images
compress_images 75

# Videos only
compress_videos
compress_videos 70
```

---

## Quick Reference

### Image Compression Commands

| Command | Description |
|---------|-------------|
| `convert input.png -quality 75 output.jpg` | Convert PNG to JPG |
| `pngquant --quality=65-80 image.png` | Compress PNG |
| `jpegoptim --max=75 image.jpg` | Compress JPEG |
| `mogrify -quality 85 *.png` | Batch compress (overwrites) |

### Video Compression Commands

| Command | Description |
|---------|-------------|
| `ffmpeg -i input.mp4 -crf 23 output.mp4` | Standard compression |
| `ffmpeg -i input.mp4 -crf 28 output.mp4` | Smaller file |
| `ffmpeg -i input.mp4 -vf scale=1280:720 -crf 23 output.mp4` | Resize to 720p |
| `ffmpeg -i input.mp4 -c:v libvpx-vp9 output.webm` | Convert to WebM |

### Script Usage

| Command | Description |
|---------|-------------|
| `./compress_media.sh` | Default (quality 75) |
| `./compress_media.sh 80` | High quality |
| `./compress_media.sh 60` | Small files |
| `./compress_media.sh 75 png` | Keep as PNG |

### Terminal Functions

| Command | Description |
|---------|-------------|
| `compress_media` | Compress all media |
| `compress_media 80` | Custom quality |
| `compress_images` | Images only |
| `compress_videos` | Videos only |

---

## Troubleshooting

### Command Not Found
```bash
# Check if installed
which convert
which ffmpeg

# Reinstall if needed
sudo apt install imagemagick ffmpeg
```

### Permission Denied
```bash
# Make script executable
chmod +x compress_media.sh
```

### Function Not Found
```bash
# Reload bashrc
source ~/.bashrc

# Or restart terminal
```

### Spaces in Filenames
Always use quotes around variables:
```bash
for img in *.png; do
    convert "$img" -quality 75 "$img"  # Quotes handle spaces
done
```

---

## Tips for Best Results

### For Images:
1. **Food/Product Photos**: Convert PNG to JPG (quality 75-80)
2. **Logos/Icons**: Keep as PNG, use pngquant
3. **Web Banners**: JPG at quality 70-75
4. **Thumbnails**: JPG at quality 60-65

### For Videos:
1. **Web Background Videos**: CRF 28-32 + resize to 720p
2. **Product Demos**: CRF 23-26 at 1080p
3. **Social Media**: CRF 26-28 + resize to 720p
4. **Long Videos**: Consider WebM format

### Batch Processing:
1. Always create `compressed/` folder to keep originals safe
2. Test on one file first to verify quality
3. Check file sizes before and after
4. Use higher quality for important content

---

## Backup This Guide

Save this markdown file:
```bash
# Save to file
nano ~/media-compression-guide.md

# Or save to Dropbox/Google Drive for easy access after PC reset
```

---

**Last Updated**: November 2024  
**System**: Ubuntu 20.04+  
**Tools**: ImageMagick, FFmpeg, Bash