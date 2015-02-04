function [ max_sv1, max_sv2] = get_largest_sv(B, Uc, Sc)
%GET_LARGEST_SV Summary of this function goes here
%   Detailed explanation goes here
[Ub, Sb] = svds(B);

W=diag(diag(1./diag(Sb))*Ub'*Uc*Sc);
gz = W > 0; 
max_sv1=min(W(gz)); 

W=diag(diag(1./diag(Sb))*Sc);
gz = W > 0;
max_sv2=min(W(gz)); 

if isempty(max_sv1)
    max_sv1=NaN;
end

if isempty(max_sv2)
    max_sv2=NaN;
end
end

