#!/usr/bin/env python3
import math
from datetime import datetime
from pathlib import Path
import numpy as np
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

    def __process_shift_registers(
        self,
        network: Network,
        ff_replacements: list[FF_Replacement],
        replicated_signals,
    ):
        num_layers = len(network.ff_layers)
        instances = ""
        # Begin by applying the ff replacements to the template.
        for num_repl in range(len(ff_replacements)):
            repl = ff_replacements[num_repl]

            ports = {"CLK": "CLK", "E": "'1'", "RST": "RST"}

            # Create instances of CS elements forming the network.
            for group in repl.groups:
                # Implementation parameter dictionary.
                impl = dict()
                for i, point in enumerate(group):
                    x, y, z = point
                    impl["REG_INPUT({})".format(i)] = "wire({})({})({})".format(z, x, y)
                    impl["REG_OUTPUT({})".format(i)] = "wire({})({})({})".format(
                        z, x, y + 1
                    )
                generics = {
                    "NUM_INPUT": len(group),
                }

                # VHDL does not allow assignment of vector indices out of order.
                items = list(impl.items()) + list(ports.items())

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

        # Proceed by handling FF not replaced by other means.
        # Find chains of continouus FF to be turned into shift-registers.
        sr_chain = ""
        for j in range(network.get_N()):
            i = 0
            while i < network.get_depth():
                # If flag at that point is True a FF is present at that point.
                if network.ff_layers[0][i][j]:
                    sr_chain_beg = i
                    sr_chain_end = i
                    # How long does the SR-chain go ?
                    while (
                        sr_chain_end < network.get_depth()
                        and network.ff_layers[0][sr_chain_end][j]
                    ):
                        sr_chain_end += 1
                    sr_chain_end = sr_chain_end - 1
                    i = sr_chain_end
                    sr_chain += "wire({row})({beg} + 1 to {end}) <= wire({row})({beg} to {end}-1);\n".format(
                        row=j, end=sr_chain_end, beg=sr_chain_beg
                    )
                i += 1

        if sr_chain:
            instances += "Delay : process(CLK) is \nbegin\nif (rising_edge(CLK)) then\n{}end if;\nend process;\n".format(
                sr_chain
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
                if network[i][j] > j:
                    # A CS is present, if the pair references a later index.
                    a = j
                    b = network[i][j]
                    impl = dict()
                    impl["A0"] = "wire(0)({})({})".format(a, i)
                    impl["B0"] = "wire(0)({})({})".format(b, i)
                    # We swap the outputs if sorting direction (indicated by sign) is not forward
                    if network[i][j] > 0:
                        impl["A1"] = "wire(0)({})({})".format(a, i + 1)
                        impl["B1"] = "wire(0)({})({})".format(b, i + 1)
                    else:
                        impl["A1"] = "wire(0)({})({})".format(b, i + 1)
                        impl["B1"] = "wire(0)({})({})".format(a, i + 1)

                    # Assign control signals to CS, differentiating between
                    # replicated ones.
                    for signal in cs.ports.keys():
                        if signal in replicated_signals.keys():
                            associated_replication = (
                                (a * 2) % N
                            ) // replicated_signals[signal][1]
                            # Replicated signals can be found in 2D signal
                            # arrays.
                            impl[signal] = "{}_i({})({})".format(
                                signal, i, associated_replication
                            )
                        elif signal not in (ports | impl).keys():
                            # Non replicated signals are present in simple
                            # std_logic_vectors.
                            impl[signal] = "{}_i({})".format(signal, i)
                    # Fill out CS generics and ports and add it to instances.
                    instances += cs.as_instance(
                        "CS_D{}_A{}_B{}".format(i, a, b),
                        generics,
                        ports | impl,
                    )
        return instances

    def __make_control_signals(self, signals, replicated_signals):
        """Generate definitions for control signals in network.

        Control signals passed to the function in the signals list will
        inserted into the template via the signal_def and signal_dist strings.
        For the replicated signals, a signal replicator from the replic_dist
        string is inserted into the template with the appropriate signal
        definition from replic_dist added as well.

        Parameters
        ----------
        signals : list[str]
            List of signal names.
        replicated_signals : dict{ name : tuple(int,int,int)}
            Dictionary with signal names as keys and a tuple of the number of
            replicas (count), the maximum signal fanout (fanout) and the depth
            of the signal distributor tree (depth).

        Returns
        -------
        signal_def : str
           Combined definitions of signals
        signal_dist : str
           Combined signal distribution patterns (shift-registers for normal
           signals and signal distributor components for replicated signals).

        """
        signal_def = ""
        signal_dist = ""
        # First process non-replicated signals
        for signal in signals:
            signal_def += self.signal_def.format(signal)
            signal_dist += self.signal_dist.format(signal)

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

    def fill_main_file(
        self,
        template,
        cs,
        network,
        ff_replacements: list[FF_Replacement] = [],
        W=8,
        SW=1,
    ):
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

        for i in range(1, network.ff_layers.shape[0]):
            # Ignore the first layer as its the FF layer tied to the CS elements.
            layer = network.ff_layers[i]
            # Each FF in the first stage correspond to a signal replication.
            replic_count = np.sum(layer[0]) or 1
            signal_name = network.layer_names[i]

            replic_fanout = network.rows_per_signal[i]
            replic_depth = math.ceil(math.log(replic_count, replic_fanout))

            replicated_signals[signal_name] = (
                replic_count,
                replic_fanout,
                replic_depth,
            )

            # Each stage involves a delay.
            if replic_depth > max_replicated_delay:
                max_replicated_delay = replic_depth

        # Non-replicated signals are found as all control signals from CS
        # without replicated signals.
        exempt_sig = ["CLK", "A0", "A1", "B0", "B1"]
        signals = [
            signal
            for signal in cs.ports.keys()
            if signal not in network.layer_names and signal not in exempt_sig
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
        ) = self.__make_control_signals(signals, replicated_signals)
        instances = ""

        instances += self.__make_cs(network, cs, generics, ports, replicated_signals)

        instances += self.__process_shift_registers(
            network, ff_replacements, replicated_signals
        )

        # Add connections to serial input.
        for i in range(N):
            connection = "wire(0)({0})(0) <= SER_INPUT({0});\n".format(i)
            instances = connection + instances

        # Add connections to serial output.
        output_list = list(output_set)
        output_list.sort()
        if shape == "min":
            output_list.reverse()
        j = 0
        for i in range(num_outputs):
            connection = "SER_OUTPUT({}) <= wire(0)({})({});\n".format(
                j, output_list[i], depth
            )
            instances = instances + connection
            j += 1

        tokens = {
            "top_name": top_name,
            "net_depth": depth,
            "num_layers": len(network.ff_layers),
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
