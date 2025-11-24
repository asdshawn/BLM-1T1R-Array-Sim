#!/bin/bash

# ==============================================================================
# PART 1: HOST SIDE BOOTSTRAP
# This section checks if we are running on the host machine.
# ==============================================================================

if [ ! -f "/.dockerenv" ]; then
    echo "[Host] 🚀 Detected Host Environment. Launching Docker Container..."

    # 1. Check argument count
    if [ "$#" -ne 2 ]; then
        echo "Error: Invalid number of arguments."
        echo "Usage: ./run.sh <spice_file.sp> <veriloga_file.va>"
        echo "Example: ./run.sh 1T1R_test.sp BLM_array.va"
        exit 1
    fi

    # 2. Run Docker
    docker run --rm -v "$(pwd):/work" blm_env "$0" "$@"
    
    EXIT_CODE=$?

    # 3. Open images ONLY if simulation was successful
    if [ $EXIT_CODE -eq 0 ]; then
        echo "----------------------------------------"
        
        # Check if the manifest file exists
        if [ -f "generated_images.list" ]; then
            echo "[Host] 🖼️  Opening images generated in 'plot' folder..."
            
            while IFS= read -r img; do
                # Remove Windows carriage return if present
                img=$(echo "$img" | tr -d '\r')
                
                if [ -f "$img" ]; then
                    echo "  -> Opening: $img"
                    if command -v explorer.exe &> /dev/null; then
                        explorer.exe "$(wslpath -w -a "$img")" < /dev/null
                    elif command -v open &> /dev/null; then
                        open "$img" < /dev/null
                    elif command -v xdg-open &> /dev/null; then
                        xdg-open "$img" < /dev/null &
                    fi
                fi
            done < "generated_images.list"
            
            # Clean up the manifest file (but keep the images in plot folder)
            rm -f "generated_images.list"
        else
            echo "[Host] No new images were generated."
        fi
    fi
    
    exit $EXIT_CODE
fi

# ==============================================================================
# PART 2: CONTAINER SIDE LOGIC
# This section runs ONLY inside the Docker container.
# ==============================================================================

echo "[Docker] 📦 Inside Container. Starting Simulation Workflow..."

SP_FILE="$1"
VA_FILE="$2"

# 1. Check input files
if [ ! -f "$SP_FILE" ]; then
    echo "Error: SPICE file '$SP_FILE' not found."
    exit 1
fi

if [ ! -f "$VA_FILE" ]; then
    echo "Error: Verilog-A file '$VA_FILE' not found."
    exit 1
fi

# 2. Prepare Output Directory & Clean up
echo "[Docker] 🧹 Preparing 'plot' folder..."
# Create directory if not exists
mkdir -p plot
# Remove old artifacts
rm -f *.ps 
rm -f generated_images.list
# Clean only old pngs in the plot folder to avoid confusion
rm -f plot/*.png

# 3. Compile Verilog-A Model
echo "========================================"
echo ">>> Step 1/3: Compiling Model $VA_FILE"
echo "========================================"
if ! openvaf "$VA_FILE"; then
    echo "Compilation failed! Please check your Verilog-A code."
    exit 1
fi

# 4. Run SPICE Simulation
echo "========================================"
echo ">>> Step 2/3: Running Simulation $SP_FILE"
echo "========================================"
# -b: Batch mode (no GUI inside Docker)
if ! ngspice -b "$SP_FILE"; then
    echo "Simulation failed! Please check your SPICE netlist."
    exit 1
fi

# 5. Convert Images and Move to 'plot' folder
echo "========================================"
echo ">>> Step 3/3: Converting Images -> plot/..."
echo "========================================"

count=0
# Loop through all generated PostScript (.ps) files
for ps_file in *.ps; do
    # Check if file exists
    [ -e "$ps_file" ] || continue

    # Define PNG filename inside 'plot' directory
    png_name="${ps_file%.ps}.png"
    out_path="plot/$png_name"
    
    echo "  [Converting] $ps_file -> $out_path"
    
    # Convert PS to PNG (High Quality)
    gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile="$out_path" "$ps_file" > /dev/null 2>&1
    
    # Add the full path to the manifest list
    echo "$out_path" >> generated_images.list
    
    # Clean up the .ps file immediately
    rm -f "$ps_file"
    
    count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
    echo "⚠️  Warning: No .ps files found."
    echo "    Please ensure your .sp file uses the 'hardcopy' command."
else
    echo "✅ Done! Generated $count PNG images in 'plot' folder."
fi