# 🌊 Hoa Binh Reservoir: ML Inflow Forecasting & Multi-Objective Optimal Operation

**Forecasting inflows to one of Vietnam's largest hydropower reservoirs, then redesigning its operating policy to produce more electricity *and* reduce flood risk in Hanoi.**

![MATLAB](https://img.shields.io/badge/MATLAB-Statistics%20%26%20ML%20Toolbox-orange) ![Python](https://img.shields.io/badge/Python-matplotlib-blue) ![Topic](https://img.shields.io/badge/topic-water%20resources-1baf7a) ![Course](https://img.shields.io/badge/Politecnico%20di%20Milano-Natural%20Resources%20Management-lightgrey)

![Pareto front](figures/pareto_front.png)

## ✨ Key results

| | Hydropower J_HP [kWh/day] | Flood index J_flo [cm²] |
|---|---|---|
| Current operating policy | ≈ 1.7 × 10⁷ | ≈ 570 |
| **Selected compromise policy** | **1.82 × 10⁷ (≈ +7%)** | **456 (≈ −20%)** |
| Best for hydropower only | 1.99 × 10⁷ | 4004 |
| Best for flood control only | 1.49 × 10⁷ | 382 |

- **Win–win policy found.** The selected policy *dominates* the current one: it produces more hydropower and lowers flood exposure in Hanoi at the same time.
- **Inflow forecasting.** Out of 6 model families, a **Random Forest** gave the best 5-day inflow forecast (validation R² ≈ 0.51). It matched the neural network's accuracy and ran about 12× faster (10 s vs 120 s for 30 calibration runs).

---

## 🗺️ Context

The **Red River basin** (169,000 km² across China, Vietnam and Laos) feeds the **Hoa Binh reservoir** on the Da river. The reservoir serves two goals that pull against each other:

- **Hydropower:** keep water levels high to maximize head and energy output.
- **Flood protection:** keep storage free to absorb monsoon peaks before they reach **Hanoi** (more than 16 million people in the metropolitan area).

The project has two parts:

1. **Forecast** the cumulative 5-day inflow to the reservoir from upstream flows and precipitation (ML).
2. **Optimize** the reservoir release policy for both objectives with Evolutionary Multi-Objective Direct Policy Search (EMODPS).

---

## Part 1: 5-day inflow forecasting (machine learning)

**Data:** 7 years of daily observations for training and validation, plus 5 years for the held-out test set. The 12 inputs are flows at 5 upstream gauges (TaBu, LaiChau, NamGiang, YenBai, VuQuang), reservoir inflow, and precipitation at 6 stations. The target is the cumulative 5-day inflow at Hoa Binh.

**Pipeline**

1. **Exploration:** a scatter matrix showed that upstream *flows* are strongly correlated with the target while precipitation is only weakly correlated. Storage was dropped because it is not a valid predictor.
2. **Deseasonalization (Box–Jenkins):** a cyclo-stationary mean and standard deviation, estimated with a periodic moving average (window = 10 days), were removed from every series and added back after prediction.
3. **Split:** first 5 years for training, last 2 for validation.
4. **Model comparison:** six structures, each a proper one-step-ahead model.

| Model | Setup | R² train | R² validation |
|---|---|---|---|
| Linear, all inputs | least squares | 0.40 | 0.42 |
| Linear, flows only | least squares | 0.38 | 0.35 |
| Linear + lagged rain | precipitation at t−1 | 0.37 | 0.34 |
| ANN | 1 hidden layer, 5 neurons, Levenberg–Marquardt, best of 30 runs | ≈ 0.43 | 0.49 |
| CART | auto hyper-parameter optimization | 0.55 | 0.36 |
| **Random Forest** ✅ | bagging, 20 trees, MinLeafSize = 10, best of 30 runs | ≈ 0.70 | **0.51** |

**Model selection:** RF and ANN are the only models that capture the nonlinear dynamics. RF was chosen because it had the **best validation R²** at **about 1/12 of the compute cost**, applying the course's accuracy-versus-complexity criterion.

| R² by model | Validation: observed vs. predicted (RF) |
|---|---|
| ![R2](figures/r2_comparison.png) | ![Validation](figures/validation_prediction.png) |

The final RF model was then used to generate the forecasts submitted for the 5-year test set, whose true outputs were held out by the instructors.

---

## Part 2: Optimal reservoir operation (EMODPS)

**Objectives** (simulated daily over 1995–2005, after a warm-up period):

- **J_HP:** mean daily hydropower production [kWh/day]. Computed from release, net head and turbine efficiency curves. *Maximize.*
- **J_flo:** mean daily squared water-level excess above the 9.5 m flood threshold in Hanoi [cm²]. *Minimize.*

**Method**

1. **Baseline:** simulated the current *standard operating policy* (SOP), a piecewise-linear release rule as a function of reservoir level, with the reservoir mass-balance model.
2. **Direct Policy Search:** parameterized the SOP by 4 decision variables (level thresholds h₁, h₂ and slopes m₁, m₂) and searched over them directly.
3. **Multi-objective evolutionary search:** ran **NSGA-II** several times (population 30, 10 generations per run), merged the final populations and extracted the **Pareto front** of non-dominated policies.
4. **Decision:** picked a compromise policy that improves on the current policy in *both* objectives.

![Policy comparison](figures/policy_comparison.png)

**How the new rule works:** the compromise policy releases less water at low levels, which keeps the head higher for hydropower. From about 102 m it starts releasing earlier and more gradually, creating flood-storage room before monsoon peaks instead of dumping water once the reservoir is nearly full.

---

## 📁 Repository structure

```
├── main.m                                       # ▶ run the whole project (Part 1 → Part 2)
├── report/Hoa_Binh_reservoir_report.pdf         # full project report
├── figures/                                     # figures used in this README
├── part1_inflow_forecast/
│   ├── main_inflow_forecast.m                   # EDA, deseasonalization, 6 models, test predictions
│   └── data/                                    # training_set_contest.txt, test_set_contest.txt
└── part2_reservoir_optimization/
    ├── main_reservoir_optimization.m            # baseline simulation, NSGA-II, selected policies
    ├── evaluate_objective.m                     # objective function called by NSGA-II
    ├── g_hydropower.m, g_flood.m                # step-cost functions
    ├── std_operating_policy.m                   # parameterized release rule
    ├── plot_pareto_front.py                     # re-creates figures/pareto_front.png
    ├── plot_policies.py                         # re-creates figures/policy_comparison.png
    ├── sim/                                     # reservoir & river simulation model (course-provided)
    ├── NSGA2/                                   # NSGA-II implementation (third-party)
    ├── data/                                    # hydrological inputs & reservoir curves
    └── results/                                 # saved NSGA-II populations and selected policies
```

## ▶️ How to run

**Requirements:** MATLAB R2016b or newer, with the Statistics and Machine Learning Toolbox and the Deep Learning Toolbox (for `feedforwardnet`).

```matlab
main   % runs Part 1 (forecasting) and then Part 2 (optimization)
```

Each part can also be run on its own: `part1_inflow_forecast/main_inflow_forecast.m` or `part2_reservoir_optimization/main_reservoir_optimization.m`. Part 1 writes its test-set forecast to `part1_inflow_forecast/results/test_set_predictions.txt`.

To re-create the Pareto and policy figures in Python:

```bash
pip install -r requirements.txt
cd part2_reservoir_optimization
python plot_pareto_front.py
python plot_policies.py
```

                                                 ## 🔍 Limitations & next steps

- Validation inputs were standardized with their own seasonal statistics. A stricter set-up would reuse the training-period statistics to rule out any information leakage.
- Validation used a single split. Year-wise (blocked) cross-validation would give more robust skill estimates.
- The next step would be to feed the 5-day inflow forecast into the operating policy (forecast-informed operation) and compare it against the level-only rule.

                                                 ## 👥 Team & credits

Team project for **Natural Resources Management** (Prof. A. Castelletti, Prof. M. Giuliani, tutor M. Sangiorgio), M.Sc. Environmental and Land Planning Engineering, **Politecnico di Milano**, A.Y. 2021/22.

**Author:** Andrea Romanò ·

The simulation model and datasets were provided by the course (Environmental Intelligence Lab, PoliMi) for educational purposes. The NSGA-II implementation is by Aravind Seshadri (2009).
