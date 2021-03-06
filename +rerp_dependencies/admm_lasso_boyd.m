% Copyright (C) 2013 Luca Pion-Tonachini, Matthew Burns, Swartz Center for Computational
% Neuroscience. 
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met: 
% 
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer. 
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution. 
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% The views and conclusions contained in the software and documentation are those
% of the authors and should not be interpreted as representing official policies, 
% either expressed or implied, of the FreeBSD Project.

function [x, u, history] = admm_lasso_boyd(A, b, Atb, lambda, x, u, L)
% lasso  Solve lasso problem via ADMM
%
% [x, u, history] = Final_Lasso_boyd(A, b, lambda);
%
% or if a hot start is available:
%
% [x, u, history] = Final_Lasso_boyd(A, b, lambda, x, u);
%
% or if the LU decomposition is already privded ( from factor() below )
%
% [x, u, history] = Final_Lasso_boyd(A, b, lambda, x, u, L, U);
%
% Solves the following problem via ADMM:
%
%   minimize 1/2*|| Ax - b ||_2^2 + \lambda || x ||_1
%
% The solution is returned in the vector x.
%
% history is a structure that contains the objective value, the primal and
% dual residual norms, and the tolerances for the primal and dual residual
% norms at each iteration.
%
% rho is the augmented Lagrangian parameter.
%
% alpha is the over-relaxation parameter (typical values for alpha are
% between 1.0 and 1.8).
%
%
% More information can be found in the paper linked at:
% http://www.stanford.edu/~boyd/papers/distr_opt_stat_learning_admm.html
%


MAX_ITER = 1000;
ABSTOL   = 1e-4;
RELTOL   = 5e-2;
alpha = 1.5;
rho = 1.5;
U=L'; 
[m, n] = size(A);
z=x; 

fprintf('%3s\t%10s\t%10s\t%10s\t%10s\t%10s\n', 'iter', ...
  'r norm', 'eps pri', 's norm', 'eps dual', 'objective');

for k = 1:MAX_ITER
    % x-update
    q = Atb + rho*(z - u);    % temporary value
    if( m >= n )    % if skinny
        x = U \ (L \ q);
    else            % if fat
        x = q/rho - (A'*(U \ ( L \ (A*q) )))/rho^2;
    end
    
    % z-update with relaxation
    zold = z;
    x_hat = alpha*x + (1 - alpha)*zold;
    z = shrinkage(x_hat + u, lambda/rho);
    
    % u-update
    u = u + (x_hat - z);
    
    % diagnostics, reporting, termination checks
    history.objval(k)  = objective(A, b, lambda, x, z);
    history.r_norm(k)  = norm(x - z);
    history.s_norm(k)  = norm(-rho*(z - zold));
    
    history.eps_pri(k) = sqrt(n)*ABSTOL + RELTOL*max(norm(x), norm(-z));
    history.eps_dual(k)= sqrt(n)*ABSTOL + RELTOL*norm(rho*u);
    
    fprintf('%3d\t%10.4f\t%10.4f\t%10.4f\t%10.4f\t%10.2f\n', k, ...
    history.r_norm(k), history.eps_pri(k), ...
    history.s_norm(k), history.eps_dual(k), history.objval(k));
    
    if (history.r_norm(k) < history.eps_pri(k) && ...
            history.s_norm(k) < history.eps_dual(k))
        break;
    end
    
    % Varying Penalty Parameter
    if (history.r_norm(k)/history.eps_pri(k)) > 10*(history.s_norm(k)/history.eps_dual(k))
        rho = 2*rho;
        u = u/2;
        
    elseif (history.s_norm(k)/history.eps_dual(k)) > 10*(history.r_norm(k)/history.eps_pri(k)) 
        rho = rho/2;
        u = u*2;
    end
    
end

end

function p = objective(A, b, lambda, x, z)
p = ( 1/2*sum((A*x - b).^2) + lambda*norm(z,1) );
end

function z = shrinkage(x, kappa)
z = max( 0, x - kappa ) - max( 0, -x - kappa );
end

