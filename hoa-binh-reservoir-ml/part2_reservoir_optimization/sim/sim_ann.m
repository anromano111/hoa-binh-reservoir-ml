function y = sim_ann(M,n,theta,n_type)

theta = theta(:) ; % must be column vector
[r,N] = size(M) ; % r = # of input, N = # of data
b1 = theta(1:n) ; % (n,1) n is ~ of neuron
i  = n+1 ;
b2 = theta(i)   ; % (1,1)
i  = i+1 ;
LW = theta(i:i+n-1) ;
LW = LW'        ; % (1,n)
i  = i+n;
IW = theta(i:i+n*r-1) ;
IW = reshape( IW, n, r ) ; % (n,r)
% compute the network output: 
y = feval(n_type, IW* M + repmat(b1,1,N) ) ; %n_type is activation fuction of hidden_layer
y = feval('purelin', LW* y + repmat(b2,1,N) ) ;