#!/usr/bin/env python3
import math
from datetime import datetime


class Generator:
    def __init__(self):
        self.name = ""
        self.keywords = dict()
        self.optional = {
            "W": "Width of operands",
            "shape": "Shape of Network: min, max, median",
            "num_outputs": "Number of output elements.",
        }

    def __str__(self):
        print(self.name)
        for k, v in self.keywords.items():
            print(k, v)
        print("optional:")
        for k, v in self.optional.items():
            print(k, v)

    def create_connection_matrix(self, N):
        pass

    def reduce_connection_matrix(self, A, N):
        """Reduces size connection matrix to N inputs."""
        # Nothing to do of target and actual size are the same.
        if N == len(A[0]):
            return A
        depth = len(A)
        for d in range(depth):
            for i in range(N):
                # Look for CS elements whose inputs are outside of the target
                # size. Replace them with bypass elements.
                if A[d][i][1] >= N:
                    A[d][i] = ("+", i)
            # Resize stage to target size.
            A[d] = A[d][:N]
        return A

    def prune_connection_matrix(self, A, output_set=set()):
        """Prunes CS elements not belonging to outputs in output_set.
        Starting at the end of the network, all CS not relevant for sorting
        elements of the output are pruned. Each stage of the network, wires
        connected to the outputs through CS elements are added to the set to
        ensure correctness.
        """
        depth = len(A)
        N = len(A[0])
        d = depth

        # Beginning at the output end of the network...
        while d >= 0:
            d -= 1
            for i in range(N):
                # ... remove all CS elements not in output_set ...
                if A[d][i][1] not in output_set and i not in output_set:
                    A[d][i] = ("", i)
                else:
                    # ... and add ports connected to wires into output_set.
                    if A[d][i][0] in ("F", "R"):
                        output_set.add(A[d][i][1])
            # If the output set contains all ports we are done.
            if len(output_set) == N:
                break

        # Remove stages which only contain delay elements.
        A = [stage for stage in A if any([pair[0] in ("F", "R") for pair in stage])]

        return A

    def generate(self, template, **kwargs):
        """Takes kwargs and returns template object with generated network."""
        if not any(kw in kwargs.keys() for kw in self.keywords):
            print("Error: The following parameters are required:")
            print(self)
            return

        # Default shape of network is max.
        shape = "max"
        if "shape" in kwargs.keys() and kwargs["shape"].lower() in (
            "max",
            "min",
            "median",
        ):
            shape = kwargs["shape"].lower()

        N = int(kwargs["N"])

        # Begin building connection matrix from parameters.
        A = self.create_connection_matrix(N)
        A = self.reduce_connection_matrix(A, N)

        # Default number of outputs is N
        num_outputs = N
        if "num_outputs" in kwargs.keys() and int(kwargs["num_outputs"]) > 0:
            num_outputs = kwargs["num_outputs"]

        # Using shape and number of output elements, build output_set.
        output_set = output_set = set(range(N - num_outputs, N))
        if shape == "median":
            if "num_outputs" not in kwargs.keys():
                # If N is even, we want the two center outputs
                num_outputs = 1 + (N + 1) % 2
            output_set = set(range((N - num_outputs) // 2, (N + num_outputs) // 2))
        elif shape == "min":
            output_set = set(range(0, num_outputs))

        # With output_set, prune unneeded CS and outputs. Might also reduce
        # depth of network.
        #
        A = self.prune_connection_matrix(A, output_set.copy())
        depth = len(A)

        # Begin building content for placeholder tokens of template.
        top_name = "ODDEVEN_{}_TO_{}_{}".format(N, num_outputs, shape.upper())
        bit_width = 8
        if "W" in kwargs.keys():
            bit_width = kwargs["W"]

        # components = kwargs["input"].as_component() + "\n"
        # components += kwargs["output"].as_component() + "\n"
        # components += kwargs["cs"].as_component() + "\n"

        generics = {"W": bit_width}
        ports = {"CLK": "CLK", "E": "E", "RST": "RST"}

        instances = ""
        # Create instances of CS elements forming the network.
        for i in range(depth):
            for j in range(N):
                if A[i][j][1] > j:
                    a = j
                    b = A[i][j]
                    specific = dict()
                    specific["A0"] = "wire({})({})".format(a, i)
                    specific["B0"] = "wire({})({})".format(b, i)
                    if A[i][j][0] == "F":
                        specific["A1"] = "wire({})({})".format(a, i + 1)
                        specific["B1"] = "wire({})({})".format(b, i + 1)
                    else:
                        specific["A1"] = "wire({})({})".format(b, i + 1)
                        specific["B1"] = "wire({})({})".format(a, i + 1)

                    specific["START"] = "START({})".format(i)
                    instances += kwargs["cs"].as_instance(
                        "CS_D{}_A{}_B{}".format(i, a, b), generics, ports | specific
                    )

        # Fill bypasses with delay elements.
        bypasses = ""
        for i in range(depth):
            for j in range(N):
                if A[i][j][0] == "+":
                    bypass_beg = i
                    bypass_end = i
                    while bypass_end < depth and A[bypass_end][j][0] == "+":
                        A[bypass_end][j][0] = ""
                        bypass_end += 1
                    bypasses += "wire({row})({end} downto {beg}+1) <= wire({row})({end}-1 downto {beg});\n".format(
                        row=j, end=bypass_end, beg=bypass_beg
                    )
        # Enclose bypassed wires in synchronous process.
        if bypasses:
            instances += "Delay : process(CLK) is \nbegin\nif (rising_edge(CLK)) then\n{}end if;\nend process;\n".format(
                bypasses
            )

        # Add serializers for each network input.
        for i in range(N):
            specific = dict()
            specific["PAR_INPUT"] = "input({})".format(i)
            specific["SER_OUTPUT"] = "wire({})(0)".format(i)
            specific["LOAD"] = "START(START'low)"

            instances += kwargs["input"].as_instance(
                "input_{}".format(i), generics, ports | specific
            )

        # Add deserializers for each network output.
        output_list = list(output_set)
        output_list.sort()
        if shape == "min":
            output_list.reverse()

        for i in range(num_outputs):
            specific = dict()
            specific["PAR_OUTPUT"] = "output({})".format(i)
            specific["SER_INPUT"] = "wire({})({})".format(output_list[i], depth)
            specific["STORE"] = "START(START'high)"
            instances += kwargs["output"].as_instance(
                "output_{}".format(i), generics, ports | specific
            )

        tokens = {
            "top_name": top_name,
            "net_depth": depth,
            "num_inputs": N,
            "num_outputs": num_outputs,
            "bit_width": bit_width,
            # "components": components,
            "instances": instances,
            "date": datetime.now(),
        }
        template.tokens = tokens
        template.name = top_name
        return template


class OddEven(Generator):
    def __init__(self):
        super().__init__()
        self.keywords = {
            "input": "Name of input component",
            "output": "Name of output component",
            "CS": "Name of compare swap element",
            "template": "Name of template",
            "N": "Number of inputs. Must be power of 2",
        }

    def create_connection_matrix(self, N):
        # Adaption of algorithm described at
        # https://en.wikipedia.org/wiki/Batcher_odd%E2%80%93even_mergesort
        logp = int(math.ceil((math.log2(N))))
        depth = logp * (logp + 1) // 2
        A = [[("+", j) for j in range(N)] for i in range(depth)]
        d = -1  # Current network depth index
        for p_e in range(0, logp):
            p = 2**p_e
            for k_e in range(p_e, -1, -1):
                k = 2**k_e
                d += 1
                for j in range(k % p, N - k, 2 * k):
                    for i in range(0, min(k, N - j - k)):
                        if math.floor((i + j) / (p * 2)) == math.floor(
                            (i + j + k) / (p * 2)
                        ):
                            A[d][i + j] = ("F", i + j + k)
                            A[d][i + j + k] = ("F", i + j)
        return A


class Bitonic(Generator):
    def __init__(self):
        super().__init__()
        self.keywords = {
            "input": "Name of input component",
            "output": "Name of output component",
            "CS": "Name of compare swap element",
            "template": "Name of template",
            "N": "Number of inputs. Must be power of 2",
        }

    def create_connection_matrix(self, N):
        # Adaption of algorithm described at
        # https://courses.cs.duke.edu//fall08/cps196.1/Pthreads/bitonic.c
        logp = int(math.ceil((math.log2(N))))
        depth = logp * (logp + 1) // 2
        A = [[("+", j) for j in range(N)] for i in range(depth)]
        d = -1  # Current network depth index
        #
        for k_e in range(0, logp + 1):
            k = 2**k_e
            for j_e in range(k_e - 1, -1, -1):
                j = 2**j_e
                print(k_e, j_e)
                d += 1
                for i in range(N):
                    x = i ^ j
                    if x > i:
                        if i & k:
                            A[d][i] = ("R", x)
                            A[d][x] = ("R", i)
                        else:
                            A[d][i] = ("F", x)
                            A[d][x] = ("F", i)
        return A


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    gen = OddEven()
    A = gen.create_connection_matrix(8)
    for layer in A:
        print(layer)
    print()
    gen = Bitonic()
    A = gen.create_connection_matrix(8)
    for layer in A:
        print(layer)
    print()
    A = gen.reduce_connection_matrix(A, 8)
    for layer in A:
        print(layer)
    print()
    output_set = set()
    output_set.add(0)
    output_set.add(7)
    print(output_set)
    A = gen.prune_connection_matrix(A, output_set.copy())
    output_list = list(output_set)
    output_list.sort()
    print(output_list)
    for layer in A:
        print(layer)
    print()
