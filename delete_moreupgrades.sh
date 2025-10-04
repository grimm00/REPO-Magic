#!/bin/bash

# Create array to store MoreUpgrades items
moreupgrades_items=()

# Find all files and directories with "moreupgrades" (case-insensitive)
while IFS= read -r -d '' item; do
    moreupgrades_items+=("$item")
done < <(find /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/ -iname "*moreupgrades*" -print0)

# Display what we found
echo "Found ${#moreupgrades_items[@]} MoreUpgrades items:"
for item in "${moreupgrades_items[@]}"; do
    echo "  $item"
done

# Ask for confirmation before deletion
echo ""
read -p "Do you want to delete these items? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting items..."
    for item in "${moreupgrades_items[@]}"; do
        if [ -d "$item" ]; then
            echo "Removing directory: $item"
            rm -rf "$item"
        elif [ -f "$item" ]; then
            echo "Removing file: $item"
            rm -f "$item"
        fi
    done
    echo "Deletion complete!"
else
    echo "Deletion cancelled."
fi
