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
%It might be useful to save all the profiles and the .study file in a
%single directory. 

path2profiles=fullfile(RerpProfile.rerp_path, 'profiles', 'example'); 
template_profile = RerpProfile(EEG);
rerp_profile_gui(template_profile);

all_profiles=[]; 
parfor i=1:length(ALLEEG)
    all_profiles(i) = RerpProfile(ALLEEG(i), template_profile);
    all_profiles(i).compute_artifact_indexes(EEG); 
    all_profiles(i).saveRerpProfile('path', fullfile(path2profiles, [this_eeg.setname '.rerp_profile']));  
end

%Get the profiles you just computed in another session. This loads all
%the profiles in the folder 
all_profiles = RerpProfile.loadRerpProfile('path', path2profiles); 

%Run the profiles against the datasets they were derived from. This computes channels/comps in parallel, if 
%you run matlabpool with more than 2 workers, or inside a batch job with many workers. 
for i=1:length(ALLEEG)
    all_results(i) = pop_rerp(ALLEEG(i), all_profiles(i)); 
end 

rerp_result_study = RerpResultStudy(all_results); 

