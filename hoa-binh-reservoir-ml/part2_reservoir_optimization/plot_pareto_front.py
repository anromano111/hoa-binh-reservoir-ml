"""Re-plot the hydropower vs. flood trade-off from the saved NSGA-II results (chrMat.mat, SelectedPoints.mat)."""
import sys, numpy as np, scipy.io as sio, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
# Usage: python plot_pareto_front.py [results_dir] [output_png]
res = sys.argv[1] if len(sys.argv) > 1 else "results"
out = sys.argv[2] if len(sys.argv) > 2 else "../figures/pareto_front.png"
chr_ = sio.loadmat(f"{res}/chrMat.mat")["chrMat"]; sel = sio.loadmat(f"{res}/SelectedPoints.mat")["SelectedPoints"]
pts = np.vstack([chr_[:, :6], chr_[:, 6:], sel])
hp, fl = -pts[:, 4] / 1e6, pts[:, 5]
nd = np.array([not np.any((hp >= hp[i]) & (fl <= fl[i]) & ((hp > hp[i]) | (fl < fl[i]))) for i in range(len(hp))])
INK, SEC, MUT, BLUE, ORANGE, GRID = "#0b0b0b", "#52514e", "#898781", "#2a78d6", "#eb6834", "#e6e5e0"
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11})
fig, ax = plt.subplots(figsize=(9, 5.6), dpi=160); fig.patch.set_facecolor("#fcfcfb"); ax.set_facecolor("#fcfcfb")
ax.scatter(hp[~nd], fl[~nd], s=34, color="#c9c8c2", edgecolor="#fcfcfb", lw=1, label="Dominated candidate policies", zorder=2)

ax.scatter(hp[nd], fl[nd], s=40, color=BLUE, edgecolor="#fcfcfb", lw=1.5, label="Pareto-optimal policies (EMODPS / NSGA-II)", zorder=4)
ax.scatter([17.0], [570], s=110, facecolor="#fcfcfb", edgecolor=ORANGE, lw=2.5, label="Current operating policy", zorder=5)
names = ["Best hydropower", "Best flood control", "Selected compromise"]
offs = [(-10, 14), (12, -14), (14, 10)]
for (h, f), n, (dx, dy) in zip(zip(-sel[:, 4] / 1e6, sel[:, 5]), names, offs):
    ax.scatter([h], [f], s=90, color=BLUE, edgecolor=INK, lw=1.5, zorder=6)
    ax.annotate(f"{n}\n{h:.1f} M kWh/day · {f:.0f} cm²", (h, f), xytext=(dx, dy), textcoords="offset points",
                ha="right" if dx < 0 else "left", va="center", fontsize=9.5, color=INK)
ax.annotate("Current\n≈17 M kWh/day · 570 cm²", (17.0, 570), xytext=(0, 26), textcoords="offset points", ha="center", fontsize=9.5, color=INK)
ax.set_yscale("log"); ax.set_yticks([400, 600, 1000, 2000, 4000]); ax.yaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter()); ax.yaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
ax.set_xlabel("Hydropower production, J_HP  [million kWh/day]   →  better", color=SEC)
ax.set_ylabel("Flood damage proxy in Hanoi, J_flo  [cm²]   ↓ better", color=SEC)
ax.set_title("Hoa Binh reservoir: hydropower vs. flood protection trade-off", loc="left", color=INK, fontsize=13, pad=12)
for s in ["top", "right"]: ax.spines[s].set_visible(False)
for s in ["left", "bottom"]: ax.spines[s].set_color(MUT)
ax.tick_params(colors=SEC); ax.grid(True, color=GRID, lw=0.8, zorder=0)
ax.legend(frameon=False, loc="upper left", fontsize=9.5, labelcolor=SEC)
ax.set_xlim(14.3, 20.6); ax.set_ylim(300, 4800); fig.tight_layout(); fig.savefig(out, facecolor=fig.get_facecolor())
print(nd.sum(), "non-dominated of", len(hp))
