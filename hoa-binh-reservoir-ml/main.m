%% HOA BINH RESERVOIR - ML INFLOW FORECASTING & MULTI-OBJECTIVE OPTIMIZATION
% Single entry point: runs the whole project in order.
%
%   Part 1 - forecast the cumulative 5-day inflow (linear, ANN, CART, Random Forest)
%   Part 2 - optimize the reservoir release policy with EMODPS / NSGA-II
%
% Requirements: MATLAB R2016b or newer, Statistics and Machine Learning
% Toolbox, Deep Learning Toolbox.
% Note: each part starts with "clear", so results are not kept between parts.

root = fileparts(mfilename('fullpath'));

fprintf('\n=== Part 1: 5-day inflow forecast ===\n');
run(fullfile(root, 'part1_inflow_forecast', 'main_inflow_forecast.m'));

root = fileparts(mfilename('fullpath'));   % restored after the "clear" in Part 1
fprintf('\n=== Part 2: reservoir optimization (EMODPS) ===\n');
run(fullfile(root, 'part2_reservoir_optimization', 'main_reservoir_optimization.m'));
