function h = storageToLevel(s)

global sys_param;
lsv = sys_param.lsv ;
h = interp_lin_scalar(lsv(:,3), lsv(:,1), s) ;

end