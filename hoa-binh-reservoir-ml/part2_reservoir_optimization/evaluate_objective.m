function f = evaluate_objective(x, M, V)
%
% function f = evaluate_objective(x, M, V)
%
% Function to evaluate the objective functions for the given input vector x.%
% x is an array of decision variables and f(1), f(2), etc are the
% objective functions. The algorithm always minimizes the objective
% function hence if you would like to maximize the function then multiply
% the function by negative one. M is the numebr of objective functions and
% V is the number of decision variables. 
%
% This functions is basically written by the user who defines his/her own
% objective function. Make sure that the M and V matches your initial user
% input.
%

x = x(1:V) ;
x = x(:)   ;

% --------------------------------------
% insert here your function:
% global variable to pass inside extra inputs
global opt_inputs ;
global sys_param ;
qq = opt_inputs.qq ;
h0 = opt_inputs.h0 ;

% 1) policy param
sys_param.reg.h1 = x(1);
sys_param.reg.h2 = x(2);
sys_param.reg.m1 = x(3);
sys_param.reg.m2 = x(4);

% 2) run simulation
[ h, u, r, ht_HN ] = simHB( qq, h0, sys_param );

% 3) compute objs
g_hyd = g_hydropower(r(sys_param.warmup+1:end), h(sys_param.warmup+1:end));
g_flo = g_flood(ht_HN(sys_param.warmup+1:end));
Jhyd = mean(g_hyd);
Jflo = mean(g_flo);

f = [ -Jhyd, Jflo ];
% --------------------------------------

% Check for error
if length(f) ~= M
    error('The number of decision variables does not match you previous input. Kindly check your objective function');
end