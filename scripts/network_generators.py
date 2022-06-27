#!/usr/bin/env python3
import math
import numpy as np
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
        self.con_net = None
        self.setup(N, depth)
        # Layers of control signals
        self.control_layers = list()
        # Signal name associated with each layer
        self.signame = list()
        # Number of rows per signal \approx fanout
        self.rows_per_signal = list()

    def setup(self, N, depth):
        self.con_net = np.empty([depth, N], dtype=object)
        for i in range(N * depth):
            self.con_net.flat[i] = ("+", i % N)
        self.output_set = set(range(0, N))

    def add_layer(self, signal_name):
        self.signame.append(signal_name)
        N = self.get_N()
        depth = self.get_depth()
        self.control_layers.append(np.empty([depth, N], dtype=object))
        for i in range(N * depth):
            self.control_layers[-1].flat[i] = ("+", 0)

    def get_N(self):
        return np.shape(self.con_net)[1]

    def get_depth(self):
        return np.shape(self.con_net)[0]

    def at(self, point):
        x, y = point
        return self.con_net[y][x]

    def num_ff_at(self, point):
        x, y = point
        count = 0
        if self.con_net[y][x][0] == "+":
            count += 1
        for layer in self.control_layers:
            if layer[y][x] == "+":
                count += 1
        return count

    def get_output_set(self):
        return self.output_set

    def __getitem__(self, key):
        return self.con_net.__getitem__(key)

    def __setitem__(self, key, value):
        return self.con_net.__setitem__(key, value)

    def __str__(self):
        a = "{0}: {1}\n".format(self.typename, self.get_N())
        for stage in self.con_net:
            a += str(stage)
            a += "\n"
        a += str(self.get_output_set())
        a += "\n"

        for i in range(len(self.control_layers)):
            a += "{}. Control Layer for Signal '{}'\n".format(i + 1, self.signame[i])
            for stage in self.control_layers[i]:
                a += str(stage)
                a += "\n"
            a += "\n"

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

    def distribute_signals(self, network, sigdict=dict()):
        for name, max_fanout in sigdict.items():
            if network.get_N() < max_fanout:
                break
            network.add_layer(name)
            network.rows_per_signal.append(max_fanout)
            # We need to calculate the incurred delay by the
            # signal distributor
            num_sig = math.ceil(network.get_N() / max_fanout)
            print(num_sig)
            if not num_sig:
                num_sig = 1
            dist_depth = math.ceil(math.log(num_sig, max_fanout))
            # We also need to know the number of stages already present
            # in the network.
            data_delay = 0
            for y in range(network.get_depth()):

                # A stage is a delay stage if all pairs are FF
                if all([pair[0] == "+" for pair in network[y]]):
                    data_delay += 1
                else:
                    # We only count stages from the beginning. If a
                    # stage with CS is present, all subsequent stages
                    # do not count toward data_delay.
                    break
            for y in range(network.get_depth()):

                for x in range(network.get_N()):
                    if (x) % max_fanout == 0:
                        network.control_layers[-1][y][x] = ("+", 0)
                    else:
                        network.control_layers[-1][y][x] = (" ", 0)
            # If not enough delay stages are present, extend all layers
            # with delay stages to the required amount.
            if data_delay < dist_depth:
                diff = dist_depth - data_delay
                network.con_net = np.pad(
                    network.con_net,
                    ((diff, 0), (0, 0)),
                    "edge",
                )
                for i in range(diff * network.get_N()):
                    network.con_net.flat[i] = ("+", i % network.get_N())

                for i, layer in enumerate(network.control_layers):
                    network.control_layers[i] = np.pad(
                        layer, ((diff, 0), (0, 0)), "edge"
                    )
                    for j in range(diff * network.get_N()):
                        network.control_layers[i].flat[j] = ("", j % network.get_N())
        return network

    def reduce(self, network, N):
        """Reduces size connection matrix to N inputs."""
        # Nothing to do of target and actual size are the same.

        if N == network.get_N():
            return network
        for d in range(network.get_depth()):
            for i in range(N):
                # Look for CS elements whose inputs are outside of the target
                # size. Replace them with bypass elements.
                if network.con_net[d][i][1] >= N:
                    network.con_net[d][i] = ("+", 0)
        # Resize network to target size.
        network.con_net = np.delete(network.con_net, range(N, network.get_N()), 1)
        network.output_set = set(
            [i for i, pair in enumerate(network[network.get_depth() - 1]) if pair[0]]
        )
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
        network.con_net = [
            stage
            for stage in network.con_net
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
    nw = gen.create(64)
    for stage in nw:
        print([flag for flag, perm in stage])
    for i, layer in enumerate(nw.control_layers):
        print("\n Layer:", i)
        for stage in layer:
            print([flag for flag, perm in stage])

    start_x = 0
    start_y = 0
    end_x = nw.get_N()
    end_y = nw.get_depth()
    gen.distribute_signals(nw, {"START": 3})

    print("-----")
    for stage in nw:
        print([flag for flag, perm in stage])
    for i, layer in enumerate(nw.control_layers):
        print("\n Layer:", i)
        for stage in layer:
            print([flag for flag, perm in stage])
