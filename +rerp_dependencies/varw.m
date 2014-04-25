function [ out ] = varw(x, w, d)
%VARW Weighted variance. Ignores NaNs in x. 

sz=size(x);
if nargin < 3
    d= find(sz > 1,1);
end

%Ignore NaN in the average
nan_idx = isnan(x);
x(nan_idx)=0;
w(nan_idx)=0;

%If no weights are given, use equal weights
if isempty(w)
    w=ones(size(x));
end

%x is empty, return NaN
if isempty(x)
    x=NaN(size(w));
end

out = var(x, w, d); 
end


