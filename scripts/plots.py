#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import ast


def figure_luts(df):
    title = "Network LUTs for Bit-Serial CS"
    print(title)
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
    plt.title(title)
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
    plt.close("all")


def figure_ff(df):
    title = "Network FFs for Bit-Serial CS"
    print(title)
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
    plt.title(title)
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
    plt.savefig("build/graphs/" + "Network_FF" + ".png", dpi=200)
    plt.close("all")


def figure_cs_distances(df: pd.DataFrame):
    base_title = "CS Distances"
    for index, row in df.iterrows():
        name = index
        title = name + " " + base_title
        print(title)
        cs_dist = row.distance_hist
        dist_dict = ast.literal_eval(cs_dist)
        if dist_dict:
            pd.DataFrame.from_dict(dist_dict, orient="index").plot(kind="bar")

            plt.title(title)
            plt.xlabel("Distance")
            plt.ylabel("Number of CS")
            plt.savefig("build/graphs/" + title + ".png", dpi=200)
            plt.close("all")


def figure_ff_chain_lengths(df: pd.DataFrame):
    base_title = "FF Chain Lengths"
    for index, row in df.iterrows():
        name = index
        title = name + " " + base_title
        print(title)
        ff_length = row.ff_hist
        ff_dict = ast.literal_eval(ff_length)
        if ff_dict:
            pd.DataFrame.from_dict(ff_dict, orient="index").plot(kind="bar")
            plt.title(title)
            plt.xlabel("Length")
            plt.ylabel("Occurances")
            plt.savefig("build/graphs/" + title + ".png", dpi=200)
            plt.close("all")


def figure_avg_cs_dists(df: pd.DataFrame):
    title = "Average CS Distances"
    print(title)
    avg = lambda x: sum(num * dist for num, dist in x.items()) / (
        sum(dist for dist in x.values() or 1)
    )
    avg_from_str = lambda x: avg(ast.literal_eval(x))
    distance_hist = df["distance_hist"]
    distance_hist = distance_hist.apply(avg_from_str)
    temp_df = df.assign(avg_dist=distance_hist)
    temp_df = temp_df.pivot(columns="network", index="N", values=["avg_dist"])

    temp_df.plot()
    plt.title(title)
    plt.xlabel("Length")
    plt.ylabel("Occurances")
    plt.savefig("build/graphs/" + title + ".png", dpi=200)
    plt.close("all")


def figure_avg_cs_dists(df: pd.DataFrame):
    title = "Average FF Chain Lengths"
    print(title)
    avg = lambda x: sum(num * dist for num, dist in x.items()) / (
        sum(dist for dist in x.values()) or 1
    )
    avg_from_str = lambda x: avg(ast.literal_eval(x))
    ff_hist = df["ff_hist"]
    ff_hist = ff_hist.apply(avg_from_str)
    temp_df = df.assign(avg_ff_length=ff_hist)
    temp_df = temp_df.pivot(columns="network", index="N", values=["avg_ff_length"])

    temp_df.plot()
    plt.title(title)
    plt.xlabel("Length")
    plt.ylabel("Occurances")
    plt.savefig("build/graphs/" + title + ".png", dpi=200)
    plt.close("all")


# def figure_example(df) : PlotWrapper):
#     columns = {
#         "example_col": "example_title",
#     }
#     syscol = dict()

#     for key, value in columns.items():
#         syscol[key] = value

#     df).columns = syscol
#     df).plot(
#         title="Figure Title",
#         index_col="Index",
#         xscale="log",
#         yscale="linear",
#         grid=True,
#     )
# print(Path().absolute())
# figure_ff(None)
# figure_luts(None)
