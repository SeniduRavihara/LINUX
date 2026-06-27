#!/bin/bash

# Image Quality Drop Script for Web Optimization
# Usage: ./compress_images.sh [quality] [format]
# Example: ./compress_images.sh 75 jpg

# Default settings
QUALITY=${1:-75}  # Default quality 75 if not specified
FORMAT=${2:-jpg}  # Default output format jpg if not specified

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Image Compression Script${NC}"
echo -e "${BLUE}==================================${NC}"
echo -e "Quality: ${GREEN}${QUALITY}${NC}"
echo -e "Output Format: ${GREEN}${FORMAT}${NC}"
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed${NC}"
    echo "Install it with: sudo apt install imagemagick"
    exit 1
fi

# Create output directory
OUTPUT_DIR="compressed"
mkdir -p "$OUTPUT_DIR"

# Counter for processed images
count=0
total=$(ls *.png 2>/dev/null | wc -l)

if [ $total -eq 0 ]; then
    echo -e "${RED}No PNG files found in current directory${NC}"
    exit 1
fi

echo -e "Found ${GREEN}${total}${NC} PNG files to compress"
echo ""

# Process each PNG file
for img in *.png; do
    if [ -f "$img" ]; then
        # Get original file size
        original_size=$(du -h "$img" | cut -f1)
        
        # Get base filename without extension
        base_name="${img%.png}"
        
        # Output filename
        if [ "$FORMAT" == "png" ]; then
            output_file="${OUTPUT_DIR}/${base_name}.png"
        else
            output_file="${OUTPUT_DIR}/${base_name}.${FORMAT}"
        fi
        
        # Compress the image
        echo -e "Processing: ${BLUE}${img}${NC} (${original_size})"
        convert "$img" -quality "$QUALITY" -strip "$output_file"
        
        if [ $? -eq 0 ]; then
            # Get compressed file size
            compressed_size=$(du -h "$output_file" | cut -f1)
            echo -e "  → Saved to: ${GREEN}${output_file}${NC} (${compressed_size})"
            ((count++))
        else
            echo -e "  → ${RED}Failed to compress${NC}"
        fi
        echo ""
    fi
done

echo -e "${BLUE}==================================${NC}"
echo -e "${GREEN}Compression Complete!${NC}"
echo -e "Processed: ${count}/${total} images"
echo -e "Output directory: ${GREEN}${OUTPUT_DIR}/${NC}"
echo -e "${BLUE}==================================${NC}"
