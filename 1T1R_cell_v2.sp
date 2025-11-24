* 1T1R Single Cell Verification - Final Version

* --- Model Definitions ---
.model blm_memory blm_memory
.model nmos_page9 nmos level=1 vto=0.49 kp=12.95u gamma=0 lambda=0

.control
    set ngbehavior=ps
    pre_osdi BLM_memory_v2.osdi
    
    option method=gear
    option reltol=0.01
    
    * Run simulation for 80ms
    tran 10u 80m 0 1u

    set hcopydevtype = postscript
    set hcopypscolor = 1

    hardcopy 1t1r_control.ps v(WL) v(BL)+6 title 'Control Voltages' xlabel 'Time' ylabel 'Voltage'
    
    hardcopy 1t1r_current.ps log10(abs(i(Vm)) + 1e-12) title '1T1R Single Cell Response' xlabel 'Time' ylabel 'Log Current (A)'
.endc

* --- Circuit Topology ---
* Structure: Source -> Resistor -> Current Meter -> NMOS -> Capacitor -> Memory -> GND

* Series protection resistor (2k Ohm)
Rseries BL N_node 2k

* Zero-voltage source acting as an Ammeter
Vm N_node N_drain DC 0

* Access Transistor
M_access N_drain WL Mid 0 nmos_page9 W=20n L=20n

* Intermediate Node Capacitor (Stabilizes voltage during switching)
Cmid Mid 0 1p

* Memory Device
N_mem Mid 0 blm_memory

* --- Voltage Sources ---

* Word Line (Gate Control): 
* Turns on at 5ms, Turns off at 60ms
V_WL WL 0 PWL(0 0 5m 0 5.1m 2.0 60m 2.0 60.1m 0)

* Bit Line (Stimulus):
* Applies the full read/write cycle
V_BL BL 0 PWL(
+ 0    0
+ 10m  0    10.1m 4.0   15m  4.0   15.1m 0    ; SET Pulse
+ 25m  0    25.1m 0.5   30m  0.5   31m  0    ; READ Verify (Should be High Current)
+ 40m  0    40.1m -4.0  45m  -4.0  46m  0    ; RESET Pulse
+ 55m  0    55.1m 0.5   60m  0.5   61m  0    ; READ Verify (Should be Low Current)
+ 70m  0    70.1m 4.0   75m  4.0   76m  0    ; Disturb Check
+ )

.end