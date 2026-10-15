clear
close all
clc

%% PART 1 - 5-DAY INFLOW FORECAST FOR THE HOA BINH RESERVOIR
% Identifies a forecast model of the cumulative 5-day inflow to Hoa Binh.
% Steps: data exploration -> deseasonalization (cyclo-stationary mean/std,
% window = 10 days) -> 6 candidate models (3 linear, ANN, CART, Random
% Forest) -> model selection -> predictions on the held-out test set.
% Run from this folder, or via ../main.m

%% INITIAL OPERATIONS (LOADING AND ORGANIZING DATA)
load('-ascii', fullfile('data', 'training_set_contest.txt'))

%   col   1 Hoa Binh STORAGE
%         2 (1) Hoa Binh INFLOW
%         3 (2) FLOW at TaBu <<<
%         4 (3) FLOW at LaiChau <<<
%         5 (4) FLOW at NamGiang <<<
%         6 (5) FLOW at YenBai
%         7 (6) FLOW at VaQuang
%         8 (7) PRECIPITATION at MuongTe
%         9 (8) PRECIPITATION at TamDuong
%         10 (9) PRECIPITATION at Da (SPATIAL AVERAGE RIVER BASIN) <<<
%         11 (10) PRECIPITATION at BaoLac
%         12 (11) PRECIPITATION at BacMe
%         13 (12) PRECIPITATION at HaGiang
%         14 (13) CUMULATIVE 5-day INFLOW at Hoa Binh

T = 365;
n_years = length(training_set_contest)/T;


% VISUALIZE DATA
% visualize some inputs
figure
plot(training_set_contest(:, 1), 'm')
xlim([0 length(training_set_contest)])
xlabel('Time [days]')
ylabel('Volume [m3]')
title('Hoa Binh STORAGE')

figure
plot(training_set_contest(:, 2), 'b')
xlim([0 length(training_set_contest)])
xlabel('Time [days]')
ylabel('Flow [m3/s]')
title('Hoa Binh INFLOW')

figure
plot(training_set_contest(:, 8), 'c')
xlim([0 length(training_set_contest)])
xlabel('Time [days]')
ylabel('Flow [m3/s]')
title('PRECIPITATION at MuongTe')

% visualize output
output = training_set_contest(1:365*n_years,14);

figure
plot(output, 'b')
xlim([0 length(output)])
xlabel('Time [days]')
ylabel('Flow [m3/s]')
title('CUMULATIVE 5-day INFLOW at Hoa Binh')

[mi_out, m_out] = moving_average(output, T, 5);
[sigma2_out, s2_out] = moving_average( (output-m_out).^2, T, 5);
s_out = sqrt(s2_out);

output_des = (output - m_out) ./ s_out;

figure
plot(output_des, 'r')
hold on
yline(0, 'k')
xlim([0 length(output_des)])
xlabel('Time [days]')
ylabel('Flow [m3/s]')
title('DESEASONALIZED CUMULATIVE 5-day INFLOW at Hoa Binh')

tt = repmat([1:365]', n_years, 1);

figure
plot(tt(1:365), output(1:365), 'LineWidth', 0.7)
hold on
plot(tt(1:365), output(1+365:365*2), 'LineWidth', 0.7)
plot(tt(1:365), output(365*2+1:365*3), 'LineWidth', 0.7)
plot(tt(1:365), output(365*3+1:365*4), 'LineWidth', 0.7)
plot(tt(1:365), output(365*4+1:365*5), 'LineWidth', 0.7)
plot(tt(1:365), output(365*5+1:365*6), 'LineWidth', 0.7)
plot(tt(1:365), output(365*6+1:365*7), 'LineWidth', 0.7)
plot(mi_out, 'Color', 'r', 'LineWidth', 1.5)
xlim([0 365])
xlabel('Time [days]')
ylabel('Flow [m3/s]')
title('Cumulative 5-day inflow at Hoa Binh and moving average')
legend('year 1', 'year 2', 'year 3', 'year 4', 'year 5', 'year 6', 'year 7', 'moving average')

% organizing data for training and validation

in = training_set_contest(1:365*5, 2:end-1);            % input data for training (storage not considered)
y = training_set_contest(1:365*5, 14);                   % output for training

in_v = training_set_contest(365*5+1:end, 2:end-1);      % input data for validation (storage not considered)
y_v = training_set_contest(365*5+1:end, 14);             % output for validation

% REMOVING SEASONALITY
% detrending inputs
m_in = zeros(365*5, 12);
s_in = zeros(365*5, 12);

m_inv = zeros(365*2, 12);
s_inv = zeros(365*2, 12);

for i = 1:12
[mi, m] = moving_average(in(:,i), T, 5);  % moving_average (window = 10)
[sigma2, s2] = moving_average( (in(:,i) - m).^2, T, 5);
s = sqrt(s2);

m_in(:,i) = m;
s_in(:,i) = s;
end

for i = 1:12
[mi, m] = moving_average(in_v(:,i), T, 5);
[sigma2, s2] = moving_average( (in_v(:,i) - m).^2, T, 5);
s = sqrt(s2);

m_inv(:,i) = m;
s_inv(:,i) = s;
end

in_des = (in - m_in) ./ s_in;
inv_des = (in_v - m_inv) ./ s_inv;

% detrending output
[mi_y, m_y] = moving_average(y, T, 5);
[sigma2_y, s2_y] = moving_average( (y-m_y).^2, T, 5);
s_y = sqrt(s2_y);

[mi_yv, m_yv] = moving_average(y_v, T, 5);
[sigma2_yv, s2_yv] = moving_average( (y_v-m_yv).^2, T, 5);
s_yv = sqrt(s2_yv);

y_des = (y - m_y) ./ s_y;
yv_des = (y_v - m_yv) ./ s_yv;

%% MODELLING

% correlogram (scatter matrix of all variables)
figure
plotmatrix(training_set_contest, training_set_contest)


% LINEAR MODEL - ALL COLUMNS
% calibration
z = y_des(2:end);
M = in_des(1:end-1, :);
theta = M \ z;

z_ = [ y_des(1) ; M*theta ];
y_est = z_ .* s_y + m_y;

R2 = 1 - sum((y(2:end)-y_est(2:end)).^2) / ...
    sum((y(2:end)-m_y(2:end)).^2)
% R2 = 0.4003

% plot(1:1825, [y, y_est])

% validation
zv = yv_des(2:end);
Mv = inv_des(1:end-1, :);
zv_ = [ yv_des(1) ; Mv*theta ];
yv_est = zv_ .* s_yv + m_yv;

R2_v = 1 - sum((y_v(2:end)-yv_est(2:end)).^2) / ...
    sum((y_v(2:end)-m_yv(2:end)).^2)
% R2_v = 0.4153

% saving R2
R2_compare = nan(6,2);      % col1 = training, col2 = validation
R2_compare(1, 1:2) = [ R2 R2_v ];

% computing and saving MSE
MSE_compare = nan(6,2); % col1 = training, col2 = validation
MSE_compare(1,1) = sum((y(2:end)-y_est(2:end)).^2) / (length(y)-1);
MSE_compare(1,2) = sum((y_v(2:end)-yv_est(2:end)).^2) / (length(y_v)-1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LINEAR MODEL - MOST SIGNIFICANT COLUMNS (flows only)

% calibration
z = y_des(2:end);
M = in_des(1:end-1, 1:6);
theta = M \ z;

z_ = [ y_des(1); M*theta ];
y_est = z_ .* s_y + m_y;


R2 = 1 - sum((y(2:end)-y_est(2:end)).^2) / ...
    sum((y(2:end)-m_y(2:end)).^2)
% R2 = 0.4003
% R2 only fluxes = 0.3756

% plot(1:1825, [y, y_est])

% validation
zv = yv_des(2:end);
Mv = inv_des(1:end-1, 1:6);
zv_ = [ yv_des(1); Mv*theta ];
yv_est = zv_ .* s_yv + m_yv;

R2_v = 1 - sum((y_v(2:end)-yv_est(2:end)).^2) / ...
    sum((y_v(2:end)-m_yv(2:end)).^2)
% R2_v = 0.4153
% R2_v only fluxes = 0.3483

% saving R2      
R2_compare(2, 1:2) = [ R2 R2_v ];

% computing and saving MSE
MSE_compare(2,1) = sum((y(2:end)-y_est(2:end)).^2) / (length(y)-1);
MSE_compare(2,2) = sum((y_v(2:end)-yv_est(2:end)).^2) / (length(y_v)-1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LINEAR MODEL WITH DELAY

%%% precipitation at t-1 %%%
% calibration
z = y_des(3:end);
M = [ in_des(2:end-1, 1:6) in_des(1:end-2, 7:12)];
theta = M \ z;

z_ = [ y_des(1); y_des(2); M*theta ];
y_est = z_ .* s_y + m_y;


R2 = 1 - sum((y(3:end)-y_est(3:end)).^2) / ...
    sum((y(3:end)-m_y(3:end)).^2)
% R2 = 0.4003
% R2_v (delayed) = 0.3662

% validation

zv = yv_des(3:end);
Mv = [inv_des(2:end-1, 1:6) inv_des(1:end-2, 7:12)];
zv_ = [ yv_des(1); yv_des(2); Mv*theta ];
yv_est = zv_ .* s_yv + m_yv;

R2_v = 1 - sum((y_v(3:end)-yv_est(3:end)).^2) / ...
    sum((y_v(3:end)-m_yv(3:end)).^2)
% R2_v =  0.4153
% R2_v (delayed) = 0.3445

% saving R2      
R2_compare(3, 1:2) = [ R2 R2_v ];

% computing and saving MSE
MSE_compare(3,1) = sum((y(2:end)-y_est(2:end)).^2) / (length(y)-1);
MSE_compare(3,2) = sum((y_v(2:end)-yv_est(2:end)).^2) / (length(y_v)-1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ANN - multiple calibrations
X = in_des(1:end-1, :);
Y = y_des(2:end);
Xv = inv_des(1:end-1, :);

tic
N_runs = 30;
R2 = zeros(N_runs, 2); % col1 = train , col2 = validation
for i = 1:N_runs
    net_i = feedforwardnet(5, 'trainlm');
    net_i = train(net_i, X', Y');
    
    Y_ = [ y_des(1) ; net_i(X')' ];
    y_est_i = Y_ .* s_y + m_y ;
    R2(i, 1) = 1 - sum((y(2:end)-y_est_i(2:end)).^2) / ...
        sum((y(2:end)-m_y(2:end)).^2);
    
    Y_v = [ yv_des(1) ; net_i(Xv')' ];
    yv_est_i = Y_v .* s_yv + m_yv ;
    R2(i, 2) = 1 - sum((y_v(2:end)-yv_est_i(2:end)).^2) / ...
        sum((y_v(2:end)-m_yv(2:end)).^2);    
    
    % saving the best model (in validation) as net_opt
    if R2(i, 2) >= max(R2(:, 2))
        net_opt = net_i ;
        y_est_ann = y_est_i ;
        yv_est_ann = yv_est_i ;
    end
end
toc

figure
bar(R2)

[max_v, j] = max(R2(:, 2));
max_t = R2(j, 1);

% R2_v_max = 0.4886

% saving R2      
R2_compare(4, 1:2) = [ max_t max_v ];

% computing and saving MSE
MSE_compare(4,1) = sum((y(2:end)-y_est_ann(2:end)).^2) / (length(y)-1);
MSE_compare(4,2) = sum((y_v(2:end)-yv_est_ann(2:end)).^2) / (length(y_v)-1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CART
% training and predicting
tree = fitrtree(in_des(1:end-1, :), y_des(2:end), 'OptimizeHyperparameters', 'auto');
Y_pro = [ y_des(1); predict(tree, in_des(1:end-1, :)) ];
y_est = Y_pro .* s_y + m_y ;
R2 = 1 - sum((y(2:end)-y_est(2:end)).^2) / ...
    sum((y(2:end)-m_y(2:end)).^2)
% R2_cart_pro = 0.5516

% validation
Xv = inv_des(1:end-1, :);
Yv_pro = [ yv_des(1); predict(tree, Xv) ];
yv_est = Yv_pro .* s_yv + m_yv;
R2_v = 1 - sum((y_v(2:end)-yv_est(2:end)).^2) / ...
    sum((y_v(2:end)-m_yv(2:end)).^2)
% R2_cart_prov = 0.3566

% saving R2      
R2_compare(5, 1:2) = [ R2 R2_v ];

% computing and saving MSE
MSE_compare(5,1) = sum((y(2:end)-y_est(2:end)).^2) / (length(y)-1);
MSE_compare(5,2) = sum((y_v(2:end)-yv_est(2:end)).^2) / (length(y_v)-1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% RANDOM FOREST - multiple calibrations
tic
N_runs = 30;
R2 = zeros(N_runs, 2);
for i = 1:N_runs
    t_i = templateTree('MinLeafSize', 10);
RF_i = fitrensemble(in_des(1:end-1, :), y_des(2:end), 'Method', 'Bag', ...
    'Learners', t_i, ...
    'NumLearningCycles', 20);

    Y_ = [ y_des(1) ; predict(RF_i, in_des(1:end-1, :)) ];
    y_est_i = Y_ .* s_y + m_y ;
    R2(i, 1) = 1 - sum((y(2:end)-y_est_i(2:end)).^2) / ...
        sum((y(2:end)-m_y(2:end)).^2);
    
    Y_v = [ yv_des(1) ; predict(RF_i, inv_des(1:end-1, :)) ];
    yv_est_i = Y_v .* s_yv + m_yv ;
    R2(i, 2) = 1 - sum((y_v(2:end)-yv_est_i(2:end)).^2) / ...
        sum((y_v(2:end)-m_yv(2:end)).^2);    
    
    % saving the best model (in validation) as RF_opt
    if R2(i, 2) >= max(R2(:, 2))
        RF_opt = RF_i ;
        y_est_rf = y_est_i ;
    end
end
toc

figure
bar(R2)

% validation
Xv = inv_des(1:end-1, :);
Yv = yv_des(2:end);
Yv_pro = [ yv_des(1); predict(RF_opt, Xv) ];
yv_est = Yv_pro .* s_yv + m_yv;
R2_RF_optv = 1 - sum((y_v(2:end)-yv_est(2:end)).^2) / ...
    sum((y_v(2:end)-m_yv(2:end)).^2)

% R2_RF_optv = 0.5088

[max_v, j] = max(R2(:, 2));
max_t = R2(j, 1);

% saving R2      
R2_compare(6, 1:2) = [ max_t max_v ];

% computing and saving MSE
MSE_compare(6,1) = sum((y(2:end)-y_est_rf(2:end)).^2) / (length(y)-1);
MSE_compare(6,2) = sum((y_v(2:end)-yv_est(2:end)).^2) / (length(y_v)-1);

figure
plot(y_v, 'Color', 'b', 'LineWidth', 0.7)
hold on
plot(yv_est, 'Color', 'r', 'LineWidth', 0.7)
xlim([0 length(y_v)])
xlabel('Time [days]')
ylabel('Flow [m3/s]')
title('CUMULATIVE 5-day INFLOW at Hoa Binh')
legend('data', 'prediction')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% VISUALIZE R2
X = categorical({'linAllCol' 'linOnlyFlow' 'linDelay' 'ANN' 'CART' 'RF'});
X = reordercats(X,{'linAllCol' 'linOnlyFlow' 'linDelay' 'ANN' 'CART' 'RF'});

figure
bar(X, R2_compare)
xlabel('type of model')
ylabel('R2 value [-]')
title('R2 of the different models')
legend('training', 'validation', 'Location', 'northwest')

% VISUALIZE MSE
figure
bar(X, MSE_compare)
xlabel('type of model')
ylabel('MSE value [(m3/s)^2]')
title('MSE of the different models')
legend('training', 'validation', 'Location', 'northeast')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TEST SET PREDICTIONS - RF
 
load('-ascii', fullfile('data', 'test_set_contest.txt'))
input = test_set_contest(:, 2:end);

T = 365;
n_years = length(test_set_contest)/T;

% detrending inputs
m_input = zeros(365*5, 12);
s_input = zeros(365*5, 12);

for i = 1:12
[mi, m] = moving_average(input(:,i), T, 5);  % moving_average (window = 10)
[sigma2, s2] = moving_average( (input(:,i) - m).^2, T, 5);
s = sqrt(s2);

m_input(:,i) = m;
s_input(:,i) = s;
end

input_des = (input - m_input) ./ s_input;

% predicting the output with RF_opt
output_des = predict(RF_opt, input_des);
output = output_des .* s_y + m_y;

% visualize output
figure
plot(output, 'b')
xlim([0 length(output)])
xlabel('Time [days]')
ylabel('Flow [m3/s]')
title('PREDICTED CUMULATIVE 5-day INFLOW at Hoa Binh')

% save test-set predictions (same format as the input data)
if ~exist('results', 'dir'); mkdir('results'); end
save(fullfile('results', 'test_set_predictions.txt'), 'output', '-ascii')

%% LOCAL FUNCTIONS
function [ mi , ym ] = moving_average( y , T , f )

% [ mi , ym ] = moving_average( y , T , f )
% 
% input:
% - y  --> time-series
% - T  --> period
% - f  --> semi-amplitude of the window
%
% output:
% - mi --> periodic moving average
% - ym --> periodic moving average repeated for the length of the
%          time-series.
%


N_years  = length( y ) / T;
Y        = reshape( y , T , N_years );

Y_       = [ Y( end - f + 1 : end , end ) , Y( end - f + 1 : end , 1 : end - 1 ); ...
            Y; ...
            Y( 1:f, 2 : end )  , Y( 1 : f , 1 )];

mi      = zeros( T , 1 );
for k = 1 : T
    mi( k ) = mean( mean( Y_( k : k + 2*f , : ) ) );
end
ym      = repmat( mi , N_years , 1 );
end
