#!/usr/bin/env python3
from scripts.network_generators import OddEven, Network


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
    def __init__(self):
        pass

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

    def allocate_ff_groups(self, network, ff_per_group):
        ff_groups = []
        next_start = (0, 0)
        while in_bounds(network, next_start):
            ff_points, next_start = self.allocate_row(network, next_start, ff_per_group)
            print(next_start, in_bounds(network, next_start))
            ff_groups.append(ff_points)
        return ff_groups

    def reallocate_ff(self, network, entity, max_entities, ff_per_entity):
        ff_groups = self.allocate_ff_groups(network, ff_per_entity)
        ff_groups = ff_groups[:max_entities]
        for group in ff_groups:
            for point in group:
                x, y = point
                network[y][x] = ("-", network[y][x][1])
        return FF_Replacement(entity, ff_groups, ff_per_entity)


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


# Elpy shenanigans
cond = __name__ == "__main__"
if cond:
    gen = OddEven()
    alloc = Resource_Allocator()
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
    groups = alloc.allocate_ff_groups(nw, 5)
    print_nw_with_ffgroups(nw, groups)
    print(groups)
