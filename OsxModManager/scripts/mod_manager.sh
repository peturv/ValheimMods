#!/usr/bin/env bash

# Determine script root directory
SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BEPINEX_DEPENDENCY="denikson-BepInExPack_Valheim"
# set -euo pipefail

MODPACKS_DIR="$SCRIPT_ROOT/modpacks"
CLIENTMODS_DIR="$MODPACKS_DIR/clientmods"
PLUGINS_DIR="$SCRIPT_ROOT/BepInEx/plugins"
IGNORED_DEP_PREFIX="$BEPINEX_DEPENDENCY"
DOWNLOADS_DIR="$MODPACKS_DIR/downloads"
LOGS_DIR="$SCRIPT_ROOT/logs"

declare -A processed_mods

# Debug mode flag
DEBUG_MODE=0

# Helper functions (minimal dependencies)
parse_dependency() {
    local dep="$1"
    local author name version
    author="${dep%%-*}"
    rest="${dep#*-}"
    if [[ "$rest" == "$dep" ]]; then
        echo "⚠️ Invalid dependency format: $dep" >&2
        return 1
    fi
    if [[ "$rest" == *-* ]]; then
        version="${rest##*-}"
        name="${rest%-*}"
    else
        name="$rest"
        version=""
    fi
    if [[ -z "$version" ]]; then
        version=$(fetch_latest_version "$author" "$name")
        if [[ -z "$version" ]]; then
            echo "⚠️ Could not fetch latest version for $author-$name" >&2
            return 1
        fi
    fi
    echo "$author-$name-$version"
}

fetch_latest_version() {
    local author=$1
    local name=$2
    local api_url="https://thunderstore.io/api/experimental/package/${author}/${name}/"
    local mod_info
    if ! mod_info=$(curl -fsSL "$api_url"); then
        echo "❌ Thunderstore API call failed for $author/$name ($api_url)" >&2
        echo ""
        return 1
    fi
    local latest_version
    latest_version=$(echo "$mod_info" | jq -r '.latest.version_number')
    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        echo "❌ No version found for $author/$name ($api_url)" >&2
        echo ""
        return 1
    fi
    echo "$latest_version"
}

debug() {
    if [[ "$DEBUG_MODE" -eq 1 ]]; then
        echo "[DEBUG] $1"
    fi
}

# Helper: Fetch latest version from Thunderstore API for a given author and name
fetch_latest_version() {
    local author=$1
    local name=$2
    local api_url="https://thunderstore.io/api/experimental/package/${author}/${name}/"
    local mod_info
    if ! mod_info=$(curl -fsSL "$api_url"); then
        echo "❌ Thunderstore API call failed for $author/$name ($api_url)" >&2
        echo ""
        return 1
    fi
    local latest_version
    latest_version=$(echo "$mod_info" | jq -r '.latest.version_number')
    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        echo "❌ No version found for $author/$name ($api_url)" >&2
        echo ""
        return 1
    fi
    echo "$latest_version"
}

# Download dependency (for modpacks)
download_dependency() {
    local dep=$(parse_dependency "$1") || { debug "Skipping $1 due to parse error"; return; }
    local target_folder="$2"

    if [[ "$dep" == $IGNORED_DEP_PREFIX* ]]; then return; fi

    IFS="-" read -r dep_author dep_name dep_version <<< "$dep"

    # If version missing or empty, fetch latest version
    if [[ -z "${dep_version:-}" ]]; then
        dep_version=$(fetch_latest_version "$dep_author" "$dep_name") || {
            echo "❌ Failed to get latest version for $dep_author-$dep_name, skipping."
            return
        }
    fi

    local download_folder="$DOWNLOADS_DIR/${dep_author}-${dep_name}-${dep_version}"
    local version_file="$download_folder/.version"

    # Prevent infinite loops
    if [[ -n "${processed_mods[$dep_author-$dep_name-$dep_version]:-}" ]]; then
        debug "Already processed $dep_author-$dep_name-$dep_version, skipping."
        return
    fi

    # Skip if already downloaded with same version
    if [[ -f "$version_file" && "$(cat "$version_file")" == "$dep_version" ]]; then
        debug "$dep_author-$dep_name (v$dep_version) already downloaded, skipping."
        processed_mods["$dep_author-$dep_name-$dep_version"]=1
        return
    fi

    echo "↓ Downloading $dep_author-$dep_name (v$dep_version)"
    mkdir -p "$download_folder"
    if ! curl -fsSL "https://thunderstore.io/package/download/${dep_author}/${dep_name}/${dep_version}/" | bsdtar -xf - -C "$download_folder"; then
        echo "❌ Failed to download $dep_author-$dep_name-$dep_version"
        return
    fi
    echo "$dep_version" > "$version_file"
    processed_mods["$dep_author-$dep_name-$dep_version"]=1

    # Check for nested dependencies
    local manifest_file="$download_folder/manifest.saved"
    if [[ ! -f "$manifest_file" ]]; then
        # Try to save manifest.json without .json suffix to avoid detection
        if [[ -f "$download_folder/manifest.json" ]]; then
            mv "$download_folder/manifest.json" "$manifest_file"
        fi
    fi

    if [[ -f "$manifest_file" ]]; then
        local nested_deps
        nested_deps=$(jq -r '.dependencies[]?' "$manifest_file" 2>/dev/null || echo "")
        # Download required nested dependencies
        while IFS= read -r nested; do
            [[ -z "$nested" ]] && continue
            download_dependency "$nested" "$target_folder"
        done <<< "$nested_deps"
    fi
}

# Helper to symlink or copy from downloads to modpack/clientmods folder
link_or_copy_mod_to_folder() {
    local dep="$1"
    local target_folder="$2"
    local use_version="$3"  # Optional: whether to include version in link name
    IFS="-" read -r dep_author dep_name dep_version <<< "$dep"
    local download_folder="$DOWNLOADS_DIR/${dep_author}-${dep_name}-${dep_version}"
    
    # Determine link name based on target folder
    local link_name
    if [[ "$target_folder" == "$PLUGINS_DIR" ]]; then
        # For plugins directory, don't include version numbers
        link_name="$target_folder/${dep_author}-${dep_name}"
    else
        # For modpacks and clientmods, include version numbers
        link_name="$target_folder/${dep_author}-${dep_name}-${dep_version}"
    fi
    
    # Remove any existing link or folder
    rm -rf "$link_name"
    if ln -s "$download_folder" "$link_name" 2>/dev/null; then
        debug "Symlinked $link_name -> $download_folder"
    else
        debug "Symlink failed, copying $download_folder to $link_name"
        rsync -a "$download_folder/" "$link_name/"
    fi
}

# Download dependency (for clientmods)
download_dependency_clientmods() {
    local dep=$(parse_dependency "$1") || { debug "Skipping $1 due to parse error"; return; }

    if [[ "$dep" == $IGNORED_DEP_PREFIX* ]]; then return; fi

    IFS="-" read -r dep_author dep_name dep_version <<< "$dep"

    local download_folder="$DOWNLOADS_DIR/${dep_author}-${dep_name}-${dep_version}"
    local version_file="$download_folder/.version"

    if [[ -n "${processed_mods[$dep_author-$dep_name-$dep_version]:-}" ]]; then
        debug "Already processed $dep_author-$dep_name-$dep_version, skipping."
        return
    fi

    if [[ -f "$version_file" && "$(cat "$version_file")" == "$dep_version" ]]; then
        debug "$dep_author-$dep_name (v$dep_version) already downloaded, skipping."
        processed_mods["$dep_author-$dep_name-$dep_version"]=1
        return
    fi

    echo "↓ Downloading clientmod $dep_author-$dep_name (v$dep_version)"
    mkdir -p "$download_folder"
    if ! curl -fsSL "https://thunderstore.io/package/download/${dep_author}/${dep_name}/${dep_version}/" | bsdtar -xf - -C "$download_folder"; then
        echo "❌ Failed to download clientmod $dep_author-$dep_name-$dep_version"
        return
    fi
    echo "$dep_version" > "$version_file"
    processed_mods["$dep_author-$dep_name-$dep_version"]=1

    # Check nested dependencies inside clientmods
    local manifest_file="$download_folder/manifest.json"
    if [[ -f "$manifest_file" ]]; then
        local nested_deps
        nested_deps=$(jq -r '.dependencies[]?' "$manifest_file" 2>/dev/null || echo "")
        while IFS= read -r nested; do
            [[ -z "$nested" ]] && continue
            download_dependency_clientmods "$nested"
        done <<< "$nested_deps"
    fi
}

# Sync clientmods folder: update dependencies per manifest, downloads missing or outdated
sync_clientmods() {
    if [[ ! -f "$CLIENTMODS_DIR/manifest.json" ]]; then
        echo "❌ clientmods/manifest.json not found, skipping clientmods sync."
        return
    fi
    processed_mods=()
    
    # Read current dependencies and update manifest with versions if missing
    local deps
    deps=$(jq -r '.dependencies[]?' "$CLIENTMODS_DIR/manifest.json")
    local updated_deps=()
    local manifest_updated=false
    
    for dep in $deps; do
        debug "Processing dependency: $dep"
        
        # Check if dependency has version number
        if [[ "$dep" != *-* ]]; then
            echo "⚠️ Invalid dependency format: $dep"
            continue
        fi
        
        # Parse dependency to check if version is missing
        IFS="-" read -r dep_author dep_name dep_version <<< "$dep"
        
        if [[ -z "${dep_version:-}" ]]; then
            # Version is missing, fetch latest version
            echo "📝 Updating manifest: fetching latest version for $dep_author-$dep_name"
            dep_version=$(fetch_latest_version "$dep_author" "$dep_name")
            if [[ -n "$dep_version" ]]; then
                updated_deps+=("$dep_author-$dep_name-$dep_version")
                manifest_updated=true
                debug "Updated dependency: $dep -> $dep_author-$dep_name-$dep_version"
            else
                echo "❌ Failed to fetch version for $dep_author-$dep_name, keeping original"
                updated_deps+=("$dep")
            fi
        else
            # Version is present, keep as is
            updated_deps+=("$dep")
        fi
    done
    
    # Update manifest if any dependencies were updated
    if [[ "$manifest_updated" == true ]]; then
        echo "📝 Updating clientmods manifest with version numbers..."
        local new_deps_json=$(printf '%s\n' "${updated_deps[@]}" | jq -R . | jq -s .)
        jq --argjson deps "$new_deps_json" '.dependencies = $deps' "$CLIENTMODS_DIR/manifest.json" > "$CLIENTMODS_DIR/manifest.json.tmp" && \
        mv "$CLIENTMODS_DIR/manifest.json.tmp" "$CLIENTMODS_DIR/manifest.json"
        echo "✅ Updated clientmods manifest"
    fi
    
    # Now process the updated dependencies
    for dep in "${updated_deps[@]}"; do
        download_dependency_clientmods "$dep"
        link_or_copy_mod_to_folder "$dep" "$CLIENTMODS_DIR"
    done
}

# Get filtered list of modpacks (excluding special directories)
get_modpack_list() {
    local modpacks=()
    for d in "$MODPACKS_DIR"/*/; do
        [[ ! -d "$d" ]] && continue
        # Skip special folders
        local base=$(basename "$d")
        if [[ "$base" == "clientmods" || "$base" == "downloads" ]]; then
            continue
        fi
        modpacks+=("$base")
    done
    printf '%s\n' "${modpacks[@]}"
}

# List modpacks with selection highlight
list_modpacks() {
    local selected_manifest="$PLUGINS_DIR/manifest.saved"
    local selected_name=""
    if [[ -f "$selected_manifest" ]]; then
        selected_name=$(jq -r '.name' "$selected_manifest" 2>/dev/null || echo "")
    fi

    local idx=1
    echo "Modpacks:"
    while IFS= read -r modpack; do
        [[ -z "$modpack" ]] && continue
        if [[ "$modpack" == "$selected_name" ]]; then
            echo "  * $idx) $modpack (selected)"
            selected_modpack="$modpack"
        else
            echo "    $idx) $modpack"
        fi
        ((idx++))
    done < <(get_modpack_list)
    
    if [[ $idx -eq 1 ]]; then
        echo "  (no modpacks found)"
        selected_modpack=""
    fi
}

# Get modpack name by number
get_modpack_by_number() {
    local number=$1
    local idx=1
    while IFS= read -r modpack; do
        [[ -z "$modpack" ]] && continue
        if [[ $idx -eq "$number" ]]; then
            echo "$modpack"
            return
        fi
        ((idx++))
    done < <(get_modpack_list)
    echo ""
}

add_modpack_from_url_or_local() {
    read -rp "Enter URL or local path to manifest.json: " input

    if [[ -z "$input" ]]; then
        echo "❌ No input entered."
        return
    fi

    local manifest_content=""
    local is_api_manifest=0

    if [[ -f "$input" ]]; then
        # Local file path
        manifest_content=$(cat "$input")
    elif [[ "$input" =~ ^https?:// ]]; then
        # URL
        local url=$input
        if [[ "$url" =~ /p/([^/]+)/([^/]+)/?$ ]]; then
          author="${BASH_REMATCH[1]}"
          modname="${BASH_REMATCH[2]}"
        else
          echo "❌ Invalid Thunderstore URL format."
          return
        fi
        api_url="https://thunderstore.io/api/experimental/package/${author}/${modname}/"
        if ! manifest_content=$(curl -fsSL "$api_url"); then
            echo "❌ Failed to download manifest.json from URL"
            return
        fi
        is_api_manifest=1
    else
        echo "❌ Input is neither a file nor a valid URL."
        return
    fi

    local modpack_name
    if [[ $is_api_manifest -eq 1 ]]; then
        modpack_name=$(echo "$manifest_content" | jq -r '.name')
    else
        modpack_name=$(echo "$manifest_content" | jq -r '.name')
    fi
    if [[ -z "$modpack_name" || "$modpack_name" == "null" ]]; then
        echo "❌ Manifest missing name field."
        return
    fi

    local folder="$MODPACKS_DIR/$modpack_name"
    mkdir -p "$folder"

    # Save manifest
    if [[ $is_api_manifest -eq 1 ]]; then
        echo "$manifest_content" > "$folder/manifest.saved"
    else
        echo "$manifest_content" > "$folder/manifest.saved"
    fi

    processed_mods=()
    local deps opt_deps
    if [[ $is_api_manifest -eq 1 ]]; then
        # Thunderstore API: dependencies are in .latest.dependencies[] as full_name
        deps=$(echo "$manifest_content" | jq -r '.latest.dependencies[]?' || echo "")
        opt_deps="" # Thunderstore API does not provide optional dependencies directly
    else
        deps=$(echo "$manifest_content" | jq -r '.dependencies[]?' || echo "")
        opt_deps=$(echo "$manifest_content" | jq -r '.optional_dependencies[]?' || echo "")
    fi

    for dep in $deps; do
        debug "Processing dependency: $dep"
        download_dependency "$dep" "$modpack_name"
        link_or_copy_mod_to_folder "$dep" "$folder"
    done
    for dep in $opt_deps; do
        debug "Processing optional dependency: $dep"
        IFS="-" read -r a n v <<< "$dep"
        if [[ -z "$v" ]]; then
            v=$(fetch_latest_version "$a" "$n") || continue
        fi
        local dep_folder="$folder/${a}-${n}"
        local version_file="$dep_folder/.version"
        if [[ ! -f "$version_file" || "$(cat "$version_file")" != "$v" ]]; then
            download_dependency "$dep" "$modpack_name"
            link_or_copy_mod_to_folder "$dep" "$folder"
        else
            debug "Optional dependency $dep already present (version $v)"
        fi
    done

    echo "✅ Added modpack: $modpack_name"
}

# Delete modpack
delete_modpack() {
    read -rp "Enter number of modpack to delete: " num
    local modpack
    modpack=$(get_modpack_by_number "$num")
    if [[ -z "$modpack" ]]; then
        echo "❌ Invalid modpack number."
        return
    fi
    rm -rf "$MODPACKS_DIR/$modpack"
    echo "✅ Deleted modpack: $modpack"
    # If deleted modpack was selected, clear selection
    if [[ "$selected_modpack" == "$modpack" ]]; then
        selected_modpack=""
        rm -f "$PLUGINS_DIR/manifest.saved"
    fi
}

# Copy modpack to plugins directory (without selection message)
copy_modpack_to_plugins() {
    local modpack="$1"
    if [[ ! -d "$MODPACKS_DIR/$modpack" ]]; then
        echo "❌ Modpack folder not found."
        return 1
    fi

    # Always ensure dependencies are present before copying
    local manifest_file="$MODPACKS_DIR/$modpack/manifest.saved"
    if [[ -f "$manifest_file" ]]; then
        processed_mods=()
        local manifest_content=$(cat "$manifest_file")
        local deps opt_deps
        if echo "$manifest_content" | jq -e '.latest.dependencies' >/dev/null 2>&1; then
            # Thunderstore API manifest
            deps=$(echo "$manifest_content" | jq -r '.latest.dependencies[]?' || echo "")
            opt_deps=""
        else
            deps=$(echo "$manifest_content" | jq -r '.dependencies[]?' || echo "")
            opt_deps=$(echo "$manifest_content" | jq -r '.optional_dependencies[]?' || echo "")
        fi
        for dep in $deps; do
            download_dependency "$dep" "$modpack"
            link_or_copy_mod_to_folder "$dep" "$MODPACKS_DIR/$modpack"
        done
        for dep in $opt_deps; do
            IFS="-" read -r a n v <<< "$dep"
            if [[ -z "$v" ]]; then
                v=$(fetch_latest_version "$a" "$n") || continue
            fi
            local dep_folder="$MODPACKS_DIR/$modpack/${a}-${n}"
            local version_file="$dep_folder/.version"
            if [[ ! -f "$version_file" || "$(cat "$version_file")" != "$v" ]]; then
                download_dependency "$dep" "$modpack"
                link_or_copy_mod_to_folder "$dep" "$MODPACKS_DIR/$modpack"
            fi
        done
    fi

    # Clear plugins folder
    find "$PLUGINS_DIR" -mindepth 1 ! -name 'Valheim.DisplayBepInExInfo.dll' -exec rm -rf {} +
    
    # Copy clientmods contents first (dereference symlinks)
    debug "Copying clientmods to plugins directory..."
    rsync -aHL --exclude='manifest.json' "$CLIENTMODS_DIR/" "$PLUGINS_DIR/"
    
    # Debug: Show what's in the plugins directory after clientmods copy
    debug "Contents of $PLUGINS_DIR after clientmods copy:"
    debug "$(ls -la "$PLUGINS_DIR/" 2>/dev/null || echo 'Directory not found or empty')"
    
    # Copy modpack contents (dereference symlinks) - this will override any conflicting clientmods
    debug "Copying modpack to plugins directory (will override conflicting clientmods)..."
    debug "Contents of $MODPACKS_DIR/$modpack/:"
    debug "$(ls -la "$MODPACKS_DIR/$modpack/" 2>/dev/null || echo 'Directory not found or empty')"
    
    rsync -aHL --exclude='manifest.json' "$MODPACKS_DIR/$modpack/" "$PLUGINS_DIR/"
    
    # Debug: Show what's in the plugins directory after modpack copy
    debug "Contents of $PLUGINS_DIR after modpack copy:"
    debug "$(ls -la "$PLUGINS_DIR/" 2>/dev/null || echo 'Directory not found or empty')"

    # Copy modpack manifest as manifest.saved in plugins (if it exists)
    if [[ -f "$MODPACKS_DIR/$modpack/manifest.saved" ]]; then
        cp "$MODPACKS_DIR/$modpack/manifest.saved" "$PLUGINS_DIR/manifest.saved"
    fi
}

# Select modpack: clear plugins, copy modpack + clientmods (excluding clientmods manifest.json)
select_modpack() {
    local modpack="$1"
    copy_modpack_to_plugins "$modpack"
    echo "✅ Selected modpack: $modpack"
}

# Helper to pretty-print dependencies from manifest.json
list_client_mods() {
    if [[ ! -f "$CLIENTMODS_DIR/manifest.json" ]]; then
        echo "No client side mods manifest found."
        return
    fi
    echo
    echo "Client side mods:"
    jq -r '.dependencies[]?' "$CLIENTMODS_DIR/manifest.json" | nl -w2 -s'. '
}

# Helper to update manifest.json with new dependencies arrays
update_client_mods_manifest() {
    local new_deps="$1"
    local new_dis_deps="$2"
    jq --argjson deps "$new_deps" --argjson dis_deps "$new_dis_deps" \
        '.dependencies = $deps | .disabled_dependencies = $dis_deps' \
        "$CLIENTMODS_DIR/manifest.json" > "$CLIENTMODS_DIR/manifest.json.tmp" && \
        mv "$CLIENTMODS_DIR/manifest.json.tmp" "$CLIENTMODS_DIR/manifest.json"
}

# Ensure clientmods manifest exists with required structure
ensure_client_mods_manifest() {
    mkdir -p "$CLIENTMODS_DIR"
    if [[ ! -f "$CLIENTMODS_DIR/manifest.json" ]]; then
        cat > "$CLIENTMODS_DIR/manifest.json" <<EOF
{
  "name": "ClientSideMods",
  "version_number": "1.0.0",
  "dependencies": [],
  "disabled_dependencies": []
}
EOF
    fi
}

# --- Validation functions ---
validate_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ jq is required but not installed. Please install jq." >&2
        exit 1
    fi
}

validate_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "❌ curl is required but not installed. Please install curl." >&2
        exit 1
    fi
}

validate_bash_version() {
    if [[ "${BASH_VERSINFO:-0}" -lt 4 ]]; then
        echo "❌ Bash version 4 or higher is required. Current version: ${BASH_VERSION:-unknown}." >&2
        exit 1
    fi
}

bepinex_enable_menu() {
    echo
    echo "❌ Mods not enabled (BepInEx not found)."
    while true; do
        echo "Options:"
        echo "  1 - Enable mods (install BepInEx)"
        echo "  q - Quit"
        read -rp "Choose an option: " modopt
        case "$modopt" in
            1)
                echo "Fetching latest BepInExPack_Valheim..."
                bep_dep=$(parse_dependency "$BEPINEX_DEPENDENCY")
                IFS="-" read -r bep_author bep_name bep_version <<< "$bep_dep"
                bep_url="https://thunderstore.io/package/download/${bep_author}/${bep_name}/${bep_version}/"
                echo "Downloading and extracting BepInExPack_Valheim..."
                tmpdir=$(mktemp -d)
                tmpzip=$(mktemp)
                curl -fsSL "$bep_url" -o "$tmpzip" || { echo "Download failed"; exit 1; }
                unzip -q -d "$tmpdir" "$tmpzip" || { echo "Unzip failed"; exit 1; }
                rsync -a "$tmpdir"/BepInExPack_Valheim/ "$SCRIPT_ROOT/"
                if [[ -n "$tmpdir" && -d "$tmpdir" && ( "$tmpdir" == /tmp/* || "$tmpdir" == /var/folders/* ) ]]; then
                    rm -rf "$tmpdir"
                else
                    echo "Refusing to delete suspicious tmpdir: $tmpdir"
                fi
                rm "$tmpzip"
                echo "✅ BepInEx installed. Mods are now enabled."
                # If on macOS, write run_bepinex.sh and copy doorstop library
                if [[ "$(uname)" == "Darwin" ]]; then
                    write_run_bepinex_sh
                    # Copy doorstop library if it doesn't exist
                    if [[ ! -f "$SCRIPT_ROOT/libdoorstop.dylib" && -f "$SCRIPT_ROOT/doorstop_libs/libdoorstop_x64.dylib" ]]; then
                        cp "$SCRIPT_ROOT/doorstop_libs/libdoorstop_x64.dylib" "$SCRIPT_ROOT/libdoorstop.dylib"
                        echo "✅ Copied doorstop library."
                    fi
                fi
                break
                ;;
            q|Q)
                echo "Quitting."
                exit 0
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

validate_bepinex_folder() {
    if [[ ! -d "$SCRIPT_ROOT/BepInEx" ]]; then
        bepinex_enable_menu
    fi
}

validate_environment() {
    validate_jq
    validate_curl
    validate_bash_version
    validate_bepinex_folder
}

# Submenu for managing client side mods
client_mods_menu() {
    ensure_client_mods_manifest
    while true; do
        echo
        echo "Client side mods menu:"
        echo "  1 - List client side mods"
        echo "  2 - Add mod"
        echo "  3 - Delete mod"
        echo "  4 - Disable mod"
        echo "  5 - Enable mod"
        echo "  q - Return to main menu"
        read -rp "Choose an option: " cmopt
        case "$cmopt" in
            1)
                list_client_mods
                ;;
            2)
                read -rp "Enter dependency (author-modname[-version]): " dep
                if [[ -z "$dep" ]]; then echo "No input."; continue; fi
                deps=$(jq -r '.dependencies // []' "$CLIENTMODS_DIR/manifest.json")
                # Add if not already present
                if echo "$deps" | jq -e --arg d "$dep" 'index($d)' >/dev/null; then
                    echo "Already present."
                else
                    new_deps=$(echo "$deps" | jq --arg d "$dep" '. + [$d]')
                    dis_deps=$(jq -r '.disabled_dependencies // []' "$CLIENTMODS_DIR/manifest.json")
                    update_client_mods_manifest "$new_deps" "$dis_deps"
                    echo "Added mod."
                fi
                ;;
            3)
                echo "Which mod do you want to delete?"
                mapfile -t deps < <(jq -r '.dependencies[]?' "$CLIENTMODS_DIR/manifest.json")
                for i in "${!deps[@]}"; do
                    printf "  %02d: %s\n" $((i+1)) "${deps[$i]}"
                done
                read -rp "Enter number to delete, or blank to cancel: " delnum
                if [[ -z "$delnum" ]]; then continue; fi
                if [[ "$delnum" =~ ^[0-9]+$ ]]; then
                    idx=$((delnum-1))
                    if (( idx >= 0 && idx < ${#deps[@]} )); then
                        new_deps=$(printf '%s\n' "${deps[@]:0:$idx}" "${deps[@]:$((idx+1))}" | jq -R . | jq -s .)
                        dis_deps=$(jq -r '.disabled_dependencies // []' "$CLIENTMODS_DIR/manifest.json")
                        update_client_mods_manifest "$new_deps" "$dis_deps"
                        echo "Deleted mod."
                    else
                        echo "Invalid index."
                    fi
                else
                    echo "Invalid number."
                fi
                ;;
            4)
                # Disable a mod
                echo "Which mod do you want to disable?"
                mapfile -t deps < <(jq -r '.dependencies[]?' "$CLIENTMODS_DIR/manifest.json")
                for i in "${!deps[@]}"; do
                    printf "  %02d: %s\n" $((i+1)) "${deps[$i]}"
                done
                read -rp "Enter number to disable, or blank to cancel: " dis_num
                if [[ -z "$dis_num" ]]; then continue; fi
                if [[ "$dis_num" =~ ^[0-9]+$ ]]; then
                    idx=$((dis_num-1))
                    if (( idx >= 0 && idx < ${#deps[@]} )); then
                        mod_to_disable="${deps[$idx]}"
                        new_deps=$(printf '%s\n' "${deps[@]:0:$idx}" "${deps[@]:$((idx+1))}" | jq -R . | jq -s .)
                        dis_deps=$(jq -r '.disabled_dependencies // []' "$CLIENTMODS_DIR/manifest.json")
                        new_dis_deps=$(echo "$dis_deps" | jq --arg d "$mod_to_disable" '. + [$d]')
                        update_client_mods_manifest "$new_deps" "$new_dis_deps"
                        echo "Disabled mod."
                    else
                        echo "Invalid index."
                    fi
                else
                    echo "Invalid number."
                fi
                ;;
            5)
                # Enable a mod
                echo "Disabled mods:"
                mapfile -t dis_deps < <(jq -r '.disabled_dependencies[]?' "$CLIENTMODS_DIR/manifest.json")
                for i in "${!dis_deps[@]}"; do
                    printf "  %02d: %s\n" $((i+1)) "${dis_deps[$i]}"
                done
                read -rp "Enter number to enable, or blank to cancel: " en_num
                if [[ -z "$en_num" ]]; then continue; fi
                if [[ "$en_num" =~ ^[0-9]+$ ]]; then
                    idx=$((en_num-1))
                    if (( idx >= 0 && idx < ${#dis_deps[@]} )); then
                        mod_to_enable="${dis_deps[$idx]}"
                        deps=$(jq -r '.dependencies // []' "$CLIENTMODS_DIR/manifest.json")
                        new_dis_deps=$(printf '%s\n' "${dis_deps[@]:0:$idx}" "${dis_deps[@]:$((idx+1))}" | jq -R . | jq -s .)
                        new_deps=$(echo "$deps" | jq --arg d "$mod_to_enable" '. + [$d]')
                        update_client_mods_manifest "$new_deps" "$new_dis_deps"
                        echo "Enabled mod."
                    else
                        echo "Invalid index."
                    fi
                else
                    echo "Invalid number."
                fi
                ;;
            q|Q)
                break
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

write_run_bepinex_sh() {
    cat > "$SCRIPT_ROOT/run_bepinex.sh" <<'EOF'
#!/bin/sh
executable_name="valheim.app"
enabled="1"
target_assembly="BepInEx/core/BepInEx.Preloader.dll"
boot_config_override=
ignore_disable_switch="0"
dll_search_path_override=""
debug_enable="0"
debug_address="127.0.0.1:10000"
debug_suspend="0"
if [ "$2" = "SteamLaunch" ]; then
    to_rotate=4
    rotated=0
    while [ $((to_rotate-=1)) -ge 0 ]; do
        while [ "z$1" = "z--" ]; do
            set -- "$@" "$1"
            shift
            rotated=$((rotated+1))
        done
        set -- "$@" "$1"
        shift
        rotated=$((rotated+1))
    done
    to_rotate=$(($# - rotated))
    set -- "$@" "$0"
    while [ $((to_rotate-=1)) -ge 0 ]; do
        set -- "$@" "$1"
        shift
    done
    exec "$@"
fi
if [ -x "$1" ] ; then
    executable_name="$1"
    echo "Target executable: $1"
    shift
fi
if [ -z "${executable_name}" ] || [ ! -x "${executable_name}" ]; then
    echo "Please set executable_name to a valid name in a text editor or as the first command line parameter"
    exit 1
fi
a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BASEDIR=$(cd "$a" || exit; pwd -P)
arch=""
executable_path=""
lib_extension=""
os_type="$(uname -s)"
case ${os_type} in
    Linux*)
        executable_path="${executable_name}"
        if ! echo "$executable_path" | grep "^/.*$"; then
            executable_path="${BASEDIR}/${executable_path}"
        fi
        lib_extension="so"
    ;;
    Darwin*)
        real_executable_name="${executable_name}"
        if ! echo "$real_executable_name" | grep "^/.*$"; then
            real_executable_name="${BASEDIR}/${real_executable_name}"
        fi
        if ! echo "$real_executable_name" | grep "^.*\.app/Contents/MacOS/.*"; then
            if ! echo "$real_executable_name" | grep "^.*\.app$"; then
                real_executable_name="${real_executable_name}.app"
            fi
            inner_executable_name=$(defaults read "${real_executable_name}/Contents/Info" CFBundleExecutable)
            executable_path="${real_executable_name}/Contents/MacOS/${inner_executable_name}"
        else
            executable_path="${executable_name}"
        fi
        lib_extension="dylib"
    ;;
    *)
        echo "Unknown operating system ($(uname -s))"
        echo "Make an issue at https://github.com/NeighTools/UnityDoorstop"
        exit 1
    ;;
esac
abs_path() {
    echo "$(cd \"$(dirname \"$1\")\" && pwd)/$(basename \"$1\")"
}
_readlink() {
    ab_path="$(abs_path "$1")"
    link="$(readlink "${ab_path}")"
    case $link in
        /*);;
        *) link="$(dirname "$ab_path")/$link";;
    esac
    echo "$link"
}
resolve_executable_path () {
    e_path="$(abs_path "$1")"
    while [ -L "${e_path}" ]; do
        e_path=$(_readlink "${e_path}");
    done
    echo "${e_path}"
}
executable_path=$(resolve_executable_path "${executable_path}")
echo "${executable_path}"
file_out="$(LD_PRELOAD="" file -b "${executable_path}")"
case "${file_out}" in
    *64-bit*)
        arch="x64"
    ;;
    *32-bit*)
        arch="x86"
    ;;
    *)
        echo "The executable \"${executable_path}\" is not compiled for x86 or x64 (might be ARM?)"
        echo "If you think this is a mistake (or would like to encourage support for other architectures)"
        echo "Please make an issue at https://github.com/NeighTools/UnityDoorstop"
        echo "Got: ${file_out}"
        exit 1
    ;;
esac
doorstop_bool() {
    case "$1" in
        TRUE|true|t|T|1|Y|y|yes)
            echo "1"
        ;;
        FALSE|false|f|F|0|N|n|no)
            echo "0"
        ;;
    esac
}
while :; do
    case "$1" in
        --doorstop_enabled)
            enabled="$(doorstop_bool "$2")"
            shift
        ;;
        --doorstop_target_assembly)
            target_assembly="$2"
            shift
        ;;
        --doorstop-boot-config-override)
            boot_config_override="$2"
            shift
        ;;
        --doorstop-mono-dll-search-path-override)
            dll_search_path_override="$2"
            shift
        ;;
        --doorstop-mono-debug-enabled)
            debug_enable="$(doorstop_bool "$2")"
            shift
        ;;
        --doorstop-mono-debug-suspend)
            debug_suspend="$(doorstop_bool "$2")"
            shift
        ;;
        --doorstop-mono-debug-address)
            debug_address="$2"
            shift
        ;;
        *)
            if [ -z "$1" ]; then
                break
            fi
            rest_args="$rest_args $1"
        ;;
    esac
    shift
done
export DOORSTOP_ENABLED="$enabled"
export DOORSTOP_TARGET_ASSEMBLY="$target_assembly"
export DOORSTOP_IGNORE_DISABLED_ENV="$ignore_disable_switch"
export DOORSTOP_MONO_DLL_SEARCH_PATH_OVERRIDE="$dll_search_path_override"
export DOORSTOP_MONO_DEBUG_ENABLED="$debug_enable"
export DOORSTOP_MONO_DEBUG_ADDRESS="$debug_address"
export DOORSTOP_MONO_DEBUG_SUSPEND="$debug_suspend"
# Set coreclr path and corlib dir for .NET Core support
coreclr_path=""
corlib_dir=""
export DOORSTOP_CLR_RUNTIME_CORECLR_PATH="$coreclr_path.$lib_extension"
export DOORSTOP_CLR_CORLIB_DIR="$corlib_dir"
doorstop_directory="${BASEDIR}/"
doorstop_name="libdoorstop.${lib_extension}"
export LD_LIBRARY_PATH="${doorstop_directory}:${corlib_dir}:${LD_LIBRARY_PATH}"
if [ -z "$LD_PRELOAD" ]; then
    export LD_PRELOAD="${doorstop_name}"
else
    export LD_PRELOAD="${doorstop_name}:$LD_PRELOAD"
fi
export DYLD_LIBRARY_PATH="${doorstop_directory}:$DYLD_LIBRARY_PATH"
if [ -z "$DYLD_INSERT_LIBRARIES" ]; then
    export DYLD_INSERT_LIBRARIES="${doorstop_name}"
else
    export DYLD_INSERT_LIBRARIES="${doorstop_name}:$DYLD_INSERT_LIBRARIES"
fi
exec "$executable_path" $rest_args
EOF
    chmod +x "$SCRIPT_ROOT/run_bepinex.sh"
}

# Main loop & menu
main_menu() {
    # Ensure directories exist
    mkdir -p "$LOGS_DIR"
    mkdir -p "$DOWNLOADS_DIR" "$CLIENTMODS_DIR"
    mkdir -p "$MODPACKS_DIR" "$CLIENTMODS_DIR" "$PLUGINS_DIR"


    selected_modpack=""
    while true; do
        echo
        list_modpacks
        echo
        echo "Options:"
        echo "  0 - No modpack (only clientmods)"
        echo "  v - Vanilla (no mods, empty plugins)"
        echo "  a - Add modpack"
        echo "  d - Delete modpack"
        echo "  c - Manage client side mods"
        echo "  i - Toggle debug mode ($([[ "$DEBUG_MODE" -eq 1 ]] && echo ON || echo OFF))"
        echo "  p - Start with selected modpack (or press Enter)"
        echo "  q - Quit"
        echo
        read -rp "Select modpack by number, or choose option: " choice

        case "$choice" in
            0)
                # No modpack: deselect, clear plugins, copy only clientmods
                selected_modpack=""
                find "$PLUGINS_DIR" -mindepth 1 ! -name 'Valheim.DisplayBepInExInfo.dll' -exec rm -rf {} +
                rsync -a --exclude='manifest.json' "$CLIENTMODS_DIR/" "$PLUGINS_DIR/"
                rm -f "$PLUGINS_DIR/manifest.saved"
                echo "✅ No modpack selected. Only clientmods copied."
                ;;
            v|V)
                # Vanilla: clear plugins, copy nothing
                selected_modpack=""
                find "$PLUGINS_DIR" -mindepth 1 ! -name 'Valheim.DisplayBepInExInfo.dll' -exec rm -rf {} +
                rm -f "$PLUGINS_DIR/manifest.saved"
                echo "✅ Vanilla mode: plugins directory cleared."
                ;;
            a|A)
                add_modpack_from_url_or_local
                ;;
            d|D)
                delete_modpack
                ;;
            c|C)
                client_mods_menu
                ;;
            i|I)
                if [[ "$DEBUG_MODE" -eq 1 ]]; then
                    DEBUG_MODE=0
                    echo "Debug mode OFF"
                else
                    DEBUG_MODE=1
                    echo "Debug mode ON"
                fi
                ;;
            q|Q)
                echo "Quitting"
                exit 0
                ;;
            p|P|"")
                if [[ -z "$selected_modpack" ]]; then
                    echo "▶️ Starting without modpack"
                else
                    echo "▶️ Starting with modpack: $selected_modpack"
                    copy_modpack_to_plugins "$selected_modpack"
                fi
                processed_mods=()
                sync_clientmods
                
                # Build start command based on platform
                if [[ "$(uname)" == "Darwin" ]]; then
                    start_cmd="arch -x86_64 ./run_bepinex.sh -console"
                else
                    start_cmd="\"$SCRIPT_ROOT/start_game_bepinex.sh\""
                fi
                
                # Check if Steam is running
                if ! pgrep -f "steam" > /dev/null; then
                    echo "⚠️  Steam is not running. Please start Steam first."
                    echo "   Steam is required for Valheim to work properly."
                    read -rp "Press Enter to continue anyway, or Ctrl+C to cancel..."
                fi
                
                # Execute with or without logging
                if [[ "$DEBUG_MODE" -eq 1 ]]; then
                    log_file="$LOGS_DIR/log_$(date +%F).txt"
                    echo "Starting game with command: $start_cmd" >> "$log_file"
                    cd "$SCRIPT_ROOT" && SteamAppId=892970 STEAM_RUNTIME=1 eval $start_cmd >> "$log_file" 2>&1
                else
                    echo "Starting game..."
                    cd "$SCRIPT_ROOT" && SteamAppId=892970 STEAM_RUNTIME=1 eval $start_cmd
                fi
                exit 0
                ;;
            ''|*[!0-9]*) # invalid input that is not number, except options handled above
                echo "❌ Invalid input."
                ;;
            *)
                # number selection
                if [[ "$choice" =~ ^[0-9]+$ ]]; then
                    mod_name=$(get_modpack_by_number "$choice")
                    if [[ -z "$mod_name" ]]; then
                        echo "❌ Invalid modpack number."
                    else
                        selected_modpack="$mod_name"
                        select_modpack "$selected_modpack"
                    fi
                else
                    echo "❌ Invalid input."
                fi
                ;;
        esac
    done
}

validate_environment
main_menu
