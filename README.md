# Sorting Network Generator for VHDL
VHDL code generator scripts based on python for creating large sorting networks based on the Bitonic and Odd-Even algorithm. Primary motivation was the serial-processing of words and the resulting reduction of a CS element to two LUT5 and 4 FFs.

## Features
-   **Arbitrary number of inputs** :: Number of inputs is not required to be a power of 2
-   **Output pruning** :: Desired network outputs can be selected with unnecessary paths removed.
-   **Variable throughput Compare-Swap** :: Sorting networks processing any number of bits per cycle can be generated.
-   **Flip-Flop replacement** :: Large FF requirements of the Network can be replaced by other FPGA resources.
-   **Network stats reporting** :: On network generation, key characteristics are logged automatically
-   **Auto Plot generation** :: Using report data, plots for each network can be generated.

## Usage

### Installation
-   For `netgen.py` to run setup a venv.
```bash
# create venv
python3 -m venv venv_sort_net_gen
# activate venv
source venv_sort_net_gen/bin/activate
# install pip packages
python3 -m pip install --no-cache-dir -r requirements.txt
```

### Example
-   The following command generates a VHDL code for a network processing 128 inputs in parallel with the START signal replicated and evenly distributed in the network and the free FFs in the network replaced with DSP resources.
    ```bash
    python3 netgen.py - generated oddeven 128 - distribute signal START 10 - replace_ff REGISTER_DSP --limit=6480 --entity_ff=48 - write
    ```
-   The results can be found under `build/ODDEVEN_128X128_FULL` with the `test_sorter` implementation synthesized using:
    ```bash
    make BOARD=VCU118 SORTER=build/ODDEVEN_128X128_FULL
    ```

### Commands
**help**<br/>
For list of available components and templates run
```bash
python3 ./netgen.py - --help
```

**generate**<br/>
Generate a network of given algorithm and size. SW parameter (sub-word) defines the number of bits processed each cycle by the network. Has no direct influence on the network topology but is required for optimization and code-generation.
```bash
python3 ./netgen.py - generate oddeven --N=8 --SW=1
```
The results can be found under: `build/ODDEVEN_8X8_FULL`

**reshape**<br/>
Reshape a generated network to one of the predefined output configurations: “min”, “max” or “median”. Number of output elements can be controlled by “num_outputs” parameter. Compare-Swap, Flip-Flops or stages irrelevant to the outputs are removed.
```bash
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - reshape max --num_outputs=3
```
The results can be found under: `build/ODDEVEN_8X3_<reshape>`

**prune**<br/>
Similar to reshape, prune network to only produce indices given by `output_set` parameter. For example, a network for finding min,max and median element can be created using:
```bash
python3 ./netgen.py - generate oddeven --N=9 --SW=1 - prune [0,4,8]
```
The results can be found under: `build/ODDEVEN_9X3_MIXED`

<!-- still unsure about what this does exactly -->
**distribute_signal**<br/>
Set maximum fanout of a signal distributed in the network. Will cause tree-based signal replicators to be placed in the generated sorter. Currently only the “START” signal supports this.
```bash
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - distribute_signal START 5
```
The results can be found under: `build/ODDEVEN_8X8_FULL`

**replace_ff**<br/>
Replace network FF with resource given by parameters. Algorithm used attempts to keep a measure of locality at the cost of efficiency in the replacement FF capacity.
```bash
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - write - replace_ff REGISTER_DSP --limit=5 --entity_ff=48
```
The results can be found under: `build/ODDEVEN_8X8_FULL`
<!-- what are these 2 args for: --limit=5 --entity_ff=48 -->

**plot**<br/>
Create plots defined in `scripts/plots.py` using data gathered in `build/reports.csv`. Currently only supports generation of all plots defined.
```bash
# the command doesnt work
python3 ./netgen.py - plot all
```
The results can be found under: `build/ODDEVEN_8X8_FULL`

**write**<br/>
Generate and write VHDL-Code of the generated network to the path specified. Also allows to specify the CS implementation to be used and the width/length of the words to be processed. Default parameters will generate a Sorter for 8-bit words using the SWCS implementation place the resulting files in a folder named after the Sorter in build.
```bash
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - write
```
The results can be found under: `build/ODDEVEN_8X8_FULL`

**print_network**<br/>
Prints network in the form of network name, permutation layers (-> CS placement), output set and the FF layers.
```bash
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - print_network
# + represent pipline regs
# | colored lines represent partition edges for recursion depts
```

### Useful commands
```bash
# generate a simple N=8 sorting network
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - write

# print list of all RTL components inside sorter
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - print_list

# print report of all the outputs generated
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - report_net

# generate network with a given range of stages
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - include_stages_range 0 3 - print_network - report_net

# generate network with indices of stages given
python3 ./netgen.py - generate oddeven --N=8 --SW=1 - include_stages [2,4,5] - print_network - report_net
```

## use this command
- for normal sorting network
```bash
# sorting network with 8192 elements each with depth 64 bits
python3 ./netgen.py - generate oddeven --N=8192 --SW=64 - report_net - write
# sorting network with 8192 elements each with depth 64 bits. FF replaced with DSP
```