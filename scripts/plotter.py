#!/usr/bin/env python3

"""Scriptable plotter for automatic collection of results from multiple csv.
Usage:

> makeplot file 'home.csv' col 'home_seq_naive' plot --title 'Naive Sequential'
Reads home.csv and plots the data from column titled 'home_seq_naive'.
Multiple columns may be selected by chaining additional col 'name' commands.

> makeplot filedir 'results' plotall
Read all .csv files contained in the results directory and create all plots
defined in plots.py.

Plot will be saved in graphs/Naive\ Sequential.pdf.

"""
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import fire
import re


class PlotWrapper:
    def __init__(self):
        if Path("build/report.csv").exists():
            self.df = pd.read_csv("build/report.csv", index_col="name")
        else:
            self.df = pd.DataFrame()

    # def plot(
    #     self,
    #     title: str = "Plot",
    #     index_col: str = "N",
    #     xscale: str = "log",
    #     yscale: str = "linear",
    #     ylabel: str = "GB/s",
    #     grid: bool = True,
    # ):
    #     """Plots data from ResultAggregator with benchmarks selected from
    #     columns. Figures are saved as .pdf in './graphs/'.
    #     Usage: makegrapth.py ... plot --title 'Title' --index_col 'N'
    #                                   --xscale 'log' --yscale 'linear'
    #                                   --grid
    #     """
    #     print(title)
    #     data = self.agg.get_results(list(self.columns.keys()), index_col)
    #     data.rename(columns=self.columns, inplace=True)
    #     data.plot(x=index_col, marker="x")
    #     plt.title(title)
    #     plt.xlabel(index_col)
    #     plt.ylabel(ylabel)
    #     if xscale == "log":
    #         plt.xscale("log", base=2)
    #     else:
    #         plt.xscale(xscale)
    #     plt.yscale(yscale)

    #     if grid:
    #         plt.grid()

    #     plt.savefig("graphs/" + title + ".png", dpi=200)
    #     plt.close("all")

    # def file(self, csv: str):
    #     """Select data file to be read in.
    #     Usage: makegraph.py file 'data.csv'
    #     """
    #     self.agg.add_data(Path(csv))
    #     return self

    # def filedir(self, dirpath: str):
    #     """Select directory containing .csv files to be read in.
    #     Usage: makegraph.py filedir 'results.csv'
    #     """

    #     for fpath in Path().glob(dirpath + "/*.csv"):
    #         self.agg.add_data(fpath)
    #     return self

    def all(self):
        """Plot all plots defined as functions in plots.py"""
        import scripts.plots as p

        for i in dir(p):
            plot_func = getattr(p, i)
            if callable(plot_func):
                plot_func(self.df)

    def print_names(self):
        """Outputs all available column names found in .csv
        Usage: makegraph.py filedir 'results' print_names
        """
        print(self.agg.dataframe["Name"].unique())

    # def testfactors(self):
    #     """Displays matched columns by regex from factors.csv"""
    #     factors = pd.read_csv("factors.csv", header=None, comment="#")
    #     for index, regex, value in factors.itertuples():
    #         print("Regex: ", regex, " Factor: ", value)
    #         print("Matched elements:")
    #         print(
    #             self.agg.dataframe.loc[
    #                 self.agg.dataframe["Name"].str.match(regex) == True,
    #             ]
    #         )


if __name__ == "__main__":
    fire.Fire(PlotWrapper)
