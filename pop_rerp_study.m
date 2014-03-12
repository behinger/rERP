%Run pop_rerp function against study or multiple datasets 
%   Usage:
%       rerp_result_study = pop_rerp_study('study', STUDY);
%           Run pop_rerp against all datasets listed in the EEGLAB STUDY
%           struct (launches rerp_setup_gui) 
%
%       rerp_result_study = pop_rerp_study('eeg', ALLEEG);
%           Run pop_rerp against all datasets listed in the EEGLAB ALLEEG
%           struct. ALLEEG can be just a single dataset (launches rerp_setup_gui)
%    
%       rerp_result_study = pop_rerp_study('eeg_dataset_paths', {'/data/RSVP/exp_53.set', '/data/RSVP/exp_54.set'});
%           Run pop_rerp against datasets listed in cell array of 
%           dataset full paths (launches rerp_setup_gui)
%
%       rerp_result_study = pop_rerp_study(..., 'rerp_profile');
%           Run pop_rerp against datasets listed in cell array of full
%           dataset paths (NO GUI, just runs the profile against datasets for scripting)
%
%       rerp_result_study = pop_rerp_study(..., 'rerp_profile', 'force_gui', 1);
%           Run pop_rerp against datasets listed in cell array of full
%           dataset paths, but launch GUI first (rerp_profile is called
%           'passed-in' in GUI) 
%
%   Parameters:
%       STUDY:
%           EEGLAB STUDY struct
%
%       ALLEEG:
%           EEGLAB ALLEEG struct
%
%       rerp_profile:
%           Object of RerpProfile class
%
%       rerp_result_study:
%           Object of RerpResultStudy class
%
%   See also:
%       rerp_setup_gui, pop_rerp, rerp, RerpProfile, RerpResultStudy

function [ rerp_result_study ] = pop_rerp_study(varargin)
% Copyright (C) 2013 Matthew Burns, Swartz Center for Computational
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
% either expressed or implied, of the FreeBSD Project.

p=inputParser;
addOptional(p,'rerp_profile', []);
addOptional(p,'eeg_dataset_paths', {}, @(x) iscell(x));
addOptional(p,'eeg', struct([]), @(x) isstruct(x));
addOptional(p,'study', struct([]), @(x) isstruct(x));
addOptional(p,'force_gui', 0);
parse(p, varargin{:});
eeg_dataset_paths=p.Results.eeg_dataset_paths;
rerp_profile=p.Results.rerp_profile;
EEG=p.Results.eeg;
STUDY=p.Results.study;
exitcode=1;

% Get the dataset paths from STUDY or EEG structs if dataset_paths was not
% specified. 
if isempty(eeg_dataset_paths)
    if ~isempty(EEG)
        for i=1:length(EEG)
            eeg_dataset_paths{i} = fullfile(EEG(i).filepath, EEG(i).filename);
        end
    elseif ~isempty(STUDY.datasetinfo)
        for i=1:length(EEG)
            eeg_dataset_paths{i} = fullfile(STUDY.datasetinfo(i).filepath, STUDY.datasetinfo(i).filename);
        end
    end
end

% If we are missing the paths to the datasets or the profile, launch the
% gui to find the missing information
if isempty(rerp_profile)||isempty(eeg_dataset_paths)||p.Results.force_gui
    [eeg_dataset_paths, rerp_profile, exitcode] = rerp_setup_gui('eeg_dataset_paths', eeg_dataset_paths, 'rerp_profile', rerp_profile);
end

% Make sure we have everything we need to run the study
if ~isa(rerp_profile, 'RerpProfile')
    return;
elseif isempty(eeg_dataset_paths)||~exitcode
    return;
end


% Run study one dataset at a time. If profile loaded did not specify to
% analyze all components or chans, then only those specified in the profile
% will be analyzed. 
rerp_results={};
for i=1:length(eeg_dataset_paths)
    EEG=pop_loadset(eeg_dataset_paths{i});
    disp(['pop_rerp_study: processing dataset ' num2str(i) '/' num2str(length(eeg_dataset_paths)) ': ' EEG.filename]);
    
    if (~rerp_profile.settings.type_proc)&&isempty(EEG.icaact)
        EEG.icaact=eeg_getica(EEG);
    end
    
    new_prof=RerpProfile(EEG, rerp_profile);
    rerp_results{i}=pop_rerp(EEG, new_prof);
end

% Create the RerpStudyResult object
rerp_result_study = RerpResultStudy(rerp_results);




