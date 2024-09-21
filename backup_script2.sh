#!/bin/bash
# Default values
backup_folder="../backups/"
log_file="backup_log.txt"
backup_directory="."
backup_count=0
last_modified=""

# Function to create backup
create_backup() {
    current_modified=$(find "${backup_directory}" -type f -exec stat -c %Y {} \; | sort -n | tail -n 1)
    
    if [ "${current_modified}" != "${last_modified}" ]; then
        timestamp=$(date +"%Y%m%d%H%M%S")
        backup_count=$((backup_count + 1))
        backup_file="${backup_folder}backup_${backup_count}.tar.gz"
        
        if tar -czf "${backup_file}" "${backup_directory}" && chmod 400 "${backup_file}"; then
            printf "Backup %d created on %s with timestamp %s\n" "${backup_count}" "$(date)" "${timestamp}" >> "${backup_folder}${log_file}"
            zenity --info --text="Backup created successfully.\nBackup location: ${backup_file}"
            last_modified="${current_modified}"
        else
            zenity --error --text="Error: Backup creation failed."
            echo "Error: Backup creation failed." >> "${backup_folder}${log_file}"
        fi
    else
        zenity --info --text="No changes detected. Skipping backup."
        echo "No changes detected. Skipping backup."
    fi
}

# Function to stop the backup script
stop_backup_script() {
    zenity --info --text="Stopping backup script and associated processes..."
    echo "Stopping backup script and associated processes..."
    pkill -P $$ # Kill child processes
    pkill -f "backup_script2.sh"
    exit 0
}

# Function to recover the latest backup
recover_latest_backup() {
    latest_backup=$(zenity --file-selection --title="Select Latest Backup" --file-filter="Backup Files (backup_*.tar.gz) | backup_*.tar.gz" --filename="${backup_folder}")
    
    if [ -n "${latest_backup}" ]; then
        recovery_folder=$(zenity --file-selection --directory --title="Select Recovery Folder")
        
        if [ -n "${recovery_folder}" ]; then
            echo "Recovering the latest backup: ${latest_backup}"
            zenity --info --text="Recovering the latest backup: ${latest_backup}"
            
            if tar -xzf "${latest_backup}" -C "${recovery_folder}"; then
                zenity --info --text="Recovery complete. Extracted to: ${recovery_folder}"
                echo "Recovery complete. Extracted to: ${recovery_folder}"
            else
                zenity --error --text="Error: Recovery failed."
                echo "Error: Recovery failed." >> "${backup_folder}${log_file}"
            fi
        fi
    else
        zenity --info --text="No valid backups found for recovery."
        echo "No valid backups found for recovery."
    fi
    
    stop_backup_script
}

# Function to prompt user for options
prompt_options() {
    option=$(zenity --list --title="Backup Options" --column="Options" "Create Backup" "Recover Latest Backup" "Stop Backup Script")
    
    case $option in
        "Create Backup") create_backup ;;
        "Recover Latest Backup") recover_latest_backup ;;
        "Stop Backup Script") stop_backup_script ;;
        *) zenity --error --text="Invalid option selected." ;;
    esac
}

# Check if the backup folder exists; create it if not
if [ ! -d "${backup_folder}" ]; then
    mkdir -p "${backup_folder}"
fi

# Prompt user for options
prompt_options

# Ensure the log file exists; create it if not
touch "${backup_folder}${log_file}"

# Main loop for continuous backup (runs in the background)
while true; do
    create_backup 2>> "${backup_folder}${log_file}"
    sleep 5m # Adjust the interval as needed
done >> "${backup_folder}${log_file}" 2>&1 &
