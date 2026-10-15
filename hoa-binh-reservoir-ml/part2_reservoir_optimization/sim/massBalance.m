function [s1,r1] = massBalance( s, u, q )


HH = 24; % hourly integration
delta = 3600;
s_ = nan(HH+1,1);
r_ = nan(HH+1,1);

s_(1) = s;
for i=1:HH
  qm = min_release(s_(i));
  qM = max_release(s_(i));
  r_(i+1) = min( qM , max( qm , u ) );
  s_(i+1) = s_(i) + delta*( q - r_(i+1) );
end

s1 = s_(HH);
r1 = mean(r_(2:end));
