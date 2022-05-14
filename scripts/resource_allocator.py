#!/usr/bin/env python3
import math
import numpy as np
from network_generators import OddEven, Network


def is_ff(pair):
    if pair[0] == "+":
        return True
    return False


def in_bounds(nw, point):
    x, y = point
    if 0 <= y and y < nw.get_depth():
        if 0 <= x and x < nw.get_N():
            return True
    return False


class FF_Replacement:
    def __init__(self, entity, groups, ff_per_entity):
        self.entity = entity
        self.ff_per_entity = ff_per_entity
        self.groups = groups


class Resource_Allocator:
    def allocate_ff_groups(self, network, max_ff_per_group):
        pass

    def reallocate_ff(self, network, entity, max_entities, ff_per_entity):
        ff_groups = self.allocate_ff_groups(network, ff_per_entity)
        ff_groups = ff_groups[:max_entities]
        for group in ff_groups:
            for point in group:
                x, y = point
                network[y][x] = ("-", network[y][x][1])
        return FF_Replacement(entity, ff_groups, ff_per_entity)


class Simple_Allocator(Resource_Allocator):
    def allocate_row(self, network, start_point, num_ff):
        ff = 0
        ff_points = []

        N = network.get_N()
        depth = network.get_depth()
        x, y = start_point
        i = x + y * N
        while i < N * depth:
            x = i % N
            y = i // N
            if is_ff(network.at((x, y))):
                ff_points.append((x, y))
                ff += 1
                if ff >= num_ff:
                    break
            i += 1
        return ff_points, np.asarray(((i + 1) % N, (i + 1) // N))

    def allocate_ff_groups(self, network, max_ff_per_group):
        ff_groups = []
        next_start = np.array(2, 0)
        while in_bounds(network, next_start):
            ff_points, next_start = self.allocate_row(
                network, next_start, max_ff_per_group
            )
            ff_groups.append(ff_points)
        return ff_groups


class Block_Allocator(Resource_Allocator):
    def __init__(self):
        self.groups = []
        self.sub_groups = []

    def distribute_to_groups(self, network, rect, total_ff, num_groups):
        """Takes a rectangle and a division index and attempts to distribute ffs
        evenly between blocks respecting some degree of locality.
        """
        a, b = rect
        start_x, start_y = a
        end_x, end_y = b
        groups = [[] for i in range(num_groups)]

        # Number of ff for each group
        target_nff = [total_ff // (num_groups) for i in range(num_groups)]

        # Distribute remainder among groups
        target_rem = (total_ff) % num_groups
        for i in range(target_rem):
            target_nff[i] += 1

        if end_y - start_y < end_x - start_x:
            # X range is the long edge.

            # Iterate other all points in rectangle.
            for y in range(start_y, end_y):
                for x in range(start_x, end_x):
                    if is_ff(network.at((x, y))):
                        # If we have a FF ...
                        for i in range(len(groups)):
                            # ...and room in the group...
                            if len(groups[i]) < target_nff[i]:
                                # ...add ff to group.
                                groups[i].append(np.asarray((x, y)))
                                break

        else:
            # Y range is the long edge.

            # Iterate other all points in rectangle.
            for x in range(start_x, end_x):
                for y in range(start_y, end_y):
                    if is_ff(network.at((x, y))):
                        # If we have a FF ...
                        for i in range(len(groups)):
                            # ...and room in the group...
                            if len(groups[i]) < target_nff[i]:
                                # ...add ff to group.
                                groups[i].append(np.asarray((x, y)))
                                break

        self.groups += groups

    def divide_block(self, network, rect, max_ff_per_group):
        """Recursively divides the rectangle on the long edge depending on
        the number of FFs present.


        """
        a, b = rect
        start_x, start_y = a
        end_x, end_y = b
        # Orientation == True if we halve in the x range.
        orientation = end_y - start_y < end_x - start_x
        # Number of ffs either per column or row
        ff_per_cr = []

        if orientation:
            # Get number of ff per column
            ff_per_cr = [
                sum([network.num_ff_at((x, y)) for y in range(start_y, end_y)])
                for x in range(start_x, end_x)
            ]
        else:
            # Get number of ff per row
            ff_per_cr = [
                sum([network.num_ff_at((x, y)) for x in range(start_x, end_x)])
                for y in range(start_y, end_y)
            ]
        # Perform scan on list
        ff_per_cr = [sum(ff_per_cr[: i + 1]) for i in range(len(ff_per_cr))]
        # Find index at which halve the number of ffs are above and below.
        total = ff_per_cr[-1]

        index = 0
        for i in range(len(ff_per_cr)):
            if ff_per_cr[i] > total // 2:
                index = i
                break
        # We need to decide how and if further subdivision is required:
        if total > 3 * max_ff_per_group and 0 < norm2square(
            (end_x - start_x, end_y - start_y)
        ):
            # Total number of blocks exceeds 3 times the maximum.
            # Recursively subdivide.
            # print("Rectangle:", rect, "with", total, "FF divided into")
            rect0 = ((0, 0), (0, 0))
            rect1 = ((0, 0), (0, 0))
            if orientation:
                rect0 = (a, (start_x + index, end_y))
                rect1 = ((start_x + index, start_y), b)
            else:
                rect0 = (a, (end_x, start_y + index))
                rect1 = ((start_x, start_y + index), b)
            # print("From: ", rect)
            # print("Calling divide_block on:")
            # print("  Rect0:", rect0)
            # print("  Rect1:", rect1)
            self.divide_block(network, rect0, max_ff_per_group)
            self.divide_block(network, rect1, max_ff_per_group)
        else:
            # print("Distributing:", rect, "with", total, "FF")
            # Total number of ff are less than thrice the maximum number.
            # In this case, distribute ff between blocks evenly.
            if total:
                num_groups = math.ceil(total / max_ff_per_group)
                if num_groups == 0:
                    num_groups = 1
                self.distribute_to_groups(network, rect, total, num_groups)

    def allocate_ff_groups(self, network, num_ff_per_entity, group_sizes_layers=[]):
        self.groups = []
        N = network.get_N()
        depth = network.get_depth()
        num_ff_per_group = num_ff_per_entity - sum(group_sizes_layers)

        self.divide_block(network, ((0, 0), (N, depth)), num_ff_per_group)
        # print(self.groups)
        self.allocate_control_ff(network, group_sizes_layers)
        # print(self.sub_groups)
        return self.groups, self.sub_groups

    def allocate_control_ff(self, network, group_sizes_layers=[]):
        """Allocate ff of the control signals to already existing groups.

        For each layer of control FF and for each FF in a layer, select the
        nearest group (smallest distance to mean of existing FF coordinates)
        with less than the specified number of control FF per layer.
        """
        layers = network.control_layers
        for i, layer in enumerate(layers):
            max_ff = group_sizes_layers[i]
            self.__allocate_layer(i, layer, max_ff)
        return self.sub_groups

    def __allocate_layer(self, layer_index, layer, max_ff):
        """Performs allocation of control signal layer ff to either existing groups,
        or new groups if all existing groups have the maximum number of ffs."""

        # If the number of groups we need to distribute the ff in the control layer
        # exceeds the number of groups we already have, add empty groups.
        total_ff = sum([is_ff(layer.flat[i]) for i in range(np.prod(np.shape(layer)))])
        num_group_diff = math.ceil(total_ff / max_ff) - len(self.groups)

        non_empty_len = len(self.groups)
        if num_group_diff > 0:
            for i in range(num_group_diff):
                self.groups.append([])

        # Add new sub_group should we process a new layer.
        if len(self.sub_groups) < layer_index + 1:
            self.sub_groups.append([[] for i in range(len(self.groups))])
        sub_groups = self.sub_groups[layer_index]

        for y, stage in enumerate(layer):
            for x, pair in enumerate(stage):
                if is_ff(pair):

                    # Create a list containing group index and distance relative
                    # to the point.

                    # Find index of the closest group ...
                    min_index = 0
                    min_dist = -1

                    for j in range(non_empty_len):
                        group = self.groups[j]
                        # ...if that group still has room
                        if len(sub_groups[j]) < max_ff:
                            dist = get_cost(group, (x, y))
                            if min_dist == -1 or min_dist > dist:
                                min_dist = dist
                                min_index = j
                            # print(min_index, min_dist, dist)

                    # If a group has been found, add ff to sub_group at that layer.
                    if min_dist > -1:
                        sub_groups[min_index].append(np.asarray((x, y)))
                    else:
                        # Otherwise look into the empty groups
                        for j in range(non_empty_len, len(self.groups)):
                            group = self.groups[j]
                            # ...if that group still has room
                            if len(sub_groups[j]) < max_ff:
                                sub_groups[j].append(np.asarray((x, y)))
                                break
        # print(sub_groups)
        self.sub_groups[layer_index] = sub_groups


def print_layer_with_ffgroups(layer, groups):
    for i in range(len(layer)):
        line = ""
        for j in range(len(layer[i])):
            if is_ff(layer[i][j]):
                elem = "+"
                for k in range(len(groups)):
                    for point in groups[k]:
                        if np.all(np.equal(np.asarray((j, i)), point)):
                            elem = "{}".format(k)
                            break
                line += elem
            else:
                line += " "
        print(line)


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
            if in_bounds(nw, (x, y)) and is_ff((x, y)):
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
    line = "|"
    for i in range(len(layer[0])):
        line += "{:<2}".format(i % 10)
    line += "|"
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


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    gen = OddEven()
    # alloc = Simple_Allocator()
    alloc = Block_Allocator()
    nw = gen.create(16)
    nw.add_layer()
    clk_zone_w = 5
    for y in range(nw.get_depth()):
        for x in range(nw.get_N()):
            center = math.ceil(clk_zone_w / 2)
            if (x + center) % clk_zone_w == 0:
                nw.control_layers[0][y][x] = ("+", 0)
            else:
                nw.control_layers[0][y][x] = (" ", 0)

    print_layer(nw.con_net)
    print_layer(nw.control_layers[0])

    target_ff = 5
    groups, sub_groups = alloc.allocate_ff_groups(nw, target_ff, [2])
    print_layer_with_ffgroups(nw.con_net, groups)
    print_layer_with_ffgroups(nw.control_layers[0], sub_groups[0])

    for group in groups:
        print(get_distscore_group(nw, group), group)
