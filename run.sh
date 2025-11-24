#!/bin/bash

# ==============================================================================
# PART 1: HOST SIDE BOOTSTRAP
# This section checks if we are running on the host machine.
# If so, it spins up the Docker container and runs this script inside it.
# ==============================================================================

# Check for the existence of the Docker environment file
if [ ! -f "/.dockerenv" ]; then
    echo "[Host] 🚀 Detected Host Environment. Launching Docker Container..."

    # Check arguments on Host side
    if [ "$#" -ne 2 ]; then
        echo "Error: Invalid number of arguments."
        echo "Usage: ./run.sh <spice_file.sp> <veriloga_file.va>"
        echo "Example: ./run.sh 1T1R_test.sp BLM_array.va"
        exit 1
    fi

    # Run Docker
    # --rm: Remove container after exit
    # -v "$(pwd):/work": Mount current folder to /work
    # blm_env: The image name
    # "$0": This script name (e.g., ./run.sh)
    # "$@": Pass all arguments (file names) to the script inside Docker
    docker run --rm -v "$(pwd):/work" blm_env "$0" "$@"
    
    # Exit the host script after Docker finishes
    exit $?
fi

# ==============================================================================
# PART 2: CONTAINER SIDE LOGIC
# This section runs ONLY inside the Docker container.
# It performs the actual compilation, simulation, and image conversion.
# ==============================================================================

echo "[Docker] 📦 Inside Container. Starting Simulation Workflow..."

SP_FILE="$1"
VA_FILE="$2"

# 1. Check file existence inside Docker
if [ ! -f "$SP_FILE" ]; then
    echo "Error: SPICE file '$SP_FILE' not found."
    exit 1
fi

if [ ! -f "$VA_FILE" ]; then
    echo "Error: Verilog-A file '$VA_FILE' not found."
    exit 1
fi

# 2. Clean up old PostScript files to avoid confusion
echo "[Docker] 🧹 Cleaning up old .ps files..."
rm -f *.ps

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
if ! ngspice -b "$SP_FILE"; then
    echo "Simulation failed! Please check your SPICE netlist."
    exit 1
fi

# 5. Convert Images and Clean Up
echo "========================================"
echo ">>> Step 3/3: Converting Images..."
echo "========================================"

count=0
# Loop through all generated .ps files
for ps_file in *.ps; do
    # Check if file exists (handles case where no .ps files are generated)
    [ -e "$ps_file" ] || continue

    # Generate PNG filename
    png_file="${ps_file%.ps}.png"
    
    echo "  [Converting] $ps_file -> $png_file"
    
    # Convert PS to PNG using Ghostscript
    # -sDEVICE=png16m : 24-bit color PNG
    # -r300           : High resolution (300 DPI)
    gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile="$png_file" "$ps_file" > /dev/null 2>&1
    
    # Remove the original PS file after conversion (as requested)
    rm "$ps_file"
    
    count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
    echo "⚠️  Warning: No .ps files found."
    echo "    Please ensure your .sp file uses the 'hardcopy' command."
else
    echo "✅ Done! Generated $count PNG images."
fi