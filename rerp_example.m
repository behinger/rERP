%% The primary source of documentation for functions and classes is the Matlab help system:
doc pop_rerp;
doc pop_rerp_study;
doc RerpProfile;
doc RerpResult;
doc RerpResultStudy;


%% Main setup GUI
rerp_result_study = pop_rerp_study('eeg', EEG);

%% Create and edit a new profile for the current dataset
rerp_profile = RerpProfile(EEG);
rerp_profile_gui(rerp_profile);

%% If you have profiles saved to disk, you can load the ones you want and run them against new datasets
rerp_profiles = RerpProfile.loadRerpProfile;

%% You can easily run multiple datasets against multiple profiles
rerp_result_study = pop_rerp_study('eeg', EEG, 'rerp_profiles', rerp_profiles);

%or
%rerp_result_study = pop_rerp_study('eeg', ALLEEG, 'rerp_profiles', rerp_profiles);

%or if STUDY is populated
%rerp_result_study = pop_rerp_study('study', STUDY, 'rerp_profiles', rerp_profiles);

%Toolbox will parallelize over channels or components automatically using
%parfor.

%% Run analysis with a single dataset and a single profile
rerp_result = pop_rerp(EEG(1), rerp_profiles(1));

%% Plot results. This will look in the default directory /results and load all .rerp_result files.
rerp_result_gui;

%or
%rerp_result_gui('results', rerp_result_study.result);

%or
%rerp_result_gui('results', rerp_result);

%% Create a profile for each dataset from template, compute artifact indexes for all datasets and save for future use

path2profiles=fullfile(RerpProfile.rerp_path, 'profiles', 'example');
template_profile = RerpProfile(EEG(1));
rerp_profile_gui(template_profile);

all_profiles={};
parfor i=1:length(ALLEEG)
    this_eeg=ALLEEG(i);
    this_eeg = eeg_checkset(this_eeg, 'loaddata');
    this_eeg.icaact = eeg_getica(this_eeg);
    all_profiles{i} = RerpProfile(this_eeg, template_profile);
    all_profiles{i}.compute_artifact_indexes(this_eeg);
    all_profiles{i}.saveRerpProfile('path', fullfile(path2profiles, [this_eeg.setname '.rerp_profile']));
end
all_profiles = [all_profiles{:}];

%Get the profiles you just computed in another session. This loads all
%the profiles in the folder
all_profiles = RerpProfile.loadRerpProfile('path', path2profiles);

%Run the profiles against the datasets they were derived from. This computes channels/comps in parallel, if
%you run matlabpool with more than 2 workers, or inside a batch job with many workers.
for i=1:length(ALLEEG)
    all_results(i) = pop_rerp(ALLEEG(i), all_profiles(i));
end

rerp_result_study = RerpResultStudy(all_results);

%% Hierarchical Event Description (HED) tag usage: Basic
%A useful GUI tool for tagging datasets is the ctagger software: http://visual.cs.utsa.edu/software/ctagger
[EEG, com] = pop_tageeg(EEG);
[STUDY, com] = pop_tageeg(STUDY);

%Or you can do it manually with a script
tag1 = 'Stimulus/Visual';
tag2 = 'Stimulus/Visual/Target';
tag3 = 'Response/Button press/Yes';
tag4 = 'Response/Button press/No';
for i=1:length(EEG.event)
    type = EEG.event(i).type;
    if type == 1
        tag=tag1;
    end
    if type == 2
        tag=tag2;
    end
    if type == 16
        tag=tag3;
    end
    if type == 32
        tag=tag4;
    end
end

%% Hierarchical Event Description (HED) tag usage: Advanced
%See the wiki for a complete explanation of this section

for i=1:length(EEG.event)
    %To specify a continuous tag, use the # tag, followed by the magnitude.
    %In theory, you could use this to model non-linear response
    %characteristics. 
    pulse_tag = sprintf('Custom/Pulse/#/%f', 20+100*rand(1));
    
    %To specify a separator tag, use the | tag, followed by the group tag
    %(i.e. estimate all variables which co-occur with |/1 in a separate
    %regression model from those tagged with |/2). 
    if i < length(EEG.event)/2
        EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/|/1',pulse_tag},';');
    else
        EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/|/2',pulse_tag},';');
    end
end





