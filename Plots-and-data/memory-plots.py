import matplotlib.pyplot as plt
import numpy as np
import re

fig, ax = None, None

benchmark_versions = {
    '_GCD_opt_none': 'GCD (-Onone)',
    '_GCD_opt_speed': 'GCD (-O)',
    '_GCD_opt_size': 'GCD (-Osize)',
    '_SC_opt_none': 'SC (-Onone)',
    '_SC_opt_speed': 'SC (-O)',
    '_SC_opt_size': 'SC (-Osize)'
}

# Used to generate "zoomed in" versions of
# the memory plots
bench_param_positions = []

def benchmark_vline_label(benchmark, parameter):

    if benchmark == 'SpawnManyWaiting':
        return '' + parameter + ' tasks'
    elif benchmark == 'SpawnManyWaitingGroup':
        return '' + parameter + ' tasks'
    elif benchmark == 'SpawnManyActors':
        return '' + parameter + ' actors'
    elif benchmark == 'Fibonacci':
        return 'Fib(' + parameter + ')'
    elif benchmark == 'NQueens':
        return '' + parameter + ' queens'
    elif benchmark == 'MatrixMultiplication':
        return '(' + parameter + 'x' + parameter + ') matrix'

def plot_file(filename, label, color, benchmark):

    print('\n-- Plotting', filename, '--\n')

    with open(filename) as f:
        lines = f.readlines()
        y_values = []

        for line in lines:

            if 'mem: ' in line:
                mb = float(line.split('mem: ')[1])
                y_values.append(mb)

            if 'Running' in line:
                (*bench_param, iterations) = re.findall(r'\d+', line) # https://sparrow.dev/object-spread-operator-python/

                plt.axvline(len(y_values))
                plt.text(len(y_values), 2, benchmark_vline_label(benchmark, bench_param[0]), rotation = 90)

                # Save value so we can automate the plotting
                # of "zoomed in" subgraphs
                bench_param_positions.append(len(y_values))

    ax.plot(y_values, label = label, color = color, linewidth = .01)

    # Color the area under the curve
    # (https://stackoverflow.com/a/71712797/16823203)
    t = np.arange(0,len(y_values),1)
    plt.fill_between(
        x = t,
        y1 = y_values,
        color = '#74a2f8',
        alpha = 0.5)

    # Ensure that the graph is stretched to fit
    # the available space of the boxplot window
    plt.xlim([0, len(y_values)*1.05]) #plt.xlim([0, test[2]])
    plt.ylim([0, plt.ylim()[1]])

    # Annotating axes and plot title
    ax.set_xlabel('Time (seconds)')
    ax.set_ylabel('Memory (Mb)')
    ax.set_title('' + benchmark + ' memory consumption profile')
    ax.legend()

def plot_benchmark(benchmark, version):
    global fig, ax

    fig, ax = plt.subplots(figsize = (10, 4))

    label = benchmark_versions[version]

    plot_file(
        filename = 'Official-memory-consumption-profile/' + benchmark + '/' + benchmark + version,
        label = 'Memory, ' + label,
        color = '#2b60c0',
        benchmark = benchmark)

    plt.show()

def plot_benchmark_to_file(benchmark):
    global fig, ax, bench_param_positions

    for (version, label) in benchmark_versions.items():
        fig, ax = plt.subplots(figsize = (10, 4))
        bench_param_positions = []

        plot_file(
            filename = 'Official-memory-consumption-profile/' + benchmark + '/' + benchmark + version,
            label = 'Memory, ' + label,
            color = '#2b60c0',
            benchmark = benchmark)

        # Convert x axis labels from FPS to seconds
        # (https://stackoverflow.com/a/18946103/16823203)
        a = ax.get_xticks().tolist()
        a = map(lambda x: round(x/60, 2), a)
        ax.set_xticklabels(a)

        plt.savefig(
            fname = 'Memory-plots/' + benchmark + '/' + benchmark + version,
            dpi = 250,
            facecolor = 'w',
            edgecolor = 'w',
            orientation = 'portrait',
            format = None,
            transparent = False,
            bbox_inches = None,
            pad_inches = 0.1,
            metadata = None)

        # Plot and save "zoomed in" parts as well
        for pos in bench_param_positions:
            plt.xlim([0, pos])

            # Convert x axis labels from FPS to seconds
            a = ax.get_xticks().tolist()
            a = map(lambda x: round(x/60, 2), a)
            ax.set_xticklabels(a)

            plt.savefig(
                fname = 'Memory-plots/' + benchmark + '/Zoomed/' + benchmark + version + str(pos),
                dpi = 250,
                facecolor = 'w',
                edgecolor = 'w',
                orientation = 'portrait',
                format = None,
                transparent = False,
                bbox_inches = None,
                pad_inches = 0.1,
                metadata = None)

def plot_all_benchmarks_to_file():
    plot_benchmark_to_file('SpawnManyWaiting')
    plot_benchmark_to_file('SpawnManyWaitingGroup')
    plot_benchmark_to_file('SpawnManyActors')
    plot_benchmark_to_file('Fibonacci')
    plot_benchmark_to_file('NQueens')
    plot_benchmark_to_file('MatrixMultiplication')

#plot_all_benchmarks_to_file()
#plot_benchmark('Fibonacci', version = '_SC_opt_none')

#plot_benchmark_to_file('MatrixMultiplication')
