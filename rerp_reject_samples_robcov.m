% Copyright (C) 2013 Christian Kothe, Swartz Center for Computational Neuroscience
% christian@sccn.ucsd.edu
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

function artifact_indexes = rerp_reject_samples_robcov(EEG, std_cutoff, margin, mu, sig)
import rerp_dependencies.*
% Reject data samples using robust covariance.
%
% In:
%    X : the data (#channels x #samples)
%
%    Cutoff : Cutoff in standard deviations from (robustly estimated) data distribution
%             (default: 5)
%
%    Margin : Optional margin in samples around rejected samples that should also be
%             rejected (default: 0).
%
% Out:
%    X: matrix of retained data samples (#channels x #samples)
%
%    Retained : mask of retained samples

assert(~isempty(EEG.data), 'rerp_reject_samples_robcov: EEG.data must be populated'); 
raw = EEG.data;

if ~exist('std_cutoff','var') || isempty(std_cutoff)
    std_cutoff = 5; 
end

if ~exist('margin','var') || isempty(margin)
    margin = 0; 
end

if ~exist('mu','var') || isempty(mu)
    disp('rerp_reject_samples_robcov: computing robust mean'); 
    mu = median(raw,2); 
end

if ~exist('sig','var') || isempty(sig)
    disp('rerp_reject_samples_robcov: computing robust covariance'); 
    sig = cov_blockgeom(raw); 
end

% truncate/censor the distribution at these (robust) standard deviations for some extra robustness
censor_cutoffs = [-5 4];

% standardize the data
disp('rerp_reject_samples_robcov: sphering data');
X = raw;
X = bsxfun(@minus,X,mu);
X = sqrtm(real(sig))\X;

% calculate the Mahalanobis distance of each sample
sample_dist = sqrt(sum(X.^2));

% estimate the robust mean and std. deviation for this channel
dist = sample_dist;

disp('rerp_reject_samples_robcov: finding EEG distribution'); 
[mu_robust, st_robust] = fit_eeg_distribution(dist); 

% censor values that are extreme outliers for this particular channel
disp('rerp_reject_samples_robcov: censoring extreme outliers');
dist = dist((dist>(mu_robust+st_robust*censor_cutoffs(1))) & (dist<(mu_robust+st_robust*censor_cutoffs(2))));
 
% fit a GEV distribution (and Gamma fallback) to distances and find the mode
disp('rerp_reject_samples_robcov: finding gamma parameters');
params_gam = gamfit(double(dist));
mode_gam = (params_gam(1) - 1)*params_gam(2);

disp('rerp_reject_samples_robcov: finding generalized extreme value parameters');
params_gev = gevfit(dist);

if params_gev(1) ~= 0
    mode_gev = params_gev(3) + params_gev(2)*((1+params_gev(1))^-params_gev(1) - 1)/params_gev(1);
else
    mode_gev = params_gev(3);
end

disp('rerp_reject_samples_robcov: thresholding artifact samples');
mu_fine = min([mode_gam,mode_gev]);

% robustly estimate a truncated normal distribution left of the mode
st_fine = median(abs(dist(dist<mu_fine)-mu_fine))*1.3652;

% calculate z scores relative to that normal distribution
distz = (sample_dist - mu_fine)/st_fine;

% flag everything that is larger than the z score cutoff
keep = distz < std_cutoff;

% also flag a margin around the flagged samples
if margin>0
    offsets = -round(margin):round(margin);
    old_keep = keep;
    for o=length(offsets):-1:1
        keep = keep & old_keep(min(length(keep),max(1,(1:length(keep))+offsets(o)))); end
end

artifact_indexes = ~keep; 
