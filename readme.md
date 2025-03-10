# Scripts for Working with Dynamatic on the ee-tik-dynamo-eda1 Machine

Once you have been given access to the server, you can login by ssh to ee-tik-dynamo-eda1.ethz.ch, using your ETH username and email password.

## Prerequisite: get your Gurobi license

Gurobi offers free [academic
license](https://www.gurobi.com/academia/academic-program-and-licenses/).

After getting the license, go to the EDA2 machine:

```sh
/opt/gurobi1000/linux64/bin/grbgetkey xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # format of your key
```

Which stores the license file at `~/gurobi.lic` (this is one of the default
location for Gurobi to check if you have a valid license).

Remember to put the following lines in your `~/.bashrc` or `~/.zshrc`.
Dynamatic's cmake settings will use these environment variables to determine
how to include the headers of Gurobi.

```sh
export GUROBI_HOME="/opt/gurobi1003/linux64"
export PATH="${PATH}:${GUROBI_HOME}/bin"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$GUROBI_HOME/lib"
```

## Clone and build dynamatic on the EDA2 machine

```sh
git clone git@github.com:EPFL-LAP/dynamatic.git
cd dynamatic/
bash ../mybuild.sh
``` 

## (Optional) Building the handshake visualizer

```sh
cd dynamatic/
git submodule init "visual-dataflow/godot-cpp"
bash "../build_visualizer.sh"
``` 

## Run your first example 

```sh
bash run.sh
```

Inspecting the generated files:
```
integration-test/fir/out/comp/
├── affine_mem.mlir # Affine dialect with memory analysis
├── affine.mlir
├── cf_dyn_transformed.mlir
├── cf.mlir         # CF dialect
├── cf_transformed.mlir
├── fir.dot
├── fir.png
├── handshake_buffered.mlir
├── handshake_export.mlir
├── handshake.mlir
├── handshake_transformed.mlir
├── hw.mlir
├── profiler-inputs.txt
└── scf.mlir
```

## Trouble-shooting

### Error when running simulation: 

```
dynamatic/include/dynamatic/Integration.h:214:34: error: no member named 'setfill' in namespace 'std'
  214 |   os << "0x" << std::hex << std::setfill('0') << std::setw(8)
```

Change `simulate.sh` as the following (note: do not include this change in your
PR): 
```diff
+++ b/tools/dynamatic/scripts/simulate.sh
@@ -24,7 +24,7 @@ IO_GEN_BIN="$SIM_DIR/C_SRC/$KERNEL_NAME-io-gen"

 # Shortcuts
 HDL_DIR="$OUTPUT_DIR/hdl"
-CLANGXX_BIN="$DYNAMATIC_DIR/bin/clang++"
+CLANGXX_BIN="clang++"
 HLS_VERIFIER_BIN="$DYNAMATIC_DIR/bin/hls-verifier"
 RESOURCE_DIR="$DYNAMATIC_DIR/tools/hls-verifier/resources" 
```

### Error during visualization:

A pop-up window saying "Your video card drivers seems not to support the
required Vulkan version...".

Change one line in `$DYNAMATIC_DIR/tools/dynamatic/scripts/visualize.sh` (note:
do not include this change in your PR):

```diff
# Launch the dataflow visualizer
echo_info "Launching visualizer..."
---"$VISUAL_DATAFLOW_BIN" "--dot=$F_DOT_POS" "--csv=$F_CSV" >/dev/null
+++"$VISUAL_DATAFLOW_BIN" "--dot=$F_DOT_POS" "--csv=$F_CSV" --rendering-driver opengl3 >/dev/null
exit_on_fail "Failed to run visualizer" "Visualizer closed" 
```

### Simulating Xilinx Floating Point IPs Using ModelSim

This part is no longer needed if we simply use the IPs generated by flopoco.
But I leave it here in case we want to compare them with Xilinx IPs.

**Compiling simulation library**. Simulating Xilinx floating point IPs needs
pre-compiled simulation libraries.  Execute the following tcl command in Vivado
shell for compiling questasim libraries:

```tcl
compile_simlib \
  -simulator questa \
  -simulator_exec_path {/path/to/questasim/bin} \
  -family kintex7 \
  -language vhdl \
  -library unisim \
  -dir {/path/to/library/modelsim_lib} \
  -32bit -force -verbose
```

This will generate the following files:
- A directory called `/path/to/library/modelsim_lib`.
- Modelsim config file `/path/to/library/modelsim.ini`.

**Copying submodule of IP blocks**. The IPs dependent on a verilog module
provided by Vivado: `$VIVADO/data/verilog/src/glbl.v`. Append `work.glbl` to
the end of `eval vsim histogram_tb` (the 3rd last line in `simulation.do`)

**Updating modelsim.ini**. Replace [this
file](https://github.com/EPFL-LAP/dynamatic/blob/main/tools/hls-verifier/resources/modelsim.ini)
with the generated `/path/to/library/modelsim.ini`






