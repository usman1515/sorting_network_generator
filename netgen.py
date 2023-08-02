#!/usr/bin/env python3

from pathlib import Path
import numpy as np
import math
import fire
import time

from scripts import vhdl
import scripts.network_generators as generators
from scripts.reporter import Reporter, Report
from scripts.template_processor import VHDLTemplateProcessor, VHDLTemplateProcessorStagewise
from scripts.resource_allocator import BlockAllocator, is_ff
from scripts.plotter import PlotWrapper


def get_sources(path=Path()):
    sources = dict()
    for source in path.glob("./**/*.vhd"):
        entity = vhdl.parseVHDLEntity(source)
        if entity:
            sources[entity.name] = entity
    return sources


def get_templates(path=Path()):
    templates = dict()
    for source in path.glob("./**/*.vhd"):
        template = vhdl.parseVHDLTemplate(source)
        if template:
            template.name = source.name
            templates[template.name] = template
    return templates


def print_timestamp(title: str):
    time_str = "[%b %d %H:%M:%S]: "
    print(time.strftime(time_str) + title, end="")


class Interface:
    def __init__(self):
        self.__start_time = time.perf_counter_ns()
        self.__entities = dict()
        print_timestamp("Parsing sources...")
        self.__entities = get_sources(Path("src/"))
        print(" done.")
        self.__templates = dict()
        print_timestamp("Parsing templates...")
        self.__templates = get_templates(Path("templates/"))
        print(" done.")
        self.__generator = None
        self.__network = None
        self.__ffreplacements = []
        self.__reporter = Reporter()

    def __del__(self):
        print_timestamp(
            "Finished after " + str(time.perf_counter_ns() - self.__start_time) + "ns."
        )
        print()

    def __str__(self):
        return ""

    def list(self, listtype=""):
        """List available components and templates.
        Searches "src/" for components, "templates/" for templates and lists
        results.
        Parameters:
            "components": list all available components with generics and ports.
            "templates": list all available templates with tokens,generics and
                        ports.
            "entity_name": list entity with generics and ports.
            "template_name": list template with tokens, generics and ports.
        """
        if listtype == "components":
            print("components:")
            for entity in self.__entities.values():
                print(entity.name)

        elif listtype == "templates":
            print("templates:")
            for template in self.__templates.values():
                print(template.name)

        elif listtype in self.__entities.keys():
            entity = self.__entities[listtype]
            print(entity.name + ":")
            if entity.generics:
                print("\tgenerics")
                for name, gtype in entity.generics.items():
                    print("\t\t" + name, ":", gtype)
            print("\tports")
            for name, ptype in entity.ports.items():
                print("\t\t" + name, ":", ptype)

        elif listtype in self.__templates.keys():
            template = self.__templates[listtype]
            print(template.name + ":")
            print("\t tokens:", template.tokens)
            if template.generics:
                print("\tgenerics")
                for name, gtype in template.generics.items():
                    print("\t\t" + name, ":", gtype)
            print("\tports")
            for name, ptype in template.ports.items():
                print("\t\t" + name, ":", ptype)

        else:
            print("components:")
            for entity in get_sources(Path("src/")).values():
                print("\t" + entity.name)
            print("templates:")
            for template in Path("templates/").glob("**/*.vhd"):
                print("\t" + template.name)
        return self

    def generate(self, algorithm: str, N: int, SW: int = 1):
        """Generate a Sorting Network based on parameters given.

        Parameters:
            algorithm:
                Sorting Network algorithm. Valid options are OddEven,
                Bitonic and Blank. The last option creates an empty
                network consisting only of delaying elements.
            N:
                Number of parallel inputs the generated network will
                support. Not required to be a power of two.
            SW:
                Number of bits of the subword to be processed in a cycle.
                Has no effect on the network topology but is required during
                FF optimization and VHDL-code generation.
        """
        # Multiple generates withine one call should cause the
        # reporter to commit its aggregated stats to memory.
        if self.__network:
            self.__reporter.commit_report()

        valid_types = ["oddeven", "bitonic", "blank"]
        if "oddeven" == algorithm.lower():
            print_timestamp("Generating Odd-Even-Network...")
            logp = int(math.ceil(math.log2(N)))
            self.__generator = generators.OddEven()
            self.__network = self.__generator.create(2**logp)
            self.__network = self.__generator.reduce(self.__network, N)
        elif "bitonic" == algorithm.lower():
            print_timestamp("Generating Bitonic-Network...")
            logp = int(math.ceil(math.log2(N)))
            self.__generator = generators.Bitonic()
            self.__network = self.__generator.create(N)
            self.__network = self.__generator.reduce(self.__network, N)
        elif "blank" == algorithm.lower():
            print_timestamp("Generating blank network...")
            logp = int(math.ceil(math.log2(N)))
            depth = logp * (logp + 1) // 2
            self.__network = generators.Network(N, depth)
        else:
            print("Options: oddeven, bitonic, blank")
        if algorithm.lower() in valid_types:
            self.__reporter.report_network(self.__network)
            print(" done.")
        return self

    def distribute_signal(self, signal_name: str, max_fanout: int):
        """Performs signal replication and distribution within the network.
        Primary use is to reduce fanout of shared signals in each stage.

        Paramters:
            signal_name: str
                Name of the signal to distribute in the network. At the current
                point, only the START signal supports distribution.
            max_fanout: int
                Maximum fanout to consider during replication. If a signal
                exceeds this number, a tree-based signal replicator is
                instantiated,
        """
        print_timestamp("Distributing signal '{}'...".format(signal_name))
        if self.__network:
            self.__network = self.__generator.distribute_signal(
                self.__network, signal_name, max_fanout
            )
        print(" done.")
        return self

    def reshape(self, output_config: str, num_outputs: int):
        """Reshape network outputs to only produce min, max or median elements.
        Redundant CS elements, FF and even stages are removed from the network.

        Parameters:
            output_config: str
                Name of the output configuration. Valid options are "max",
                "min" or "median".
            num_outputs: int
                Number of desired outputs. Allows creation of networks
                producing a set of the largest/smallest/median inputs.
        """
        if output_config.lower() not in ["max", "min", "median"]:
            print("Error: output_config options are max, min, median")
            return self
        elif output_config.lower() == "full":
            return self
        else:
            print_timestamp(
                "Reshaping Network to {} with {} outputs...".format(
                    output_config, num_outputs
                ),
            )
            N = self.__network.get_N()
            if output_config.lower() == "max":
                self.__generator.prune(self.__network, set(range(0, num_outputs)))
                self.__network.output_config = "max"
            elif output_config.lower() == "min":
                self.__generator.prune(self.__network, set(range(N - num_outputs, N)))
                self.__network.output_config = "min"
            elif output_config.lower() == "median":
                lower_bound = N // 2 - num_outputs // 2
                upper_bound = N // 2 + (num_outputs + 1) // 2
                self.__generator.prune(
                    self.__network, set(range(lower_bound, upper_bound))
                )
                self.__network.output_config = "median"
            print(" done.")
            self.__reporter.report_network(self.__network)
        return self

    def prune(self, output_set, name: str = "mixed"):
        """Prune network outputs to only contain CS,FF and stages relevant
        to the sorting of the indices given by the output set.

        Parameters
            output_set: list[int]
                Indices of the desired outputs. For a 16-input Sorting
                Network, to produce a network for min,max and median
                elements, the set must contain 0,7,15.
            name: str
                Name of the output config, relevant for correct reporting.
                Default value is 'mixed'.
        """
        print_timestamp(
            "Pruning Network outputs...",
        )
        self.__generator.prune(self.__network, set(output_set))
        self.__network.output_config = name
        print(" done.")
        self.__reporter.report_network(self.__network)
        return self

    def print_network(self):
        """Print network. Divides output into CS configuration and FF layers."""
        print(self.__network)
        return self

    def replace_ff(self, entity: str, limit=1500, entity_ff=48):
        """Replace network FF with resource given by parameters. Algorithm used
        attempts to keep a measure of locality at the cost of efficiency in the
        replacement FF capacity.

        Parameters:
            entity: str
                Name of the entity to use as a FF replacement. Use 'list'
                command to get all parsed entitys. Currently, only
                REGISTER_DSP is supported.
            limit: int
                Maximum number of replacements to use. May not exceed the total
                number of the resource available on the target device.
            entity_ff: int
                Maximum number of FF to be replaced with one instantce of the
                replacement. Depends on the target device.
        """
        print_timestamp(
            "Replacing FF with {} resource...".format(entity),
        )
        entity_obj = self.__entities[entity]
        ralloc = BlockAllocator()
        ffrepl = ralloc.reallocate_ff(self.__network, entity_obj, limit, entity_ff)
        self.__reporter.report_ff_replacement(ffrepl)
        self.__ffreplacements.append(ffrepl)
        print(" done.")
        return self

    def write(
        self,
        path: str = "",
        cs: str = "SWCS",
        W: int = 8,
        stagewise: bool = False,
    ):
        """Generate and write VHDL code from the network. Produces
        "Network.vhd" containing the Sorting Network, "Sorter.vhd"
        containing the Sorter providing a unified interface and
        "Test_Sorter.vhd", which contains a test infrastructure.

        Parameters:
            path:
                Path to place generated files at. Defaults to
                'build/*NetworkName*/'
            cs:
                Name of the CS element instantiated in the code.
            W:
                Width or length of the words to be sorted.
        """
        # Templates: Network.vhd, Sorter.vhd, Test_Sorter.vhd
        template_names = ["Sorter.vhd", "Test_Sorter.vhd"]
        print_timestamp(
            "Writing templates ...",
        )
        cs_entity = self.__entities[cs]
        if not path:
            name = self.__network.algorithm
            name += "_" + str(self.__network.get_N())
            name += "X" + str(len(self.__network.output_set))
            if self.__network.output_config:
                name += "_" + self.__network.output_config.upper()
            path = "build/{}/".format(name)
        path_obj = Path(path)
        path_obj.mkdir(parents=True, exist_ok=True)
        template_processor = None
        if stagewise:
            template_processor = VHDLTemplateProcessorStagewise()
        else:
            template_processor = VHDLTemplateProcessor()

        entities = {
            "CS": cs_entity,
            "Signal_Distributor": self.__entities["SIGNAL_DISTRIBUTOR"],
            "Stage": self.__entities["Stage"],
        }
        kwargs = {"W": W, "ff_replacements": self.__ffreplacements}
        template_processor.process_network_template(
            path_obj / "Network.vhd",
            self.__network,
            self.__templates["Network.vhd"],
            entities,
            **kwargs,
        )
        for temp in template_names:
            template_processor.process_template(
                path_obj / temp,
                self.__network,
                self.__templates[temp],
                **kwargs,
            )
        print(" done.")
        print(
            "Wrote Network.vhd, "
            + ", ".join(template_names)
            + " to {}".format(str(path_obj))
        )
        print_timestamp("Writing reports ...")
        self.__reporter.commit_report()
        path = "build/report.csv"
        self.__reporter.write_report(path)
        print(" done.")
        print("Added data to build/report.csv.")
        return self

    def report_net(self):
        """Print data gathered by the reporter from the current network."""
        report = Report(self.__network)
        for key, value in report.content.items():
            print(key, value)
        return self

    def show_ff(self):
        layer = self.__network.con_net
        line = "|"
        for i in range(len(layer[0])):
            line += "{:<2}".format(i % 10)
            # line += "__".format(i % 10)
        line += "|"
        print(line)
        for i, stage in enumerate(layer):
            line = "|"
            for pair in stage:
                if is_ff(pair):
                    line += "+ "
                else:
                    line += "  "
            line += "| {}".format(i)
            print(line)

    def pretty_print(self):
        """Pretty print CS configuration of the network."""
        layer = self.__network.con_net
        for stage in layer:
            print(" " + "--" * len(stage) + "")
            for i, pair in enumerate(stage):
                if i < pair[1]:
                    end = pair[1]
                    if pair[0] == "F":
                        print(
                            " "
                            + "| " * (i)
                            + "==" * (end - i - 1)
                            + "=>"
                            + "| " * (len(stage) - end)
                            + " "
                        )
                    elif pair[0] == "R":
                        print(
                            " "
                            + "| " * (i)
                            + "<="
                            + "==" * (end - i - 1)
                            + "| " * (len(stage) - end)
                            + " "
                        )

    def show_ff_assign(self):
        layer = self.__network.con_net
        groups = self.__ffreplacements[0]
        line = "|"
        for i in range(len(layer[0])):
            line += "{:<2}".format(i % 10)
        line += "|"
        print(line)
        for i in range(len(layer)):
            line = "|"
            for j in range(len(layer[i])):
                if is_ff(layer[i][j]):
                    elem = "+ "
                    for k in range(len(groups)):
                        for point in groups[k]:
                            if np.all(np.equal(np.asarray((j, i)), point)):
                                elem = "{} ".format(k)
                                break
                    line += elem
                else:
                    line += "  "
            print(line)

    def plot(self):
        return PlotWrapper()


# a = Interface()
# a.test()

if __name__ == "__main__":
    fire.Fire(Interface)
