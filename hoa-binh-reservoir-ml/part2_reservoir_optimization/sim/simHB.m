function [ h, u, r, ht_HN ] = simHB( qq, h_in, policy )

global sys_param;
% Simulation setting
q_sim = [ nan; qq.q_Da ];
H = length(q_sim) - 1;

% Initialization
[h,s,r,u] = deal(nan(size(q_sim)));

% Start simulation
h(1) = h_in;
s(1) = levelToStorage(h(1));

for t = 1: H
  
  % Compute release decision
  u(t) = std_operating_policy(h(t), policy);
  
  % Hourly integration of mass-balance equation
  [s(t+1), r(t+1)] = massBalance( s(t), u(t), q_sim(t+1) );
  h(t+1) = storageToLevel(s(t+1));
  
end

% routing: ANN model approximating routing in the delta to estimate water level in Hanoi (h_HN)
q_YB_sim = [ nan; qq.q_YB ]  ;
q_VQ_sim = [ nan; qq.q_VQ ]  ;
M = [ r, q_YB_sim, q_VQ_sim ];
N = size(M,1);
M = (M - repmat(sys_param.sh.min_input,N,1))./(repmat(sys_param.sh.max_input,N,1) - repmat(sys_param.sh.min_input,N,1));

ht_HN   = sim_ann(M' , sys_param.hanoi.neuron , sys_param.hanoi.theta , sys_param.hanoi.newron_type )';
ht_HN   = ht_HN * (sys_param.sh.max_output(1) - sys_param.sh.min_output(1)) + sys_param.sh.min_output(1);


% Calculate objectives (daily average of immediate costs)
%q_YB_sim = [ nan; qq.q_YB ]  ;
%q_VQ_sim = [ nan; qq.q_VQ ]  ;
%gt_hyd = g_hydropower( r, h );
%[gt_flo, ht_HN] = g_flood( r, q_YB_sim, q_VQ_sim ) ;

%Jhyd = mean(gt_hyd(sys_param.warmup:end));
%Jflo = mean(gt_flo(sys_param.warmup:end));

end