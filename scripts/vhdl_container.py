#!/usr/bin/env python3


class Entity:
    def __init__(self, name, ports=dict(), generics=dict()):
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
                    if i + 1 < len(genassign):
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

    def as_instance_portmanual(
        self, instance_name="", genassign=dict(), port_string=""
    ):
        a = "{} : entity work.{}\n".format(instance_name, self.name)

        if bool(self.generics) and bool(genassign):
            a += "generic map(\n"
            keys = list(self.generics.keys())
            for i in range(0, len(self.generics)):
                key = keys[i]
                if key in genassign.keys():
                    a += "   {} => {}".format(key, genassign[key])
                    if i + 1 < len(genassign):
                        a += ","
                a += "\n"
            a += ")\n"
        a += port_string
        return a

    def __str__(self):
        return self.as_entity()


class Template(Entity):
    def __init__(
        self, name, template_file, generics=dict(), ports=dict(), tokens=dict()
    ):
        super().__init__(name, generics, ports)
        self.template_file = template_file
        self.tokens = tokens

    def as_template(self):
        # for key, value in self.tokens.items():
        #     print(key, value)
        return self.template_file.format_map(self.tokens)
