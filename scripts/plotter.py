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


class ResultAggregator:
    """
    Class for collecting results from our catch2 benchmarks and
    outputting easily plottable tables.
    """

    # csv separator
    separator = "\t"
    header = {0: "Name", 1: "Throughput"}
    # Datatype used in the benchmarks, in our case float = 4 Bytes
    operand_size = 4.0

    def __init__(self):
        self.dataframe = pd.DataFrame()
        # self.factors = pd.read_csv("factors.csv", header=None, comment="#")

    def __str__(self):
        return str(self.dataframe)

    def add_data(self, data_path=Path()):
        """Reads csv file and concatenates the result to the internal
        dataframe.
        Warning: The filename is inserted before the benchmark names to
        allow easy aggregation of the same benchmarks from multiple
        machines.
        Example: mp-media.csv
            seq_naive -> mp-media_seq_naive

            Parameters:
               data_path (Path): Path object pointing to csv file.

            Returns:
               None
        """
        print(data_path)
        new_df = pd.read_csv(str(data_path), sep=self.separator, header=None)
        for i in range(2, len(new_df.columns)):
            label = new_df[i][0].split(" ")[0]
            self.header[i] = label
            # Extract base10 value from string. Example:
            # N := 16777216 (0x1000000)
            #      ^^^^^^^^
            new_df[i] = new_df[i].str.split(" ").str.get(2)
            if label == "N":
                new_df[1] = new_df[i].astype(float) / new_df[1].astype(float)

        # Insert filename into later column names.
        new_df[0] = new_df[0].apply(
            lambda value: data_path.name.split(".")[0] + "_" + value
        )

        new_df = new_df.rename(columns=self.header)
        # Apply factors to rows selected by regex read from factors.csv
        # for index, regex, value in self.factors.itertuples():
        #     new_df.loc[
        #         new_df["Name"].str.match(regex) == True,
        #         "Throughput",
        #     ] *= value
        if self.dataframe.empty:
            self.dataframe = new_df
        else:
            self.dataframe = pd.concat([self.dataframe, new_df], axis=0)

    def get_results(self, benchnames=[], index_col="N"):
        """Pivots dataframe and returns the selected columns.

        Parameters:
           benchnames (list(str)): Benchmark names of the desired
                                benchmark results.
        Returns:
           Pandas.DataFrame: Benchmark results with index of 'N' and
                             selected results column-wise.
        """
        df = self.dataframe[self.dataframe["Name"].isin(benchnames)]
        df = df.pivot(columns="Name", values="Throughput", index=index_col).sort_values(
            by=[index_col], key=lambda col: col.astype(int)
        )
        # Plotting logscale with index is bugged
        # N must be added again
        df[index_col] = df.index.astype(int)

        return df[[index_col] + benchnames]


class PlotWrapper:
    def __init__(self):
        self.agg = ResultAggregator()

        self.columns = dict()

    def col(self, column: str, name=""):
        """Select column/benchmark name to be part of the plot.
        Usage: makegraph.py col 'column name'
        Warning: Please consider that this script prepends the filename
        of the csv to the column names!
        """
        if not name:
            name = column
        self.columns[name] = column
        return self

    def plot(
        self,
        title: str = "Plot",
        index_col: str = "N",
        xscale: str = "log",
        yscale: str = "linear",
        ylabel: str = "GB/s",
        grid: bool = True,
    ):
        """Plots data from ResultAggregator with benchmarks selected from
        columns. Figures are saved as .pdf in './graphs/'.
        Usage: makegrapth.py ... plot --title 'Title' --index_col 'N'
                                      --xscale 'log' --yscale 'linear'
                                      --grid
        """
        print(title)
        data = self.agg.get_results(list(self.columns.keys()), index_col)
        data.rename(columns=self.columns, inplace=True)
        data.plot(x=index_col, marker="x")
        plt.title(title)
        plt.xlabel(index_col)
        plt.ylabel(ylabel)
        if xscale == "log":
            plt.xscale("log", base=2)
        else:
            plt.xscale(xscale)
        plt.yscale(yscale)

        if grid:
            plt.grid()

        plt.savefig("graphs/" + title + ".png", dpi=200)
        plt.close("all")

    def file(self, csv: str):
        """Select data file to be read in.
        Usage: makegraph.py file 'data.csv'
        """
        self.agg.add_data(Path(csv))
        return self

    def filedir(self, dirpath: str):
        """Select directory containing .csv files to be read in.
        Usage: makegraph.py filedir 'results.csv'
        """

        for fpath in Path().glob(dirpath + "/*.csv"):
            self.agg.add_data(fpath)
        return self

    def all(self):
        """Plot all plots defined as functions in plots.py"""
        import scripts.plots as p

        for i in dir(p):
            plot_func = getattr(p, i)
            if callable(plot_func):
                plot_func(self)

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
