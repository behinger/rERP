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

p=inputParser;
addOptional(p,'rerp_profiles', {}, @(x) iscell(x));
addOptional(p,'eeg_dataset_paths', {}, @(x) iscell(x));
addOptional(p,'eeg', struct([]), @(x) isstruct(x));
addOptional(p,'study', struct([]), @(x) isstruct(x));
addOptional(p,'force_gui', 0);
parse(p, varargin{:});
eeg_dataset_paths=p.Results.eeg_dataset_paths;
rerp_profiles=p.Results.rerp_profiles;
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
if isempty(rerp_profiles)||isempty(eeg_dataset_paths)||p.Results.force_gui
    [eeg_dataset_paths, rerp_profiles, exitcode] = rerp_setup_gui('eeg_dataset_paths', eeg_dataset_paths, 'rerp_profiles', rerp_profiles);
end

% Make sure we have everything we need to run the study
if isempty(rerp_profiles)||isempty(eeg_dataset_paths)||~exitcode
    return;
end

% Run study, one dataset at a time, for all profiles. If profile loaded did not specify to
% analyze all components or chans, then only those specified in the profile
% will be analyzed. 
rerp_results=cell(length(eeg_dataset_paths), length(rerp_profiles));
for i=1:length(eeg_dataset_paths)
    EEG=pop_loadset(eeg_dataset_paths{i});
    artifact_name='';
    artifact=[]; 
    for j=1:length(rerp_profiles)

        disp(['pop_rerp_study: processing dataset ' num2str(i) '/' num2str(length(eeg_dataset_paths)) ': ' EEG.filename ', profile ' num2str(j) '/' num2str(length(rerp_profiles)) ': ' rerp_profiles(j).name ]);

        if (~rerp_profiles(j).settings.type_proc)&&isempty(EEG.icaact)
            EEG.icaact=eeg_getica(EEG);
        end
        
        %Save us from recomputing artifact indexes for multiple profiles
        this_profile = RerpProfile(EEG, rerp_profiles(j));
        this_profile.computed_artifact_indexes = artifact;
        this_profile.computed_artifact_indexes_function_name = artifact_name; 
        
        rerp_results{i,j}=pop_rerp(EEG, this_profile);
        artifact = rerp_results{i,j}.rerp_profile.computed_artifact_indexes; 
        artifact_name = rerp_results{i,j}.rerp_profile.computed_artifact_indexes_function_name; 
    end
end

rerp_result_study=cell(1,length(rerp_profiles)); 
for i=1:length(rerp_profiles)
    % Create the RerpStudyResult object for each profile
    rerp_result_study{i} = RerpResultStudy([rerp_results{:, i}]);
end
rerp_result_study=[rerp_result_study{:}]; 




