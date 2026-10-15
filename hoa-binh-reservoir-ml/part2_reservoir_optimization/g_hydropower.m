function g_hyd = g_hydropower( r, h )
% P = g_hyd [kWh/d]
k = 86400/(3.6*10^6)*1000; % [s/day * kWh/J * kg/m3]
eta_ = 0.85;
qT_max = 2360; % [m3/s]
qT_min = 38; % [m3/s]

% initialization
P = nan(size(h));
eta = nan(size(h));
csi = nan(size(h));
qT = nan(size(h));
deltah = nan(size(h));

for t = 1:length(h)
    qT(t) = min(r(t), qT_max);
    if qT(t) < qT_min
        qT(t) = 0;
    end
    csi(t) = 0.000000000003663570691434010 * r(t)^3 - 0.000000136377708978325 * r(t)^2 + 0.00208777089783313 * r(t) + 11.6601651186797;
    deltah(t) = h(t) - csi(t);
    eta(t) = eta_ * (-0.000747602341932219 * deltah(t)^2 + 0.137069286795915 * deltah(t) + 3.02854144738924);
    P(t) = k * eta(t) * qT(t) * deltah(t);
end

g_hyd = P;

end