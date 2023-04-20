#!/usr/bin/env python3
import math
import numpy as np
from dataclasses import dataclass
from abc import ABC, abstractmethod

from scripts.network_generators import OddEven, Network
from scripts.vhdl import VHDLEntity


def is_ff(value):
    # if value[0] == "+":
    #     return True
    # return False
    return value


def is_inbounds(nw, point):
    x, y = point
    if 0 <= y and y < nw.get_depth():
        if 0 <= x and x < nw.get_N():
            return True
    return False


@dataclass
class FF_Assignment:
    point: tuple[int, int, int]
    ff_range: tuple[int, int]


@dataclass
class FF_Replacement:
    entity: VHDLEntity
    ff_per_entity: int
    groups: list[list[FF_Assignment]]


class Resource_Allocator(ABC):
    @abstractmethod
    def allocate_ff_groups(
        self, network: Network, max_ff_per_group: int, max_entities: int
    ) -> list[list[FF_Assignment]]:
        pass

    def reallocate_ff(self, network, entity, max_entities, ff_per_entity):
        ff_groups = self.allocate_ff_groups(network, ff_per_entity, max_entities)
        return FF_Replacement(entity, ff_per_entity, ff_groups)


# class Simple_Allocator(Resource_Allocator):
#     def allocate_row(self, network, start_point, num_ff):
#         ff = 0
#         ff_points = []

#         N = network.get_N()
#         depth = network.get_depth()
#         x, y = start_point
#         i = x + y * N
#         while i < N * depth:
#             x = i % N
#             y = i // N
#             if is_ff(network.at((x, y))):
#                 ff_points.append((x, y))
#                 ff += 1
#                 if ff >= num_ff:
#                     break
#             i += 1
#         return ff_points, np.asarray(((i + 1) % N, (i + 1) // N))

#     def allocate_ff_groups(self, network, max_ff_per_group, max_entities):
#         ff_groups = []
#         next_start = np.array(2, 0)
#         while is_inbounds(network, next_start):
#             ff_points, next_start = self.allocate_row(
#                 network, next_start, max_ff_per_group
#             )
#             ff_groups.append(ff_points)
#         return ff_groups


class Block_Allocator(Resource_Allocator):
    def __init__(self):
        self.ff_matrix = None
        self.groups: list[list[FF_Assignment]] = []

    def __add_ff_to_group(self, network, groups, grp_i, target_nff, x, y):
        for z in range(network.ff_layers.shape[0]):
            point = (x, y, z)
            ff_start = 0
            ff_end = 0
            while ff_end < network.ff_layers[z, y, x]:
                ff_at_point = 1
                if z == 0:
                    # First layer is the permutation layer of variable data
                    # width
                    ff_at_point = network.signals["DATA"].bit_width

                # Find the current number of FF assigned to the group.
                cur_group_ff = sum([ff_r[1] - ff_r[0] for p, ff_r in groups[grp_i]])
                # The new endpoint of the range is either the full amount of FF
                # at that point or at least all FF that still fit into the group.
                # Since we need the old value of ff_end, make a copy.
                ff_end_prev = ff_end
                ff_end = min(ff_at_point, target_nff[grp_i] - cur_group_ff)
                groups[grp_i].append((point, (ff_start, ff_end)))
                ff_start = ff_end_prev
                if cur_group_ff + ff_end >= target_nff[grp_i]:
                    # if the group is full increment grp_i.
                    grp_i += 1
        return grp_i

    def distribute_to_groups(self, network, rect, total_ff, max_ff_per_group):
        """Takes network and rectangle and attempts to distribute ffs
        evenly into groups respecting some degree of locality.

        Parameters:
            network : Network
                Network object containing 3d matrix ff_layers.
            rect : tuple[tuple[int,int], tuple[int,int]]
                Rectangle within the network with ff within to
                be distributed
            total_ff : int
                Total number of FF to be distributed into groups.
            num_groups : int
                Number of groups to be created.
         Returns:
            groups : list[list[tuple[int,int,int]]]
                List of groups themself consisting of a list of coordinate tuples.
                Mirrored in the attribute groups.
        """
        start_x, start_y = rect[0]
        end_x, end_y = rect[1]
        num_groups = math.ceil(total_ff / max_ff_per_group)

        # Number of ff for each group
        target_nff = [total_ff // (num_groups) for i in range(num_groups)]
        groups = [[] for i in range(num_groups)]
        index = 0
        # Distribute remainder among groups
        for i in range(total_ff % num_groups):
            target_nff[i] += 1

        if end_y - start_y < end_x - start_x:
            for y in range(start_y, end_y):
                for x in range(start_x, end_x):
                    index = self.__add_ff_to_group(
                        network, groups, index, target_nff, x, y
                    )
        else:
            for x in range(start_x, end_x):
                for y in range(start_y, end_y):
                    index = self.__add_ff_to_group(
                        network, groups, index, target_nff, x, y
                    )
        self.groups += groups
        return self.groups

    def divide_block(self, network, rect, max_ff_per_group, max_entities):
        """Recursively divides the rectangle on the long edge depending on
        the number of FFs present.


        """
        # List of blocks to be divided and or distributed,
        # depdending on the number of FF.
        blocks = [
            rect,
        ]
        while blocks and len(self.groups) < max_entities:
            block = blocks.pop()
            # Unpack block into start and end coordinates
            start_x, start_y = block[0]
            end_x, end_y = block[1]
            total = np.sum(self.ff_matrix[start_y:end_y, start_x:end_x])
            if total < 3 * max_ff_per_group:
                # Distribute ff between groups evenly.
                self.distribute_to_groups(network, block, total, max_ff_per_group)
            elif total > 0:
                # Along the x and y, build sum of ffs then compute cumulative sum.
                ff_over_x = np.sum(self.ff_matrix[start_y:end_y, start_x:end_x], axis=0)
                ff_csum_x = np.cumsum(ff_over_x)
                ff_over_y = np.sum(self.ff_matrix[start_y:end_y, start_x:end_x], axis=1)
                ff_csum_y = np.cumsum(ff_over_y)

                # Find indices in x,y where the cumulative sum exceeds half the total
                split_x = 0
                while split_x < len(ff_csum_x) and ff_csum_x[split_x + 1] < total // 2:
                    split_x += 1
                split_y = 0
                while split_y < len(ff_csum_y) and ff_csum_y[split_y + 1] < total // 2:
                    split_y += 1

                # To assert which axis split is more even, check which split
                # produces blocks closer to half the total.
                # Difference from optimal in x axis.
                diff_opt_x = total // 2 - ff_csum_x[split_x]
                diff_opt_y = total // 2 - ff_csum_y[split_y]
                axis = 0
                if diff_opt_y < diff_opt_x:
                    axis = 1

                # Total number of blocks exceeds 3 times the maximum.
                # Recursively subdivide.
                if axis == 0:
                    blocks.append((block[0], (start_x + split_x, end_y)))
                    blocks.append(((start_x + split_x, start_y), block[1]))
                else:
                    blocks.append((block[0], (end_x, start_y + split_y)))
                    blocks.append(((start_x, start_y + split_y), block[1]))
                # print(self.ff_matrix[start_y:end_y, start_x:end_x])
                # print("Rectangle:", block, "with", total, "FF divided into")
                # print("Indices x,y:", split_x, split_y)
                # print("Axis:", axis)
                # print("Calling divide_block on:")
                # print("  Rect0:", blocks[-2])
                # print("  Rect1:", blocks[-1])

    def allocate_ff_groups(
        self, network: Network, num_ff_per_group: int, max_entities: int
    ) -> list[list[FF_Assignment]]:
        """Allocate FF present in the entire network (delay and replicated
        signals) to groups later replaced by other means.
        Parameters: network : Network object
                    num_ff_per_group : int
                        Number of a single group may contain
        Returns:   groups : list[list[tuple(int)]]
                        List of groups consisting of a list of array indices.
        """

        self.groups = []
        self.ff_matrix = np.sum(network.ff_layers[1:], axis=0, dtype=np.int32)
        self.ff_matrix += network.ff_layers[0] * network.signals["DATA"].bit_width

        # print(self.ff_matrix)
        N = network.get_N()
        depth = network.get_depth()

        self.divide_block(network, ((0, 0), (N, depth)), num_ff_per_group, max_entities)
        if len(self.groups) > max_entities:
            self.groups = self.groups[:max_entities]
        # print(self.groups)
        # self.allocate_control_ff(network)
        # print(self.sub_groups)
        return self.groups


def norm2square(point):
    return np.dot(point, point)


def get_distscore_rect(nw, rect):
    """Calculates the smallest bounding box of FF contained in given rectangle.
    Returns square of diagonal."""

    a, b = rect
    start_x, start_y = a
    end_x, end_y = b

    min_x = end_x + 1
    min_y = end_y + 1
    max_x = start_x
    max_y = start_y
    for y in range(start_y, end_y + 1):
        for x in range(start_x, end_x + 1):
            if is_inbounds(nw, (x, y)) and is_ff((x, y)):
                if x < min_x:
                    min_x = x
                if x > max_x:
                    max_x = x
                if y < min_y:
                    min_y = y
                if y > max_y:
                    max_y = y
    diff = np.asarray((max_x, max_y)) - np.asarray((min_x, min_y))
    return norm2square(diff)


def get_distscore_group(nw, group):
    """Calculates the smallest bounding box of FF in grouping.
    Returns square of diagonal."""

    max_x = 0
    max_y = 0
    min_x = nw.get_N()
    min_y = nw.get_depth()
    for point in group:
        x, y = point
        if x < min_x:
            min_x = x
        if x > max_x:
            max_x = x
        if y < min_y:
            min_y = y
        if y > max_y:
            max_y = y
    diff = np.asarray((max_x, max_y)) - np.asarray((min_x, min_y))
    return norm2square(diff)


def get_mean(group):
    mean = np.asarray((0, 0))
    if group:
        for x, y in group:
            mean[0] += x
            mean[1] += y
        mean[0] /= len(group)
        mean[1] /= len(group)
    return mean


def get_cost(group, point=None):
    if not point:
        point = get_mean(point)
    cost = 0
    for gpoint in group:
        cost += norm2square(gpoint - point)
    return cost


def print_layer(layer):
    line = "_"  # "|"
    for i in range(len(layer[0])):
        #  line += "{:<2}".format(i % 10)
        line += "__"  # .format(i % 10)
    line += "_"
    print(line)
    for i, stage in enumerate(layer):
        line = "|"
        for pair in stage:
            if is_ff(pair):
                line += "+ "
            else:
                line += "  "
        line += "| {}".format(i)
        print(line)


def print_layers_with_ffgroups(network, groups):
    for z, layer in enumerate(network.ff_layers):
        print("Layer {}: {}".format(z, network.layer_attr[z].signal_name))
        for y in range(len(layer)):
            line = "|"
            # Get the number of blanks required for the largest integer in
            # string representation
            len_blanks = len(str(len(groups)))
            for x in range(len(layer[y])):
                elem = " " + " " * len_blanks
                if layer[y][x]:
                    elem = "+" + " " * len_blanks
                for i, group in enumerate(groups):
                    if (x, y, z) in group:
                        elem = " {:" + str(len_blanks) + "}"
                        elem = elem.format(i)
                line += elem
            line += "|"
            print(line)
