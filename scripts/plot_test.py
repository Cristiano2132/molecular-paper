"""
=============================================================================
AGENT: Statistician (Python Specialist / Bioinformatics)
ROLE : Generate statistical figures for the molecular markers paper.
TASK : Simulate SNP/SSR marker data and export a PIC Boxplot as PDF.
OUTPUT: output/figures/test_plot.pdf
=============================================================================
"""

import os
import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.ticker import MultipleLocator
from pathlib import Path

# ---------------------------------------------------------------------------
# 0. Configuration
# ---------------------------------------------------------------------------
matplotlib.rcParams.update({
    "font.family": "serif",
    "font.size": 11,
    "axes.titlesize": 13,
    "axes.labelsize": 12,
    "xtick.labelsize": 10,
    "ytick.labelsize": 10,
    "legend.fontsize": 10,
    "pdf.fonttype": 42,   # embeds fonts properly in PDF
    "ps.fonttype": 42,
})

OUTPUT_DIR = Path(__file__).parent.parent / "output" / "figures"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

# ---------------------------------------------------------------------------
# 1. Simulate Molecular Marker Data (SNP / SSR)
# ---------------------------------------------------------------------------
def simulate_marker_data(n_markers: int = 60) -> pd.DataFrame:
    """
    Simulate a dataset of molecular markers with allele frequency data.

    Parameters
    ----------
    n_markers : int
        Total number of markers to simulate.

    Returns
    -------
    pd.DataFrame
        DataFrame with columns: Marker, Type, p (major allele freq), q,
        PIC, He (expected heterozygosity), Ho (observed heterozygosity).
    """
    n_snp = int(n_markers * 0.6)
    n_ssr = n_markers - n_snp

    marker_types = ["SNP"] * n_snp + ["SSR"] * n_ssr

    # Major allele frequency (p); minor allele = 1 - p
    # SNPs tend to have higher major allele frequency
    p_snp = np.random.beta(a=6, b=2, size=n_snp)
    p_ssr = np.random.beta(a=3, b=3, size=n_ssr)
    p = np.concatenate([p_snp, p_ssr])
    q = 1 - p

    # PIC (Polymorphism Information Content) for biallelic markers:
    # PIC = 1 - (p^2 + q^2) - 2*(p^2)*(q^2)
    pic = 1 - (p**2 + q**2) - 2 * (p**2) * (q**2)

    # Expected heterozygosity: He = 2pq
    he = 2 * p * q

    # Observed heterozygosity: add biological noise around He
    ho = np.clip(he + np.random.normal(0, 0.04, size=n_markers), 0, 1)

    markers = [f"M{str(i+1).zfill(3)}" for i in range(n_markers)]

    df = pd.DataFrame({
        "Marker": markers,
        "Type":   marker_types,
        "p":      p,
        "q":      q,
        "PIC":    pic,
        "He":     he,
        "Ho":     ho,
    })
    return df


# ---------------------------------------------------------------------------
# 2. Summary Statistics (LaTeX-ready)
# ---------------------------------------------------------------------------
def compute_summary(df: pd.DataFrame) -> pd.DataFrame:
    """Compute summary statistics grouped by marker type."""
    summary = (
        df.groupby("Type")[["PIC", "He", "Ho"]]
        .agg(["mean", "std", "min", "max"])
        .round(4)
    )
    return summary


def export_latex_table(summary: pd.DataFrame, path: Path) -> None:
    """
    Export summary statistics as a LaTeX table (hand-crafted to avoid
    the optional jinja2 / Styler dependency in pandas.to_latex).
    """
    path.parent.mkdir(parents=True, exist_ok=True)

    lines = []
    lines.append(r"\begin{table}[H]")
    lines.append(r"    \centering")
    lines.append(r"    \small")
    lines.append(
        r"    \caption{Summary statistics of simulated molecular markers "
        r"(SNP\,/\,SSR). "
        r"Values are mean\,$\pm$\,SD (min -- max).}"
    )
    lines.append(r"    \label{tab:marker_summary}")
    lines.append(r"    \begin{tabular}{llrrrr}")
    lines.append(r"        \toprule")
    lines.append(
        r"        \textbf{Metric} & \textbf{Type} & "
        r"\textbf{Mean} & \textbf{SD} & \textbf{Min} & \textbf{Max} \\"
    )
    lines.append(r"        \midrule")

    metrics = [("PIC", r"\pic{}"), ("He", r"\he{}"), ("Ho", r"\ho{}")]
    marker_types = ["SNP", "SSR"]

    for i, (col, label) in enumerate(metrics):
        for j, mtype in enumerate(marker_types):
            row = summary.loc[mtype, col]
            mean_v = f"{row['mean']:.4f}"
            std_v  = f"{row['std']:.4f}"
            min_v  = f"{row['min']:.4f}"
            max_v  = f"{row['max']:.4f}"
            # Only print metric label on the first marker type row
            metric_label = label if j == 0 else ""
            lines.append(
                f"        {metric_label} & {mtype} & "
                f"{mean_v} & {std_v} & {min_v} & {max_v} \\\\"
            )
        if i < len(metrics) - 1:
            lines.append(r"        \addlinespace")

    lines.append(r"        \bottomrule")
    lines.append(r"    \end{tabular}")
    lines.append(r"\end{table}")

    content = "\n".join(lines) + "\n"
    path.write_text(content, encoding="utf-8")
    print(f"[Statistician] LaTeX table saved → {path}")


# ---------------------------------------------------------------------------
# 3. Boxplot Figure
# ---------------------------------------------------------------------------
def plot_pic_boxplot(df: pd.DataFrame, output_path: Path) -> None:
    """
    Generate a publication-quality boxplot comparing PIC values
    between SNP and SSR markers.

    Parameters
    ----------
    df : pd.DataFrame
        Simulated marker data.
    output_path : Path
        Destination PDF file path.
    """
    fig, axes = plt.subplots(1, 2, figsize=(9, 5), sharey=False)
    fig.suptitle(
        "Polymorphism Information Content (PIC)\nSNP vs SSR Markers",
        fontsize=14,
        fontweight="bold",
        y=1.01,
    )

    metrics = [("PIC", "PIC Value"), ("He", "Expected Heterozygosity (He)")]
    palette = {"SNP": "#2196F3", "SSR": "#FF7043"}

    for ax, (metric, ylabel) in zip(axes, metrics):
        groups = [df.loc[df["Type"] == t, metric].values for t in ["SNP", "SSR"]]

        bp = ax.boxplot(
            groups,
            patch_artist=True,
            notch=False,
            widths=0.5,
            medianprops=dict(color="black", linewidth=2),
            whiskerprops=dict(linewidth=1.2),
            capprops=dict(linewidth=1.2),
            flierprops=dict(marker="o", markersize=4, alpha=0.5),
        )

        for patch, color in zip(bp["boxes"], palette.values()):
            patch.set_facecolor(color)
            patch.set_alpha(0.75)

        ax.set_xticks([1, 2])
        ax.set_xticklabels(["SNP", "SSR"])
        ax.set_ylabel(ylabel)
        ax.set_xlabel("Marker Type")
        ax.yaxis.set_minor_locator(MultipleLocator(0.05))
        ax.grid(axis="y", linestyle="--", alpha=0.4)
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)

        # Annotate mean
        for i, (grp, color) in enumerate(zip(groups, palette.values()), start=1):
            mean_val = np.mean(grp)
            ax.text(
                i, mean_val + 0.01, f"μ={mean_val:.3f}",
                ha="center", va="bottom", fontsize=8.5, color=color, fontweight="bold",
            )

    legend_patches = [
        mpatches.Patch(color=c, alpha=0.75, label=t)
        for t, c in palette.items()
    ]
    fig.legend(handles=legend_patches, loc="lower center", ncol=2,
               bbox_to_anchor=(0.5, -0.04), frameon=False)

    plt.tight_layout()
    fig.savefig(output_path, format="pdf", bbox_inches="tight", dpi=300)
    plt.close(fig)
    print(f"[Statistician] Figure saved → {output_path}")


# ---------------------------------------------------------------------------
# 4. Main
# ---------------------------------------------------------------------------
def main() -> None:
    print("[Statistician] Starting analysis pipeline...")

    df = simulate_marker_data(n_markers=60)
    print(f"[Statistician] Simulated {len(df)} markers "
          f"({(df.Type=='SNP').sum()} SNP, {(df.Type=='SSR').sum()} SSR)")

    summary = compute_summary(df)
    print("\n[Statistician] Summary Statistics:")
    print(summary.to_string())

    # Export figure
    fig_path = OUTPUT_DIR / "test_plot.pdf"
    plot_pic_boxplot(df, fig_path)

    # Export LaTeX table
    table_path = Path(__file__).parent.parent / "output" / "tables" / "marker_summary.tex"
    export_latex_table(summary, table_path)

    # Save raw data as CSV for reproducibility
    csv_path = Path(__file__).parent.parent / "output" / "data"
    csv_path.mkdir(parents=True, exist_ok=True)
    df.to_csv(csv_path / "simulated_markers.csv", index=False)
    print(f"[Statistician] Raw data saved → {csv_path / 'simulated_markers.csv'}")

    print("\n[Statistician] Pipeline complete. ✓")


if __name__ == "__main__":
    main()
