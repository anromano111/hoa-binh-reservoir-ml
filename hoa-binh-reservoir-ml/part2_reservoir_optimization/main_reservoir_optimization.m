clear
close all
clc

%% PART 2 - OPTIMAL OPERATION OF THE HOA BINH RESERVOIR (EMODPS)
% 1) simulate the current standard operating policy (SOP)
% 2) optimize the 4 SOP parameters with NSGA-II for two objectives:
%    hydropower production (max) and flooding in Hanoi (min)
% 3) evaluate and plot the selected policies (best hydropower, best flood,
%    compromise) saved in results/SelectedPoints.mat
% Run from this folder, or via ../main.m

%% Data import and model setup
addpath ./data
addpath ./sim

global sys_param; % global structure containing model parameters

qq = model_setup([1 11 1994], [31 12 2005]); % structure containing trajectories of Hoa Binh inflow and flow of Thao and Lo rivers


%% simulation of current policy

% set policy parameters
theta = [89,107,1200,2500,5000]; % h1, h2, m1, m2, w

sys_param.reg.h1 = theta(1);
sys_param.reg.h2 = theta(2);
sys_param.reg.m1 = theta(3);
sys_param.reg.m2 = theta(4);
sys_param.reg.w = theta(5);

sys_param.nat.h0 = 80;
sys_param.nat.h_max = 117;

% visualize policy
hh = [75:.5:124] ;
for i=1:length(hh)
    ss(i) = levelToStorage(hh(i));
    rmin(i) = min_release(ss(i));
    rmax(i) = max_release(ss(i));
    uu(i) = std_operating_policy(hh(i), sys_param);
    rr(i) = min(max(uu(i), rmin(i)), rmax(i));
end

figure
plot(hh', rmin', 'LineWidth', 0.7, 'LineStyle', '--')
hold on
plot(hh', rmax', 'LineWidth', 0.7, 'LineStyle', '--')
plot(hh', uu', 'LineWidth', 0.7, 'LineStyle', '-')
xlabel('level [m]')
ylabel('release [m3/s]')
title('Hoa Binh current standard operating policy')
legend('min release', 'max release', 'policy', 'Location', 'northwest')

% set initial condition and run simulation
h_in = 104;
[ h, u, r, ht_HN ] = simHB( qq, h_in, sys_param );

% visualize trajectories
date_day = datetime(1995,1,1):datetime(2005,12,31);
figure
subplot(221); plot(qq.q_Da); title('HB inflow'); xlabel('Time [days]'); ylabel('Inflow [m3/s]') % inflow
subplot(222); plot(h); title('HB level'); xlabel('Time [days]'); ylabel('Level [m]') % HB level
subplot(223); plot(r); title('HB release'); xlabel('Time [days]'); ylabel('Release [m3/s]') % HB release
subplot(224); plot(ht_HN); title('HN level'); xlabel('Time [days]'); ylabel('Level [m]') % level in Hanoi

% compute policy perfomance
gt_hyd = g_hydropower( r(sys_param.warmup+1:end), h(sys_param.warmup+1:end) );
gt_flo = g_flood( ht_HN(sys_param.warmup+1:end) ) ;
Jhyd = mean(gt_hyd);
Jflo = mean(gt_flo);

% figure
% plot(Jflo, Jhyd, 'bo')

%% Optimization via NSGAII

addpath ./NSGA2
global opt_inputs ;
opt_inputs.qq = qq;
opt_inputs.h0 = 104;

pop = 30 ; % number of individuals in the population
gen = 10 ; % number of generations
M = 2 ; % number of objectives
V = 4 ; % number of decision variables (policy parameters)
min_range = [ 85 102 250 400]; % minimum value of each parameter
max_range = [ 100 115 350 2000]; % maximum value of each parameter
[ chr0, chrF ] = nsga_2(pop,gen,M,V,min_range,max_range) ;

% visualize the initial and final population and the performance of the SOP
figure
plot(chr0(:, 6), chr0(:, 5), 'bo')
hold on
plot(chrF(:, 6), chrF(:, 5), 'ro')
plot(Jflo, Jhyd, 'go')

% PERFORMANCE SOP

sys_param.reg.h1 = chrF(15, 1);
sys_param.reg.h2 = chrF(15, 2);
sys_param.reg.m1 = chrF(15, 3);
sys_param.reg.m2 = chrF(15, 4);

hh = [75:.5:124] ;
for i=1:length(hh)
    ss(i) = levelToStorage(hh(i));
    rmin(i) = min_release(ss(i));
    rmax(i) = max_release(ss(i));
    uu(i) = std_operating_policy(hh(i), sys_param);
    rr(i) = min(max(uu(i), rmin(i)), rmax(i));
end

% representation of the optimized policy obtained from one single run of NSGAII
figure
plot(hh', rmin', 'LineWidth', 0.7, 'LineStyle', '--')
hold on
plot(hh', rmax', 'LineWidth', 0.7, 'LineStyle', '--')
plot(hh', uu', 'LineWidth', 0.7, 'LineStyle', '-', 'Color', 'm')
xlabel('level [m]')
ylabel('release [m3/s]')
title('Hoa Binh optimized standard operating policy')
legend('min release', 'max release', 'policy', 'Location', 'northwest')

chrMat = nan(length(chrF), 12);
chrMat(:, 1:6) = chrF(:, 1:6);

%% Combining several NSGA-II runs
% NSGA-II was run several times; the final populations were merged and the
% non-dominated (Pareto-optimal) policies extracted. Three policies were then
% selected (best hydropower, best flood control, compromise) and saved in
% results/SelectedPoints.mat. See plot_pareto_front.py for the merged front.

%% Simulation of the non-dominated policies
% Load the three selected policies and compute both objectives for each.
% Obj: one row per policy; col1 = flooding [cm2], col2 = hydropower [kWh/day]

% import of selected points in the objective space
load(fullfile('results', 'SelectedPoints.mat'))
Obj = nan(3, 2);

h_in = 104;

warmup = 62;

BestHyd.reg.h1 = SelectedPoints(1,1);
BestHyd.reg.h2 = SelectedPoints(1,2);
BestHyd.reg.m1 = SelectedPoints(1,3);
BestHyd.reg.m2 = SelectedPoints(1,4);
BestHyd.reg.w = 5000;
BestHyd.nat.h0 = 80;
BestHyd.nat.h_max = 117;

BestFlood.reg.h1 = SelectedPoints(2,1);
BestFlood.reg.h2 = SelectedPoints(2,2);
BestFlood.reg.m1 = SelectedPoints(2,3);
BestFlood.reg.m2 = SelectedPoints(2,4);
BestFlood.reg.w = 5000;
BestFlood.nat.h0 = 80;
BestFlood.nat.h_max = 117;

Compr.reg.h1 = SelectedPoints(3,1);
Compr.reg.h2 = SelectedPoints(3,2);
Compr.reg.m1 = SelectedPoints(3,3);
Compr.reg.m2 = SelectedPoints(3,4);
Compr.reg.w = 5000;
Compr.nat.h0 = 80;
Compr.nat.h_max = 117;

% COMPUTATION OF THE OBJECTIVES
% compute objectives for best hydropower solution
[ h_BH, u_BH, r_BH, ht_HN_BH ] = simHB( qq, h_in, BestHyd );
Obj(1, 1) = mean( g_flood(ht_HN_BH(warmup+1:end)) );
Obj(1, 2) = mean( g_hydropower(r_BH(warmup+1:end), h_BH(warmup+1:end)) );

% compute objectives for best flooding solution
[ h_BF, u_BF, r_BF, ht_HN_BF ] = simHB( qq, h_in, BestFlood );
Obj(2, 1) = mean( g_flood(ht_HN_BF(warmup+1:end)) );
Obj(2, 2) = mean( g_hydropower(r_BF(warmup+1:end), h_BF(warmup+1:end)) );

% compute objectives for compromise solution
[ h_C, u_C, r_C, ht_HN_C ] = simHB( qq, h_in, Compr );
Obj(3, 1) = mean( g_flood(ht_HN_C(warmup+1:end)) );
Obj(3, 2) = mean( g_hydropower(r_C(warmup+1:end), h_C(warmup+1:end)) );


% COMPUTATION AND REPRESENTATION OF THE THREE SOP (BestHyd, BestFlood, Compromise)
% Best hydropower solution
hh = [75:.5:124] ;
for i=1:length(hh)
    ss(i) = levelToStorage(hh(i));
    rmin(i) = min_release(ss(i));
    rmax(i) = max_release(ss(i));
    uu(i) = std_operating_policy(hh(i), BestHyd);
    rr(i) = min(max(uu(i), rmin(i)), rmax(i));
end

figure
plot(hh', rmin', 'LineWidth', 0.7, 'LineStyle', '--')
hold on
plot(hh', rmax', 'LineWidth', 0.7, 'LineStyle', '--')
plot(hh', uu', 'LineWidth', 0.7, 'LineStyle', '-', 'Color', 'g')
title('Best hydropower SOP')
xlabel('level [m]')
ylabel('release [m3/s]')
legend('min release', 'max release', 'policy', 'Location', 'northwest')

% Best flood solution
hh = [75:.5:124] ;
for i=1:length(hh)
    ss(i) = levelToStorage(hh(i));
    rmin(i) = min_release(ss(i));
    rmax(i) = max_release(ss(i));
    uu(i) = std_operating_policy(hh(i), BestFlood);
    rr(i) = min(max(uu(i), rmin(i)), rmax(i));
end

figure
plot(hh', rmin', 'LineWidth', 0.7, 'LineStyle', '--')
hold on
plot(hh', rmax', 'LineWidth', 0.7, 'LineStyle', '--')
plot(hh', uu', 'LineWidth', 0.7, 'LineStyle', '-', 'Color', 'r')
title('Best flood SOP')
xlabel('level [m]')
ylabel('release [m3/s]')
legend('min release', 'max release', 'policy', 'Location', 'northwest')

% Compromise solution
hh = [75:.5:124] ;
for i=1:length(hh)
    ss(i) = levelToStorage(hh(i));
    rmin(i) = min_release(ss(i));
    rmax(i) = max_release(ss(i));
    uu(i) = std_operating_policy(hh(i), Compr);
    rr(i) = min(max(uu(i), rmin(i)), rmax(i));
end

figure
plot(hh', rmin', 'LineWidth', 0.7, 'LineStyle', '--')
hold on
plot(hh', rmax', 'LineWidth', 0.7, 'LineStyle', '--')
plot(hh', uu', 'LineWidth', 0.7, 'LineStyle', '-', 'Color', 'b')
title('Compromise SOP')
xlabel('level [m]')
ylabel('release [m3/s]')
legend('min release', 'max release', 'policy', 'Location', 'northwest')