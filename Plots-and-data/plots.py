import re
import matplotlib.pyplot as plt
import numpy as np
import pprint

## Settings
iterations_to_discard = 10

benchmark_versions = {
    '_GCD_opt_none' : 'GCD (-Onone)',
    '_GCD_opt_speed': 'GCD (-O)',
    '_GCD_opt_size' : 'GCD (-Osize)',
    '_SC_opt_none'  : 'SC (-Onone)',
    '_SC_opt_speed' : 'SC (-O)',
    '_SC_opt_size'  : 'SC (-Osize)'
}

benchmark_titles = {
    'SpawnManyWaiting': 'SpawnManyWaiting (spawning N tasks, 100 iterations)',
    'SpawnManyWaitingGroup': 'SpawnManyWaitingGroup (spawning N tasks, 100 iterations)',
    'SpawnManyActors': 'SpawnManyActors (spawning N actors, 100 iterations)',
    'Fibonacci': 'Fibonacci (calculating Fib(n), 100 iterations)',
    'NQueens': 'NQueens (finding all solutions for N queens, 100 iterations)',
    'MatrixMultiplication': 'MatrixMultiplication (multiplying two NxN matrices, 100 iterations)'
}

benchmark_xlabels = {
    'SpawnManyWaiting': 'Number of tasks',
    'SpawnManyWaitingGroup': 'Number of tasks',
    'SpawnManyActors': 'Number of actors',
    'Fibonacci': 'Fibonacci number, n',
    'NQueens': 'Number of queens',
    'MatrixMultiplication': 'Matrix size (NxN)'
}

## Colors (inspired from https://weirddata.github.io/2019/06/17/matplotlib-secret-colors.html)
# Also see: https://www.dunderdata.com/blog/view-all-available-matplotlib-styles
purple = '#9e70f2' # 158,112,242
orange = '#ec6c2c' # 236,108,44
green = '#7da140' # 125,161,64
blue = '#428fdf' # 66,143,223
raspberry_sherbet = '#dc5e8a' # 220,94,138

c_GCD_opt_none = purple
c_GCD_opt_speed = orange
c_GCD_opt_size = green
c_SC_opt_none = blue
c_SC_opt_speed = '#e6e600'
c_SC_opt_size = raspberry_sherbet

version_colors = {
    '_GCD_opt_none': c_GCD_opt_none,
    '_GCD_opt_speed': c_GCD_opt_speed,
    '_GCD_opt_size': c_GCD_opt_size,
    '_SC_opt_none': c_SC_opt_none,
    '_SC_opt_speed': c_SC_opt_speed,
    '_SC_opt_size': c_SC_opt_size
}

fig, ax = None, None

# Calculate sample standard deviation
def sample_s(samples, sample_mean):
    # NB: This whole function seems equivalent to just: np.std(samples, ddof = 1)
    # (https://numpy.org/doc/stable/reference/generated/numpy.std.html)

    res = 0
    for x_i in samples:
        res += (x_i - sample_mean)**2

    res /= (len(samples) - 1)
    res = np.sqrt(res)

    return res

# Calculate sample varaince
def sample_variance(samples, sample_mean):
    res = 0
    for x_i in samples:
        res += (x_i - sample_mean)**2

    res /= (len(samples) - 1)
    return res

# Create a plot based on data in the supplied file, populating
# the global 'fig' and 'ax' variables.
def plot_file(filename, label, color, benchmark, marker = '.'):

    print('\n-- Plotting', filename, '--\n')

    with open(filename) as f:
        lines = f.readlines()

        x_values = []
        y_values = []
        ci_lower = []
        ci_upper = []

        samples = []
        bench_param = 0
        iterations = 0

        for line in lines:

            if line.startswith('Running'):
                if 'MatrixMultiplication' in line:
                    # E.g. 'Running BenchApp.MatrixMultiplication:runAsync with (25x25) matrix and 110 iteration(s).'
                    # --> bench_param, _, iterations = [25, 25, 110]
                    bench_param, _, iterations = list(map(int, re.findall(r'\d+', line))) # https://stackoverflow.com/a/5306100/16823203 for map(int, ...) trick
                else:
                    # All other 'Running ...' lines are for benchmarks with 1 parameter, e.g.:
                    # 'Running BenchApp.Fibonacci:runAsync with fib(5) and 110 iteration(s).'
                    # 'Running BenchApp.SpawnManyActors:runAsync with 100 actor(s) and 110 iteration(s).'
                    # etc.
                    bench_param, iterations = list(map(int, re.findall(r'\d+', line)))
                continue

            if 'average' in line:
                relevant_samples = samples[iterations_to_discard:]

                swift_avg = float(re.findall(r'(\d+\.?\d*(?:e-?)?\d+) seconds', line)[0])

                s = sample_s(relevant_samples, swift_avg)

                # https://stackoverflow.com/a/59747610/16823203 for confidence interval plotting in matplotlib
                # z table: https://www.math.arizona.edu/~rsims/ma464/standardnormaltable.pdf
                # or: https://www.sjsu.edu/faculty/gerstman/StatPrimer/t-table.pdf (z at bottom of table)
                ci = 1.96 * s/np.sqrt(len(relevant_samples)) # 3.291 for 99.9% interval

                ci_lower.append(swift_avg-ci)
                ci_upper.append(swift_avg+ci)

                x_values.append(bench_param)
                y_values.append(swift_avg)

                samples = []
                continue

            if 'Benchmark done' in line:
                break

            # If line does not start with 'Running' or contains 'average', the line is the
            # time that one benchmark iteration took, hence we add it to the samples array.
            if re.findall(r'\d+\.?\d*(?:e-?)?\d+', line) != []:
                samples.append(float(re.findall(r'\d+\.?\d*(?:e-?)?\d+', line)[0]))

    # Plot the execution time and confidence interval
    ax.plot(x_values, y_values, label = label, color = color, marker = marker, markersize = 7, linewidth = .5)
    ax.fill_between(x_values, ci_lower, ci_upper, color = color, alpha = .1)

    # Annotating axes and plot title
    ax.set_xlabel(benchmark_xlabels[benchmark])
    ax.set_ylabel('Runtime (seconds)')
    ax.set_title(benchmark_titles[benchmark])
    ax.legend()

    # If you want to set different background color in graph
    #ax.set_facecolor((0.95, 0.95, 0.92))

# Actually plot the benchmark, either to screen or to file
def plot_benchmark(benchmark, save_to_file = False):
    global fig, ax

    fig, ax = plt.subplots(figsize = (6.5, 5.3))

    for (version, label) in benchmark_versions.items():

        plot_file(
            filename = 'Official-execution-time/' + benchmark + '/' + benchmark + version,
            label = label,
            color = version_colors[version],
            benchmark = benchmark)

    if (not save_to_file):
        plt.tight_layout(pad=1.1)
        plt.show()
    else:
        plt.savefig('Execution-time-plots/' + benchmark,
            dpi = 250,
            transparent = False,
            bbox_inches = 'tight',
            pad_inches = 0.1)

# Plot all six benchmarks to file
def plot_all_benchmarks_to_file():
    plot_benchmark('SpawnManyWaiting', save_to_file = True)
    plot_benchmark('SpawnManyWaitingGroup', save_to_file = True)
    plot_benchmark('SpawnManyActors', save_to_file = True)
    plot_benchmark('Fibonacci', save_to_file = True)
    plot_benchmark('NQueens', save_to_file = True)
    plot_benchmark('MatrixMultiplication', save_to_file = True)

# Calculate sample mean and variance for all benchmark
# parameters of a certain benchmark version
def get_stats(benchmark, version):
    filename = 'Official-execution-time/' + benchmark + '/' + benchmark + version

    # 'res' will contain mappings for
    # bench_param -> [sample_mean, sample_variance]
    # E.g.:
    # [
    #   ['2' : ['0.2094', '0.002']],
    #   ['4' : ['0.4185', '0.018']],
    #   ['6' : ['0.6285', '0.023']],
    #   ['8' : ['0.8379', '0.021']],
    #   ['10': ['1.0452', '0.015']]
    # ]
    res = {}

    with open(filename) as f:
        lines = f.readlines()

        samples = []
        bench_param = 0
        iterations = 0

        for line in lines:

            if line.startswith('Running'):
                if 'MatrixMultiplication' in line:
                    # E.g. 'Running BenchApp.MatrixMultiplication:runAsync with (25x25) matrix and 110 iteration(s).'
                    # --> bench_param, _, iterations = [25, 25, 110]
                    bench_param, _, iterations = list(map(int, re.findall(r'\d+', line))) # https://stackoverflow.com/a/5306100/16823203 for map(int, ...) trick
                else:
                    # All other 'Running ...' lines are for benchmarks with 1 parameter, e.g.:
                    # 'Running BenchApp.Fibonacci:runAsync with fib(5) and 110 iteration(s).'
                    # 'Running BenchApp.SpawnManyActors:runAsync with 100 actor(s) and 110 iteration(s).'
                    # etc.
                    bench_param, iterations = list(map(int, re.findall(r'\d+', line)))
                continue

            if 'average' in line:
                relevant_samples = samples[iterations_to_discard:]

                swift_avg = float(re.findall(r'(\d+\.?\d*(?:e-?)?\d+) seconds', line)[0])
                var = sample_variance(relevant_samples, swift_avg)

                # Save average and variance
                res[bench_param] = [swift_avg, var]

                samples = []
                continue

            if 'Benchmark done' in line:
                break

            # If line does not start with 'Running' or contains 'average', the line is the
            # time that one benchmark iteration took, hence we add it to the samples array.
            if re.findall(r'\d+\.?\d*(?:e-?)?\d+', line) != []:
                samples.append(float(re.findall(r'\d+\.?\d*(?:e-?)?\d+', line)[0]))

    return res

# Generate LaTeX source code for approximate confidence intervals
# for difference between means of GCD and SC versions
def generate_comparison_tables(benchmark):

    # 'stats' will contain mappings from version to
    # dictionary of bench_params, and then
    # bench_param -> [sample_mean, sample_variance]
    #
    # So, for SpawnManyWaiting, for example, it could be:
    # {'_GCD_opt_none':
    #   {
    #       2 : [0.2094, 0.002],
    #       4 : [0.4185, 0.018],
    #       6 : [0.6285, 0.023],
    #       8 : [0.8379, 0.021],
    #       10: [1.0452, 0.015]
    #   },
    # '_GCD_opt_speed':
    #   {
    #       2 : [0.2088, 0.019],
    #       4 : [0.4183, 0.018],
    #       6 : [0.6285, 0.023],
    #       8 : [0.8376, 0.021],
    #       10: [1.0452, 0.015]
    #   },
    #   ...
    # }
    stats = {}

    for version in list(benchmark_versions.keys()):
        stats[version] = get_stats(benchmark, version)

    # Useful for verification
    #pp = pprint.PrettyPrinter(indent=4)
    #pp.pprint(stats)

    # We can use any key here; bench_params are same for all versions
    bench_params = list(stats['_GCD_opt_none'].keys())

    # 'tables' will contain mappings from bench_param to
    # matrix of [diff, error] vectors
    #
    # So, for SpawnManyWaiting, for example, it could be:
    # {   2: [   [0.0011799612466711629, 0.0013675718674405314],
    #            [-0.004500176672590894, 0.0009951767254470225],
    #            [0.0022863787459209695, 0.001342534122491655],
    #            [0.0005665104230865858, 0.001396717573529481],
    #            [-0.005113627496175471, 0.0010348641855155475],
    #            [0.0016729279223363924, 0.0013722117320755338],
    #            [0.0006176391686312788, 0.0014102672072140103],
    #            [-0.005062498750630778, 0.0010530800055075968],
    #            [0.0017240566678810854, 0.0013860009571363434]],
    #     4: [   [-0.003913242077687784, 0.002592025574439803],
    #            [-0.0064503154088743075, 0.0025252629587746403],
    #            [-0.0047027716564480015, 0.0024096340293675287],
    #            [-0.004125995836220697, 0.002605834924001763],
    #            [-0.006663069167407221, 0.002539435386765439],
    #            [-0.004915525414980915, 0.0024244824660292507],
    #            [-0.004331586254993469, 0.0026384847365148708],
    #            [-0.006868659586179993, 0.0025729279308272916],
    #            [-0.005121115833753687, 0.002459540868080453]],
    #     ...
    # }
    tables = {}

    for bench_param in bench_params:

        tables[bench_param] = []

        for GCD_version in list(benchmark_versions.keys())[:3]:
            for SC_version in list(benchmark_versions.keys())[3:]:
                (x_1, s2_1) = stats[GCD_version][bench_param]
                (x_2, s2_2) = stats[SC_version][bench_param]

                diff = x_1 - x_2

                S = np.sqrt(s2_1 / 100 + s2_2 / 100)
                error = S * 1.96 # 1.96 for 95% confidence, 3.291 for 99.9%

                tables[bench_param].append([diff, error])

    # Useful for verification
    #pp = pprint.PrettyPrinter(indent=4)
    #pp.pprint(tables)

    latex_tables = generate_latex_tables(benchmark, tables)

# Generate LaTeX tables from data
def generate_latex_tables(benchmark, tables):

    # \begin{table}[!ht]
    # \footnotesize
    #   \begin{center}
    #     \caption{Difference between the means of the execution time results in \textit{SpawnManyWaiting} for N = 10.}
    #     \label{tab:smw_table}
    #     \begin{tabular}{|l|c|c|c|}
    #       \hline
    #       \textbf{} & \textbf{SC (-Onone)} & \textbf{SC (-O)} & \textbf{SC (-Osize)}\\
    #       \hline
    #       \textbf{GCD (-Onone)} & 42.32 ± 3.001 & 42.32 ± 3.001 & 42.32 ± 3.001\\
    #       \hline
    #       \textbf{GCD (-O)} & 467.35 & 450.10 & 0.1 ± 0.00189\\
    #       \hline
    #       \textbf{GCD (-Osize)} & 467.35 & 450.10 & \cellcolor[HTML]{d6d6d6} 42\\
    #       \hline
    #     \end{tabular}
    #   \end{center}
    # \end{table}

    for (bench_param, table) in tables.items():

        print('\\begin{table}[!ht]')
        print('\\footnotesize')
        print('  \\begin{center}')
        print('    \\caption{Difference (GCD - SC) between the means of the execution time results in \\textit{' + benchmark + '} for N = ' + str(bench_param) + '.}')
        print('    \\label{tab:' + benchmark + '_' + str(bench_param) + '}')
        print('    \\begin{tabular}{|l|c|c|c|}')
        print('      \\hline')
        print('      \\textbf{} & \\textbf{SC (-Onone)} & \\textbf{SC (-O)} & \\textbf{SC (-Osize)}\\\\')
        print('      \\hline')
        print('      \\textbf{GCD (-Onone)} & ' + generate_latex_cell(table[0]) + ' & ' + generate_latex_cell(table[1]) + ' & ' + generate_latex_cell(table[2]) + '\\\\')
        print('      \\hline')
        print('      \\textbf{GCD (-O)} & ' + generate_latex_cell(table[3]) + ' & ' + generate_latex_cell(table[4]) + ' & ' + generate_latex_cell(table[5]) + '\\\\')
        print('      \\hline')
        print('      \\textbf{GCD (-Osize)} & ' + generate_latex_cell(table[6]) + ' & ' + generate_latex_cell(table[7]) + ' & ' + generate_latex_cell(table[8]) + '\\\\')
        print('      \\hline')
        print('    \\end{tabular}')
        print('  \\end{center}')
        print('\\end{table}')
        print()

def generate_latex_cell(diff_and_error):
    diff, error = diff_and_error

    # https://stackoverflow.com/a/34032934/16823203 for 'format'
    ret = '{:0.3e}'.format(diff) + ' ± ' + '{:0.3e}'.format(error)

    if contains_zero(diff, error):
        ret = '\\cellcolor[HTML]{d6d6d6} ' + ret

    return ret

def contains_zero(a, b):
    return abs(b) >= abs(a)

#generate_comparison_tables('MatrixMultiplication')

# -- Base benchmarks --
#plot_benchmark('SpawnManyWaiting')
#plot_benchmark('SpawnManyWaitingGroup')
#plot_benchmark('SpawnManyActors')

# -- Applied benchmarks --
#plot_benchmark('Fibonacci')
#plot_benchmark('NQueens')
#plot_benchmark('MatrixMultiplication')

#plot_all_benchmarks_to_file()