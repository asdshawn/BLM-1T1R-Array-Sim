* 2x2 Memory Array Simulation (1T1R Architecture)

* ==========================================
* 1. Model Definitions
* ==========================================
* Define the memory model (links to the OSDI file)
.model blm_memory blm_memory

* Define the NMOS selector model (Parameters from Spec Page 15)
* Level 1 model is used for basic behavior verification
.model nmos_page9 nmos level=1 vto=0.49 kp=12.95u gamma=0 lambda=0

.control
    * Enable PS compatibility and load the compiled Verilog-A object
    set ngbehavior=ps
    pre_osdi BLM_memory_v2.osdi
    
    * Simulation settings for stability
    option method=gear
    option reltol=0.01
    
    * Run transient analysis for 80ms
    tran 10u 80m 0 1u

    * --- PostScript ---
    set hcopydevtype = postscript
    set hcopypscolor = 1

    * --- 1. Control Signals ---
    hardcopy array_control.ps v(WL0) v(BL0)+6 title 'Control Signals (Active Cell)' xlabel 'Time' ylabel 'Voltage'

    * --- 2. Selectivity Test ---
    hardcopy array_current.ps abs(i(V_BL0)) abs(i(V_BL1)) title 'Array Selectivity Test (Abs)' xlabel 'Time' ylabel 'Magnitude of Current (A)'
.endc

* ==========================================
* 2. 1T1R Subcircuit Definition
* ==========================================
* This block defines a single bit cell consisting of 1 Transistor + 1 Resistor
.subckt CELL_1T1R my_BL my_WL my_SL
    * Access Transistor (NMOS Selector)
    M_access N_internal my_WL my_BL 0 nmos_page9 W=20n L=20n
    
    * Parasitic Capacitor (Crucial for simulation convergence during switching)
    C_stab N_internal my_SL 0.1p
    
    * Memory Device (Verilog-A model)
    N_mem N_internal my_SL blm_memory
.ends

* ==========================================
* 3. Array Instantiation (2x2 Matrix)
* ==========================================
* Architecture:
* BL0      BL1
* |        |
* WL0 --[0,0]----[0,1]--
* |        |
* WL1 --[1,0]----[1,1]--

* Target Cell (0,0) -> Connected to active WL0 and active BL0
X00 BL0_node WL0 0 CELL_1T1R

* Neighbor Cell (0,1) -> Connected to active WL0 but inactive BL1
X01 BL1_node WL0 0 CELL_1T1R

* Neighbor Cell (1,0) -> Connected to inactive WL1 and active BL0
X10 BL0_node WL1 0 CELL_1T1R

* Neighbor Cell (1,1) -> Connected to inactive WL1 and inactive BL1
X11 BL1_node WL1 0 CELL_1T1R

* ==========================================
* 4. Peripheral Circuits (Drivers)
* ==========================================

* --- Bit Line Drivers ---
* BL0: Stimulus for the Target Cell
* Sequence: SET (4V) -> READ (0.5V) -> RESET (-4V) -> READ (0.5V) -> DISTURB (4V)
V_BL0 src_BL0 0 PWL(
+ 0    0
+ 10m  0    10.1m 4.0   15m  4.0   15.1m 0    ; SET Pulse (Write 1)
+ 25m  0    25.1m 0.5   30m  0.5   30.1m 0    ; READ Pulse (Verify 1)
+ 40m  0    40.1m -4.0  45m  -4.0  46m  0     ; RESET Pulse (Write 0)
+ 55m  0    55.1m 0.5   60m  0.5   60.1m 0    ; READ Pulse (Verify 0)
+ 70m  0    70.1m 4.0   75m  4.0   75.1m 0    ; Disturb Check (WL OFF)
+ )
* Series resistor to simulate line resistance and limit current
R_BL0 src_BL0 BL0_node 2k

* BL1: Inactive Bitline (Held at 0V)
V_BL1 src_BL1 0 DC 0
R_BL1 src_BL1 BL1_node 2k

* --- Word Line Drivers ---
* WL0: Active Wordline (Turns on the row)
V_WL0 WL0 0 PWL(0 0 5m 0 5.1m 2.0 60m 2.0 60.1m 0)

* WL1: Inactive Wordline (Keeps row off)
V_WL1 WL1 0 DC 0

.end