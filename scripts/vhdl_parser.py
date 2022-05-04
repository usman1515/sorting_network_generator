#!/usr/bin/env python3
from pathlib import Path
import regex
from scripts.vhdl_container import *


def parse_entity_vhdl(path=Path()):
    """Parse entity definition of vhdl file at path.

    Returns Entity object or None, entity couldn't be parsed.
    """
    content = ""
    # Read vhdl file and remove comments.
    with open(str(path), "r") as fd:
        for line in fd:
            content += line.split("--")[0]
    # Find entity name.
    name = regex.findall(r"entity\s*(\w+)\s*is", content, regex.S | regex.M)
    if name:
        name = name[0]
    else:
        # Attempt to find entity name placeholder.
        name = regex.findall(r"entity\s*(\{.*?\})\s*is", content, regex.S | regex.M)
        if not name:
            return None
        else:
            name = name[0]
    # Using entity name, find entity definition.
    entity_def = regex.findall(
        r"entity\s*{0}\sis.*end\sentity\s{0};".format(name), content, regex.S | regex.M
    )
    if entity_def:
        entity_def = entity_def[0]
        ports = dict()
        generics = dict()

        # Attempt to find generic clause.
        generic_clause = regex.findall(
            r"generic\s*\((.*)\);\s*port", entity_def, regex.M | regex.S
        )
        if generic_clause:
            # Extract generics.
            generic_matcher = regex.compile(r"\s*?(\w+)\s*?:\s*(\w*)")
            for pair in regex.findall(generic_matcher, generic_clause[0]):
                generics[pair[0]] = pair[1]

        # Attempt to find port clause
        port_clause = regex.findall(r"port\s\((.*)\);", entity_def, regex.M | regex.S)

        # Extract port definitions.
        if port_clause:
            port_matcher = regex.compile(r"\s*?(\w+)\s*?:\s*(\w*?\s+\w+[^;\n]*)")
            for pair in regex.findall(port_matcher, port_clause[0]):
                ports[pair[0]] = pair[1]
        else:
            return None
        return Entity(name, ports, generics)
    else:
        return None


def parse_template_vhdl(path=Path()):
    """Parse file given by path as template.

    Returns a template object or None if template couldn't be parsed.
    """
    content = ""
    # Read lines of file and remove comments.
    with open(str(path), "r") as fd:
        for line in fd:
            content += line.split("--")[0]

    # Create dictionary of tokens replaceable by string.format
    tokens = dict()
    for token in regex.findall(r"\{(.*?)\}", content, regex.S | regex.M):
        tokens[token] = ""
    # Templates are normal vhdl Entities without the tokens.
    entity = parse_entity_vhdl(path)
    if entity:
        return Template(entity.name, content, entity.ports, entity.generics, tokens)
    else:
        return None


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    pass
    # gen = OddEven()
    # self.A = gen.create_connection_matrix(8)
    # for layer in self.A:
    #     print(layer)
    # print(parse_entity_vhdl(Path("../src/CS/SubWordCS.vhd")))
