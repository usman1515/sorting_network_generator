#!/usr/bin/env python3

from pathlib import Path
import numpy as np
import math
import fire
import time

from scripts import vhdl
import scripts.network_generators as generators
from scripts.reporter import Reporter, Report
from scripts.template_processor import VHDLTemplateProcessor
from scripts.resource_allocator import Block_Allocator, is_ff


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
        self.start_time = time.perf_counter_ns()
        self.entities = dict()
        print_timestamp("Parsing sources...")
        self.entities = get_sources(Path("src/"))
        print(" done.")
        self.templates = dict()
        print_timestamp("Parsing templates...")
        self.templates = get_templates(Path("templates/"))
        print(" done.")
        self.generator = None
        self.network = None
        self.template = None
        self.ffreplacements = []
        self.reporter = Reporter()

    def __del__(self):
        print_timestamp(
            "Finished after " + str(time.perf_counter_ns() - self.start_time) + "ns."
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
            for entity in self.entities.values():
                print(entity.name)

        elif listtype == "templates":
            print("templates:")
            for template in self.templates.values():
                print(template.name)

        elif listtype in self.entities.keys():
            entity = self.entities[listtype]
            print(entity.name + ":")
            if entity.generics:
                print("\tgenerics")
                for name, gtype in entity.generics.items():
                    print("\t\t" + name, ":", gtype)
            print("\tports")
            for name, ptype in entity.ports.items():
                print("\t\t" + name, ":", ptype)

        elif listtype in self.templates.keys():
            template = self.templates[listtype]
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

    def generate(self, ntype: str, N: int, SW: int = 1):
        valid_types = ["oddeven", "bitonic", "blank"]
        if "oddeven" == ntype.lower():
            print_timestamp("Generating Odd-Even-Network...")
            logp = int(math.ceil(math.log2(N)))
            self.generator = generators.OddEven()
            self.network = self.generator.create(2**logp)
            self.network = self.generator.reduce(self.network, N)
        elif "bitonic" == ntype.lower():
            print_timestamp("Generating Bitonic-Network...")
            logp = int(math.ceil(math.log2(N)))
            self.generator = generators.Bitonic()
            self.network = self.generator.create(N)
            self.network = self.generator.reduce(self.network, N)
        elif "blank" == ntype.lower():
            print_timestamp("Generating blank Network...")
            logp = int(math.ceil(math.log2(N)))
            depth = logp * (logp + 1) // 2
            self.network = generators.Network(N, depth)
        else:
            print("Options: oddeven, bitonic, blank")
        if ntype.lower() in valid_types:
            print(" done.")
        return self

    def distribute_signal(self, signal_name: str, max_fanout: int):
        """Distributes the signal with the given name so that
        only a number of rows less than max_fanout is driven by the signal.
        """
        print_timestamp("Distributing signal '{}'...".format(signal_name))
        if self.network:
            self.network = self.generator.distribute_signal(
                self.network, signal_name, max_fanout
            )
        print(" done.")
        return self

    def shape(self, shape_type, num_outputs):
        if shape_type.lower() not in ["max", "min", "median"]:
            print("Error: shape_type options are max, min, median")
        else:
            print_timestamp(
                "Reshaping Network to {} with {} outputs...".format(
                    shape_type, num_outputs
                ),
            )
            N = self.network.get_N()
            if shape_type.lower() == "max":
                self.generator.prune(self.network, range(0, num_outputs))
                self.network.shape = "max"
            elif shape_type.lower() == "min":
                self.generator.prune(self.network, range(N - num_outputs, N))
                self.network.shape = "min"
            elif shape_type.lower() == "median":
                lower_bound = N // 2 - num_outputs // 2
                upper_bound = N // 2 + (num_outputs + 1) // 2
                self.generator.prune(self.network, range(lower_bound, upper_bound))
                self.network.shape = "median"
            print(" done.")
        return self

    def prune(self, output_list):
        print_timestamp(
            "Pruning Network outputs...",
        )
        self.generator.prune(self.network, output_list)
        self.network.shape = "mixed"
        print(" done.")
        return self

    def show_network(self):
        print(self.network)
        return self

    def show_template(self):
        if self.template:
            print(self.template.as_template())
        else:
            print("No template selected.")
        return self

    def replace_ff(self, entity: str, limit=1500, entity_ff=48):
        print_timestamp(
            "Replacing FF with {} resource...".format(entity),
        )
        entity_obj = self.entities[entity]
        ralloc = Block_Allocator()
        ffrepl = ralloc.reallocate_ff(self.network, entity_obj, limit, entity_ff)
        self.ffreplacements.append(ffrepl)
        print(" done.")
        return self

    def write(
        self,
        path: str = "",
        cs: str = "SWCS",
        W: int = 8,
    ):
        # Templates: Network.vhd, Sorter.vhd, Test_Sorter.vhd
        template_names = ["Sorter.vhd", "Test_Sorter.vhd"]
        templates = [self.templates[n] for n in template_names]
        print_timestamp(
            "Writing templates {} ...",
        )
        cs_entity = self.entities[cs]
        if not path:
            name = self.network.typename
            name += "_" + str(self.network.get_N())
            name += "X" + str(len(self.network.output_set))
            if self.network.shape:
                name += "_" + self.network.shape
            path = "build/{}/".format(name)
        path_obj = Path(path)
        path_obj.mkdir(parents=True, exist_ok=True)
        template_processor = VHDLTemplateProcessor()
        entities = {
            "CS": cs_entity,
            "Signal_Distributor": self.entities["SIGNAL_DISTRIBUTOR"],
        }
        kwargs = {"W": W, "ff_replacements": self.ffreplacements}
        template_processor.process_network_template(
            path_obj / "Network.vhd",
            self.network,
            self.templates["Network.vhd"],
            entities,
            **kwargs,
        )
        for temp in template_names:
            template_processor.process_template(
                path_obj / temp,
                self.network,
                self.templates[temp],
                **kwargs,
            )
        self.reporter.add(self.network)
        print(" done.")
        print("Wrote Network.vhd, " + ", ".join(template_names) + " to {}".format(path))
        return self

    def write_report(self, path=""):
        if not path:
            path = "build/report.csv"
        if not self.template and self.network:
            self.reporter.add(self.network)
        self.reporter.write_report(path)
        return self

    def report_net(self, path=""):
        report = Report(self.network)
        for key, value in report.content.items():
            print(key, value)
        return self

    def show_ff(self):
        layer = self.network.con_net
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
        layer = self.network.con_net
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
        layer = self.network.con_net
        groups = self.ffreplacements[0]
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


# a = Interface()
# a.test()

if __name__ == "__main__":
    fire.Fire(Interface)
