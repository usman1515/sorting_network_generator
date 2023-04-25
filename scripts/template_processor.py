#!/usr/bin/env python3
from datetime import datetime
from pathlib import Path
import numpy as np
import math

from scripts.vhdl import VHDLEntity, VHDLTemplate, parseVHDLEntity
from scripts.network_generators import Network, NetworkSignal, DistributionType
from scripts.resource_allocator import FF_Replacement, FF_Assignment


class VHDLTemplateWriter:
    """Class encapsulating writing the template to a file in an incremental
    fashion"""

    def __init__(self, template: VHDLTemplate, output_file: Path):
        self.template = template
        self.output_file = output_file
        self.output_fd = None
        self.preamble_written = False
        self.body_written = False
        self.footer = ""
        self.footer_written = False
        self.len_line = 80

    def __del__(self):
        if self.output_fd:
            self.output_fd.close()

    def write_preamble(self, tokens: dict[str, str]) -> bool:
        """Write template preamble consisting of the tokens for generics and other
        parameters as well as the signal definitions.

        Parameters:
            tokens : dict[str:str]
                Dict of tokens and values from which generics and parameters in
                the template are filled out.
        Returns:
            preamble_written : Bool
                True if writing was successful.
        """
        self.template.tokens = tokens
        template_string = self.template.as_template()
        preamble, self.footer = template_string.split("{body}")
        with self.output_file.open("w") as file:
            num_char = file.write(preamble)
            if num_char != len(preamble):
                return False
        self.preamble_written = True
        return self.preamble_written

    def write_start_comment(self, block_title: str):
        len_title = 4 + len(block_title)
        self.write_incremental("-" * self.len_line + "\n")
        self.write_incremental(
            "-- " + block_title + " " + "-" * (len_title - self.len_line) + "\n"
        )
        self.write_incremental("-" * self.len_line + "\n")

    def write_end_comment(self):
        self.write_incremental("-" * self.len_line + "\n\n")

    def write_incremental(self, vhdl_block: str) -> bool:
        """Write a block of vhdl code to the output file at the position of
        the "{body}" token.

        Parameters:
            vhdl_block: str
                Piece of vhdl_code to be written.
        Returns
            write_success: Bool
                Signifies write success. Fails if preamble hasn't been written.
        """
        if self.preamble_written:
            if not self.output_fd:
                self.output_fd = self.output_file.open("a")
            num_char = self.output_fd.write(vhdl_block)
            if num_char == len(vhdl_block):
                return True
        return False

    def write_footer(self) -> bool:
        """Writes footer to file and returns success."""
        if self.output_fd:
            num_char = self.output_fd.write(self.footer)
            if num_char == len(self.footer):
                self.footer_written = True
                return True
        return False


def __list_points_in_distance(
    start_point: tuple[int, int], dist=int, bounds=tuple[int, int]
) -> list[tuple[int, int]]:
    """Returns a list of 2D points around the start_point with the distance
    given. Will return an empty list of no points exist in bounds.

    Diagonals are treated as equidistand.
    """
    if dist == 0:
        return [
            start_point,
        ]
    s_x, s_y = start_point
    points = []
    for i in range(0, 2 * dist - 1):
        x = s_x - dist + i
        y = s_y - dist
        if x > 0 and x < bounds[0]:
            if y > 0 and y < bounds[1]:
                points.append((x, y))
    for i in range(0, 2 * dist - 1):
        x = s_x + dist - 1
        y = s_y - dist + i
        if x > 0 and x < bounds[0]:
            if y > 0 and y < bounds[1]:
                points.append((x, y))
    for i in range(2 * dist - 1, 0, -1):
        x = s_x - dist + i
        y = s_y + dist - 1
        if x > 0 and x < bounds[0]:
            if y > 0 and y < bounds[1]:
                points.append((x, y))
    for i in range(2 * dist - 1, 0, -1):
        x = s_x - dist
        y = s_y - dist + i
        if x > 0 and x < bounds[0]:
            if y > 0 and y < bounds[1]:
                points.append((x, y))
    return points


class VHDLTemplateProcessor:
    """Handles intepretation and code generation of sorting networks and writes
    generated code into file whose path is provided in init.
    """

    def __init__(self, output_file: Path):
        self.output_file = output_file
        self.writer: VHDLTemplateWriter

    def __get_signal_source(
        self, network: Network, signal_name: str, point: tuple[int, int]
    ) -> tuple[bool, tuple[int, int, int]]:
        bounds = list(network.ff_layers.shape)
        bounds.reverse()
        for coord, bound in zip(point, bounds):
            if coord < 0 or coord >= bound:
                return False, (-1, -1, -1)
        x, y = point

        z = -1
        assoc_signal = None
        if signal_name.upper() in network.signals:
            if network.signals[signal_name].layer_index >= 0:
                assoc_signal = network.signals[signal_name]
                z = network.signals[signal_name].layer_index
            else:
                return False, (-1, -1, -1)
        source_point = (x, y, z)

        if assoc_signal.distribution == DistributionType.GLOBAL:
            # Signal source is global and either provided through ports
            # or generated locally to entity. Should be caught earlier,
            # hence an invalid point is returned.
            return False, (-1, -1, -1)
        if assoc_signal.distribution == DistributionType.ONE_TO_ONE:
            # Signal source must come from the same point in the network.
            if network.ff_layers[z, y, x]:
                return True, source_point
            return False, source_point
        if assoc_signal.distribution == DistributionType.PER_STAGE:
            # Find the closest source in the same stage.
            if network.ff_layers[z, y, x]:
                # Found source at point given. Nothing to do.
                return True, source_point
            # Otherwise, search in the x-axis for a source, increasing
            # distance searched.
            dist = 1
            while x - dist >= 0 or x + dist < network.ff_layers.shape[2]:
                if x + dist < network.ff_layers.shape[2]:
                    # print(x + dist, network.ff_layers[z, y, x + dist])
                    if network.ff_layers[z, y, x + dist]:
                        return True, (x + dist, y, z)
                if x - dist >= 0:
                    # print(x - dist, network.ff_layers[z, y, x - dist])
                    if network.ff_layers[z, y, x - dist]:
                        return True, (x - dist, y, z)
                dist += 1
            return False, (-1, -1, -1)

        if assoc_signal.distribution == DistributionType.PER_LINE:
            if network.ff_layers[z, y, x]:
                # Found source at point given. Nothing to do.
                return True, source_point
            # Find the closest source in the same line.
            dist = 1
            while y - dist >= 0 or y + dist < network.ff_layers.shape[2]:
                if y + dist < network.ff_layers.shape[2]:
                    # print(x + dist, network.ff_layers[z, y, x + dist])
                    if network.ff_layers[z, y + dist, x]:
                        return True, (x, y + dist, z)
                if y - dist >= 0:
                    # print(x - dist, network.ff_layers[z, y, x - dist])
                    if network.ff_layers[z, y - dist, x]:
                        return True, (x, y - dist, z)
                dist += 1
            return False, (-1, -1, -1)

        if assoc_signal.distribution == DistributionType.PER_AREA:
            # Search for valid sources in a growing square around the point.
            # Should no valid source be found as the distance becomes greater than
            # the layer bounds, return false.
            distance = 0
            points = __list_points_in_distance((x, y), distance, bounds[:1])
            while points:
                for p in points:
                    if network.ff_layers[z, p[1], p[0]]:
                        return True, source_point
                distance += 1
                points = __list_points_in_distance((x, y), distance, bounds[:1])
        return False, source_point

    def __map_signal(
        self,
        network: Network,
        template: VHDLTemplate,
        signal_name: str,
        point: tuple[int, int],
    ) -> str:
        normalized_name = signal_name.split("_")[0].upper()
        if normalized_name not in network.signals:
            print("Signal '{name}' not found in network signals", normalized_name)
            return "open"
        signal = network.signals[normalized_name]
        if signal.distribution == DistributionType.GLOBAL:
            return "{s_name}_global".format(
                name=signal_name, s_name=normalized_name.lower()
            )
        if signal.distribution == DistributionType.UNCONNECTED:
            print("UNCONNECTED")
            return "open"

        # Signal exists in the network and is neither global nor unconnected
        is_mapped, source_point = self.__get_signal_source(
            network, normalized_name, point
        )
        if not is_mapped or any(c < 0 for c in source_point):
            print(
                "Signal '{}' at {} not mapped or source invalid".format(
                    normalized_name, point
                )
            )
            return "open"
        if signal.is_replicated:
            # While all signals are defined inside fully sized matrices,
            # definitions in the template may be smaller in dimensions.
            if signal.distribution == DistributionType.PER_STAGE:
                x, y, z = source_point
                x = x // signal.max_fanout
                return "{s_name}_array({x})({y})".format(
                    s_name=signal.name.lower(), x=x, y=y
                )
            if signal.distribution == DistributionType.PER_LINE:
                x, y, z = source_point
                y = y // signal.max_fanout
                print(signal.name, source_point, x, y)
                return "{s_name}_array({x})({y})".format(
                    s_name=signal.name.lower(), x=x, y=y
                )
            # The remaining options for distribution are PER_AREA or
            # ONE_TO_ONE.
            x, y, z = source_point
            return "{s_name}_array({x})({y})".format(
                s_name=signal.name.lower(), x=x, y=y
            )
        return "open"

    def __get_permutation_layer_definitions(self, network: Network, **kwargs) -> str:
        """Generates code containing signal definition for the signal array
        based on which the sorting network is created.
        """
        # Constants defined in the beginning of the entity architecture are used
        # instead of variables from the script. Function therfore returns a constant
        # string.

        # fmap = {
        #     "SW": kwargs.get("SW") or 1,
        #     "N": network.get_N(),
        #     "depth": network.get_depth(),
        # }
        sdef = """

  -- Generator scripts array is indexed using (z,y,x) = (Layer, Stage, N)
  -- but here perm_arr is indexed with (z,x,y) = (N,Stage,Subword) to allow
  -- compact shift register definition.
  type stream_array_t is array (0 to N-1) of SLVArray(0 to DEPTH)(SW-1 downto 0);
  -- Wire grid with the dimensions of NxDepthxSubword
  signal stream_array     : stream_array_t;

"""
        # return sdef.format_map(fmap)
        return sdef

    def __get_control_layer_definitions(self, network: Network, **kwargs) -> str:
        """Generates code for the control signal definition as an array of
        (replicated) an delayed registers.
        """
        def_str = ""
        for signal in network.signals.values():
            if signal.name == "STREAM":
                # Data array creation is handled in another function.
                continue
            if signal.distribution == DistributionType.GLOBAL:
                def_str += "signal {}_global : std_logic;\n".format(signal.name.lower())
            else:
                fmap = {
                    "signal_name": signal.name.lower(),
                    "depth": str(network.get_depth()),
                    "N": signal.num_replications,
                }
                def_str += "signal {signal_name}_array : SLVArray(0 to {N}-1)(0 to {depth});\n".format_map(
                    fmap
                )
        return def_str

    def __get_signal_definitions(
        self, network: Network, entities: dict[str, VHDLEntity], **kwargs
    ) -> str:
        """Build signal definitions string from supplied paramters

        Parameters:
            network : Network
                Sorting Network object.
            entities : dict[str, VHDLEntity]
                Dictionary of string tokens and entity objects.
        Returns:
            signal_definitions : str
                VHDL code containing all relevant signal definitions.
        """
        signal_definitions = self.__get_permutation_layer_definitions(network, **kwargs)
        signal_definitions += self.__get_control_layer_definitions(network, **kwargs)
        return signal_definitions

    def __make_io_assignments(self, network, template):
        """Generates code connecting module inputs and outputs to
        appropriate internal signals.
        """
        # Handle data io from an to the permutation layer first
        inputs = "\n"
        for i in range(network.get_N()):
            inputs += "stream_array({n})(0) <= STREAM_I({n});\n".format(n=i)
        outputs = "\n"
        for entry in network.output_set:
            outputs += "STREAM_O({m}) <= stream_array({m})({depth});\n".format(
                m=entry, depth=network.get_depth()
            )

        # Handle output of control signals
        for signal in network.signals.values():
            input_ports = [
                port.split("_")[0]
                for port in template.ports
                if port.split("_")[1] == "I"
            ]
            if signal.name.upper() in input_ports:
                if signal.distribution == DistributionType.GLOBAL:
                    # Other types of signals should be handled in
                    # make_signal_replicators.
                    inputs += "{sname}_global <= {pname}_I;\n".format(
                        sname=signal.name.lower(), pname=signal.name.upper()
                    )
            output_ports = [
                port.split("_")[0]
                for port in template.ports
                if port.split("_")[1] == "O"
            ]
            if signal.name.upper() in output_ports:
                for i in range(signal.num_replications):
                    outputs += "{pname}_O({i}) <= {name}_array({i})({depth});\n".format(
                        pname=signal.name.upper(),
                        name=signal.name.lower(),
                        i=i,
                        depth=network.get_depth(),
                    )
        self.writer.write_start_comment("Generated I/O Assignments")
        self.writer.write_incremental(inputs + outputs)
        self.writer.write_end_comment()

    def __instantiate_signal_distributors(
        self, network: Network, template: VHDLTemplate, entities: dict[str, VHDLEntity]
    ):
        """Generates code instantiating signal distributor modules and connects
        them to designated control signal inputs and control signal arrays.
        """
        entity = entities["Signal_Distributor"]
        self.writer.write_start_comment("Generated Signal Distribution")
        for signal in network.signals.values():
            if signal.is_replicated:
                if signal.num_replications > 1:
                    ports = {}
                    for port in entity.ports:
                        ports[port] = ""
                    ports.pop("REPLIC_O")
                    generics = {
                        "NUM_SIGNALS": str(signal.num_replications),
                        "MAX_FANOUT": str(max(signal.max_fanout, 2)),
                    }
                    ports["SOURCE_I"] = signal.name.upper() + "_I"
                    ports["FEEDBACK_O"] = signal.name.upper() + "_FEEDBACK_O"
                    for j in range(signal.num_replications):
                        ports[
                            "REPLIC_O({})".format(j)
                        ] = "{signal_name}_array({j})(0)".format(
                            j=j, signal_name=signal.name.lower()
                        )
                    for port in ports:
                        if not ports[port]:
                            ports[port] = self.__map_signal(
                                network, template, port, (0, 0)
                            )
                    self.writer.write_incremental(
                        entity.as_instance_manual(
                            signal.name + "_repl", generics, ports
                        )
                    )
                else:
                    self.writer.write_incremental(
                        signal.name.lower()
                        + "_array(0)(0) <="
                        + signal.name.upper()
                        + "_I;\n"
                    )
                    self.writer.write_incremental(
                        signal.name.upper()
                        + "_FEEDBACK_O <="
                        + signal.name.upper()
                        + "_I;\n"
                    )
        self.writer.write_end_comment()

    def __make_cs(
        self,
        network: Network,
        template: VHDLTemplate,
        entities: dict[str, VHDLEntity],
        tokens: dict[str, str],
        x: int,
        y: int,
    ):
        """Creates CS instance in the network at the point provided. Specific
        CS implementation is provided through the entities dict with port
        mapping and generics derived from the network and the tokens dictionary
        respectively. Instantiation string is written to file through the
        writer object.
        """
        stage = network.pmatrix[y]
        instance_name = "CS_STAGE{stage}_{a}_TO_{b}".format(
            stage=y, a=x, b=abs(stage[x])
        )
        if stage[x] < 0:
            instance_name += "_REVERSE"

        generics = {
            "W": tokens["word_width"],
            "SW": tokens["subword_width"],
        }

        ports = {}
        ports["A_I"] = "stream_array({})({})".format(x, y)
        ports["B_I"] = "stream_array({})({})".format(stage[x], y)

        # Swap and Compare direction is indicated by the sign.
        if stage[x] > 0:
            ports["A_O"] = "stream_array({})({})".format(x, y + 1)
            ports["B_O"] = "stream_array({})({})".format(stage[x], y + 1)
        else:
            ports["A_O"] = "stream_array({})({})".format(stage[x], y + 1)
            ports["B_O"] = "stream_array({})({})".format(x, y + 1)

        # Start signal is usally replicated and distributed in another layer.
        # Assign each CS its appropriate source register for that signal.
        cs = entities["CS"]
        unconnected_ports = [port for port in cs.ports.keys() if port not in ports]
        for port in unconnected_ports:
            signal_name = port.split("_")[0].upper()
            if signal_name in network.signals:
                signal = network.signals[signal_name]
                ports[port] = ""
            if signal_name.upper() not in network.signals:
                # Signal is not represented anywhere in the network,
                # must be global, like f.e. CLK.
                ports[port] = "{signal_name}_I".format(signal_name=signal_name.upper())
            else:
                ports[port] = self.__map_signal(
                    network, template, signal_name.upper(), (x, y)
                )

        self.writer.write_incremental(cs.as_instance(instance_name, generics, ports))

    def __connect_cs_network(
        self,
        network: Network,
        template: VHDLTemplate,
        entities: dict[str, VHDLEntity],
        tokens: dict[str, str],
    ):
        """Iterates over permutation matrix and calls __make_cs for each point
        containing un-ordered index.
        """
        self.writer.write_start_comment("Generated CS Network")
        for y in range(network.pmatrix.shape[0]):
            stage = network.pmatrix[y]
            for x in range(stage.shape[0]):
                if abs(stage[x]) > x:
                    # The value at each index in the stage represents the index
                    # with which the current index has to be compared to.
                    # A CS is only placed when index and value differ.
                    # As a CS handles two indices, only place an element if
                    # the value is greater than the index.
                    self.__make_cs(network, template, entities, tokens, x, y)
        self.writer.write_end_comment()

    def __instantiate_ff_replacements(
        self,
        network: Network,
        template: VHDLTemplate,
        stream_layer_ff: np.ndarray,
        ff_replacements: list[FF_Replacement],
    ) -> np.ndarray:
        """Replaces points in the network which normally contain FF resources
        with a functionally equivalent replacement of (ideally) another
        resource like DSPs or BRAMs. Generates code containing instantiations
        of those replacements.
        """
        self.writer.write_start_comment("Generated FF Replacements")
        for repl in ff_replacements:
            replacement_id = 0
            # Each group represents one instance of the replacement.
            for group in repl.groups:
                ports = {}
                for key in repl.entity.ports:
                    ports[key] = ""
                ports["ENABLE_I"] = "'1'"
                ports.pop("REG_O")
                ports.pop("REG_I")
                reg_index = 0
                # Group center coordinates used to determine mapping of
                # control signals.
                c_x, c_y = (-1, -1)
                reg_ports_in = {}
                reg_ports_out = {}
                for point, ff_range in group:
                    x, y, z = point
                    if not c_x:
                        c_x = x
                    else:
                        c_x += x
                    if not c_y:
                        c_y = y
                    else:
                        c_y += y

                    start, end = ff_range
                    # Special handling of the first layer
                    if z == 0:
                        for i in range(start, end):
                            reg_ports_in[
                                "REG_I({})".format(reg_index)
                            ] = "stream_array({x})({y})({i})".format(x=x, y=y, i=i)
                            reg_ports_out[
                                "REG_O({})".format(reg_index)
                            ] = "stream_array({x})({y})({i})".format(x=x, y=y + 1, i=i)
                        stream_layer_ff[y][x] -= end - start
                        if stream_layer_ff[y][x] == 0:
                            network.ff_layers[z, y, x] = False
                    else:
                        signal = None
                        for s in network.signals.values():
                            if s.layer_index == z:
                                signal = s
                                break
                        if not signal:
                            print(
                                "Layer {} without associated NetworkSignal object!".format(
                                    z
                                )
                            )
                            continue
                        mapped_x = x
                        mapped_y = y
                        if signal.distribution == DistributionType.PER_STAGE:
                            if signal.max_fanout:
                                mapped_x = x // signal.max_fanout
                        if signal.distribution == DistributionType.PER_LINE:
                            if signal.max_fanout:
                                mapped_y = y // signal.max_fanout

                        reg_ports_in[
                            "REG_I({})".format(reg_index)
                        ] = "{signal_name}_array({x})({y})".format(
                            signal_name=signal.name.lower(),
                            x=mapped_x,
                            y=mapped_y,
                        )
                        reg_ports_out[
                            "REG_O({})".format(reg_index)
                        ] = "{signal_name}_array({x})({y})".format(
                            signal_name=signal.name.lower(),
                            x=mapped_x,
                            y=mapped_y + 1,
                        )
                        network.ff_layers[z, y, x] = False
                    reg_index += 1
                # Done with assigning ports in this group.
                c_x = c_x // len(group)
                c_y = c_y // len(group)
                for port, assign in ports.items():
                    if not assign:
                        signal_name = port.split("_")[0].upper()
                        ports[port] = self.__map_signal(
                            network, template, signal_name, (c_x, c_y)
                        )

                name = "REPL_" + str(replacement_id)
                replacement_id += 1
                generics = {"NUM_INPUTS": str(reg_index)}
                self.writer.write_incremental(
                    repl.entity.as_instance_manual(
                        name, generics, ports | reg_ports_in | reg_ports_out
                    )
                )
        self.writer.write_end_comment()

        return stream_layer_ff

    def __process_reg_chains(
        self,
        network: Network,
        stream_layer_ff: np.ndarray,
        ff_chains: list[list[tuple[int, int, int]]],
    ):
        reg_assign = "{signal_name}_array({x})({y_s}+1 to {y_e}) <= {signal_name}_array({x})({y_s} to {y_e}-1);\n"
        reg_assign_sw = "{signal_name}_array({x})({y_e})({sw_e} downto {sw_s}) <= {signal_name}_array({x})({y_s})({sw_e} downto {sw_s});\n"

        for z, group in enumerate(ff_chains):
            if z == 0:
                sw = network.signals["STREAM"].bit_width
                for x, start, end in group:
                    for y in range(start, end):
                        self.writer.write_incremental(
                            reg_assign_sw.format(
                                signal_name="stream",
                                x=x,
                                y_s=y,
                                y_e=y + 1,
                                sw_s=stream_layer_ff[y][x] - 1,
                                sw_e=sw - 1,
                            )
                        )
            else:
                signal = None
                for s in network.signals.values():
                    if s.layer_index == z:
                        signal = s
                        break
                if not signal:
                    print("No signal associated with layer {z}!".format(z=z))
                    continue
                signal_name = signal.name
                num_signals = signal.num_replications
                max_fan_out = signal.max_fanout
                for x, start, end in group:
                    print(x, start, end)
                    self.writer.write_incremental(
                        reg_assign.format(
                            signal_name=signal_name.lower(),
                            x=x // max_fan_out,
                            y_s=start,
                            y_e=end,
                        )
                    )

    def __make_registers(
        self,
        network: Network,
        stream_layer_ff: np.ndarray,
        entities: dict[str, VHDLEntity],
    ):
        self.writer.write_start_comment("Generated FF")
        ff_chains: list[list[tuple[int, int, int]]] = []
        self.writer.write_incremental(
            """
DelayRegister: process (CLK_I) is
begin
"""
        )
        for z, layer in enumerate(network.ff_layers):
            # Iterate over the layer stage wise.
            ff_chains.append([])
            print(z)
            for x in range(layer.shape[1]):
                start = 0
                end = 0
                # Find lateral register chains in the layer.
                print(layer[0:-1, x])
                for y in range(layer.shape[0]):
                    if layer[y, x]:
                        if start == end:
                            start = y
                        end = y + 1
                    elif start < end:
                        ff_chains[z].append((x, start, end))
                        start = end
                if start < end:
                    ff_chains[z].append((x, start, end))

        print(ff_chains)
        self.__process_reg_chains(network, stream_layer_ff, ff_chains)
        self.writer.write_incremental("\nend process;\n")
        self.writer.write_end_comment()

    def __handle_registers(
        self,
        network: Network,
        template: VHDLTemplate,
        entities: dict[str, VHDLEntity],
        **kwargs
    ):
        # We need to keep track fo the assigned FFs in the permutation layer,
        # the only layer which contains potentially more than one FF.
        # Since the only information provided by the ff_layers is whether
        # any FF are present at a point, a new matrix has to be created.
        stream_layer_ff = np.zeros(network.ff_layers[0].shape, dtype=int)
        stream_layer_ff = network.signals["STREAM"].bit_width * network.ff_layers[0]
        if "ff_replacements" in kwargs:
            stream_layer_ff = self.__instantiate_ff_replacements(
                network, template, stream_layer_ff, kwargs["ff_replacements"]
            )
        self.__make_registers(network, stream_layer_ff, entities)

    def process_template(
        self,
        network: Network,
        template: VHDLTemplate,
        entities: dict[str, VHDLEntity],
        **kwargs
    ):
        self.writer = VHDLTemplateWriter(template, self.output_file)
        tokens = template.tokens
        tokens["top_name"] = "{}_{}X{}".format(
            network.typename, network.get_N(), len(network.output_set)
        )
        if network.shape:
            tokens["top_name"] += "_" + network.shape
        tokens["num_inputs"] = str(network.get_N())
        tokens["net_depth"] = str(network.get_depth())
        tokens["num_outputs"] = str(len(network.output_set))
        tokens["word_width"] = str(kwargs.get("W")) or str(8)
        tokens["subword_width"] = str(network.signals["STREAM"].bit_width)

        for signal in network.signals.values():
            tokens["num_" + signal.name.lower()] = str(signal.num_replications)

        for key in tokens.keys():
            if key.split("_")[0] == "num" and tokens[key] == "{" + key + "}":
                tokens[key] = str(1)

        tokens["signal_definitions"] = self.__get_signal_definitions(
            network, entities, **kwargs
        )
        self.writer.write_preamble(tokens)
        self.__instantiate_signal_distributors(network, template, entities)
        self.__make_io_assignments(network, template)
        self.__connect_cs_network(network, template, entities, tokens)
        self.__handle_registers(network, template, entities, **kwargs)
        self.writer.write_footer()
