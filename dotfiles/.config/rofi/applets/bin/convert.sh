for img in ~/Pictures/Wallpapers/*.{jpg,png}; do

    [ -f "$img" ] || continue
    filename=$(basename "$img")
    echo "$filename"
    convert "$img" -resize 48x48 "$HOME/Pictures/Wallpapers/wal-icons/$filename"
done
