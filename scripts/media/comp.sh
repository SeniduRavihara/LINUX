# Create the directory if it doesn't exist
mkdir -p compressed

for f in *; do
    # Skip directories and the script itself
    [ -f "$f" ] || continue
    [[ "$f" == "compressed" ]] && continue
    
    echo "Optimizing $f -> compressed/${f%.*}.webp"
    
    # -y overwrites if it already exists in the compressed folder
    ffmpeg -i "$f" -c:v libwebp -lossless 0 -quality 20 -preset drawing "compressed/${f%.*}.webp" -y
done

