#!/usr/bin/env python3

from pathlib import Path
import fire
import csv

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
        self.logs = []

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

    def generate(
        self,
        nettype,
        inputs,
        outputs,
        cs,
        template,
        N,
        W,
        num_outputs,
        shape,
    ):
        print(
            nettype,
            inputs,
            outputs,
            cs,
            template,
            N,
            W,
            num_outputs,
            shape,
        )
        template = self.templates[template]
        # inputs = self.entities[inputs]
        # outputs = self.entities[outputs]
        cs = self.entities[cs]
        if "oddeven" == nettype.lower():
            generator = OddEven()
            template = generator.generate(cs, template, N, W, num_outputs, shape)
            path = Path("build/{}.vhd".format(template.name))
            with open(str(path), "w") as fd:
                fd.write(template.as_template())
            self.logs.append(generator.log_dict)

        elif "bitonic" == nettype.lower():
            generator = Bitonic()
            template = generator.generate(cs, template, N, W, num_outputs, shape)
            path = Path("build/{}.vhd".format(template.name))
            with open(str(path), "w") as fd:
                fd.write(template.as_template())
            self.logs.append(generator.log_dict)
        else:
            print("Options: oddeven, bitonic")
        return self

    def write_log(self, logfile="report.csv"):
        with open("build/{}.csv".format(logfile), "w") as fd:
            w = csv.DictWriter(fd, self.logs[0].keys())
            # w.writerow(dict((fn, fn) for fn in log_dict.keys()))
            w.writeheader()
            w.writerows(self.logs)
        return self

    def test(self):
        #        print(parse_entity_vhdl(Path("templates/SortNet.vhd")))

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
