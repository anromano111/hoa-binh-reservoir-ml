function qq = model_setup(ini_date, fin_date)

global sys_param ;

% Simulation period:
ini_date_m = [ini_date(3), ini_date(2), ini_date(1)];
fin_date_m = [fin_date(3), fin_date(2), fin_date(1)];

% Load inflows
load a_hoabinh_K 
a_hoabinh_K = Kali_tmp;
% Time indices (matlab data): 
idx1 = find( a_hoabinh_K.signal.time(:,1) == datenum( ini_date_m ) ) ;
idx2 = find( a_hoabinh_K.signal.time(:,1) == datenum( fin_date_m ) ) ;
t_dates = time_JD2date([time_date2JD(ini_date):time_date2JD(fin_date)]');
t_nat   = time_date2nat( t_dates ) ; % t_nat(t), t=1,...,N
% Inflow to Hoa Binh:
a = a_hoabinh_K.signal.value(idx1:idx2) ; % a(t+1), t=1,...,N
% Flow from tributaries (Lo and Thao):
load q_yenbai
idx1 = find( q_yenbai.signal.time(:,1) == time_date2JD( ini_date ) ) ;
idx2 = find( q_yenbai.signal.time(:,1) == time_date2JD( fin_date ) ) ;
q_YB = q_yenbai.signal.value(idx1:idx2) ; % q_YB(t+1), t=1,...,N
load q_vuquang
idx1 = find( q_vuquang.signal.time(:,1) == time_date2JD( ini_date ) ) ;
idx2 = find( q_vuquang.signal.time(:,1) == time_date2JD( fin_date ) ) ;
q_VQ = q_vuquang.signal.value(idx1:idx2) ; % q_VQ(t+1), t=1,...,N
qq.q_Da = a;
qq.q_YB = q_YB;
qq.q_VQ = q_VQ;

% Reservoir parameters: min/max release volumes:
load -ascii lsv_rel_HoaBinh.txt
load -ascii max_release_HoaBinh.txt
sys_param.lsv = lsv_rel_HoaBinh';
sys_param.maxRel = max_release_HoaBinh';
% Downstream model parameters:
sys_param.sh.min_input  = [     0     0     0 ];
sys_param.sh.max_input  = [ 58315 31164 36917 ];
sys_param.sh.min_output = [  0     0 ] ;
sys_param.sh.max_output = [ 15 25900 ] ;
load HN_theta_n8_m0.txt
sys_param.hanoi.theta        = HN_theta_n8_m0 ;
sys_param.hanoi.neuron       = 8              ;
sys_param.hanoi.newron_type  = 'tansig'       ;

sys_param.warmup = 62 ; % first day to compute objective functions
end