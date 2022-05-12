#!/usr/bin/env python3
from scripts.network_generators import Network


def is_ff(pair):
    if pair[0] == "+":
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
        if is_ff(network.at(start_point)):
            ff = 1

        ff_points = []

        N = network.get_N()
        depth = network.get_depth()
        x, y = start_point
        i = x + y * depth
        while i < N * depth:
            if is_ff(network[i % depth][i // depth]):
                ff_points.append((i % depth, i // depth))
                ff += 1
                if ff >= num_ff:
                    break
            i += 1
        return ff_points, (i % depth, i // depth)

    def allocate_ff_groups(self, network, ff_per_group):
        ff_groups = []
        next_start = (0, 0)
        while next_start != (0, network.get_N()):
            ff_points, next_start = self.allocate_row(network, next_start, ff_per_group)
            ff_groups.append(ff_points)
        return ff_groups

    def reallocate_ff(self, network, entity, max_entities, ff_per_entity):
        ff_groups = self.allocate_ff_groups(network, ff_per_entity)
        ff_groups = ff_groups[:max_entities]
        for group in ff_groups:
            for point in group:
                x, y = point
                network[x][y] = ("-", network[x][y][1])
        return FF_Replacement(entity, ff_groups, ff_per_entity)


# Elpy shenanigans
# cond = __name__ == "__main__"
# if cond:
#     gen = OddEven()
#     alloc = Resource_Allocator()
#     nw = gen.create(16)
#     for stage in nw.cn:
#         print([flag for flag, perm, in stage])
#     for stage in nw:
#         line = ""
#         for pair in stage:
#             if is_ff(pair):
#                 line += "+ "
#             else:
#                 line += "  "
#         print(line)
#     target_ff = 5
#     print(alloc.allocate_ff_groups(nw, 5))
