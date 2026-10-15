function r = std_operating_policy(h, policy)

% -- Get policy parameters --
h1 = policy.reg.h1;
h2 = policy.reg.h2;
m1 = policy.reg.m1;
m2 = policy.reg.m2;
w = policy.reg.w;

% -- Construct the policy using piecewise linear functions --

L1 = policy.reg.w + policy.reg.m1 * (h - policy.reg.h1);
L2 = policy.reg.w + policy.reg.m2 * (h - policy.reg.h2);
r = max( min(L1, policy.reg.w), L2 );

r(h >= policy.nat.h_max) = max_release(levelToStorage(h));

r(h < policy.nat.h0) = 0;

idx = r > max_release(levelToStorage(h));
r(idx) = max_release(levelToStorage(h));

% -- Verify release are non-negative  --

r(r < 0) = 0;

end