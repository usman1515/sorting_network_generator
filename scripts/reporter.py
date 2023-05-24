#!/usr/bin/env python3
import pandas as pd
import csv
from pathlib import Path
from scripts.network_generators import Network
from scripts.resource_allocator import FF_Replacement, FF_Assignment


class Report:
    def __init__(self, network):
        self.content = dict()
        self.evaluate_network(network)

    def evaluate_network(self, network):
        self.content["network"] = network.typename

        # Estimate network shape
        if network.shape:
            self.content["shape"] = network.shape
        else:
            output_list = list(network.get_output_set())
            output_list.sort()
            if all(
                [
                    output_list[i] == output_list[i + 1] + 1
                    for i in range(len(output_list) - 1)
                ]
            ):
                if output_list[0] == 0:
                    self.content["shape"] = "min"
                elif output_list[-1] == len(output_list):
                    self.content["shape"] = "max"
                else:
                    self.content["shape"] = "median"
            else:
                self.content["shape"] = "mixed"

        self.content["num_inputs"] = network.get_N()
        self.content["num_outputs"] = len(network.get_output_set())
        self.content["depth"] = network.get_depth()

        # Get number of CS and histograms of FF-chains and compare distances.
        depth = network.get_depth()
        N = network.get_N()
        num_cs = 0
        num_ff = 0
        distance_hist = [0 for i in range(N)]
        FF_hist = [0 for i in range(depth)]
        for i in range(depth):
            for j in range(N):
                # Each out of order value constitutes a cs.
                if network[i][j] > j:
                    num_cs += 1
                    distance_hist[network[i][j] - j] += 1
        for j in range(N):
            i = 0
            while i < depth:
                # If flag at that point is "+" or "-", a FF is present at that point.
                if network.ff_layers[0][i][j]:
                    bypass_beg = i
                    bypass_end = i
                    # How long does the FF-chain (shift register) go ?
                    while bypass_end < depth and network.ff_layers[0][bypass_end][j]:
                        bypass_end += 1
                    bypass_end = bypass_end - 1
                    num_ff += bypass_end - bypass_beg + 1
                    FF_hist[bypass_end - bypass_beg] += 1
                    i = bypass_end
                i += 1

        self.content["num_cs"] = num_cs
        self.content["distance_hist"] = dict()
        for i in range(N):
            if distance_hist[i]:
                self.content["distance_hist"][i] = distance_hist[i]
        self.content["num_ff"] = num_ff
        self.content["FF_hist"] = dict()
        for i in range(depth):
            if FF_hist[i]:
                self.content["FF_hist"][i + 1] = FF_hist[i]

        self.content["ff_replacement"] = "None"
        self.content["num_replacements"] = 0
        self.content["ff_per_entity"] = 0
        self.content["replaced_ff"] = 0

    def evaluate_ffreplacement(self, ff_replacement):
        self.content["ff_replacement"] = ff_replacement.entity.name
        self.content["num_replacements"] = len(ff_replacement.groups)
        self.content["ff_per_entity"] = ff_replacement.ff_per_entity

        ff_per_group = []
        for group in ff_replacement.groups:
            ff = 0
            for assignment in group:
                ff += assignment.ff_range[1] - assignment.ff_range[0]
            ff_per_group.append(ff)
        self.content["replaced_ff"] = sum(ff_per_group)

    def as_df(self):
        name = (
            self.content["network"]
            + "_"
            + str(self.content["num_inputs"])
            + "X"
            + str(self.content["num_outputs"])
        )

        self.content["name"] = name
        data = [self.content]
        return pd.DataFrame.from_records(data, index="name")


class Reporter:
    def __init__(self):
        self.current_report = None
        self.current_report_committed = False
        self.reports = None

    def commit_report(self):
        if not self.current_report_committed:
            if not self.reports:
                self.reports = self.current_report.as_df()
            else:
                current_df = self.current_report.as_df()
                self.reports = pd.concat(
                    [
                        self.reports[~self.reports.index.isin(current_df.index)],
                        current_df,
                    ]
                )

    def report_network(self, network):
        self.current_report = Report(network)
        self.current_report_committed = False

    def report_ff_replacement(self, ff_replacement):
        self.current_report.evaluate_ffreplacement(ff_replacement)

    def write_report(self, report_file=""):
        if not self.reports.empty:
            fpath = Path(report_file)
            if fpath.exists():
                reports = pd.read_csv(str(fpath), index_col="name")
                reports = pd.concat(
                    [reports[~reports.index.isin(self.reports.index)], self.reports]
                )
                reports.to_csv(report_file)
            else:
                self.reports.to_csv(report_file)
