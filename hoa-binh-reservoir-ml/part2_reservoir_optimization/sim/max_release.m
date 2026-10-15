function V = max_release(s)

global sys_param;
MR = sys_param.maxRel ;
h = storageToLevel(s);
V = interp_lin_scalar(MR(:,1), MR(:,2), h) ;

end