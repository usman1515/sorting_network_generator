#!/usr/bin/env python3

from pathlib import Path
from scripts.vhdl_container import *
from scripts.network_generators import *


class Template_Processor:
    def __init__(self):
        pass

    def fill_main_file(self, template, cs, network, W=8, SW=1):
        """Takes kwargs and returns template object with generated network."""

        N = network.get_N()
        shape = network.shape
        output_set = network.get_output_set()
        num_outputs = len(output_set)
        depth = network.get_depth()

        bit_width = W
        subword_width = SW

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

        instances = ""
        # Create instances of CS elements forming the network.
        for i in range(depth):
            for j in range(N):
                if network[i][j][1] > j:
                    a = j
                    b = network[i][j][1]
                    specific = dict()
                    specific["A0"] = "wire({})({})".format(a, i)
                    specific["B0"] = "wire({})({})".format(b, i)
                    if network[i][j][0] == "F":
                        specific["A1"] = "wire({})({})".format(a, i + 1)
                        specific["B1"] = "wire({})({})".format(b, i + 1)
                    else:
                        specific["A1"] = "wire({})({})".format(b, i + 1)
                        specific["B1"] = "wire({})({})".format(a, i + 1)

                    specific["START"] = "start_i({})".format(i)
                    instances += cs.as_instance(
                        "CS_D{}_A{}_B{}".format(i, a, b),
                        generics,
                        ports | specific,
                    )

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

        # Enclose bypassed wires in synchronous process.
        if bypasses:
            instances += "Delay : process(CLK) is \nbegin\nif (rising_edge(CLK)) then\n{}end if;\nend process;\n".format(
                bypasses
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
