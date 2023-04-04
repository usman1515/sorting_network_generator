#!/usr/bin/env python3
import math
import numpy as np
from datetime import datetime


def isInOrder(index: int, perm: int):
    """Helper function to check whether permutation at index is actually in order."""
    return index == abs(perm)


class Network:
    def __init__(self, N: int = 0, depth: int = 0):
        # Name of the network type
        self.typename = ""
        # Name of the network shape. may be left empty.
        self.shape = ""
        # Set of outputs containing valid items
        self.output_set = set()
        # "Permutation matrix" describing the network
        # In actuality each row of the matrix is the one-line notation
        # of the conditional permutation performed. Sign of the number indicates
        # direction of the sorting condition , i.e. if CS checks inputs a < b then
        # inverse direction checks a > b.
        self.pmatrix = np.ones((1, 1), dtype=np.int64)
        # Layers containing FFs. Purpose/usage is derived from the layer_names list.
        # Contains 2D np arrays
        self.ff_layers = np.zeros((1, 1), dtype=np.bool_)
        # Signal name associated with each layer
        self.layer_names = list()
        # Number of rows per signal \approx fanout
        self.rows_per_signal = list()
        self.setup(N, depth)

    def setup(self, N: int, depth: int):
        self.pmatrix = np.empty([depth, N], dtype=np.int64)
        ident_perm = np.arange(0, N)
        for d in range(depth):
            self.pmatrix[d] = ident_perm.copy()
        self.output_set = set(range(0, N))
        # Add the first layer containing delay FF
        self.ff_layers = np.ones([1, depth, N], dtype=np.bool_)
        self.layer_names.append("Delay")
        # Add information regarding the required number signal replication.
        # As the FF are not replicated control signals, add one to indicate
        # zero effect on signal replication.
        self.rows_per_signal.append(1)

    def add_layer(self, layer_name: str):
        """Add an additional ff layer with specified purpose/usage through the layer name."""
        N = self.get_N()
        depth = self.get_depth()
        self.layer_names.append(layer_name)
        self.ff_layers = np.pad(
            self.ff_layers, ((0, 1), (0, 0), (0, 0)), "constant", constant_values=True
        )

    def get_N(self) -> int:
        return np.shape(self.pmatrix)[1]

    def get_depth(self) -> int:
        return np.shape(self.pmatrix)[0]

    def at(self, point: (int, int)):
        x, y = point
        return self.pmatrix[y][x]

    def num_ff_at(self, point: (int, int)):
        x, y = point
        count = 0
        for layer in self.ff_layers:
            if layer[y][x]:
                count += 1
        return count

    def get_output_set(self):
        return self.output_set

    def __getitem__(self, key):
        return self.pmatrix.__getitem__(key)

    def __setitem__(self, key, value):
        return self.pmatrix.__setitem__(key, value)

    def __str__(self):
        a = "{0}: {1}\n".format(self.typename, self.get_N())
        for stage in self.pmatrix:
            a += str(stage)
            a += "\n"
        a += str(self.get_output_set())
        a += "\n"

        for i in range(len(self.ff_layers)):
            a += "{}. Control Layer for Signal '{}'\n".format(
                i + 1, self.layer_names[i]
            )
            for stage in self.ff_layers[i]:
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
        return ""

    def create(self, N):
        return Network()

    def distribute_signals(self, network, sigdict=dict()):
        for name, max_fanout in sigdict.items():
            network.add_layer(name)
            network.rows_per_signal.append(max_fanout)
            # We need to calculate the incurred delay by the
            # signal distributor
            num_sig = math.ceil(network.get_N() / max_fanout)
            if not num_sig:
                num_sig = 1
            dist_depth = math.ceil(math.log(num_sig, max_fanout))
            # We also need to know the number of stages already present
            # in the network.
            data_delay = 0
            for y in range(network.get_depth()):
                # A stage is a delay stage if all entries are FF
                if all(network.ff_layers[0][y]):
                    data_delay += 1
                else:
                    # We only count stages from the beginning. If a
                    # stage with CS is present, all subsequent stages
                    # do not count toward data_delay.
                    break
            for y in range(network.get_depth()):
                for x in range(network.get_N()):
                    if (x + (max_fanout + 1) // 2) % max_fanout != 0:
                        network.ff_layers[-1][y][x] = False
                # Deal with remainder
                if network.get_N() % max_fanout:
                    network.ff_layers[-1][y][-1] = True
            # If not enough delay stages are present, extend all layers
            # with delay stages to the required amount.
            # if data_delay < dist_depth:
            #     diff = dist_depth - data_delay
            #     for j, layer in enumerate(network.ff_layers):
            #         network.ff_layers[j] = np.pad(
            #             network.ff_layers[j],
            #             ((diff, 0)),
            #             "constant",
            #             constant_values=True,
            #         )
        return network

    def reduce(self, network, N):
        """Reduces size connection matrix to N inputs."""
        # Nothing to do of target and actual size are the same.

        old_N = network.get_N()
        if N == network.get_N():
            return network
        for d in range(network.get_depth()):
            for i in range(N):
                # Look for CS elements whose inputs are outside of the target
                # size. Replace them with bypass elements.
                if network.pmatrix[d][i] >= N:
                    network.pmatrix[d][i] = i
        # Resize network to target size.
        network.pmatrix = np.delete(network.pmatrix, range(N, network.get_N()), 1)
        network.output_set = set(
            [
                i
                for i, perm in enumerate(network[network.get_depth() - 1])
                if not isInOrder(i, perm)
            ]
        )
        num_layers = network.ff_layers.shape[0]
        network.ff_layers = np.resize(network.ff_layers, (num_layers,network.get_depth(), N))
        # for i in range(len(network.ff_layers)):
        #     network.ff_layers[i] = np.delete(network.ff_layers[i], range(N, old_N), 1)
        return network

    def prune(self, network, new_output_set: set = set()):
        """Prunes CS elements not belonging to outputs in output_set.
        Starting at the end of the network, all CS not relevant for sorting
        elements of the output are pruned. Each stage of the network, wires
        connected to the outputs through CS elements are added to the set to
        ensure correctness.
        """
        N = network.get_N()
        d = network.get_depth()

        network.output_set = new_output_set.copy()
        # Beginning at the output end of the network...
        while d >= 0:
            d -= 1
            for i in range(N):
                # ... remove all CS elements not in output_set ...
                if i in new_output_set:
                    if not isInOrder(i, network[d][i]):
                        new_output_set.add(network[d][i])
                    else:
                        network[d][i] = i
                        network.ff_layers[0][d][i] = False
                elif network[d][i] in new_output_set:
                    new_output_set.add(i)
                else:
                    network[d][i] = i
                    network.ff_layers[0][d][i] = False
            # If the output set contains all ports we are done.
            if len(new_output_set) == N:
                break

        # Remove stages which only contain delay elements.
        network.pmatrix = [
            stage
            for stage in network.pmatrix
            if any([not isInOrder(i, perm) for i, perm in enumerate(stage)])
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
                            network[d][i + j] = i + j + k
                            network[d][i + j + k] = i + j
                            network.ff_layers[0][d][i + j] = False
                            network.ff_layers[0][d][i + j + k] = False
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
                    network[depth][i] = i + middle
                    network[depth][i + middle] = i
                else:
                    network[depth][i] = -1 * (i + middle)
                    network[depth][i + middle] = -1 * i
                network.ff_layers[0][depth][i] = False
                network.ff_layers[0][depth][i + middle] = False
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
        print(stage)
    for i, layer in enumerate(nw.ff_layers):
        print("\n Layer:", nw.layer_names[i])
        for stage in layer:
            print(["+" if i else " " for i in stage])

    nw = gen.distribute_signals(nw, {"START": 5})

    for stage in nw:
        print(stage)
    for i, layer in enumerate(nw.ff_layers):
        print("\n Layer:", nw.layer_names[i])
        for stage in layer:
            print(["+" if i else " " for i in stage])

    # start_x = 0
    # start_y = 0
    # end_x = nw.get_N()
    # end_y = nw.get_depth()
    # gen.distribute_signals(nw, {"START": 3})

    # print("-----")
    # for stage in nw:
    #     print([flag for flag, perm in stage])

    # for i, layer in enumerate(nw.ff_layers):
    #     print("\n Layer:", i)
    #     for stage in layer:
    #         print([flag for flag, perm in stage])
