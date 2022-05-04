#!/usr/bin/env python3

from pathlib import Path
import fire
import csv

from scripts.template_processor import *
from scripts.reporter import *
from scripts.vhdl_parser import *
from scripts.vhdl_container import *
from scripts.network_generators import *


def get_sources(path=Path()):
    sources = dict()
    for source in path.glob("./**/*.vhd"):
        entity = parse_entity_vhdl(source)
        if entity:
            sources[entity.name] = entity
    return sources


def get_templates(path=Path()):
    templates = dict()
    for source in path.glob("./**/*.vhd"):
        template = parse_template_vhdl(source)
        if template:
            template.name = source.name
            templates[template.name] = template
    return templates


class Interface:
    def __init__(self):
        self.entities = dict()
        self.entities = get_sources(Path("src/"))
        self.templates = dict()
        self.templates = get_templates(Path("templates/"))
        self.generator = None
        self.network = None
        self.template = None
        self.reporter = Reporter()

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

    def generate(self, network_type, N):
        if "oddeven" == network_type.lower():
            logp = int(math.ceil(math.log2(N)))
            self.generator = OddEven()
            self.network = self.generator.create(2**logp)
            self.network = self.generator.reduce(self.network, N)
        elif "bitonic" == network_type.lower():
            logp = int(math.ceil(math.log2(N)))
            self.generator = Bitonic()
            self.network = self.generator.create(2**logp)
            self.network = self.generator.reduce(self.network, N)
        else:
            print("Options: oddeven, bitonic")
        return self

    def shape(self, shape_type, num_outputs):
        if shape_type.lower() not in ["max", "min", "median"]:
            print("Error: shape_type options are max, min, median")
        else:
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
        return self

    def prune(self, output_list):
        self.generator.prune(self.network, output_list)
        self.network.shape = "mixed"
        return self

    def show_network(self):
        print(self.network)
        return self

    def show_template(self):
        print("hello")
        if self.template:
            print(self.template.as_template())
        else:
            print("No template selected.")
        return self

    def fill_template(self, template_name, cs, W=8, SW=1):
        self.template = self.templates[template_name]
        cs = self.entities[cs]
        template_processor = Template_Processor()
        self.template = template_processor.fill_main_file(
            self.template, cs, self.network, W, SW
        )
        self.reporter.add(self.network)
        return self

    def write_template(self, path=""):
        if not path:
            path = "build/{}.vhd".format(self.template.name)
        with open(path, "w") as fd:
            fd.write(self.template.as_template())
        return self

    def write_report(self, path=""):
        if not path:
            path = "build/report.csv"
        self.reporter.write_report(path)
        return self

    # def generate(
    #     self,
    #     nettype,
    #     cs,
    #     template,
    #     N,
    #     W,
    #     SW,
    #     num_outputs,
    #     shape,
    # ):
    #     template = self.templates[template]
    #     cs = self.entities[cs]
    #     if "oddeven" == nettype.lower():
    #         generator = OddEven()
    #         template = generator.generate(cs, template, N, W, SW, num_outputs, shape)
    #         path = Path("build/{}.vhd".format(template.name))
    #         with open(str(path), "w") as fd:
    #             fd.write(template.as_template())
    #         self.logs.append(generator.log_dict)

    #     elif "bitonic" == nettype.lower():
    #         generator = Bitonic()
    #         template = generator.generate(cs, template, N, W, SW, num_outputs, shape)
    #         path = Path("build/{}.vhd".format(template.name))
    #         with open(str(path), "w") as fd:
    #             fd.write(template.as_template())
    #         self.logs.append(generator.log_dict)
    #     else:
    #         print("Options: oddeven, bitonic")
    #     return self

    # def write_log(self, logfile="report.csv"):
    #     with open("build/{}.csv".format(logfile), "w") as fd:
    #         w = csv.DictWriter(fd, self.logs[0].keys())
    #         # w.writerow(dict((fn, fn) for fn in log_dict.keys()))
    #         w.writeheader()
    #         w.writerows(self.logs)
    #     return self

    def test(self):
        gen = OddEven()
        A = gen.create_connection_matrix(8)
        for layer in A:
            print(layer)
        print()
        A = gen.reduce_connection_matrix(A, 8)
        for layer in A:
            print(layer)
        print()
        output_set = set()
        output_set.add(1)
        output_set.add(4)
        A = gen.prune_connection_matrix(A, output_set)
        for layer in A:
            print(layer)
        print()


# a = Interface()
# a.test()

if __name__ == "__main__":
    fire.Fire(Interface)
