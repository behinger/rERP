%Detect artifact indexes by thresholding liklihood of samples in sphered space. Requires precomputed ICA.  
function artifact_indexes = rerp_reject_samples_probability(EEG) 
% Copyright (C) 2013 Nima Bigdely-Shamlo Swartz Center for Computational
% Neuroscience.
%
% User feedback welcome: email rerptoolbox@gmail.com
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
% either expressed or implied, of the FreeBSD Project.function isFrameAnArtifact= rerp_reject_samples_probability(EEG, varargin)

ARTIFACT_LIKELIHOOD_THRESHOLD=2.1; 
assert(~isempty(EEG.icaweights) && ~isempty(EEG.icaweights), 'rerp_reject_samples_probability: EEG.icaweights and EEG.icasphere must be populated'); 
data = double(eeg_getdatact(EEG));
data = real((EEG.icaweights * EEG.icasphere) * data);

logLikelihood = zeros(size(data));
for i=1:size(data,1)
    triedRank = tiedrank(data(i,:)) / size(data, 2);
    twoSidedPvalue = min(triedRank, 1 - triedRank);
    logLikelihood(i,:) = -log(twoSidedPvalue);
end;

fprintf('\n');
meanLogLikelihood= mean(logLikelihood, 1);

windowTimeLenght = 200;%in ms
windowFrameLength = round((EEG.srate * windowTimeLenght/1000));
windowFrame = round((-windowFrameLength/2):(windowFrameLength/2));
meanLogLikelihood(isinf(meanLogLikelihood))=0; 
smoothMeanLogLikelihood =  filtfilt( ones(1, windowFrameLength) , 1, meanLogLikelihood)/(windowFrameLength.^2);

isArtifactWindowCenter = find(smoothMeanLogLikelihood > ARTIFACT_LIKELIHOOD_THRESHOLD)';

% add two sides on the window
artifactFrames = repmat(windowFrame, length(isArtifactWindowCenter), 1) + repmat(isArtifactWindowCenter, 1, length(windowFrame));
artifactFrames = max(artifactFrames, 1);
artifactFrames = min(artifactFrames, length(smoothMeanLogLikelihood));
artifactFrames = unique(artifactFrames(:));

isFrameAnArtifact = zeros(1, length(smoothMeanLogLikelihood));
isFrameAnArtifact(artifactFrames)  =1;

raisingEdge = find(diff([0 isFrameAnArtifact]) > 0);
fallingEdge = find(diff([isFrameAnArtifact 0]) < 0);

rejectionWindows = [];
for i=1:length(fallingEdge)
    rejectionWinowStart = raisingEdge(i);
    rejectionWinowEnd = fallingEdge(i);
    rejectionWindows =cat(1, rejectionWindows, [rejectionWinowStart rejectionWinowEnd]);
end;

artifact_indexes=logical(isFrameAnArtifact'); 