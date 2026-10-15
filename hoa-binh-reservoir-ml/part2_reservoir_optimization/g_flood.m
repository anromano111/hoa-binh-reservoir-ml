function g_flo = g_flood(h_HN)
% F = g_flo [cm^2]
ht = h_HN * 100;
hF = 950; % [cm]

diff = ht - hF;
diff(diff < 0) = 0;

g_flo = diff.^2;

end