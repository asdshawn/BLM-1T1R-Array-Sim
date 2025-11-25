* ==============================================================================
* 2x2 Memory Array Simulation with Distributed RC Parasitics
* * This netlist models a 2x2 Crossbar Array using 1T1R cells.
* Unlike the ideal model, this version includes wire resistance and capacitance
* based on the specification (R=10 Ohm/cell, C=30 aF/cell).
* ==============================================================================

* ------------------------------------------------------------------------------
* 1. Model Configuration & Simulation Control
* ------------------------------------------------------------------------------

* Define the Verilog-A memory model (must match your .osdi file)
.model blm_memory blm_memory

* Define the NMOS selector model (Level 1 model using parameters from Spec Page 15)
.model nmos_page9 nmos level=1 vto=0.49 kp=12.95u gamma=0 lambda=0

.control
    * Enable PSpice compatibility mode
    set ngbehavior=ps
    
    * Load the compiled Verilog-A object file
    pre_osdi BLM_memory_v2.osdi
    
    * Simulation Settings:
    * 'gear': A stable integration method for switching circuits.
    * 'reltol': Relaxed tolerance (1%) to help convergence during rapid switching.
    option method=gear
    option reltol=0.01
    
    * Run Transient Analysis:
    * Step size: 10us, Total time: 80ms, Start saving at: 0, Max step: 1us
    tran 10u 80m 0 1u

    * --- Plotting / Output Configuration ---
    * Set output format to PostScript for file generation
    set hcopydevtype = postscript
    set hcopypscolor = 1

    * Plot 1: Voltage Drop Analysis (IR Drop)
    * Compares the voltage at the source driver (src_BL0) vs. the actual cell (BL0_n0).
    * In small arrays (2x2), these will look similar. In large arrays, they will differ.
    hardcopy rc_voltage.ps v(src_BL0) v(BL0_n0) title 'IR Drop Check (Source vs Cell)'

    * Plot 2: Current Selectivity
    * Compares current in the Active Bitline (BL0) vs. the Inactive Bitline (BL1).
    hardcopy rc_current.ps abs(i(V_BL0)) abs(i(V_BL1)) ylabel 'Current (A)' title 'Array with RC Parasitics'
.endc

* ------------------------------------------------------------------------------
* 2. Subcircuit Definition: 1T1R Cell
* ------------------------------------------------------------------------------
* This defines a single memory bit consisting of:
* 1. An Access Transistor (NMOS) for selection.
* 2. A Memory Device (BLM) for data storage.
* 3. A small stabilizing capacitor to aid simulation convergence.
.subckt CELL_1T1R my_BL my_WL my_SL
    * NMOS Transistor: Drain connected to Bitline, Gate to Wordline
    M_access N_internal my_WL my_BL 0 nmos_page9 W=20n L=20n
    
    * Stabilization Capacitor (0.1pF) at the internal node
    C_stab N_internal my_SL 0.1p
    
    * Memory Device: Connected between internal node and Source Line
    N_mem N_internal my_SL blm_memory
.ends

* ------------------------------------------------------------------------------
* 3. Array Construction with Parasitics
* ------------------------------------------------------------------------------
* Instead of connecting cells directly to voltage sources, we simulate the physical
* wires using a "Ladder Network" of Resistors and Capacitors.

* Define Parasitic Values 
.param R_wire = 10   ; 10 Ohms per cell
.param C_wire = 30a  ; 30 atto-Farads per cell

* --- Word Line 0 (Row 0) Interconnects ---
* Path: Driver -> Resistor -> Node0 -> Resistor -> Node1
R_w0_0  WL0_src WL0_n0  {R_wire}
C_w0_0  WL0_n0  0       {C_wire}

R_w0_1  WL0_n0  WL0_n1  {R_wire}
C_w0_1  WL0_n1  0       {C_wire}

* --- Word Line 1 (Row 1) Interconnects ---
R_w1_0  WL1_src WL1_n0  {R_wire}
C_w1_0  WL1_n0  0       {C_wire}

R_w1_1  WL1_n0  WL1_n1  {R_wire}
C_w1_1  WL1_n1  0       {C_wire}

* --- Bit Line 0 (Column 0) Interconnects ---
R_b0_0  BL0_in  BL0_n0  {R_wire}
C_b0_0  BL0_n0  0       {C_wire}

R_b0_1  BL0_n0  BL0_n1  {R_wire}
C_b0_1  BL0_n1  0       {C_wire}

* --- Bit Line 1 (Column 1) Interconnects ---
R_b1_0  BL1_in  BL1_n0  {R_wire}
C_b1_0  BL1_n0  0       {C_wire}

R_b1_1  BL1_n0  BL1_n1  {R_wire}
C_b1_1  BL1_n1  0       {C_wire}

* --- Cell Instantiation ---
* We connect each cell to the corresponding nodes in the parasitic network.

* Cell (0,0): The Target Cell (Active WL, Active BL)
X00 BL0_n0 WL0_n0 0 CELL_1T1R

* Cell (0,1): Neighbor in same Row (Active WL, Inactive BL)
X01 BL1_n0 WL0_n1 0 CELL_1T1R

* Cell (1,0): Neighbor in same Column (Inactive WL, Active BL)
X10 BL0_n1 WL1_n0 0 CELL_1T1R

* Cell (1,1): Diagonal Neighbor (Inactive WL, Inactive BL)
X11 BL1_n1 WL1_n1 0 CELL_1T1R

* ------------------------------------------------------------------------------
* 4. Peripheral Circuits (Drivers)
* ------------------------------------------------------------------------------

* --- Bit Line 0 Driver (Active) ---
* Generates the test pattern: SET -> READ -> RESET -> READ -> DISTURB
V_BL0 src_BL0 0 PWL(
+ 0    0
+ 10m  0    10.1m 4.0   15m  4.0   15.1m 0    ; SET Pulse (Write 1, 4V)
+ 25m  0    25.1m 0.5   30m  0.5   30.1m 0    ; READ Pulse (Verify 1, 0.5V)
+ 40m  0    40.1m -4.0  45m  -4.0  46m  0    ; RESET Pulse (Write 0, -4V)
+ 55m  0    55.1m 0.5   60m  0.5   60.1m 0    ; READ Pulse (Verify 0, 0.5V)
+ 70m  0    70.1m 4.0   75m  4.0   75.1m 0    ; Disturb Check (Write 1 attempt with WL off)
+ )
* Driver Internal Resistance (2k Ohm) - distinct from wire parasitics
R_drive_BL0 src_BL0 BL0_in 2k

* --- Bit Line 1 Driver (Inactive) ---
* Held at 0V to test isolation
V_BL1 src_BL1 0 DC 0
R_drive_BL1 src_BL1 BL1_in 2k

* --- Word Line 0 Driver (Active) ---
* Activates Row 0 from 5ms to 60ms
V_WL0 WL0_src 0 PWL(0 0 5m 0 5.1m 2.0 60m 2.0 60.1m 0)

* --- Word Line 1 Driver (Inactive) ---
* Keeps Row 1 turned off
V_WL1 WL1_src 0 DC 0

.end