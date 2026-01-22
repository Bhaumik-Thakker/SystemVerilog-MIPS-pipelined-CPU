# CPU5 SystemVerilog Project

This repository contains a **32-bit, MIPS-like, 5‑stage pipelined CPU** (“**cpu5**”) implemented in **SystemVerilog**, along with a self-checking-ish **simulation testbench** and **program/memory initialization** files.

Key design themes visible in the codebase:

- Classic **IF/ID/EX/MEM/WB** pipelining with **forwarding** and **stall** logic
- A small **instruction cache** implemented as a **CAM (content-addressable memory)** plus a simple controller
- A MIPS-flavored ISA subset (arithmetic/logic, branches, jumps, loads/stores, plus `halt`)

> Reset is **active-low** (`rst_`). Several control signals are also active-low (e.g., `rw_`, `mem_rw_`, `cache_write_`), so read the signal names carefully.

---

## Repository layout

- `src/` — synthesizable-ish CPU RTL and support modules  
  - `cpu5.sv` — top-level CPU (pipeline + cache integration)
  - `pc.sv` — program counter (supports branches/jumps + stall inputs)
  - `instr_reg.sv` + `instr_reg_params.vh` — instruction decode / control signal generation
  - `alu.sv`, `regfile.sv` — datapath primitives
  - `pipe_id_ex.sv`, `pipe_ex_mem.sv`, `pipe_mem_wb.sv` — pipeline register stages
  - `forward.sv`, `equality.sv` — hazard/compare helpers
  - `memory.sv` — simple word-addressed memory with byte enables
  - Cache:
    - `cam2.sv` — CAM-based cache storage (tag/data/valid arrays)
    - `ca_ctrl.sv` — cache controller FSM (miss handling + replacement/invalidations)
  - Parameters / include files:
    - `cpu_params.vh`, `common.vh`, `cam_params.vh`

- `tb/` — simulation-only testbench  
  - `top_cpu5.sv` — instantiates `cpu5`, loads instruction memory (`$readmemh`), dumps waves, and ends sim on `halt`/`exception`

- Program / init files (under `src/`):
  - `i_mem_vals.s` — MIPS-like assembly for a cache stress test program
  - `i_mem_vals.txt` — hex words consumed by `$readmemh`
  - `i_mem_vals_*.txt` — additional/derived dumps

- `control_and_datapath.png` — design diagram (control + datapath overview)

---

## CPU configuration parameters

The top-level `cpu5` module exposes parameters for the instruction cache:

- `CACHE_ENTRIES` (default **8**) — number of cache entries
- `CACHE_TAGSZ` (default **32**) — tag width (uses full address)
- `CACHE_ADDR_LEFT` — derived index width (`$clog2(CACHE_ENTRIES)-1`)

Core sizing constants are in `src/cpu_params.vh`:

- `BITS = 32`
- `REG_WORDS = 32`
- `I_MEM_WORDS = 1024`
- `D_MEM_WORDS = 1024`
- `I_MEM_BASE_ADDR = 0`
- `D_MEM_BASE_ADDR = 32'h4000_0000`

Note: the provided `memory.sv` uses an address validity check that assumes the address range is `[BASE_ADDR, BASE_ADDR + WORDS)`. In this project, the PC increments by 1 per instruction, so addresses are effectively treated as **word indices** rather than byte addresses.

---

## Implemented instruction subset

Instruction decode is centralized in `src/instr_reg.sv` (see also `src/instr_reg_params.vh`). The decode logic drives:

- register file write enable (`rw_`, active-low)
- memory read/write (`mem_rw_`, active-low)
- ALU op selection (`alu_op`)
- immediate selection/sign extension
- branch/jump control
- byte enables for sub-word loads/stores
- `halt`/`exception` outputs

ISA coverage visible in the decode includes (at least):

### Arithmetic / logical
- `ADD`, `ADDU`, `ADDI`, `ADDIU`
- `SUB`, `SUBU`
- `AND`, `ANDI`, `OR`, `ORI`, `NOR`
- Shifts: `SLL`, `SRL`, `SRA`
- Set-less-than: `SLT`, `SLTU`, `SLTI`, `SLTIU`
- `LUI`

### Control flow
- Branches: `BEQ`, `BNE`
- Jumps: `J`, `JAL`, `JR`
- System: `HALT`

### Memory
- Word: `LW`, `SW`
- Byte/half: `LBU`, `LHU`, `SB`, `SH`
- Atomic pair: `LL`, `SC` (link/conditional store support signals exist in decode)

If an unrecognized instruction encoding is seen, decode asserts `exception`.

---

## Running simulation

### Prerequisites
- A SystemVerilog simulator. The provided makeflow is set up for **Synopsys VCS**.
- `make` (optional, if using the provided Makefile).
- A waveform viewer (optional), e.g., GTKWave, to open `cpu5_waves.vcd`.

### Important note about file locations
The testbench (`tb/top_cpu5.sv`) executes:

```systemverilog
$readmemh("i_mem_vals.txt", cpu5.i_memory.mem);
```

The file `i_mem_vals.txt` lives in `src/`, so the simplest approach is to **run simulation from the `src/` directory** (so the relative path resolves).

---

### Option 1: Compile/run with VCS (direct command)

From the repository root:

```bash
cd src

# Compile
vcs -sverilog -full64 -timescale=1ps/1ps -debug_access+all     +incdir+.     -top top_cpu5     ../tb/top_cpu5.sv     *.sv     -o simv_cpu5

# Run
./simv_cpu5
```

Outputs to expect:
- Console prints showing program load and progress
- Simulation terminates on `halt` (or `exception`)
- Waveform file: `cpu5_waves.vcd` (in the directory you ran from)

---

### Option 2: Use the provided `src/Makefile`

The Makefile in `src/` expects `top_*.sv` testbenches to be in the **same directory** as the Makefile. You can satisfy that expectation via a symlink (or copy):

```bash
cd src
ln -s ../tb/top_cpu5.sv top_cpu5.sv   # or: cp ../tb/top_cpu5.sv .
make comp
make sim
```

If you later want to remove the symlink:

```bash
rm top_cpu5.sv
```

---

## Waveforms

The testbench enables VCD dumping:

- `cpu5_waves.vcd`
- `$dumpvars(0, top_cpu5);`

Open with a waveform viewer, for example:

```bash
gtkwave cpu5_waves.vcd
```

---

## Program / memory initialization

- `src/i_mem_vals.s` is the assembly source for the included cache corner-case stress test.
- `src/i_mem_vals.txt` is the hex memory image loaded into instruction memory by the testbench.

A course-provided `assembler` tool was referenced in the original environment; it is not included in this repo (and is ignored via `.gitignore`). If you have an assembler in your environment, the typical flow is:

1. Edit `i_mem_vals.s`
2. Re-generate `i_mem_vals.txt`
3. Re-run simulation

---

## Notes / common pitfalls

- **Active-low signals:** `rst_`, `rw_`, `mem_rw_`, and `cache_write_` are active-low.
- **Run location matters** for `$readmemh("i_mem_vals.txt", ...)`. If you run from `tb/` or the repo root, you may need to copy/symlink `src/i_mem_vals.txt` into your run directory.
- The Makefile contains a synthesis target (`syn_*`) that references `syn.tcl`; that TCL script is not present here and is typically course-/environment-specific.

---

