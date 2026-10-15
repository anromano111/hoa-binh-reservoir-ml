"""Plot the current vs. selected compromise release policy (Python port of std_operating_policy.m)."""
import sys, numpy as np, scipy.io as sio, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt

out = sys.argv[1] if len(sys.argv) > 1 else "../figures/policy_comparison.png"
mr = np.loadtxt("data/max_release_HoaBinh.txt")            # row 0: level [m], row 1: max release [m3/s]
max_rel = lambda h: np.interp(h, mr[0], mr[1])
H0, H_MAX, W = 80, 117, 5000

def policy(h, h1, h2, m1, m2, w=W):
    r = np.maximum(np.minimum(w + m1 * (h - h1), w), w + m2 * (h - h2))
    r = np.where(h >= H_MAX, max_rel(h), r)
    r = np.where(h < H0, 0, r)
    return np.clip(r, 0, max_rel(h))

sel = sio.loadmat("results/SelectedPoints.mat")["SelectedPoints"]
hh = np.arange(75, 124.01, 0.1)
INK, SEC, MUT, BLUE, ORANGE, GRID = "#0b0b0b", "#52514e", "#898781", "#2a78d6", "#eb6834", "#e6e5e0"
fig, ax = plt.subplots(figsize=(9, 5.2), dpi=160); fig.patch.set_facecolor("#fcfcfb"); ax.set_facecolor("#fcfcfb")
ax.plot(hh, max_rel(hh) / 1e3, color=MUT, lw=1.5, ls="--", label="Max feasible release")
ax.plot(hh, policy(hh, 89, 107, 1200, 2500) / 1e3, color=ORANGE, lw=2, label="Current policy")
ax.plot(hh, policy(hh, *sel[2, :4]) / 1e3, color=BLUE, lw=2, label="Selected compromise policy")
ax.set_xlabel("Reservoir level at Hoa Binh [m]", color=SEC); ax.set_ylabel("Release [thousand m³/s]", color=SEC)
ax.set_title("Release rule: current vs. optimized compromise", loc="left", color=INK, fontsize=13, pad=12)
for s in ["top", "right"]: ax.spines[s].set_visible(False)
for s in ["left", "bottom"]: ax.spines[s].set_color(MUT)
ax.tick_params(colors=SEC); ax.grid(True, color=GRID, lw=0.8); ax.set_xlim(75, 124); ax.set_ylim(0, 46)
ax.legend(frameon=False, loc="upper left", fontsize=9.5, labelcolor=SEC)
fig.tight_layout(); fig.savefig(out, facecolor=fig.get_facecolor())
