#!/usr/bin/env python3

import csv
from pathlib import Path
from scripts.network_generators import Network


class Report:
    def __init__(self, network):
        self.content = self.evaluate(network)

    def evaluate(self, network):
        content = dict()
        content["network"] = network.typename

        # Estimate network shape
        if network.shape:
            content["shape"] = network.shape
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
                    content["shape"] = "min"
                elif output_list[-1] == len(output_list):
                    content["shape"] = "max"
                else:
                    content["shape"] = "median"
            else:
                content["shape"] = "mixed"

        content["num_inputs"] = network.get_N()
        content["num_outputs"] = len(network.get_output_set())
        content["depth"] = network.get_depth()

        # Get number of CS and histograms of FF-chains and compare distances.
        depth = network.get_depth()
        N = network.get_N()
        num_cs = 0
        distance_hist = [0 for i in range(N)]
        FF_hist = [0 for i in range(depth)]
        for i in range(depth):
            for j in range(N):
                # Each out of order value constitutes a cs.
                if network[i][j][1] > j:
                    num_cs += 1
                    distance_hist[network[i][j][1] - j] += 1
                # If flag at that point is "+" or "-", a FF is present at that point.
                if network[i][j][0] in ["+", "-"]:
                    bypass_beg = i
                    bypass_end = i
                    # How long does the FF-chain (shift register) go ?
                    while bypass_end < depth and network[bypass_end][j][0] in [
                        "+",
                        "-",
                    ]:
                        bypass_end += 1
                    bypass_end = bypass_end - 1
                    FF_hist[bypass_end - bypass_beg] += 1

        content["distance_hist"] = dict()
        for i in range(N):
            if distance_hist[i]:
                content["distance_hist"][i] = distance_hist[i]
        content["FF_hist"] = dict()
        for i in range(depth):
            if FF_hist[i]:
                content["FF_hist"][i] = FF_hist[i]

        content["num_cs"] = num_cs
        return content


class Reporter:
    def __init__(self):
        self.reports = list()

    def add(self, network):
        self.reports.append(Report(network))
        return network

    def write_report(self, report_file=""):
        if self.reports:
            header_key = self.reports[0].content.keys()
            report_contents = [report.content for report in self.reports]
            with open(str(report_file), "w") as fd:
                w = csv.DictWriter(fd, header_key)
                # w.writerow(dict((fn, fn) for fn in log_dict.keys()))
                w.writeheader()
                w.writerows(report_contents)
