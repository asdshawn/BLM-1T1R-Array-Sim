# BLM Memory 2x2 Array Simulation 📦⚡

Welcome to the **Bipolar Liquid Memory (BLM) Simulation Project**\!

This project provides a complete, containerized environment to simulate a next-generation non-volatile memory technology called **BLM** (Bipolar Liquid Memory). We have implemented a physics-based Verilog-A model and expanded it into a **2x2 1T1R (1 Transistor - 1 Resistor) Crossbar Array** to verify its read/write operations and anti-interference capabilities.

**No complex installation required\!** We use **Docker** to package all necessary tools (ngspice, OpenVAF, Ghostscript). If you can follow a few simple steps, you can run professional-grade circuit simulations.

-----

## 📚 What is BLM?

**BLM (Bipolar Liquid Memory)** is a hypothetical memory cell technology that stores data by changing its resistance state.

  * **SET Operation (Write 1):** Applying a positive voltage ($>0.75V$) switches the device to a **Low Resistance State (LRS)**.
  * **RESET Operation (Write 0):** Applying a negative voltage ($<-0.92V$) switches the device back to a **High Resistance State (HRS)**.

In this project, we simulate a **2x2 Array** using the **1T1R architecture**. This means every memory cell is paired with a selector transistor (NMOS) to ensure precise control and prevent electrical interference between neighboring cells.

-----

## 💻 System Requirements

To run this project, you only need a Windows computer capable of running WSL (Windows Subsystem for Linux).

  * **OS:** Windows 10 (Version 2004 or higher) or Windows 11.
  * **Architecture:** x64 processor with virtualization enabled in BIOS.
  * **RAM:** At least 4GB recommended.

-----

## 🛠️ Installation Guide (Step-by-Step)

### Step 1: Install WSL 2 (Windows Subsystem for Linux)

If you are on Windows, you need a Linux environment to run the scripts easily.

1.  Open **PowerShell** or **Command Prompt** as Administrator.
2.  Type the following command and press Enter:
    ```powershell
    wsl --install
    ```
3.  **Restart your computer** when prompted.
4.  After restarting, Ubuntu will open automatically. Follow the instructions to create a username and password.

### Step 2: Install Docker Desktop

Docker allows us to package the complex simulation tools (ngspice, OpenVAF) into a single "box" so you don't have to install them manually.

1.  Download **Docker Desktop for Windows** from [docker.com](https://www.docker.com/products/docker-desktop/).
2.  Run the installer. **Make sure to check the box "Use WSL 2 based engine"**.
3.  Once installed, open Docker Desktop settings:
      * Go to **Resources** \> **WSL Integration**.
      * Enable the integration for your Linux distribution (e.g., "Ubuntu").
      * Click **Apply & Restart**.

### Step 3: Get the Project Files

1.  Open your Ubuntu (WSL) terminal.
2.  Create a folder and download the project files (clone this repository if using Git).
    ```bash
    git clone https://github.com/asdshawn/BLM-1T1R-Array-Sim.git
    ```

-----

## 🚀 How to Run the Simulation

We have prepared a one-click script that handles everything: compiling the model, running the simulation, and converting the results into images.

### 1\. Build the Environment

First, we need to build the Docker image. This only needs to be done **once**.
Run this command in your terminal (inside the project folder):

```bash
docker build -t blm_env .
```

*Wait for the process to finish. It may take a few minutes to download necessary tools.*

### 2\. Run the Simulation Script

Now, use the following command to start the simulation. This command starts the Docker container and runs our automation script.

**Syntax:**

```bash
docker run --rm -v $(pwd):/work blm_env ./run.sh <SPICE_File> <VerilogA_File>
```

**Example (Running the 2x2 Array Test):**

```bash
docker run --rm -v $(pwd):/work blm_env ./run.sh 2x2_array.sp BLM_array.va
```

### 3\. View the Results

Once the script finishes (you will see "Done\! Generated X PNG images"), check your project folder in Windows.
You will see new **.png** image files (e.g., `array_result.png`).

  * **Red Line:** Shows the current in the target cell (switching between 0 and 1).
  * **Blue Line:** Shows the neighbor cell (remaining silent), proving the array works correctly without interference.

-----

## 📂 File Structure Description

  * **`Dockerfile`**: The recipe file that builds the simulation environment (installs Rust, ngspice, etc.).
  * **`run.sh`**: The automation script that compiles models and converts plots to PNG images.
  * **`BLM_array.va`**: The physics-based Verilog-A model of the BLM memory cell.
  * **`2x2_array.sp`**: The SPICE netlist describing the 2x2 circuit and the test sequence.
  * **`1T1R_test.sp`**: (Optional) A simpler test file for a single memory cell.

-----

## ❓ Troubleshooting

**Error: `bad interpreter: /bin/bash^M: No such file or directory`**

  * **Cause:** This happens if you edited the `run.sh` file in Windows Notepad, which adds invisible line endings (`CRLF`) that Linux doesn't like.
  * **Fix:** Run this command in your WSL terminal to fix the file:
    ```bash
    sed -i 's/\r$//' run.sh
    ```

**Error: `docker: command not found`**

  * **Cause:** Docker Desktop is not running or WSL integration is not enabled.
  * **Fix:** Open Docker Desktop on Windows, wait for the green whale icon, and check Settings \> Resources \> WSL Integration.