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

function [mu,sig] = fit_eeg_distribution(x,min_clean_fraction,max_dropout_fraction,fit_quantiles,step_sizes,num_bins)
% Fit a truncated Gaussian to possibly contaminated EEG data.
% [Mu,Sigma] = fit_eeg_distribution(X,MinCleanFraction,MaxDropoutFraction,FitQuantiles,StepSizes,NumBins)
%
% This function assumes that the observations are EEG amplitude values that can be characterized
% as a Gaussian component (the clean data) with a heavy and potentially peaky tail, and possibly a 
% relatively small fraction of samples with amplitude below that of the Gaussian component.
% 
% The method works by finding a quantile range that best fits a truncated Gaussian (in terms of KL 
% divergence), using a grid search over a range of the data that is restricted by MinCleanFraction
% and MaxDropoutFraction.
%
% In:
%   X : vector of amplitude values of EEG, possible containing artifacts 
%       (coming from single samples or windowed averages)
%
%   MinCleanFraction : Minimum fraction of values in X that needs to be clean
%                      (default: 0.25)
%
%   MaxDropoutFraction : Maximum fraction of values in X that can be subject to
%                        signal dropouts (e.g., sensor unplugged) (default: 0.1)
%
%   FitQuantiles : Quantile range [upper,lower] of the truncated Gaussian distribution 
%                  that shall be fit to the EEG contents (default: [0.022 0.6])
%
%   StepSizes : Step size of the grid search; the first value is the stepping of the lower bound
%               (which essentially steps over any dropout samples), and the second value
%               is the stepping over possible scales (i.e., clean-data quantiles) 
%               (default: [0.01 0.01])
%
%   NumBins : Number of bins for Kullback-Leibler divergence calculation (default: 50)
%
% Out:
%   Mu : estimated mean of the distribution
%
%   Sigma : estimated standard deviation of the distribution
%
% Notes:
%   For small numbers of samples (<10000) it may help to use fewer bins.
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2013-08-15

% assign defaults
if ~exist('min_clean_fraction','var') || isempty(min_clean_fraction)
    min_clean_fraction = 0.25; end
if ~exist('max_dropout_fraction','var') || isempty(max_dropout_fraction)
    max_dropout_fraction = 0.1; end
if ~exist('fit_quantiles','var') || isempty(fit_quantiles)
    fit_quantiles = [0.022 0.6]; end
if ~exist('step_sizes','var') || isempty(step_sizes)
    step_sizes = [0.01 0.01]; end
if ~exist('num_bins','var') || isempty(num_bins)
    num_bins = 50; end

% sort data so we can access quantiles directly
x = sort(x(:));
n = length(x);

% generate a binned approximation for the truncated Gaussian pdf
series = (0:num_bins)/num_bins; series(end) = Inf;
bounds = -sqrt(2)*erfcinv(2*[min(fit_quantiles) max(fit_quantiles)]);
p = exp(-0.5*(bounds(1)+(0:(num_bins-1))/(num_bins-1)*diff(bounds)).^2)/(sqrt(2*pi)); p=p'/sum(p);

% determine the limits for the grid search
lower_min = min(fit_quantiles);                     % we can generally skip the tail below the lower quantile
min_width = min_clean_fraction*diff(fit_quantiles); % minimum width of the fit interval, as fraction of data
max_width = diff(fit_quantiles);                    % maximum width is the fit interval if all data is clean

opt_kl = Inf;
% for each interval width
for width = min_width : step_sizes(2) : max_width
    inds = (1:round(n*width))';
    offsets = round(n*(lower_min : step_sizes(1) : lower_min+max_dropout_fraction));
    
    % get data in shifted intervals
    T = x(bsxfun(@plus,inds,offsets));
    
    % calculate histograms
    q = histc(bsxfun(@times,bsxfun(@minus,T,T(1,:)),1./(T(end,:)-T(1,:))),series);
    
    % calc KL divergences
    kl = sum(bsxfun(@times,p,log(bsxfun(@rdivide,p,q(1:end-1,:))))) + log(length(inds));
    
    % update optimal range
    [min_kl,idx] = min(kl);
    if min_kl < opt_kl
        opt_kl = min_kl;
        opt_lu = T([1,end],idx);
    end
end

% recover mu and sigma from optimal bounds
sig = (opt_lu(2)-opt_lu(1))/diff(bounds);
mu = opt_lu(1)-bounds(1)*sig;
