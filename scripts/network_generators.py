#!/usr/bin/env python3
import math
from datetime import datetime


class Network:
    def __init__(self, N=0, depth=0):
        # Name of the network type
        self.typename = ""
        # Name of the network shape. may be left empty.
        self.shape = ""
        # Set of outputs containing valid items
        self.output_set = set()
        # Connection matrix of the network.
        self.cn = list()
        if N > 0 and depth > 0:
            self.setup(N, depth)

    def setup(self, N, depth):
        self.cn = [[("+", j) for j in range(N)] for i in range(depth)]
        self.output_set = set(range(0, self.get_N()))

    def get_N(self):
        if not self.cn:
            return 0
        else:
            return len(self.cn[0])

    def at(self, pair):
        x, y = pair
        return self.cn[x][y]

    def get_depth(self):
        return len(self.cn)

    def get_output_set(self):
        return self.output_set

    def __getitem__(self, key):
        return self.cn.__getitem__(key)

    def __setitem__(self, key, value):
        return self.cn.__setitem__(key, value)

    def __str__(self):
        a = "{0}: {1}\n".format(self.typename, self.get_N())
        for layer in self.cn:
            a += str(layer)
            a += "\n"
        a += str(self.get_output_set())
        return a


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

    def create(self, N):
        return Network()

    def reduce(self, network, N):
        """Reduces size connection matrix to N inputs."""
        # Nothing to do of target and actual size are the same.
        if N == network.get_N():
            return network
        for d in range(network.get_depth()):
            for i in range(N):
                # Look for CS elements whose inputs are outside of the target
                # size. Replace them with bypass elements.
                if network[d][i][1] >= N:
                    network[d][i] = ("+", i)
            # Resize stage to target size.
            network[d] = network[d][:N]
        return network

    def prune(self, network, output_set=set()):
        """Prunes CS elements not belonging to outputs in output_set.
        Starting at the end of the network, all CS not relevant for sorting
        elements of the output are pruned. Each stage of the network, wires
        connected to the outputs through CS elements are added to the set to
        ensure correctness.
        """
        N = network.get_N()
        d = network.get_depth()

        output_set = set(output_set)
        network.output_set = output_set.copy()
        # Beginning at the output end of the network...
        while d >= 0:
            d -= 1
            for i in range(N):
                # ... remove all CS elements not in output_set ...
                if network[d][i][1] not in output_set and i not in output_set:
                    network[d][i] = ("", i)
                else:
                    # ... and add ports connected to wires into output_set.
                    if network[d][i][0] in ("F", "R"):
                        output_set.add(network[d][i][1])
            # If the output set contains all ports we are done.
            if len(output_set) == N:
                break

        # Remove stages which only contain delay elements.
        network.cn = [
            stage
            for stage in network.cn
            if any([pair[0] in ("F", "R") for pair in stage])
        ]

        return network


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

    def create(self, N):
        # Adaption of algorithm described at
        # https://en.wikipedia.org/wiki/Batcher_odd%E2%80%93even_mergesort

        logp = int(math.ceil((math.log2(N))))
        depth = logp * (logp + 1) // 2
        network = Network(N, depth)
        network.typename = self.name
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
                            network[d][i + j] = ("F", i + j + k)
                            network[d][i + j + k] = ("F", i + j)
        return network


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

    def bitonicSort(self, network, low_bound, N, depth, asc=True):
        if N > 1:
            # print("BSort:", low_bound, N, depth)
            middle = N // 2
            # print(low_bound, middle, N - middle, depth)
            d1 = self.bitonicSort(network, low_bound, middle, depth, not asc)
            d2 = self.bitonicSort(network, low_bound + middle, N - middle, depth, asc)
            return self.bitonicMerge(network, low_bound, N, max(d1, d2), asc)
        else:
            return 0

    def bitonicMerge(self, network, low_bound, N, depth, asc=True):
        if N > 1:
            # middle = math.floor(math.log2(N))
            middle = self.max_pow2_less_N(N)
            # print("BMerge:", low_bound, N, depth)
            for i in range(low_bound, low_bound + N - middle):
                if asc:
                    network[depth][i] = ("F", i + middle)
                    network[depth][i + middle] = ("F", i)
                else:
                    network[depth][i] = ("R", i + middle)
                    network[depth][i + middle] = ("R", i)
            # print(
            #     "\tCalling BMerge({},{},{},{})".format(
            #         low_bound, middle, depth + 1, asc
            #     )
            # )
            d1 = self.bitonicMerge(network, low_bound, middle, depth + 1, asc)
            # print(
            #     "\tCalling BMerge({},{},{},{})".format(
            #         low_bound + middle, N - middle, depth + 1, asc
            #     )
            # )
            d2 = self.bitonicMerge(
                network, low_bound + middle, N - middle, depth + 1, asc
            )

            return max(d1, d2)
        else:
            return depth

    def reduce(self, network, N):
        return network

    def create(self, N):
        # Adaption of algorithm described at
        # https://courses.cs.duke.edu//fall08/cps196.1/Pthreads/bitonic.c
        logp = int(math.ceil((math.log2(N))))
        depth = logp * (logp + 1) // 2
        network = Network(N, depth)
        network.typename = self.name
        self.bitonicSort(network, 0, N, 0)

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
        #                     network[d][i] = ("R", x)
        #                     network[d][x] = ("R", i)
        #                 else:
        #                     network[d][i] = ("F", x)
        #                     network[d][x] = ("F", i)
        return network


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    gen = OddEven()
    nw = gen.create(16)
    for stage in nw:
        print([flag for flag, perm in stage])
