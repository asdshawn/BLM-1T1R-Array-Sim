#!/bin/bash

# 1. Check argument count
if [ "$#" -ne 2 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: ./run.sh <spice_file.sp> <veriloga_file.va>"
    echo "Example: ./run.sh 1T1R_test.sp BLM_memory.va"
    exit 1
fi

SP_FILE="$1"
VA_FILE="$2"

# 2. Check file existence
if [ ! -f "$SP_FILE" ]; then
    echo "Error: SPICE file '$SP_FILE' not found."
    exit 1
fi

if [ ! -f "$VA_FILE" ]; then
    echo "Error: Verilog-A file '$VA_FILE' not found."
    exit 1
fi

# 3. Clean up old PostScript files to avoid confusion
rm -f *.ps

# 4. Compile Verilog-A Model
echo "========================================"
echo ">>> Step 1/3: Compiling Model $VA_FILE"
echo "========================================"
if ! openvaf "$VA_FILE"; then
    echo "Compilation failed! Please check your Verilog-A code."
    exit 1
fi

# 5. Run SPICE Simulation
echo "========================================"
echo ">>> Step 2/3: Running Simulation $SP_FILE"
echo "========================================"
if ! ngspice -b "$SP_FILE"; then
    echo "Simulation failed! Please check your SPICE netlist."
    exit 1
fi

# 6. Convert Images and Clean Up
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
    gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile="$png_file" "$ps_file" > /dev/null 2>&1
    
    # Remove the original PS file after conversion
    rm "$ps_file"
    
    count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
    echo "⚠️  Warning: No .ps files found."
    echo "    Please ensure your .sp file uses the 'hardcopy' command."
else
    echo "✅ Done! Generated $count PNG images."
fi