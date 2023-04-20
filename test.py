#!/usr/bin/env python3

import importlib


def test_netgen():
    import scripts.network_generators as generators
    import scripts.resource_allocator as allocators

    importlib.reload(generators)
    importlib.reload(allocators)

    gen = generators.OddEven()
    # alloc = Simple_Allocator()
    alloc = allocators.Block_Allocator()
    nw = gen.create(128)
    nw = gen.distribute_signals(nw, {"START": 10})
    print("Network Top Level:")
    for i in range(len(nw.ff_layers)):
        print("Layer {}: {}".format(i, nw.layer_names[i]))
        allocators.print_layer(nw.ff_layers[i])

    print("\nAfter assignment:")
    target_ff = 50
    groups = alloc.allocate_ff_groups(nw, target_ff, 50)
    print(groups)
    allocators.print_layers_with_ffgroups(nw, groups)
    # print("---------------------------")
    # for i, layer in enumerate(nw.ff_layers):
    #     print_layer_with_ffgroups(layer, sub_groups[i])
    # # for i, group in enumerate(groups):
    # #     print(len(group), sum([len(subgroup) for subgroup in sub_groups[0][i]]), group)
    # for i, subgroup in enumerate(sub_groups[0]):
    #     print(len(subgroup), subgroup)


def test_template():
    from pathlib import Path
    from scripts.network_generators import OddEven
    from scripts.template_processor import Template_Processor
    from scripts.vhdl_parser import parseVHDLEntity, parseVHDLTemplate

    template = parseVHDLTemplate(Path("templates/Network.vhd"))
    cs = parseVHDLEntity(Path("src/CS/BitCS_Sync.vhd"))

    gen = OddEven()
    nw = gen.create(4)
    nw = gen.reduce(nw, 3)
    # print(nw.pmatrix)
    # print(nw.ff_layers.shape)
    # print(nw.layer_names)
    # print(template.as_template())

    output_set = set()
    output_set.add(0)
    nw = gen.prune(nw, output_set.copy())

    tempproc = Template_Processor()
    template = tempproc.fill_main_file(template, cs, nw)

    print(template.as_instance())


cond = __name__ == "__main__"
if cond:
    # test_netgen()
    test_template()
