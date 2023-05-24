#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np


def figure_luts(pltwrap):
    x = np.arange(1, 2**15, 1)
    # Fomulars based on Sorting networks on FPGAs, Mueller et al., 2012.
    p = np.log2(x)
    s = p * (p + 1.0) / 2.0
    oe_cs = (p * p - p + 4) * np.power(2, p - 2) - 1
    bitonic_cs = (p * p + p) * np.power(2, p - 2)
    # LUTs based on implemenation data of bit-serial CS.
    oe_luts = 2.0 * oe_cs
    bitonic_luts = 2.0 * bitonic_cs

    fig = plt.figure()
    (p1,) = plt.plot(x, oe_luts, label="Odd-Even")
    (p2,) = plt.plot(x, bitonic_luts, label="Bitonic")
    plot_handles = [p1, p2]
    plt.title("Network LUTs for Bit-Serial CS")
    plt.xlabel("N")
    plt.ylabel("LUTs")
    plt.xscale("log", base=2)
    plt.grid(True)
    legend0 = plt.legend(handles=plot_handles, loc=2, title="Network Type")

    l1 = plt.axhline(y=1182 * 10**3, color="black", label="VU9P")
    line_handles = [
        l1,
    ]
    plt.legend(handles=line_handles, loc=9, title="FPGAs")
    plt.gca().add_artist(legend0)
    plt.savefig("build/graphs/" + "Network_LUTs" + ".png", dpi=200)


def figure_ff(pltwrap):
    x = np.arange(1, 2**15, 1)
    # Fomulars based on Sorting networks on FPGAs, Mueller et al., 2012.
    p = np.log2(x)
    # Number of stages s.
    s = p * (p + 1.0) / 2.0
    oe_cs = (p * p - p + 4) * np.power(2, p - 2) - 1
    bitonic_cs = (p * p + p) * np.power(2, p - 2)
    # Number of total FF is derived from the number of delaying FF in the
    # network (s**2) + the number if FF added by the CS state-machine (2*CS).
    oe_ff = s * s + 2.0 * oe_cs
    bitonic_ff = s * s + 2.0 * bitonic_cs

    fig = plt.figure()
    (p1,) = plt.plot(x, oe_ff, label="Odd-Even")
    (p2,) = plt.plot(x, bitonic_ff, label="Bitonic")
    plot_handles = [p1, p2]
    plt.title("Network FFs for Bit-Serial CS")
    plt.xlabel("N")
    plt.ylabel("LUTs")
    plt.xscale("log", base=2)
    plt.grid(True)
    legend0 = plt.legend(handles=plot_handles, loc=2, title="Network Type")

    l1 = plt.axhline(y=2364 * 10**3, color="black", label="VU9P")
    line_handles = [
        l1,
    ]
    plt.legend(handles=line_handles, loc=9, title="FPGAs")
    plt.gca().add_artist(legend0)
    plt.savefig("build/graphs/" + "Network_LUTs" + ".png", dpi=200)
    plt.savefig("build/graphs/" + "Network_FF" + ".png", dpi=200)


# def figure_example(pltwrap : PlotWrapper):
#     columns = {
#         "example_col": "example_title",
#     }
#     syscol = dict()

#     for key, value in columns.items():
#         syscol[key] = value

#     pltwrap.columns = syscol
#     pltwrap.plot(
#         title="Figure Title",
#         index_col="Index",
#         xscale="log",
#         yscale="linear",
#         grid=True,
#     )
# print(Path().absolute())
# figure_ff(None)
# figure_luts(None)
