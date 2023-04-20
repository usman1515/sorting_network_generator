#!/usr/bin/env python3

from pathlib import Path
import regex


class VHDLEntity:
    def __init__(
        self, name: str, ports: dict[str, str] = {}, generics: dict[str, str] = {}
    ):
        self.name = name
        self.ports = ports
        self.generics = generics

    def __deflist(self, listname, elements):
        a = ""
        if elements:
            a += "{} (\n".format(listname)
            keys = list(elements)
            for i in range(0, len(elements)):
                value = elements[keys[i]]
                a += "   " + keys[i] + ": " + value
                if i + 1 < len(elements):
                    a += ";"
                a += "\n"
            a += ");\n"
        return a

    def __def(self):
        a = ""
        a += self.__deflist("generic", self.generics)
        a += self.__deflist("port", self.ports)
        return a

    def as_entity(self):
        a = "entity {} is\n".format(self.name)
        a += self.__def()
        a += "end entity {};".format(self.name)
        return a

    def as_component(self):
        a = "component {} is\n".format(self.name)
        a += self.__def()
        a += "end component {};".format(self.name)
        return a

    def as_instance(self, instance_name="", genassign=dict(), portassign=dict()):
        a = "{} : entity work.{}\n".format(instance_name, self.name)

        if bool(self.generics) and bool(genassign):
            a += "generic map(\n"
            keys = list(self.generics.keys())
            for i in range(0, len(self.generics)):
                key = keys[i]
                if key in genassign.keys():
                    a += "   {} => {}".format(key, genassign[key])
                    if i + 1 < len(self.generics):
                        a += ","
                a += "\n"
            a += ")\n"
        if self.ports:
            a += "port map(\n"
            keys = list(self.ports.keys())
            for i in range(0, len(self.ports)):
                key = keys[i]
                a += "   {} => {}".format(key, portassign[key])
                if i + 1 < len(self.ports):
                    a += ","
                a += "\n"
            a += ");\n"
        return a

    def as_instance_manual(
        self,
        instance_name: str,
        generics: dict[str, str] = {},
        ports: dict[str, str] = {},
    ):
        """Using parameters, generates code for instantiation of the entity.
        Unlike as_instance, this method ignores whether generics or ports
        actually exist in the entity definition.
        """
        inst = "{} : entity work.{}\n".format(instance_name, self.name)

        if generics:
            inst += "generic map(\n"
            for i, key in enumerate(generics.keys()):
                inst += "   {} => {}".format(key, generics[key])
                if i + 1 < len(generics):
                    inst += ","
                inst += "\n"
            inst += ")\n"
        if ports:
            inst += "port map(\n"
            for i, key in enumerate(ports.keys()):
                inst += "   {} => {}".format(key, ports[key])
                if i + 1 < len(ports):
                    inst += ","
                inst += "\n"
            inst += ");\n"
        return inst

    def __str__(self):
        return self.as_entity()


class VHDLTemplate(VHDLEntity):
    def __init__(
        self,
        name: str,
        template_string: str,
        generics: dict[str, str] = {},
        ports: dict[str, str] = {},
        tokens: dict[str, str] = {},
    ):
        super().__init__(name, generics, ports)
        self.template_string = template_string
        self.tokens = tokens

    def as_template(self):
        # for key, value in self.tokens.items():
        #     print(key, value)
        return self.template_string.format_map(self.tokens)


def parseVHDLEntity(path=Path()):
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
        return VHDLEntity(name, ports, generics)
    return None


def parseVHDLTemplate(path=Path()):
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
        tokens[token] = "{" + token + "}"
    # VHDLTemplates are normal vhdl Entities without the tokens.
    entity = parseVHDLEntity(path)
    if entity:
        return VHDLTemplate(entity.name, content, entity.ports, entity.generics, tokens)
    return None


cond = __name__ == "__main__"
if cond:
    print(parseVHDLTemplate("../templates/Network.vhd").tokens)
