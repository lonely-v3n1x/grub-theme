#!/bin/bash

# requires to be run as root, unless the user has access to the theme folder
if [[ `id -u` -ne 0 ]] ; then
	echo "Must be run as root!"
	exit
fi 

# this should be the directory of the cloned repo
SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
# I accidentally deleted the above line once and it copied / into the theme folder, so lets prevent this
if [[ -z $SCRIPT_DIR ]] ; then echo "Something didn't work, exiting"; exit; fi

# the theme folder inside this repo, must match the name used below and in the README
THEME_DIR="$SCRIPT_DIR/grub_themer"
if [[ ! -d "$THEME_DIR" ]] ; then echo "Can't find the theme folder $THEME_DIR. Exiting."; exit 1; fi

# check if the grub folder is called grub/ or grub2/
if [ -d /boot/grub ]    ; then
	grub_path="/boot/grub"
elif [ -d /boot/grub2 ] ; then
	grub_path="/boot/grub2"
else 
	echo "Can't find a /boot/grub or /boot/grub2 folder. Exiting."
	exit 
fi
theme_path="$grub_path/themes/grub_themer"

# regenerate grub.cfg (self-contained, also duplicated in uninstall_theme.sh)
run_grub_mkconfig() {
    if command -v grub-mkconfig >/dev/null 2>&1 ; then
        grub-mkconfig -o "$grub_path/grub.cfg" || { echo "[ERROR] grub-mkconfig failed!"; return 1; }
        echo "[INFO] Regenerated $grub_path/grub.cfg"
    elif command -v grub2-mkconfig >/dev/null 2>&1 ; then
        grub2-mkconfig -o "$grub_path/grub.cfg" || { echo "[ERROR] grub2-mkconfig failed!"; return 1; }
        echo "[INFO] Regenerated $grub_path/grub.cfg"
    else
        echo "[WARN] Neither grub-mkconfig nor grub2-mkconfig was found in your PATH."
        echo "       Run it manually, e.g.: grub-mkconfig -o $grub_path/grub.cfg"
    fi
}

## Prompts

# Choosing a background, comment this out if it's annoying
read -p "[?] Do you want to choose a specific background? [y/N] " -en 1 choose_bg
if [[ "$choose_bg" =~ ^[yY] ]]; then
    echo "[INFO] Choosing a background from ./background/"
    "$SCRIPT_DIR/choose_background.sh"
else
    echo "[INFO] [Skipping] Choosing a background"
fi

read -p "[?] Copy/Update the theme to '$theme_path'? [Y/n] " -en 1 copy_theme
if [[ "$copy_theme" =~ ^[nN] ]]; then
    echo "[INFO] [Skipping] Copying the theme files to boot partition"
else
    echo "[INFO] => Copying the theme files to boot partition:"
    # copy recursive, update, verbose
    mkdir -p "$grub_path/themes" || { echo "[ERROR] Could not create $grub_path/themes"; exit 1; }
    cp -ruv "$THEME_DIR" "$grub_path/themes/" | awk '$0 !~ /skipped/ { print "\t"$0 }'

    # optional: wire the theme up in /etc/default/grub (skipped = today's behavior)
    read -p "[?] Update GRUB_THEME= in /etc/default/grub? [y/N] " -en 1 update_grub_theme
    if [[ "$update_grub_theme" =~ ^[yY] ]]; then
        if [[ -f /etc/default/grub ]] ; then
            # one-time backup, never overwrite an existing one
            if [[ -e /etc/default/grub.grubphemous-backup ]] ; then
                echo "[INFO] Backup already exists at /etc/default/grub.grubphemous-backup (not overwriting)"
            else
                cp -n /etc/default/grub /etc/default/grub.grubphemous-backup && echo "[INFO] Backup created at /etc/default/grub.grubphemous-backup"
            fi
            grub_theme_line="GRUB_THEME=\"$grub_path/themes/grub_themer/theme.txt\""
            if grep -q '^GRUB_THEME=' /etc/default/grub ; then
                sed -i "s|^GRUB_THEME=.*|${grub_theme_line}|" /etc/default/grub
            else
                printf '\n# Lines to configure the Grubphemous theme\n%s\n' "$grub_theme_line" >> /etc/default/grub
            fi
            echo "[INFO] /etc/default/grub now contains:"
            grep '^GRUB_THEME=' /etc/default/grub
        else
            echo "[ERROR] /etc/default/grub not found, cannot update GRUB_THEME="
        fi
    else
        echo "[INFO] [Skipping] Updating GRUB_THEME= in /etc/default/grub"
    fi

    # optional: regenerate grub.cfg right away (skipped = today's behavior)
    read -p "[?] Re-run grub-mkconfig now? [y/N] " -en 1 run_mkconfig
    if [[ "$run_mkconfig" =~ ^[yY] ]]; then
        run_grub_mkconfig
    else
        echo "[INFO] [Skipping] Re-running grub-mkconfig"
    fi
fi

echo
echo "======= Done! ======="
echo "[YEAH] Make sure to add/change this line in /etc/default/grub :"
echo
echo -e "    GRUB_THEME=$theme_path/theme.txt"
echo
echo
