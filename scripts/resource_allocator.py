#!/usr/bin/env python3
from network_generators import OddEven, Network


def is_ff(pair):
    if pair[0] == "+":
        return True
    return False


def in_bounds(nw, point):
    x, y = point
    print(nw.get_depth(), nw.get_N())
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
        return ff_points, ((i + 1) % N, (i + 1) // N)

    def allocate_ff_groups(self, network, max_ff_per_group):
        ff_groups = []
        next_start = (0, 0)
        while in_bounds(network, next_start):
            ff_points, next_start = self.allocate_row(
                network, next_start, max_ff_per_group
            )
            print(next_start, in_bounds(network, next_start))
            ff_groups.append(ff_points)
        return ff_groups


class Block_Allocator(Resource_Allocator):
    def __init__(self):
        self.groups = []

    def distribute_to_groups(self, network, rect, total_ff, num_groups):
        """Takes a rectangle and a division index and attempts to distribute ffs
        evenly between blocks respecting some degree of locality.
        """
        print(rect, total_ff, num_groups)
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
                        for i, group in enumerate(groups):
                            if len(group) < target_nff[i]:
                                group.append((x, y))

        else:
            # Y range is the long edge.

            # Iterate other all points in rectangle.
            for x in range(start_x, end_x):
                for y in range(start_y, end_y):
                    if is_ff(network.at((x, y))):
                        # If we have a FF ...
                        for i, group in enumerate(groups):
                            if len(group) < target_nff[i]:
                                group.append((x, y))

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
        print(ff_per_cr)
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
            print("Rectangle:", rect, "with", total, "FF divided into")
            rect0 = (0, 0)
            rect1 = (0, 0)
            if orientation:
                rect0 = (a, (index + 1, end_y))
                rect1 = ((index + 1, start_y), b)
            else:
                rect0 = (a, (end_x, index + 1))
                rect1 = ((start_y, index + 1), b)
            print("Rect0:", rect0)
            self.divide_block(network, rect0, max_ff_per_group)
            print("Rect1:", rect1)
            self.divide_block(network, rect1, max_ff_per_group)
        else:
            print("Distributing:", rect, "with", total, "FF")
            # Total number of ff are less than thrice the maximum number.
            # In this case, distribute ff between blocks evenly.
            num_groups = (total + max_ff_per_group + 1) // max_ff_per_group
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
                elem = "+ "
                for k in range(len(groups)):
                    if (j, i) in groups[k]:
                        elem = "{} ".format(k)
                line += elem
            else:
                line += "  "
        print(line)


def get_distscore_rect(nw, rect):
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
                if x < max_x:
                    max_x = x
                if y < min_y:
                    min_y = y
                if y < max_y:
                    max_y = y
    diag2 = (max_x - min_x) ** 2 + (max_y - min_y) ** 2
    return diag2


def get_distscore_group(nw, group):

    min_x = 0
    min_y = 0
    max_x = nw.get_N()
    max_y = nw.get_depth()
    for point in group:
        x, y = point
        if x < min_x:
            min_x = x
        if x < max_x:
            max_x = x
        if y < min_y:
            min_y = y
        if y < max_y:
            max_y = y
    diag2 = (max_x - min_x) ** 2 + (max_y - min_y) ** 2
    return diag2


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
