#!/bin/bash

SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# the theme folder inside this repo, must match the theme name used in install_theme.sh
THEME_DIR="$SCRIPT_DIR/grub_themer"

cd "$SCRIPT_DIR/background/" || exit 1

echo "Choose which background you'd like!":

# iterate PNG files with a glob: safe with spaces in filenames, no ls parsing
backgrounds=()
for f in *.png ; do
	# no matches -> literal pattern, skip it
	[[ -e "$f" ]] || continue
	backgrounds+=("$f")
done

if [[ ${#backgrounds[@]} -eq 0 ]] ; then
	echo "No backgrounds found in $SCRIPT_DIR/background/. Add some .png files first."
	exit 1
fi

ind=0
for f in "${backgrounds[@]}"; do 
	echo "[$ind]: $f"
	ind=$((ind + 1))
done

echo -n '>> ' 
read chosen_ind

if ! [[ "$chosen_ind" =~ ^[0-9]+$ ]] ; then 
	echo "Not changing background" 
	exit 1
fi

chosen_background=${backgrounds[$chosen_ind]}
if [[ "$chosen_background" == "" ]]; then
	echo "Not changing background."
else
	echo "Chose option $chosen_ind:  $chosen_background"
	cp "$chosen_background" "$THEME_DIR/background.png"
	echo "[INFO] Saved as $THEME_DIR/background.png"
fi
