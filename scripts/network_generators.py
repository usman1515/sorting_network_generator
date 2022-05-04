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
        self.A = [[]]  # Connection matrix
        self.log_dict = {}

    def __str__(self):
        print(self.name)
        for k, v in self.keywords.items():
            print(k, v)
        print("optional:")
        for k, v in self.optional.items():
            print(k, v)

    def create_connection_matrix(self, N):
        pass

    def reduce_connection_matrix(self, N):
        """Reduces size connection matrix to N inputs."""
        # Nothing to do of target and actual size are the same.
        if N == len(self.A[0]):
            return self.A
        depth = len(self.A)
        for d in range(depth):
            for i in range(N):
                # Look for CS elements whose inputs are outside of the target
                # size. Replace them with bypass elements.
                if self.A[d][i][1] >= N:
                    self.A[d][i] = ("+", i)
            # Resize stage to target size.
            self.A[d] = self.A[d][:N]
        return self.A

    def prune_connection_matrix(self, output_set=set()):
        """Prunes CS elements not belonging to outputs in output_set.
        Starting at the end of the network, all CS not relevant for sorting
        elements of the output are pruned. Each stage of the network, wires
        connected to the outputs through CS elements are added to the set to
        ensure correctness.
        """
        depth = len(self.A)
        N = len(self.A[0])
        d = depth

        # Beginning at the output end of the network...
        while d >= 0:
            d -= 1
            for i in range(N):
                # ... remove all CS elements not in output_set ...
                if self.A[d][i][1] not in output_set and i not in output_set:
                    self.A[d][i] = ("", i)
                else:
                    # ... and add ports connected to wires into output_set.
                    if self.A[d][i][0] in ("F", "R"):
                        output_set.add(self.A[d][i][1])
            # If the output set contains all ports we are done.
            if len(output_set) == N:
                break

        # Remove stages which only contain delay elements.
        self.A = [
            stage for stage in self.A if any([pair[0] in ("F", "R") for pair in stage])
        ]

        return self.A

    def generate(self, cs, template, N, W=8, SW=1, num_outputs=0, shape=""):
        """Takes kwargs and returns template object with generated network."""

        # Default shape of network is max.
        if not shape.lower() in (
            "max",
            "min",
            "median",
        ):
            shape = "max"
        shape = shape.lower()

        # Begin building connection matrix from parameters.
        self.A = self.create_connection_matrix(N)
        self.A = self.reduce_connection_matrix(N)
        # Using shape and number of output elements, build output_set.
        if shape == "median":
            if num_outputs == 0:
                # If N is even, we want the two center outputs
                num_outputs = 1 + (N + 1) % 2
            output_set = set(range((N - num_outputs) // 2, (N + num_outputs) // 2))
        elif shape == "min":
            if not num_outputs:
                num_outputs = N
            output_set = set(range(N - num_outputs, N))
        else:
            shape = "max"
            # Default number of outputs is N
            if not num_outputs:
                num_outputs = N
            output_set = output_set = set(range(0, num_outputs))

        # With output_set, prune unneeded CS and outputs. Might also reduce
        # depth of network.
        #
        self.A = self.prune_connection_matrix(output_set.copy())
        depth = len(self.A)

        self.log_dict["network"] = self.name
        self.log_dict["num_inputs"] = N
        self.log_dict["shape"] = shape
        self.log_dict["num_outputs"] = num_outputs
        self.log_dict["depth"] = depth

        # Begin building content for placeholder tokens of template.
        top_name = "{}_{}_TO_{}_{}".format(
            self.name.upper(), N, num_outputs, shape.upper()
        )
        bit_width = W
        subword_width = SW

        # components = kwargs["input"].as_component() + "\n"
        # components += kwargs["output"].as_component() + "\n"
        # components += kwargs["cs"].as_component() + "\n"

        generics = {"W": bit_width, "SW": subword_width}
        ports = {"CLK": "CLK", "E": "E", "RST": "RST"}

        self.log_dict["CS"] = 0
        distance_hist = [0 for i in range(0, N)]
        instances = ""
        # Create instances of CS elements forming the network.
        for i in range(depth):
            for j in range(N):
                if self.A[i][j][1] > j:
                    self.log_dict["CS"] += 1
                    a = j
                    b = self.A[i][j][1]
                    specific = dict()
                    specific["A0"] = "wire({})({})".format(a, i)
                    specific["B0"] = "wire({})({})".format(b, i)
                    if self.A[i][j][0] == "F":
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
                    distance_hist[b - a] += 1

        # Remove trailing zero buckets from histogram.
        i = depth
        while i > 1:
            i -= 1
            if distance_hist[i]:
                break
        self.log_dict["distance_hist"] = distance_hist[: i + 1]

        # Fill bypasses with delay elements.

        FF_hist = [0 for i in range(0, depth)]

        bypasses = ""
        for i in range(depth):
            for j in range(N):
                if self.A[i][j][0] == "+":
                    bypass_beg = i
                    bypass_end = i
                    while bypass_end < depth and self.A[bypass_end][j][0] == "+":
                        self.A[bypass_end][j] = ("", j)
                        bypass_end += 1

                    FF_hist[bypass_end - bypass_beg] += 1

                    bypasses += "wire({row})({beg} + 1 to {end}) <= wire({row})({beg} to {end}-1);\n".format(
                        row=j, end=bypass_end, beg=bypass_beg
                    )

        # Remove trailing zero buckets from histogram.
        i = depth
        while i > 1:
            i -= 1
            if FF_hist[i]:
                break
        self.log_dict["FF_hist"] = FF_hist[: i + 1]

        # Enclose bypassed wires in synchronous process.
        if bypasses:
            instances += "Delay : process(CLK) is \nbegin\nif (rising_edge(CLK)) then\n{}end if;\nend process;\n".format(
                bypasses
            )

        # Add connections to serial input.
        for i in range(N):
            connection = "wire({0})(0) <= SER_INPUT({0});\n".format(i)
            instances = connection + instances
            # specific = dict()
            # specific["PAR_INPUT"] = "input({})".format(i)
            # specific["SER_OUTPUT"] = "wire({})(0)".format(i)
            # specific["LOAD"] = "START(START'low)"

            # instances += inputs.as_instance(
            #     "input_{}".format(i), generics, ports | specific
            # )

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
            # specific = dict()
            # specific["PAR_OUTPUT"] = "output({})".format(i)
            # specific["SER_INPUT"] = "wire({})({})".format(output_list[i], depth)
            # specific["STORE"] = "START(START'high)"
            # instances += outputs.as_instance(
            #     "output_{}".format(i), generics, ports | specific
            # )

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


class OddEven(Generator):
    def __init__(self):
        super().__init__()
        self.name = "ODDEVEN"
        self.keywords = {
            # "input": "Name of input component",
            # "output": "Name of output component",
            "CS": "Name of compare swap element",
            "template": "Name of template",
            "N": "Number of inputs.",
        }

    def create_connection_matrix(self, N):
        # Adaption of algorithm described at
        # https://en.wikipedia.org/wiki/Batcher_odd%E2%80%93even_mergesort
        logp = int(math.ceil((math.log2(N))))
        depth = logp * (logp + 1) // 2
        self.A = [[("+", j) for j in range(N)] for i in range(depth)]
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
                            self.A[d][i + j] = ("F", i + j + k)
                            self.A[d][i + j + k] = ("F", i + j)
        return self.A


class Bitonic(Generator):
    def __init__(self):
        super().__init__()
        self.name = "BITONIC"
        self.keywords = {
            # "input": "Name of input component",
            # "output": "Name of output component",
            "CS": "Name of compare swap element",
            "template": "Name of template",
            "N": "Number of inputs.",
        }

    def max_pow2_less_N(self, N):
        k = 1
        while k > 0 and k < N:
            k = k << 1
        return k >> 1

    def bitonicSort(self, low_bound, N, depth, asc=True):
        if N > 1:
            # print("BSort:", low_bound, N, depth)
            middle = N // 2
            # print(low_bound, middle, N - middle, depth)
            d1 = self.bitonicSort(low_bound, middle, depth, not asc)
            d2 = self.bitonicSort(low_bound + middle, N - middle, depth, asc)
            return self.bitonicMerge(low_bound, N, max(d1, d2), asc)
        else:
            return 0

    def bitonicMerge(self, low_bound, N, depth, asc=True):
        if N > 1:
            # middle = math.floor(math.log2(N))
            middle = self.max_pow2_less_N(N)
            # print("BMerge:", low_bound, N, depth)
            for i in range(low_bound, low_bound + N - middle):
                if asc:
                    self.A[depth][i] = ("F", i + middle)
                    self.A[depth][i + middle] = ("F", i)
                else:
                    self.A[depth][i] = ("R", i + middle)
                    self.A[depth][i + middle] = ("R", i)
            # print(
            #     "\tCalling BMerge({},{},{},{})".format(
            #         low_bound, middle, depth + 1, asc
            #     )
            # )
            d1 = self.bitonicMerge(low_bound, middle, depth + 1, asc)
            # print(
            #     "\tCalling BMerge({},{},{},{})".format(
            #         low_bound + middle, N - middle, depth + 1, asc
            #     )
            # )
            d2 = self.bitonicMerge(low_bound + middle, N - middle, depth + 1, asc)

            return max(d1, d2)
        else:
            return depth

    def reduce_connection_matrix(self, N):
        return self.A

    def create_connection_matrix(self, N):
        # Adaption of algorithm described at
        # https://courses.cs.duke.edu//fall08/cps196.1/Pthreads/bitonic.c
        logp = int(math.ceil((math.log2(N))))
        depth = logp * (logp + 1) // 2
        self.A = [[("+", j) for j in range(N)] for i in range(depth)]

        self.bitonicSort(0, N, 0)

        # d = -1  # Current network depth index
        # #
        # for k_e in range(0, logp + 1):
        #     k = 2**k_e
        #     for j_e in range(k_e - 1, -1, -1):
        #         j = 2**j_e
        #         d += 1
        #         for i in range(2**logp):
        #             x = i ^ j
        #             if x > i:
        #                 if i & k:
        #                     self.A[d][i] = ("R", x)
        #                     self.A[d][x] = ("R", i)
        #                 else:
        #                     self.A[d][i] = ("F", x)
        #                     self.A[d][x] = ("F", i)
        return self.A


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    # gen = OddEven()
    # self.A = gen.create_connection_matrix(8)
    # for layer in self.A:
    #     print(layer)
    gen = Bitonic()
    print()
    gen.create_connection_matrix(8)
    for layer in gen.A:
        print(layer)
    print(gen.log_dict)
    # self.A = gen.reduce_connection_matrix(self.A, 10)
    # for layer in self.A:
    #     print(layer)
    # print()
    # output_set = set()
    # output_set.add(0)
    # output_set.add(1)
    # output_set.add(2)
    # print(output_set)
    # self.A = gen.prune_connection_matrix(self.A, output_set.copy())
    # output_list = list(output_set)
    # output_list.sort()
    # print(output_list)
    # for layer in self.A:
    #     print(layer)
    # print()
