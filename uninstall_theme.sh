#!/bin/bash

# check if the grub folder is called grub/ or grub2/ (same logic as install_theme.sh)
if [ -d /boot/grub ]    ; then
	grub_path="/boot/grub"
elif [ -d /boot/grub2 ] ; then
	grub_path="/boot/grub2"
else 
	echo "Can't find a /boot/grub or /boot/grub2 folder. Exiting."
	echo "Hint: is this a UEFI install? Check that /boot is mounted (the theme lives in /boot/grub/themes)."
	exit 
fi
theme_path="$grub_path/themes/grub_themer"

# regenerate grub.cfg (self-contained, also duplicated in install_theme.sh)
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

echo "[INFO] Theme directory: $theme_path"

read -p "[?] Remove the grub_themer theme? [y/N] " -en 1 remove_theme
if [[ "$remove_theme" =~ ^[yY] ]]; then
    if [[ ! -d "$theme_path" ]] ; then
        echo "[INFO] [Skipping] $theme_path doesn't exist, nothing to remove (already uninstalled?)"
    elif [[ ! -f "$theme_path/theme.txt" ]] ; then
        echo "[ERROR] $theme_path exists but has no theme.txt, refusing to delete it (not a grub_themer theme?)"
    elif [[ `id -u` -ne 0 ]] ; then
        echo "Must be run as root! The theme lives in $theme_path under /boot, which only root can modify."
        echo "[INFO] [Skipping] Removing the theme files"
    else
        # warn before pulling the theme out if GRUB still points at it
        if [[ -f /etc/default/grub ]] && grep -q '^GRUB_THEME=' /etc/default/grub ; then
            echo "[WARN] GRUB_THEME= in /etc/default/grub points to this theme, the path will be gone after removal!"
            echo "[WARN] Back up /etc/default/grub before editing it (the next step keeps a one-time copy at /etc/default/grub.grubphemous-backup-uninstall)."
        fi
        rm -rf "$theme_path"
        echo "[INFO] Removed the theme from $theme_path"
    fi
else
    echo "[INFO] [Skipping] Removing the theme files"
fi

read -p "[?] Comment out the GRUB_THEME= line in /etc/default/grub? [y/N] " -en 1 comment_grub_theme
if [[ "$comment_grub_theme" =~ ^[yY] ]]; then
    if [[ ! -f /etc/default/grub ]] ; then
        echo "[ERROR] /etc/default/grub not found, nothing to comment out"
    else
        # one-time backup, never overwrite an existing one
        if [[ -e /etc/default/grub.grubphemous-backup-uninstall ]] ; then
            echo "[INFO] Backup already exists at /etc/default/grub.grubphemous-backup-uninstall (not overwriting)"
        elif cp -n /etc/default/grub /etc/default/grub.grubphemous-backup-uninstall ; then
            echo "[INFO] Backup created at /etc/default/grub.grubphemous-backup-uninstall"
        else
            echo "[ERROR] Could not back up /etc/default/grub, are you root?"
        fi
        if grep -q '^GRUB_THEME=' /etc/default/grub ; then
            sed -i 's|^GRUB_THEME=|#&|' /etc/default/grub
            echo "[INFO] /etc/default/grub now contains:"
            grep '^#GRUB_THEME=' /etc/default/grub
        else
            echo "[INFO] No GRUB_THEME= line found in /etc/default/grub"
        fi
    fi
else
    echo "[INFO] [Skipping] Commenting out GRUB_THEME= in /etc/default/grub"
fi

read -p "[?] Re-run grub-mkconfig now? [y/N] " -en 1 run_mkconfig
if [[ "$run_mkconfig" =~ ^[yY] ]]; then
    run_grub_mkconfig
else
    echo "[INFO] [Skipping] Re-running grub-mkconfig"
fi

echo
echo "======= Done! ======="
echo
