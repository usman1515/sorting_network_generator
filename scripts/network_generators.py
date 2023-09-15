#!/usr/bin/env python3
import math
import numpy as np
from dataclasses import dataclass
from datetime import datetime
from enum import Enum


def is_in_order(index: int, perm: int):
    """Helper function to check whether permutation at index is actually in order."""
    return index == abs(perm)


class DistributionType(Enum):
    GLOBAL = 1
    ONE_TO_ONE = 2
    PER_STAGE = 3
    PER_LINE = 4
    PER_AREA = 5
    UNCONNECTED = 6
    STAGEWISE_FLAT = 7


@dataclass
class NetworkSignal:
    name: str
    layer_index: int = -1
    distribution: DistributionType = DistributionType.GLOBAL
    bit_width: int = 1
    is_replicated: bool = False
    num_replications: int = 0
    max_fanout: int = 1


class Network:
    def __init__(self, N: int = 0, depth: int = 0, SW: int = 1):
        # Name of the underlying algorithm
        self.algorithm = ""
        # Name of the output configuration. Namely min, max, or median.
        self.output_config = "full"
        # Set of output indices produced by the network.
        self.output_set: set[int] = set()
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
        self.signals: dict[str, NetworkSignal] = {}
        self.setup(N, depth, SW)

    def setup(self, N: int, depth: int, SW: int = 1):
        self.pmatrix = np.empty([depth, N], dtype=np.int64)
        ident_perm = np.arange(0, N)
        for d in range(depth):
            self.pmatrix[d] = ident_perm.copy()
        self.output_set = set(range(0, N))
        # Add the first layer containing delay FF
        self.ff_layers = np.ones([1, depth, N], dtype=np.bool_)
        self.signals["STREAM"] = NetworkSignal(
            name="STREAM",
            layer_index=0,
            distribution=DistributionType.ONE_TO_ONE,
            bit_width=SW,
        )
        index = self.add_layer("START")
        self.add_signal(
            signal_name="START",
            layer_index=index,
            distribution=DistributionType.PER_STAGE,
            is_replicated=True,
            num_replications=1,
            max_fanout=1,
        )
        for y in range(self.ff_layers[index].shape[0]):
            self.ff_layers[index, y, 0] = True
        index = self.add_layer("ENABLE")
        self.add_signal(
            signal_name="ENABLE",
            layer_index=index,
            distribution=DistributionType.PER_STAGE,
            is_replicated=True,
            num_replications=1,
            max_fanout=1,
        )
        for y in range(self.ff_layers[index].shape[0]):
            self.ff_layers[index, y, 0] = True

        self.add_signal(
            signal_name="CLK",
            layer_index=-1,
            distribution=DistributionType.GLOBAL,
            is_replicated=False,
            num_replications=0,
            max_fanout=0,
        )
        self.add_signal(
            signal_name="RST",
            layer_index=-1,
            distribution=DistributionType.GLOBAL,
            is_replicated=False,
            num_replications=0,
            max_fanout=0,
        )

    def add_signal(
        self,
        signal_name,
        layer_index: int = -1,
        distribution: DistributionType = DistributionType.GLOBAL,
        bit_width: int = 1,
        is_replicated: bool = False,
        num_replications: int = 0,
        max_fanout: int = 0,
    ):
        self.signals[signal_name] = NetworkSignal(
            name=signal_name,
            layer_index=layer_index,
            distribution=distribution,
            bit_width=bit_width,
            is_replicated=is_replicated,
            num_replications=num_replications,
            max_fanout=max_fanout,
        )

    def add_layer(self, layer_name: str) -> int:
        """Add an additional ff layer with specified purpose/usage through the layer name."""
        new_layer_index = self.ff_layers.shape[0]
        self.ff_layers = np.pad(
            self.ff_layers, ((0, 1), (0, 0), (0, 0)), "constant", constant_values=False
        )
        return new_layer_index

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
        a = "{0}: {1}\n".format(self.algorithm, self.get_N())
        for stage in self.pmatrix:
            a += str(stage)
            a += "\n"
        a += str(self.get_output_set())
        a += "\n"

        for i in range(self.ff_layers.shape[0]):
            layer = self.ff_layers[i]
            signal = None
            for s in self.signals.values():
                if i == s.layer_index:
                    signal = s
            if not signal:
                continue

            a += "{}. Control Layer for Signal '{}'\n".format(i + 1, signal.name)
            line = "_"  # "|"
            for i in range(layer.shape[1]):
                #  line += "{:<2}".format(i % 10)
                line += "__"  # .format(i % 10)
            line += "_"
            a += line + "\n"
            for i in range(layer.shape[0]):
                stage = layer[i]
                line = "|"
                for point in stage:
                    if point:
                        line += "+ "
                    else:
                        line += "  "
                line += "| {}".format(i)
                a += line + "\n"
            a += "\n"

        return a


class Generator:
    def __init__(self):
        self.name = ""
        self.keywords: dict[str:str] = {}
        self.optional = {
            "SW": "Width of operands",
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

    def distribute_signal(self, network: Network, signal_name: str, max_fanout: int):
        """Replicate and distribute signal in the network using FF according to
        max_fanout."""
        index = -1
        if signal_name in network.signals:
            index = network.signals[signal_name].layer_index
        else:
            network.add_signal(signal_name)

        if not index:
            index = network.add_layer(signal_name)
            network.signals[signal_name].layer_index = index

        # We need to calculate the incurred delay by the
        # signal distributor
        num_sig = math.ceil(network.get_N() / max_fanout)
        if not num_sig:
            num_sig = 1
        # dist_depth = math.ceil(math.log(num_sig, max_fanout))
        for y in range(network.get_depth()):
            for x in range(network.get_N()):
                if (x + (max_fanout + 1) // 2) % max_fanout != 0:
                    network.ff_layers[index][y][x] = False
                else:
                    network.ff_layers[index][y][x] = True
            # Deal with remainder
            if max_fanout * num_sig < network.get_N():
                network.ff_layers[index][y][-1] = True
        network.signals[signal_name].distribution = DistributionType.PER_STAGE
        network.signals[signal_name].is_replicated = True
        network.signals[signal_name].num_replications = num_sig
        network.signals[signal_name].max_fanout = max_fanout

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
        """Reduces number of inputs of connection matrix to N."""
        # Nothing to do of target and actual size are the same.

        if N == network.get_N():
            return network
        for s in range(network.get_depth()):
            for i in range(N):
                # Look for CS elements whose inputs are outside of the target
                # size. Replace them with bypass elements.
                if network.pmatrix[s][i] >= N:
                    network.pmatrix[s][i] = i
        # Resize network to target size.
        diff = range(N, network.get_N())
        network.pmatrix = np.delete(network.pmatrix, diff, axis=1)
        network.output_set = set(
            [
                i
                for i, perm in enumerate(network[network.get_depth() - 1])
                if not is_in_order(i, perm)
            ]
        )
        num_layers = network.ff_layers.shape[0]
        network.ff_layers = np.delete(network.ff_layers, diff, axis=2)
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
                    if not is_in_order(i, network[d][i]):
                        new_output_set.add(network[d][i])
                    else:
                        network.pmatrix[d][i] = i
                        network.ff_layers[0][d][i] = False
                elif network[d][i] in new_output_set:
                    new_output_set.add(i)
                else:
                    network.pmatrix[d][i] = i
                    network.ff_layers[0][d][i] = False
            # If the output set contains all ports we are done.
            if len(new_output_set) == N:
                break

        # Remove stages which only contain delay elements.
        indices = []
        for i in range(0, network.pmatrix.shape[0]):
            stage = network.pmatrix[i]
            if all(is_in_order(j, p) for j, p in enumerate(stage)):
                indices.append(i)
        network.pmatrix = np.delete(network.pmatrix, indices, axis=0)
        network.ff_layers = np.delete(network.ff_layers, indices, axis=1)
        return network

    def make_stagewise(self, network: Network):
        """Change signal distribution of the ENABLE and START signal to STAGEWISE_FLAT."""
        network.signals["START"].distribution = DistributionType.STAGEWISE_FLAT
        network.signals["ENABLE"].distribution = DistributionType.STAGEWISE_FLAT
        return network

    def delete_stages(self, network: Network, stage_list: list[int]):
        """Delete stages with indices given by stage_list."""
        network.pmatrix = np.delete(network.pmatrix, stage_list, axis=0)
        network.ff_layers = np.delete(network.ff_layers, stage_list, axis=1)
        return network

    def limit_stages(self, network: Network, stage_list: list[int]):
        """Remove all but the indices given by stage_list."""
        stage_list = [i for i in range(network.get_depth()) if i not in stage_list]
        return self.delete_stages(network, stage_list)


class OddEven(Generator):
    def __init__(self):
        super().__init__()
        self.name = "ODDEVEN"
        self.keywords = {
            "N": "Number of inputs.",
        }

    def create(self, N):
        # Adaption of algorithm described at
        # https://en.wikipedia.org/wiki/Batcher_odd%E2%80%93even_mergesort

        logp = int(math.ceil((math.log2(N))))
        depth = logp * (logp + 1) // 2
        network = Network(N, depth)
        network.algorithm = self.name
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
        network.algorithm = self.name
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
    nw = gen.create(128)
    for stage in nw:
        print(stage)
    for i, layer in enumerate(nw.ff_layers):
        for stage in layer:
            print(["+" if i else " " for i in stage])

    nw = gen.distribute_signal(nw, "START", 50)
    print(nw.signals["START"])
    for stage in nw:
        print(stage)
    for i, layer in enumerate(nw.ff_layers):
        print("Layer Nr.:", i)
        for stage in layer:
            for point in stage:
                if point:
                    print("+", end="")
                else:
                    print(" ", end="")
            print()

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
