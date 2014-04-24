function [ out ] = meanw(x, w, d)
%MEANW Weighted mean over first non-singleton dimension
sz=size(x);
if nargin < 3
    d= find(sz > 1,1);
end

if isempty(x)
    x=NaN(size(w));
end

out = sum(x.*w, d)./sum(w, d);
end

