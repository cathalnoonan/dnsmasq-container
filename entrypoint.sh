#!/bin/sh

replace_placeholders() {
    local template_file="${1}"

    # 1. Validation: Ensure template is actually within the DNSMASQ_TEMPLATE_DIRECTORY
    # This prevents directory traversal via ../
    case "$(realpath "$template_file")" in
        "$(realpath "$DNSMASQ_TEMPLATE_DIRECTORY")"*) ;; # Path is valid, proceed
        *) echo "[Setup Error] Path escape detected: $template_file" && exit 1 ;;
    esac

    # 2. Derive destination: Replace the template root path with destination root path
    # Example: /opt/dnsmasq/templates/dnsmasq.conf.d/a.conf -> /opt/dnsmasq/dnsmasq.conf.d/a.conf
    local relative_path="${template_file#$DNSMASQ_TEMPLATE_DIRECTORY/}"
    local destination_file="${DNSMASQ_ROOT_DIRECTORY%/}/$relative_path"

    # 3. Create destination directory if it doesn't exist (e.g., dnsmasq.conf.d/)
    mkdir -p "$(dirname "$destination_file")"

    if [ -f "${template_file}" ]; then
        echo "[Setup Info] Processing: '${template_file}' -> '${destination_file}'"
        envsubst < "${template_file}" > "${destination_file}"
    else
        echo "[Setup Error] File '${template_file}' doesn't exist" && exit 1
    fi
}

if [ -d "$DNSMASQ_TEMPLATE_DIRECTORY" ]; then
    # Use 'find' to get all .conf files recursively from the templates folder
    # This handles both the root dnsmasq.conf and the .conf.d/ files in one go
    find "$DNSMASQ_TEMPLATE_DIRECTORY" -type f -name "*.conf" | while read -r file; do
        replace_placeholders "$file"
    done
else
    echo "[Setup Info] Template directory '$DNSMASQ_TEMPLATE_DIRECTORY' not found, skipping template processing."
fi

echo "[Setup Info] Starting dnsmasq..."
echo
exec dnsmasq -k --conf-file="${DNSMASQ_ROOT_DIRECTORY%/}/dnsmasq.conf"
