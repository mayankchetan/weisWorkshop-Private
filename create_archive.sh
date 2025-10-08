#!/bin/bash
# create_archive.sh
# Helper script to create compressed archives of specified folders with exclude patterns
# Created: September 29, 2025

# Set colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define folders to archive (edit this list as needed)
FOLDERS_TO_ARCHIVE=(
    "stage-0-baseline/outputs_preCompute"
    "stage-1-aeroStruct/outputs_preCompute"
    "stage-1-aeroStruct/outputs_nonOpti"
    "stage-2-controller/outputs_preCompute"
    "stage-3-semisub/outputs_preCompute"
    "stage-3-semisub/outputs_of_preCompute"
    "stage-3.5-semisubCCD/outputs_of_preCompute"
    "stage-4-dlcs/outputs_preCompute"
    "stage-4.5-dlcs/outputs_preCompute"
    # "examples"
    # "docs"
    # Add more folders here as needed
)

# Default archive name (can be overridden)
DEFAULT_ARCHIVE_NAME="archive_$(date +%Y%m%d_%H%M%S).tar.gz"

# Check if required tools are installed
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    if ! command -v tar &> /dev/null; then
        echo -e "${RED}Error: tar is not installed.${NC}"
        exit 1
    fi
    
    if ! command -v gzip &> /dev/null; then
        echo -e "${RED}Error: gzip is not installed.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies satisfied.${NC}"
}

# Ask yes/no question with default
ask_yes_no() {
    local prompt="$1"
    local default="$2"
    
    local yn_prompt
    if [ "$default" = "y" ]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi
    
    read -p "$prompt $yn_prompt: " answer
    
    if [ -z "$answer" ]; then
        answer=$default
    fi
    
    if [[ $answer =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Create .zipignore file if it doesn't exist
create_zipignore() {
    if [ ! -f ".zipignore" ]; then
        echo -e "${YELLOW}Creating default .zipignore file...${NC}"
        cat > .zipignore << 'EOF'
# Default exclude patterns for archive creation
# Add patterns for files/folders you want to exclude

# Compiled files and build artifacts
*.p


EOF
        echo -e "${GREEN}.zipignore file created with default patterns.${NC}"
        echo -e "${YELLOW}You can edit .zipignore to customize exclusion patterns.${NC}"
    else
        echo -e "${GREEN}Using existing .zipignore file.${NC}"
    fi
}

# Create .zipallow file if it doesn't exist
create_zipallow() {
    if [ ! -f ".zipallow" ]; then
        echo -e "${YELLOW}Creating default .zipallow file...${NC}"
        cat > .zipallow << 'EOF'
# Allow list for archive creation
# Files matching these patterns will be INCLUDED even if they match .zipignore patterns
# This is useful for including specific files that would otherwise be excluded
# 
# Examples:
# important_data.p        # Include this specific .p file
# */critical/*.p          # Include all .p files in any critical/ subdirectory
# config/settings.log     # Include this specific log file
# 
# Add your specific files/patterns below:

EOF
        echo -e "${GREEN}.zipallow file created.${NC}"
        echo -e "${YELLOW}You can edit .zipallow to specify files to include despite .zipignore patterns.${NC}"
    else
        echo -e "${GREEN}Using existing .zipallow file.${NC}"
    fi
}

# Display current configuration
show_config() {
    echo -e "${BLUE}Current Configuration:${NC}"
    echo -e "${GREEN}Folders to archive:${NC}"
    for folder in "${FOLDERS_TO_ARCHIVE[@]}"; do
        if [ -d "$folder" ]; then
            echo -e "  ✓ $folder (exists)"
        else
            echo -e "  ✗ $folder (not found)"
        fi
    done
    
    echo -e "\n${GREEN}Exclude patterns from .zipignore:${NC}"
    if [ -f ".zipignore" ]; then
        grep -v '^#' .zipignore | grep -v '^$' | head -10 | sed 's/^/  /'
        local total_patterns=$(grep -v '^#' .zipignore | grep -v '^$' | wc -l)
        if [ "$total_patterns" -gt 10 ]; then
            echo -e "  ... and $((total_patterns - 10)) more patterns"
        fi
    else
        echo -e "  ${YELLOW}No .zipignore file found${NC}"
    fi
    
    echo -e "\n${GREEN}Allow patterns from .zipallow (override exclusions):${NC}"
    if [ -f ".zipallow" ]; then
        local allow_patterns=$(grep -v '^#' .zipallow | grep -v '^$')
        if [ -n "$allow_patterns" ]; then
            echo "$allow_patterns" | head -10 | sed 's/^/  /'
            local total_allow=$(echo "$allow_patterns" | wc -l)
            if [ "$total_allow" -gt 10 ]; then
                echo -e "  ... and $((total_allow - 10)) more patterns"
            fi
        else
            echo -e "  ${YELLOW}No allow patterns defined${NC}"
        fi
    else
        echo -e "  ${YELLOW}No .zipallow file found${NC}"
    fi
}

# Calculate detailed size information with exclusions
calculate_detailed_size() {
    echo -e "${YELLOW}Calculating detailed size information...${NC}"
    
    local existing_folders=()
    local exclude_file=$(mktemp)
    
    # Get existing folders
    for folder in "${FOLDERS_TO_ARCHIVE[@]}"; do
        if [ -d "$folder" ]; then
            existing_folders+=("$folder")
        fi
    done
    
    if [ ${#existing_folders[@]} -eq 0 ]; then
        echo -e "${RED}No valid folders found to archive!${NC}"
        rm -f "$exclude_file"
        return 1
    fi
    
    # Create exclude patterns
    if [ -f ".zipignore" ]; then
        grep -v '^#' .zipignore | grep -v '^$' > "$exclude_file"
    else
        touch "$exclude_file"
    fi
    
    # Calculate total size without exclusions first
    local total_size_kb=$(du -sk "${existing_folders[@]}" 2>/dev/null | awk '{sum += $1} END {print sum}')
    
    # Calculate size with exclusions using tar --totals (dry run)
    echo -e "${BLUE}Calculating size with exclusions (this may take a moment)...${NC}"
    
    local tar_options="--create --totals"
    if [ -s "$exclude_file" ]; then
        tar_options="$tar_options --exclude-from=$exclude_file"
    fi
    
    # Capture tar output to get actual size that will be archived
    local tar_output=$(tar $tar_options --file=/dev/null "${existing_folders[@]}" 2>&1)
    local actual_size_bytes=$(echo "$tar_output" | grep "Total bytes written" | awk '{print $4}' | tr -d '(' | tr -d ')')
    
    if [ -n "$actual_size_bytes" ] && [ "$actual_size_bytes" -gt 0 ]; then
        local actual_size_kb=$((actual_size_bytes / 1024))
    else
        # Fallback: estimate by excluding common patterns manually
        local excluded_size_kb=0
        if [ -s "$exclude_file" ]; then
            while IFS= read -r pattern; do
                local pattern_size=$(find "${existing_folders[@]}" -name "$pattern" -type f -exec du -sk {} + 2>/dev/null | awk '{sum += $1} END {print sum}' || echo 0)
                excluded_size_kb=$((excluded_size_kb + pattern_size))
            done < "$exclude_file"
        fi
        local actual_size_kb=$((total_size_kb - excluded_size_kb))
        if [ "$actual_size_kb" -lt 0 ]; then
            actual_size_kb=$total_size_kb
        fi
    fi
    
    # Convert to human readable formats
    local total_size_mb=$((total_size_kb / 1024))
    local total_size_gb=$((total_size_mb / 1024))
    local actual_size_mb=$((actual_size_kb / 1024))
    local actual_size_gb=$((actual_size_mb / 1024))
    
    # Estimate compressed size (typical gzip compression ratio is 3-5x for text/code files)
    # Use conservative estimate of 3x for mixed content
    local estimated_compressed_kb=$((actual_size_kb / 3))
    local estimated_compressed_mb=$((estimated_compressed_kb / 1024))
    local estimated_compressed_gb=$((estimated_compressed_mb / 1024))
    
    echo -e "${BLUE}Size Analysis:${NC}"
    
    # Display total size
    if [ "$total_size_gb" -gt 0 ]; then
        echo -e "${YELLOW}Total folder size (before exclusions): ${total_size_gb}GB (${total_size_mb}MB)${NC}"
    else
        echo -e "${YELLOW}Total folder size (before exclusions): ${total_size_mb}MB${NC}"
    fi
    
    # Display actual size to be archived
    if [ "$actual_size_gb" -gt 0 ]; then
        echo -e "${GREEN}Size to be archived (after exclusions): ${actual_size_gb}GB (${actual_size_mb}MB)${NC}"
    else
        echo -e "${GREEN}Size to be archived (after exclusions): ${actual_size_mb}MB${NC}"
    fi
    
    # Display estimated compressed size
    if [ "$estimated_compressed_gb" -gt 0 ]; then
        echo -e "${BLUE}Estimated compressed size: ${estimated_compressed_gb}GB (${estimated_compressed_mb}MB)${NC}"
    else
        echo -e "${BLUE}Estimated compressed size: ${estimated_compressed_mb}MB${NC}"
    fi
    
    # Show savings from exclusions
    if [ "$total_size_kb" -gt "$actual_size_kb" ]; then
        local saved_kb=$((total_size_kb - actual_size_kb))
        local saved_mb=$((saved_kb / 1024))
        local saved_percent=$((saved_kb * 100 / total_size_kb))
        echo -e "${GREEN}Space saved by exclusions: ${saved_mb}MB (${saved_percent}%)${NC}"
    fi
    
    # Show file count
    local file_count=$(find "${existing_folders[@]}" -type f | wc -l)
    echo -e "${BLUE}Approximate file count: ${file_count}${NC}"
    
    rm -f "$exclude_file"
    return 0
}

# Simple size calculation for backward compatibility
calculate_source_size() {
    local existing_folders=()
    
    for folder in "${FOLDERS_TO_ARCHIVE[@]}"; do
        if [ -d "$folder" ]; then
            existing_folders+=("$folder")
        fi
    done
    
    if [ ${#existing_folders[@]} -eq 0 ]; then
        return 1
    fi
    
    local size_kb=$(du -sk "${existing_folders[@]}" 2>/dev/null | awk '{sum += $1} END {print sum}')
    local size_mb=$((size_kb / 1024))
    local size_gb=$((size_mb / 1024))
    
    if [ "$size_gb" -gt 0 ]; then
        echo -e "${GREEN}Total source size: ~${size_gb}GB (${size_mb}MB)${NC}"
    else
        echo -e "${GREEN}Total source size: ~${size_mb}MB${NC}"
    fi
    
    return 0
}

# Create the archive
create_archive() {
    echo -e "${BLUE}Preparing to create archive...${NC}"
    
    # Check if folders exist
    local existing_folders=()
    for folder in "${FOLDERS_TO_ARCHIVE[@]}"; do
        if [ -d "$folder" ]; then
            existing_folders+=("$folder")
        else
            echo -e "${YELLOW}Warning: Folder '$folder' not found, skipping...${NC}"
        fi
    done
    
    if [ ${#existing_folders[@]} -eq 0 ]; then
        echo -e "${RED}Error: No valid folders found to archive!${NC}"
        return 1
    fi
    
    # Ask for archive name
    read -p "Enter archive name (or press Enter for default): " ARCHIVE_NAME
    ARCHIVE_NAME=${ARCHIVE_NAME:-$DEFAULT_ARCHIVE_NAME}
    
    # Add .tar.gz extension if not present
    if [[ ! "$ARCHIVE_NAME" =~ \.(tar\.gz|tgz)$ ]]; then
        ARCHIVE_NAME="${ARCHIVE_NAME}.tar.gz"
    fi
    
    # Check if file already exists
    if [ -f "$ARCHIVE_NAME" ]; then
        if ! ask_yes_no "Archive '$ARCHIVE_NAME' already exists. Overwrite?" "n"; then
            echo -e "${RED}Archive creation cancelled.${NC}"
            return 1
        fi
    fi
    
    # Calculate detailed size information
    if ! calculate_detailed_size; then
        return 1
    fi
    
    # Show what will be archived
    echo -e "\n${GREEN}Folders to be archived:${NC}"
    for folder in "${existing_folders[@]}"; do
        echo -e "  • $folder"
    done
    
    if ! ask_yes_no "Continue with archive creation?" "y"; then
        echo -e "${RED}Archive creation cancelled.${NC}"
        return 1
    fi
    
    # Create exclude file from .zipignore
    local exclude_file=$(mktemp)
    if [ -f ".zipignore" ]; then
        # Convert .zipignore patterns to tar exclude format
        grep -v '^#' .zipignore | grep -v '^$' > "$exclude_file"
        echo -e "${GREEN}Using exclusion patterns from .zipignore${NC}"
    else
        touch "$exclude_file"
        echo -e "${YELLOW}No .zipignore file found, archiving without exclusions${NC}"
    fi
    
    echo -e "${GREEN}Creating archive with maximum compression...${NC}"
    echo -e "${YELLOW}This may take some time depending on the size of your folders.${NC}"
    
    # Create archive with maximum compression and progress
    local tar_options="--create --gzip --file=$ARCHIVE_NAME"
    
    if [ -s "$exclude_file" ]; then
        tar_options="$tar_options --exclude-from=$exclude_file"
    fi
    
    # Add verbose option if requested
    if ask_yes_no "Show files as they're archived?" "n"; then
        tar_options="$tar_options --verbose"
    fi
    
    # Set maximum compression for gzip
    export GZIP=-9
    
    echo -e "${GREEN}Running: tar $tar_options ${existing_folders[*]}${NC}"
    
    if tar $tar_options "${existing_folders[@]}"; then
        echo -e "${GREEN}Archive created successfully!${NC}"
        
        # Show archive information
        local archive_size=$(ls -lh "$ARCHIVE_NAME" | awk '{print $5}')
        echo -e "${GREEN}Archive file: $ARCHIVE_NAME${NC}"
        echo -e "${GREEN}Archive size: $archive_size${NC}"
        
        # Calculate compression ratio
        local original_size_kb=$(du -sk "${existing_folders[@]}" 2>/dev/null | awk '{sum += $1} END {print sum}')
        local archive_size_kb=$(du -sk "$ARCHIVE_NAME" | awk '{print $1}')
        
        if [ "$original_size_kb" -gt 0 ]; then
            local compression_ratio=$(echo "scale=1; $original_size_kb / $archive_size_kb" | bc 2>/dev/null || echo "N/A")
            echo -e "${GREEN}Compression ratio: ${compression_ratio}:1${NC}"
        fi
    else
        echo -e "${RED}Error: Archive creation failed!${NC}"
        rm -f "$exclude_file"
        return 1
    fi
    
    # Clean up temporary file
    rm -f "$exclude_file"
}

# Edit folders list interactively
edit_folders() {
    echo -e "${BLUE}Current folders to archive:${NC}"
    for i in "${!FOLDERS_TO_ARCHIVE[@]}"; do
        echo -e "$((i+1)). ${FOLDERS_TO_ARCHIVE[$i]}"
    done
    
    echo -e "\nOptions:"
    echo -e "1. Add a folder"
    echo -e "2. Remove a folder"
    echo -e "3. Clear all folders"
    echo -e "4. Return to main menu"
    
    read -p "Select option (1-4): " edit_choice
    
    case $edit_choice in
        1)
            read -p "Enter folder name to add: " new_folder
            if [ -n "$new_folder" ]; then
                FOLDERS_TO_ARCHIVE+=("$new_folder")
                echo -e "${GREEN}Added: $new_folder${NC}"
            fi
            ;;
        2)
            read -p "Enter folder number to remove (1-${#FOLDERS_TO_ARCHIVE[@]}): " remove_idx
            if [[ "$remove_idx" =~ ^[0-9]+$ ]] && [ "$remove_idx" -ge 1 ] && [ "$remove_idx" -le "${#FOLDERS_TO_ARCHIVE[@]}" ]; then
                removed_folder="${FOLDERS_TO_ARCHIVE[$((remove_idx-1))]}"
                unset "FOLDERS_TO_ARCHIVE[$((remove_idx-1))]"
                FOLDERS_TO_ARCHIVE=("${FOLDERS_TO_ARCHIVE[@]}")  # Re-index array
                echo -e "${GREEN}Removed: $removed_folder${NC}"
            else
                echo -e "${RED}Invalid folder number${NC}"
            fi
            ;;
        3)
            if ask_yes_no "Clear all folders from the list?" "n"; then
                FOLDERS_TO_ARCHIVE=()
                echo -e "${GREEN}All folders cleared${NC}"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    press_any_key
    edit_folders
}

# List available archives in current directory
list_archives() {
    echo -e "${BLUE}Available archives in current directory:${NC}"
    
    local archives=($(ls *.tar.gz *.tgz 2>/dev/null))
    
    if [ ${#archives[@]} -eq 0 ]; then
        echo -e "${YELLOW}No .tar.gz or .tgz files found in current directory.${NC}"
        return 1
    fi
    
    for i in "${!archives[@]}"; do
        local archive="${archives[$i]}"
        local size=$(ls -lh "$archive" | awk '{print $5}')
        local date=$(ls -l "$archive" | awk '{print $6, $7, $8}')
        echo -e "$((i+1)). $archive (${size}, ${date})"
    done
    
    return 0
}

# Show archive contents
show_archive_contents() {
    local archive_file="$1"
    
    echo -e "${BLUE}Contents of $archive_file:${NC}"
    
    if ! tar -tzf "$archive_file" >/dev/null 2>&1; then
        echo -e "${RED}Error: Invalid or corrupted archive file.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Archive structure:${NC}"
    tar -tzf "$archive_file" | head -20
    
    local total_files=$(tar -tzf "$archive_file" | wc -l)
    if [ "$total_files" -gt 20 ]; then
        echo -e "${YELLOW}... and $((total_files - 20)) more files/directories${NC}"
    fi
    
    echo -e "${GREEN}Total entries in archive: $total_files${NC}"
    
    # Show top-level directories
    echo -e "${YELLOW}Top-level directories in archive:${NC}"
    tar -tzf "$archive_file" | cut -d'/' -f1 | sort -u | head -10
    
    return 0
}

# Extract archive with path restoration
extract_archive() {
    echo -e "${BLUE}Archive Extraction Utility${NC}"
    
    # List available archives or ask for file
    if ! list_archives; then
        read -p "Enter path to archive file: " archive_file
        if [ ! -f "$archive_file" ]; then
            echo -e "${RED}Error: Archive file '$archive_file' not found.${NC}"
            return 1
        fi
    else
        echo
        read -p "Select archive number or enter path to archive file: " selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]]; then
            local archives=($(ls *.tar.gz *.tgz 2>/dev/null))
            if [ "$selection" -ge 1 ] && [ "$selection" -le "${#archives[@]}" ]; then
                archive_file="${archives[$((selection-1))]}"
            else
                echo -e "${RED}Invalid selection.${NC}"
                return 1
            fi
        else
            archive_file="$selection"
            if [ ! -f "$archive_file" ]; then
                echo -e "${RED}Error: Archive file '$archive_file' not found.${NC}"
                return 1
            fi
        fi
    fi
    
    echo -e "${GREEN}Selected archive: $archive_file${NC}"
    
    # Show archive contents
    if ask_yes_no "Would you like to see the archive contents first?" "y"; then
        show_archive_contents "$archive_file"
        echo
    fi
    
    # Verify archive integrity
    echo -e "${YELLOW}Verifying archive integrity...${NC}"
    if ! tar -tzf "$archive_file" >/dev/null 2>&1; then
        echo -e "${RED}Error: Archive appears to be corrupted or invalid.${NC}"
        return 1
    fi
    echo -e "${GREEN}Archive integrity verified.${NC}"
    
    # Ask for extraction options
    echo -e "${BLUE}Extraction Options:${NC}"
    echo -e "1. Extract to original locations (recommended for same system)"
    echo -e "2. Extract to current directory (preserves relative paths)"
    echo -e "3. Extract to specific directory"
    echo -e "4. Cancel extraction"
    
    read -p "Select option (1-4): " extract_option
    
    case $extract_option in
        1)
            # Extract to original locations (from root /)
            echo -e "${YELLOW}Extracting to original paths...${NC}"
            echo -e "${RED}Warning: This will overwrite files at their original locations!${NC}"
            
            if ! ask_yes_no "Continue with extraction to original paths?" "n"; then
                echo -e "${RED}Extraction cancelled.${NC}"
                return 1
            fi
            
            # Extract from root directory
            echo -e "${GREEN}Extracting archive from root directory...${NC}"
            if ask_yes_no "Show files as they're extracted?" "n"; then
                sudo tar -xvzf "$PWD/$archive_file" -C /
            else
                sudo tar -xzf "$PWD/$archive_file" -C /
            fi
            ;;
            
        2)
            # Extract to current directory
            echo -e "${YELLOW}Extracting to current directory...${NC}"
            
            if ask_yes_no "Show files as they're extracted?" "n"; then
                tar -xvzf "$archive_file"
            else
                tar -xzf "$archive_file"
            fi
            ;;
            
        3)
            # Extract to specific directory
            read -p "Enter destination directory: " dest_dir
            
            if [ ! -d "$dest_dir" ]; then
                if ask_yes_no "Directory '$dest_dir' doesn't exist. Create it?" "y"; then
                    mkdir -p "$dest_dir"
                else
                    echo -e "${RED}Extraction cancelled.${NC}"
                    return 1
                fi
            fi
            
            echo -e "${YELLOW}Extracting to $dest_dir...${NC}"
            
            if ask_yes_no "Show files as they're extracted?" "n"; then
                tar -xvzf "$archive_file" -C "$dest_dir"
            else
                tar -xzf "$archive_file" -C "$dest_dir"
            fi
            ;;
            
        4)
            echo -e "${RED}Extraction cancelled.${NC}"
            return 1
            ;;
            
        *)
            echo -e "${RED}Invalid option.${NC}"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Extraction completed successfully!${NC}"
        
        # Show what was extracted
        local extracted_files=$(tar -tzf "$archive_file" | wc -l)
        echo -e "${GREEN}Extracted $extracted_files files/directories${NC}"
        
        # Show top-level items that were extracted
        echo -e "${BLUE}Top-level items extracted:${NC}"
        case $extract_option in
            1) echo -e "${YELLOW}Files restored to their original system paths${NC}" ;;
            2) tar -tzf "$archive_file" | cut -d'/' -f1 | sort -u | head -5 ;;
            3) echo -e "${YELLOW}Files extracted to: $dest_dir${NC}" ;;
        esac
        
    else
        echo -e "${RED}Extraction failed!${NC}"
        return 1
    fi
}

# Main menu
main_menu() {
    echo "================================================"
    echo "     Archive Management Utility (tar.gz)       "
    echo "================================================"
    echo "CREATION:"
    echo "1. Show current configuration"
    echo "2. Edit folders to archive" 
    echo "3. Create/edit .zipignore file"
    echo "4. Create archive"
    echo ""
    echo "EXTRACTION:"
    echo "5. List available archives"
    echo "6. Extract archive"
    echo "7. Show archive contents"
    echo ""
    echo "8. Exit"
    echo "================================================"
    read -p "Select an option (1-8): " CHOICE
    
    case $CHOICE in
        1) show_config; press_any_key; main_menu ;;
        2) edit_folders; main_menu ;;
        3) create_zipignore; if ask_yes_no "Edit .zipignore file now?" "y"; then ${EDITOR:-nano} .zipignore; fi; press_any_key; main_menu ;;
        4) create_archive; press_any_key; main_menu ;;
        5) list_archives; press_any_key; main_menu ;;
        6) extract_archive; press_any_key; main_menu ;;
        7) 
            if list_archives; then
                echo
                read -p "Enter archive number or path: " archive_selection
                local archives=($(ls *.tar.gz *.tgz 2>/dev/null))
                
                if [[ "$archive_selection" =~ ^[0-9]+$ ]] && [ "$archive_selection" -ge 1 ] && [ "$archive_selection" -le "${#archives[@]}" ]; then
                    show_archive_contents "${archives[$((archive_selection-1))]}"
                elif [ -f "$archive_selection" ]; then
                    show_archive_contents "$archive_selection"
                else
                    echo -e "${RED}Invalid selection or file not found.${NC}"
                fi
            fi
            press_any_key; main_menu ;;
        8) echo "Exiting."; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}"; press_any_key; main_menu ;;
    esac
}

press_any_key() {
    echo
    read -n 1 -s -r -p "Press any key to continue..."
    echo
}

# Main execution
main() {
    echo -e "${BLUE}Archive Management Utility${NC}"
    echo -e "${YELLOW}Create and extract tar.gz archives with maximum compression${NC}"
    echo -e "${YELLOW}Perfect for backing up large files before git operations${NC}"
    echo
    
    check_dependencies
    create_zipignore
    main_menu
}

# Run the script
main
