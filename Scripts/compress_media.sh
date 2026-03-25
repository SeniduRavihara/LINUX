#!/bin/bash
# Compatible with both bash and zsh

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

# Find all image files
shopt -s nullglob 2>/dev/null || setopt nullglob 2>/dev/null
image_files=(*.png *.jpg *.jpeg *.PNG *.JPG *.JPEG)

for img in "${image_files[@]}"; do
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
    
    # Find all video files
    video_files=(*.mp4 *.mov *.avi *.mkv *.webm *.MP4 *.MOV *.AVI *.MKV *.WEBM)
    
    for vid in "${video_files[@]}"; do
        if [ -f "$vid" ]; then
            original_size=$(du -h "$vid" | cut -f1)
            base_name="${vid%.*}"
            
            # Output format
            if [ "$FORMAT" == "auto" ]; then
                # Use current extension for video if it's a known format
                out_ext="${vid##*.}"
                out_ext="${out_ext,,}"
                if [[ ! "$out_ext" =~ ^(mp4|mov|avi|mkv|webm)$ ]]; then
                    out_format="mp4"
                else
                    out_format="$out_ext"
                fi
            elif [ "$FORMAT" == "jpg" ] || [ "$FORMAT" == "png" ]; then
                out_format="mp4"
            else
                out_format="$FORMAT"
            fi
            
            output_file="${OUTPUT_DIR}/${base_name}_compressed.${out_format}"
            
            echo -e "  ${vid} (${original_size})"
            
            # Video compression with ffmpeg
            # CRF scale: 18-28 (lower = better quality, 23 is default)
            CRF=$((51 - QUALITY * 28 / 100))  # Convert 0-100 scale to CRF 51-23
            
            if [ "$out_format" == "webm" ]; then
                # WebM / VP9 Compression (Optimized for speed with -cpu-used 5)
                # -row-mt 1 enables row-based multithreading
                ffmpeg -i "$vid" -c:v libvpx-vp9 -crf "$CRF" -b:v 0 -cpu-used 5 -row-mt 1 -c:a libopus -y "$output_file" 2>&1 | grep -v "frame=" | grep -v "time=" | tail -5
            else
                # Standard H.264 / AAC Compression (using 'faster' preset for efficiency)
                ffmpeg -i "$vid" -c:v libx264 -crf "$CRF" -preset faster -c:a aac -b:a 128k -y "$output_file" 2>&1 | grep -v "frame=" | grep -v "time=" | tail -5
            fi
            
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