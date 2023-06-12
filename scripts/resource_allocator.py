#!/usr/bin/env python3
from math import ceil
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
class FFAssignment:
    point: tuple[int, int, int]
    ff_range: tuple[int, int]


@dataclass
class FFReplacement:
    entity: VHDLEntity
    ff_per_entity: int
    groups: list[list[FFAssignment]]


class ResourceAllocator(ABC):
    @abstractmethod
    def allocate_ff_groups(
        self, network: Network, max_ff_per_group: int, max_entities: int
    ) -> list[list[FFAssignment]]:
        pass

    def reallocate_ff(self, network, entity, max_entities, ff_per_entity):
        ff_groups = self.allocate_ff_groups(network, ff_per_entity, max_entities)

        # for i, group in enumerate(ff_groups):
        # print("Group: " + str(i + 1))
        # for assign in group:
        # print(assign)
        # print_layers_with_ffgroups(network, ff_groups)
        return FFReplacement(entity, ff_per_entity, ff_groups)


# class Simple_Allocator(ResourceAllocator):
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


@dataclass
class Block:
    """Container for geometry info used in recursion algorithm of the BlockAllocator"""

    first_half: bool
    start: tuple[int, int]
    size: tuple[int, int]


class BlockAllocator(ResourceAllocator):
    def __init__(self):
        self.ff_matrix = None
        self.groups: list[list[FFAssignment]] = []

    def __print_block(self, dim_x, dim_y, block: Block):
        for y in range(dim_y):
            line = "|"
            for x in range(dim_x):
                elem = " "
                if x >= block.start[0] and x < block.start[0] + block.size[0]:
                    if y >= block.start[1] and y < block.start[1] + block.size[1]:
                        elem = "+"
                line += elem
            line += "|"
            print(line)

    def allocate_ff_groups(
        self, network: Network, num_ff_per_group: int, max_entities: int
    ) -> list[list[FFAssignment]]:
        """Allocate FF present in the entire network (delay and replicated
        signals) to groups later replaced by other means.
        Parameters: network : Network object
                    num_ff_per_group : int
                        Number of a single group may contain
        Returns:   groups : list[list[FFAssignment]]
                        List of groups themselves consisting of a list of FFAssignments.
        """

        self.groups = []
        # Create 2d matrix containing total number of FFs at a point.
        self.ff_matrix = np.sum(network.ff_layers[1:], axis=0, dtype=np.int32)
        # Stream layer is treated differently as bit_width has to be considered.
        self.ff_matrix += network.ff_layers[0] * network.signals["STREAM"].bit_width

        # print(self.ff_matrix)
        N = network.get_N()
        depth = network.get_depth()

        # Begin subdivision procedure.
        self.divide_block(
            network, Block(True, (0, 0), (N, depth)), num_ff_per_group, max_entities
        )
        if len(self.groups) > max_entities:
            self.groups = self.groups[:max_entities]
        # print(self.groups)
        # self.allocate_control_ff(network)
        # print(self.sub_groups)
        return self.groups

    def __get_second_half(self, parent: Block, child: Block) -> Block:
        # Figure out axis using coord of child and parent.
        # If x coords are the same, division axis was y and
        # vice versa.
        size_x, size_y = parent.size
        if parent.start[0] == child.start[0]:
            size_y -= child.size[1]
        else:
            size_x -= child.size[0]
        return Block(
            True,
            parent.start,
            (size_x, size_y),
        )

    def divide_block(
        self,
        network: Network,
        init_block: Block,
        max_ff_per_group: int,
        max_entities: int,
    ):
        """Recursively divides the rectangle given by init_block parameter
        on the long edge depending on which edge divides the number of FFs more
        evenly.
        """
        # Stack of blocks to process.
        blocks = [
            init_block,
        ]
        # print()
        while blocks and len(self.groups) < max_entities:
            # Unpack block into start and end coordinates
            start_x, start_y = blocks[-1].start
            size_x, size_y = blocks[-1].size
            # Total number of FF contained in the block.
            # TODO: Calculation is only required once.
            total = np.sum(
                self.ff_matrix[start_y : start_y + size_y, start_x : start_x + size_x]
            )
            # print(blocks[-1], "with", total, "FF is being processed:")
            # self.__print_block(init_block.size[0], init_block.size[1], blocks[-1])
            if not blocks[-1].first_half:
                # Reached parent block those first half has been proceessed, at which point
                # the blocks second half has been proccessed as well.
                # Remove from stack
                # print(" " * len(blocks), "\tParent block finished.")
                child = blocks.pop()
                if blocks:
                    parent = blocks[-1]
                    if blocks[-1].first_half:
                        blocks[-1].first_half = False
                        blocks.append(self.__get_second_half(parent, child))
            else:
                # Check whether current block is a leaf block, i.e. if its
                # total number of FFs is below a threshold.
                if total < 3 * max_ff_per_group:
                    # Block is a leaf as it is small enough to be processed
                    # into FFAssignment groups.
                    self.distribute_to_groups(
                        network, blocks[-1], total, max_ff_per_group
                    )
                    # print(
                    #     " " * len(blocks),
                    #     "\tTotal FF below threshold. Distributing to groups",
                    # )
                    child = blocks.pop()
                    if blocks:
                        parent = blocks[-1]
                        # If child was parents first half, calculate dim of second half
                        # and put on block stack.
                        # print(
                        #     " " * len(blocks),
                        #     "\tParent blocks first half has been processed",
                        # )
                        if parent.first_half:
                            blocks[-1].first_half = False
                            blocks.append(self.__get_second_half(parent, child))
                            # print(" " * len(blocks), "\tSecond Half is ", blocks[-1])

                elif total > 0:
                    half_sum_x = np.sum(
                        self.ff_matrix[
                            start_y : start_y + size_y, start_x : start_x + size_x // 2
                        ]
                    )
                    diff_x = abs(total // 2 - half_sum_x)
                    half_sum_y = np.sum(
                        self.ff_matrix[
                            start_y : start_y + size_y // 2,
                            start_x : start_x + size_x,
                        ]
                    )
                    diff_y = abs(total // 2 - half_sum_y)
                    if diff_x < diff_y:
                        start_x += ceil(size_x / 2)
                        size_x = size_x // 2
                    else:
                        start_y += ceil(size_y / 2)
                        size_y = size_y // 2

                    blocks.append(Block(True, (start_x, start_y), (size_x, size_y)))
                    # print(" " * len(blocks), "\tTotal FF exceeded threshold.")
                    # print(" " * len(blocks), "\tDivided along x-axis:", diff_x < diff_y)
                    # print(" " * len(blocks), "\tChild block is ", blocks[-1])

    def distribute_to_groups(self, network, block, total_ff, max_ff_per_group):
        """Takes network and rectangle and attempts to distribute ffs
        evenly into groups respecting some degree of locality.

        Parameters:
            network : Network
                Network object containing 3d matrix ff_layers.
            block : Block
                Block object containing geometry info.
            total_ff : int
                Total number of FF to be distributed into groups.
            max_ff_per_group : int
                Number of groups to be created.
         Returns:
            groups : list[list[FFAssignment]]]
                List of groups themself consisting of a list of coordinate tuples.
                Mirrored in the attribute groups.
        """
        start_x, start_y = block.start
        end_x, end_y = block.size
        end_x += start_x
        end_y += start_y
        if total_ff == 0:
            return self.groups
        num_groups = ceil(total_ff / max_ff_per_group)

        # Number of ff for each group
        target_ff = [total_ff // (num_groups) for i in range(num_groups)]
        groups = [[] for i in range(num_groups)]
        index = 0
        # Distribute remainder among groups
        for i in range(total_ff % num_groups):
            target_ff[i] += 1

        if end_y - start_y < end_x - start_x:
            for y in range(start_y, end_y):
                for x in range(start_x, end_x):
                    index = self.__add_ff_to_group(
                        network, groups, index, target_ff, x, y
                    )
        else:
            for x in range(start_x, end_x):
                for y in range(start_y, end_y):
                    index = self.__add_ff_to_group(
                        network, groups, index, target_ff, x, y
                    )
        self.groups += groups
        return self.groups

    def __add_ff_to_group(
        self,
        network: Network,
        groups: list[list[FFAssignment]],
        grp_i: int,
        target_ff: list[int],
        x: int,
        y: int,
    ):
        """Takes a point and adds FF to group indicated by group index until
        either the target number of FF is reached or no FF remain at that
        point.

        Parameters:
            network: Network
                Sorting Network on which to work on.
            groups: list[list[FFAssignment]]
                List of groups to operate on.
            grp_i: int
                Index of the group to operate on.
            target_ff: list[int]
                List of maximum numbers of FF per group. Each group index
                relates to the associated maximum number of FF in target_ff.
            x: int
                X coordinate in the network.
            y: int
                Y coordinate in the network.
        Returns:
            grp_i: int
                Group index of the next group to operate on. Increment happens
                when the maximum number of FFs of the current group has been
                reached but unassigned FFs at the point remain.
        """
        for z in range(network.ff_layers.shape[0]):
            point = (x, y, z)
            ff_start = 0
            ff_end = 0
            while ff_end < network.ff_layers[z, y, x]:
                ff_at_point = 1
                if z == 0:
                    # First layer is the permutation layer of variable data
                    # width
                    ff_at_point = network.signals["STREAM"].bit_width

                # Find the current number of FF assigned to the group.
                cur_group_ff = sum(
                    [a.ff_range[1] - a.ff_range[0] for a in groups[grp_i]]
                )
                # The new endpoint of the range is either the full amount of FF
                # at that point or at least all FF that still fit into the group.
                # Since we need the old value of ff_end, make a copy.
                ff_end_prev = ff_end
                ff_end = min(ff_at_point, target_ff[grp_i] - cur_group_ff)
                groups[grp_i].append(FFAssignment(point, (ff_start, ff_end)))
                ff_start = ff_end_prev
                if cur_group_ff + ff_end >= target_ff[grp_i]:
                    # if the group is full increment grp_i.
                    grp_i += 1
        return grp_i


def norm2square(point):
    return np.dot(point, point)


def get_distscore_rect(nw, block):
    """Calculates the smallest bounding box of FF contained in given rectangle.
    Returns square of diagonal."""

    a, b = block
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
        layer_name = ""
        for attrib in network.signals:
            if attrib.index == z:
                layer_name = attrib.name
                break

        print("Layer {}: {}".format(z, layer_name))
        for y in range(len(layer)):
            line = "|"
            # Get the number of blanks required for the largest integer in
            # string representation
            len_blanks = len(str(len(groups)))
            for x in range(len(layer[y])):
                elem = " " + " " * len_blanks
                if layer[y][x]:
                    elem = "+" + " " * len_blanks
                is_assigned = False
                for i, group in enumerate(groups):
                    for assign in group:
                        if (x, y, z) == assign.point:
                            if is_assigned:
                                elem = "#" + " " * len_blanks
                            else:
                                elem = " {:" + str(len_blanks) + "}"
                                elem = elem.format(i)
                            is_assigned = True
                line += elem
            line += "|"
            print(line)
