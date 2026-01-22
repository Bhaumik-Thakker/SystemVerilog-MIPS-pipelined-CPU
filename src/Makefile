
#############################################
# Use wild-cards to find all of our designs
#############################################
SRC = $(wildcard *.sv)
TOP_SRC = $(wildcard top*.sv)
TOP = $(TOP_SRC:.sv=)
SIMS = $(patsubst top%,simv%,$(TOP))
LOGS = $(SIMS:=.log)
SYNS = $(patsubst top%,syn%.log,$(TOP))

############################################
# Verilog Compiler Flags
############################################

VCS_CC ?= gcc
COMPILER := vcs

VERILOG_LINT_FLAGS :=  +lint=PCWM         \
                       +lint=UV           \
                       +lint=IRIMW        \
                       +lint=FIAAS        \
                       +lint=CAWM-L       \
                       +lint=ERASM-L      \
                       +warn=all

#                      -ova_lint          \
#                      -ova_lint_magellan \

# "-sverilog" enables system verilog
# "+lint=PCWM" enables linting error messages
# "+libext+.v" specifies that library files (imported by the "-y" directive) ends with ".v"
# "-notice" used to get details when ports are coerced to inout
# "-full64" for 64 bit compilation and simulation
# "+v2k" for verilog 2001 constructs such as generate
# "-timescale=1ns/1ns" sets the time unit and time precision for the entire design
# "+noportcoerce" compile-time option to shut off the port coercion for the entire design
# "-top topModuleName" specifies the top module
# "-f verilogFiles.list" specifies a file that contains list of verilog files to compile
VERILOG_COMPILE_FLAGS := 	$(VERILOG_LINT_FLAGS)                           \
                                -sverilog 					\
                                +vcs+lic+wait                                   \
				+libext+.v					\
				-full64						\
				+v2k						\
				-timescale=1ps/1ps				\
                                -LDFLAGS -Wl,--no-as-needed                     \
                                -debug_access+all                               \
                                -kdb                                            \
 				-ld $(VCS_CC) 

#				+cli 						\
#                               -licqueue                                       \
#				+lint=PCWM					\
#				-notice						\
#				-debug_pp					\
#				-diag timescale                                 \
#				+noportcoerce         				\
#                               -parallel+saif=1                                \
#                               +vcs+saif_libcell                               \
#                               -lca                                            \
#				-ld $(VCS_CC) -debug_pp


VERILOG_SIMULATION_FLAGS := 	$(VERILOG_SIMULATION_FLAGS) 			\
				-l $(EXECUTABLE).log				\
				+vpdbufsize+500					\
				+vpdfileswitchsize+5000                         \
                                +vcs+lic+wait                                   \
                                +vpdports                                       \
                                $(SIMARG) \
                                +SAIF

############################################
# Synthesis Compiler Flags
############################################

SYN := dc_shell-xg-t -64bit





############################################
# Build Rules
############################################




# Compile Pattern Rule
simv_%: top_%.sv %.sv
	$(COMPILER) $(VERILOG_COMPILE_FLAGS) -top top_$* -o $@ $(SRC) | tee comp_$*.log

# Simulation Rule
simv_%.log: simv_%
	./$< $(VERILOG_SIMULATION_FLAGS) -l $@ 

syn_%.log: simv_%.log
	mkdir phys_$* 
	cd phys_$*; $(SYN) -x " set DESIGN $* ; set VERILOG {$(SRC)} ; set TOPV {$(TOP_SRC)} ; source -echo -verbose ../syn.tcl " | tee ../syn_$*.log

# All the sims
sim: $(LOGS)

# All the comps
comp: $(SIMS)

syn: $(SYNS)

# Everything
all: sim comp SYNS

# Clean up the system
clean:
	\rm -rf simv_* *~ csrc  ucli.key *.log *.csv phys_* novas.* *fsdb urgReport vdCovLog verdi* 
