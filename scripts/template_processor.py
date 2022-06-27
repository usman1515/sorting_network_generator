#!/usr/bin/env python3
import math
from datetime import datetime
from pathlib import Path
from scripts.vhdl_container import *
from scripts.network_generators import *
from scripts.resource_allocator import FF_Replacement


class Template_Processor:
    def __init__(self):
        self.signal_def = """
  signal {}_i   : std_logic_vector(DEPTH downto 0) := (others => '0');\n
"""
        self.signal_dist = """
  -- {0}DELAY------------------------------------------------------------------
  -- Generates a shift register for delaying the {0} signal for each sorter
  -- stage.
  -------------------------------------------------------------------------------
  {0}DELAY : process(CLK) is
  begin

    if (rising_edge(CLK)) then
      if (RST = '1') then
        {0}_i({0}_i'high downto {0}_i'low + 1) <= (others => '0');
      else
        {0}_i({0}_i'high downto {0}_i'low + 1) <= {0}_i({0}_i'high - 1 downto {0}_i'low);
        end if;
    end if;

  end process {0}DELAY;
  {0}_i(0) <= {0};
"""
        self.replic_def = """
  type {0}_replicated_t is array (DEPTH downto 0) of std_logic_vector(0 to {1} -1);
  signal {0}_i   : {0}_replicated_t := (others => (others => '0'));
"""
        self.replic_dist = """
  {0}_DISTRIBUTOR_1: entity work.SIGNAL_DISTRIBUTOR
    generic map (
      NUM_SIGNALS => {1},
      MAX_FANOUT  => {2})
    port map (
      CLK    => CLK,
      RST    => RST,
      E      => E,
      SOURCE => {0},
      REPLIC => {0}_i({3})
      );
"""

    def process_shift_registers(self, network, ff_replacements, replicated_signals):

        num_layers = len(network.control_layers)
        instances = ""

        for num_repl in range(len(ff_replacements)):
            repl = ff_replacements[num_repl]
            print(repl.sub_groups)

            ports = {"CLK": "CLK", "E": "'1'", "RST": "RST"}

            # Create instances of CS elements forming the network.
            for i in range(len(repl.groups)):
                group = repl.groups[i]

                specific = dict()
                for j in range(len(group)):
                    x, y = group[j]
                    specific["REG_INPUT({})".format(j)] = "wire({})({})".format(x, y)
                    specific["REG_OUTPUT({})".format(j)] = "wire({})({})".format(
                        x, y + 1
                    )
                start_index = len(group)

                for k in range(num_layers):

                    sub_group = repl.sub_groups[k][i]
                    signame = repl.sub_group_sig[k]
                    replic_fanout = replicated_signals[signame][1]
                    signame = "{}_i".format(signame)

                    for j in range(len(sub_group)):
                        x, y = sub_group[j]
                        x = x // replic_fanout
                        specific[
                            "REG_INPUT({})".format(start_index + j)
                        ] = "{}({})({})".format(signame, y, x)
                        specific[
                            "REG_OUTPUT({})".format(start_index + j)
                        ] = "{}({})({})".format(signame, y + 1, x)
                    start_index += len(sub_group)

                generics = {
                    "NUM_INPUT": start_index,
                }

                items = list(specific.items())
                items.sort(key=lambda kv: kv[0])

                items = list(ports.items()) + items

                a = "port map(\n"

                for j in range(0, len(items)):
                    key, value = items[j]
                    a += "   {} => {}".format(key, value)
                    if j + 1 < len(items):
                        a += ","
                    a += "\n"
                a += ");\n"

                instances += repl.entity.as_instance_portmanual(
                    "FF_REPLACEMENT_{}_GRP{}".format(num_repl, i), generics, a
                )
        N = network.get_N()
        depth = network.get_depth()
        # Fill bypasses with delay elements.
        bypasses = ""
        for i in range(depth):
            for j in range(N):
                if network[i][j][0] == "+":
                    bypass_beg = i
                    bypass_end = i
                    while bypass_end < depth and network[bypass_end][j][0] == "+":
                        network[bypass_end][j] = ("-", j)
                        bypass_end += 1

                    bypasses += "wire({row})({beg} + 1 to {end}) <= wire({row})({beg} to {end}-1);\n".format(
                        row=j, end=bypass_end, beg=bypass_beg
                    )
        # for k, layer in enumerate(network.control_layers):
        #     signame = network.signame[k]
        #     signame = "{}_i".format(signame)
        #     for i in range(depth):
        #         for j in range(N):
        #             if layer[i][j][0] == "+":
        #                 bypass_beg = i
        #                 bypass_end = i
        #                 while bypass_end < depth and layer[bypass_end][j][0] == "+":
        #                     layer[bypass_end][j] = ("-", j)
        #                     bypass_end += 1
        #                 # TODO Fix control signal shifting if not enough DSP are available.
        #                 bypasses += "{signame}({row})({beg} + 1 to {end}) <= wire({row})({beg} to {end}-1);\n".format(
        #                     signame=signame, row=j, end=bypass_end, beg=bypass_beg
        #                 )
        # Enclose bypassed wires in synchronous process.
        if bypasses:
            instances += "Delay : process(CLK) is \nbegin\nif (rising_edge(CLK)) then\n{}end if;\nend process;\n".format(
                bypasses
            )

        return instances

    def __make_cs(self, network, cs, generics, ports, replicated_signals):
        """Fills out ports and generics dicts of of all CS elements and returns
        combined instance string."""
        N = network.get_N()
        depth = network.get_depth()
        instances = ""
        # Create instances of CS elements forming the network.
        for i in range(depth):
            for j in range(N):
                if network[i][j][1] > j:
                    # A CS is present, if the pair references a later index.
                    a = j
                    b = network[i][j][1]
                    specific = dict()
                    specific["A0"] = "wire({})({})".format(a, i)
                    specific["B0"] = "wire({})({})".format(b, i)
                    # We swap the outputs if sorting direction is not *F*orward
                    if network[i][j][0] == "F":
                        specific["A1"] = "wire({})({})".format(a, i + 1)
                        specific["B1"] = "wire({})({})".format(b, i + 1)
                    else:
                        specific["A1"] = "wire({})({})".format(b, i + 1)
                        specific["B1"] = "wire({})({})".format(a, i + 1)

                    # Assign control signals to CS, differentiating between
                    # replicated ones.
                    for signal in cs.ports.keys():
                        if signal in replicated_signals.keys():

                            associated_replication = (
                                (a * 2) % N
                            ) // replicated_signals[signal][1]
                            # Replicated signals can be found in 2D signal
                            # arrays.
                            specific[signal] = "{}_i({})({})".format(
                                signal, i, associated_replication
                            )
                        elif signal not in (ports | specific).keys():
                            # Non replicated signals are present in simple
                            # std_logic_vectors.
                            specific[signal] = "{}_i({})".format(signal, i)
                    # Fill out CS generics and ports and add it to instances.
                    instances += cs.as_instance(
                        "CS_D{}_A{}_B{}".format(i, a, b),
                        generics,
                        ports | specific,
                    )
        return instances

    def __make_control_signals(self, network, signals, replicated_signals):
        signal_def = ""
        signal_dist = ""
        # First process non-replicated signals
        for signal in signals:
            signal_def += self.signal_def.format(signal)

            signal_dist += self.signal_dist.format(signal)

        N = network.get_N()

        for signal, param in replicated_signals.items():
            count, fanout, depth = param
            signal_def += self.replic_def.format(
                signal,
                count,
                depth,
            )
            if count > 1:
                signal_dist += self.replic_dist.format(signal, count, fanout, depth)
            else:
                signal_dist += "{0}_i(0)(0) <= {0};\n".format(signal)
        return signal_def, signal_dist

    def fill_main_file(self, template, cs, network, ff_replacements, W=8, SW=1):
        """Takes kwargs and returns template object with generated network."""

        N = network.get_N()
        shape = network.shape
        output_set = network.get_output_set()
        num_outputs = len(output_set)
        depth = network.get_depth()

        bit_width = W
        subword_width = SW

        # Process control signal layers from network as replicated signals
        # 2 variables are generated:
        # - max_replicated_delay: int
        #   Since the signal replication incures a delay on startup, we need to
        #   know the maximum delay present for the READY_DELAY counter.
        # - replicated_signals: dict
        #   For each signal name as key, a pair of the number of replications
        #   and the fanout (rows per replication) is necessary. Both values
        #   are reconstructed from the control signal layers of the network.
        max_replicated_delay = 0
        replicated_signals = dict()
        for i, layer in enumerate(network.control_layers):
            # Each FF in the first stage correspond to a signal replication.
            replic_count = sum([1 for pair in layer[-1] if pair[0] in ("+", "-")])
            signal_name = network.signame[i]

            replic_fanout = network.rows_per_signal[i]
            replic_depth = math.ceil(math.log(replic_count, replic_fanout))

            replicated_signals[signal_name] = (
                replic_count,
                replic_fanout,
                replic_depth,
            )
            # Depth of the distributor is log of replic count to base of fanout
            distributor_stages = math.ceil(math.log(replic_count, replic_fanout))
            # Each stage involves a delay.
            if distributor_stages > max_replicated_delay:
                max_replicated_delay = distributor_stages

        # Non-replicated signals are found as all control signals from CS
        # without replicated signals.
        exempt_sig = ["CLK", "A0", "A1", "B0", "B1"]
        signals = [
            signal
            for signal in cs.ports.keys()
            if signal not in network.signame and signal not in exempt_sig
        ]

        # Default shape of network is max.
        if not shape.lower() in (
            "max",
            "min",
            "median",
            "mixed",
        ):
            shape = "max"
        shape = shape.lower()

        # Begin building content for placeholder tokens of template.
        top_name = "{}_{}_TO_{}_{}".format(
            network.typename.upper(), N, num_outputs, shape.upper()
        )

        generics = {"W": bit_width, "SW": subword_width}
        ports = {"CLK": "CLK", "E": "E", "RST": "RST"}

        (
            control_signal_definition,
            control_signal_distribution,
        ) = self.__make_control_signals(network, signals, replicated_signals)
        print(control_signal_definition, control_signal_distribution)
        instances = ""

        instances += self.__make_cs(network, cs, generics, ports, replicated_signals)

        instances += self.process_shift_registers(
            network, ff_replacements, replicated_signals
        )

        # Add connections to serial input.
        for i in range(N):
            connection = "wire({0})(0) <= SER_INPUT({0});\n".format(i)
            instances = connection + instances

        # Add connections to serial output.
        output_list = list(output_set)
        output_list.sort()
        if shape == "min":
            output_list.reverse()
        j = 0
        for i in range(num_outputs):
            connection = "SER_OUTPUT({}) <= wire({})({});\n".format(
                j, output_list[i], depth
            )
            instances = instances + connection
            j += 1

        tokens = {
            "top_name": top_name,
            "net_depth": depth,
            "num_inputs": N,
            "num_outputs": num_outputs,
            "bit_width": bit_width,
            "subword_width": subword_width,
            "control_signal_definition": control_signal_definition,
            "control_signal_distribution": control_signal_distribution,
            "ready_delay": max_replicated_delay,
            # "components": components,
            "instances": instances,
            "date": datetime.now(),
        }
        template.tokens = tokens
        template.name = top_name
        return template


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    pass
    # from vhdl_parser import *

    # template = parse_template_vhdl(Path("../templates/Network_SW.vhd"))
    # cs = parse_entity_vhdl(Path("../src/CS/SubWordCS.vhd"))

    # gen = Bitonic()
    # gen.create_connection_matrix(8)
    # gen.reduce_connection_matrix(10)

    # tempproc = Template_Processor()
    # template = tempproc.fill_main_file(template, cs, gen.nw)
    # print(template.as_template())

    # output_set = set()
    # output_set.add(0)
    # output_set.add(1)
    # output_set.add(2)
    # print(output_set)
    # network = gen.prune_connection_matrix(network, output_set.copy())
    # output_list = list(output_set)
    # output_list.sort()
    # print(output_list)
    # for layer in network:
    #     print(layer)
    # print()
