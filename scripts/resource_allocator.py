#!/usr/bin/env python3
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

    def distribute_to_groups(self, network, rect, total_ff, num_groups):
        """Takes a rectangle and a division index and attempts to distribute ffs
        evenly between blocks respecting some degree of locality.
        """
        a, b = rect
        start_x, start_y = a
        end_x, end_y = b
        groups = [[] for i in range(num_groups)]
        target_rem = (total_ff) % num_groups
        target_nff = [total_ff // num_groups for i in range(num_groups)]
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
                            if len(groups[i]) < target_nff[i]:
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
                            if len(groups[i]) < target_nff[i]:
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
                sum([1 for y in range(start_y, end_y) if is_ff(network.at((x, y)))])
                for x in range(start_x, end_x)
            ]
        else:
            # Get number of ff per row
            ff_per_cr = [
                sum([1 for x in range(start_x, end_x) if is_ff(network.at((x, y)))])
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
        if total > 3 * max_ff_per_group:
            # Total number of blocks exceeds 3 times the maximum.
            # Recursively subdivide.
            # print("Rectangle:", rect, "with", total, "FF divided into")
            rect0 = ((0, 0), (0, 0))
            rect1 = ((0, 0), (0, 0))
            if orientation:
                rect0 = (a, (index, end_y))
                rect1 = ((index, start_y), b)
            else:
                rect0 = (a, (end_x, index))
                rect1 = ((start_x, index), b)
            print("Rect0:", rect0)
            self.divide_block(network, rect0, max_ff_per_group)
            print("Rect1:", rect1)
            self.divide_block(network, rect1, max_ff_per_group)
        else:
            # print("Distributing:", rect, "with", total, "FF")
            # Total number of ff are less than thrice the maximum number.
            # In this case, distribute ff between blocks evenly.
            num_groups = (total) // max_ff_per_group
            self.distribute_to_groups(network, rect, total, num_groups)

    def allocate_ff_groups(self, network, max_ff_per_group):
        self.groups = []
        N = network.get_N()
        depth = network.get_depth()
        self.divide_block(network, ((0, 0), (N, depth)), max_ff_per_group)
        return self.groups


def print_nw_with_ffgroups(nw, groups):
    for i in range(len(nw.cn)):
        line = ""
        for j in range(len(nw[i])):
            if is_ff(nw[i][j]):
                elem = "+"
                for k in range(len(groups)):
                    if np.any(np.all(np.asarray((j, i)) == groups[k], axis=1)):
                        elem = "{}".format(k)
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
        cost += norm2square(gpoint, point)
    return cost


def get_transferral_cost(point, group_s, group_t):
    """Calculates improvement of cost if point is transferred from group_s
    to group_t.

    See https://proceedings.mlr.press/v9/telgarsky10a.html for details"""
    cost_target = (
        len(group_t) / (len(group_t) + 1) * norm2square(get_mean(group_t) - point)
    )
    cost_source = (
        len(group_s) / (len(group_s) - 1) * norm2square(get_mean(group_s) - point)
    )

    return cost_target - cost_source


def get_swap_cost(point_a, group_a, point_b, group_b):
    """Calculates cost of swapping point a from group a with b from group b.
    Simply sums the transferral costs.
    """
    transf_a = get_transferral_cost(point_a, group_a, group_b)
    transf_b = get_transferral_cost(point_b, group_b, group_a)

    if transf_a + transf_b > 0:
        print(transf_a, transf_b)
    return transf_a + transf_b


def swap_points_at_index(index_a, group_a, index_b, group_b):
    point = group_a[index_a]
    group_a[index_a] = group_b[index_b]
    group_b[index_b] = point


def select_point(cur_point, cur_group, groups, start_group_index):
    """Finds the next best point which has positive cost.
    Iterates over groups starting at index start_group_index and points in groups.
    returns pair of point index and related group.
    """
    print(
        "Searching partner for point {} beginning at {}.".format(
            cur_point, start_group_index
        )
    )
    for i in range(start_group_index, len(groups)):
        for j in range(len(groups[i])):
            cost = get_swap_cost(cur_point, cur_group, groups[i][j], groups[i])
            if cost > 0:
                print(
                    "Found point in group number {} with index {} and cost {}".format(
                        i, j, cost
                    )
                )
                return j, groups[i]
    return None


def find_group(cur_point, cur_group, groups, start_group_index):
    """Finds the next best point which has positive cost.
    Iterates over groups starting at index start_group_index and points in groups.
    returns pair of point index and related group.
    """
    print(
        "Searching partner for point {} beginning at {}.".format(
            cur_point, start_group_index
        )
    )
    for i in range(start_group_index, len(groups)):
        cost = get_transferral_cost(cur_point, cur_group, groups[i])
        if cost > 0:
            print("Found group number {} and cost {}".format(i, cost))
            return groups[i]
    return None


def find_best_swap_partner(cur_point, cur_group, group_b):
    best_index = 0
    best_cost = 0
    for i, y in enumerate(group_b):
        cost = get_transferral_cost(y, group_b, cur_group)
        if best_cost < cost:
            best_cost = cost
            best_index = i
    return best_index, best_cost


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    gen = OddEven()
    # alloc = Simple_Allocator()
    alloc = Block_Allocator()
    nw = gen.create(16)
    for stage in nw:
        line = ""
        for pair in stage:
            if is_ff(pair):
                line += "+ "
            else:
                line += "  "
        print(line)
    target_ff = 5
    groups = alloc.allocate_ff_groups(nw, 4)
    print_nw_with_ffgroups(nw, groups)
    for group in groups:
        print(get_distscore_group(nw, group), group)
    for n in range(0, 1):
        for i, group_a in enumerate(groups):
            for j, x in enumerate(group_a):
                group_b = find_group(x, group_a, groups, i + 1)
                k, cost = find_best_swap_partner(x, group_a, group_b)
                print(k, cost, len(group_a), len(group_b))
                swap_points_at_index(j, group_a, k, group_b)
                break

            print_nw_with_ffgroups(nw, groups)
