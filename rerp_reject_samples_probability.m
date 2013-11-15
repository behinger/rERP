function isFrameAnArtifact= rerp_reject_samples_probability(EEG, varargin)

data = double(eeg_getdatact(EEG));

assert(~isempty(EEG.icaweights) && ~isempty(EEG.icaweights), 'rerp_reject_samples_probability: EEG.icaweights and EEG.icasphere must be populated'); 
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

isArtifactWindowCenter = find(smoothMeanLogLikelihood > 2.1);

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

isFrameAnArtifact=logical(isFrameAnArtifact'); 