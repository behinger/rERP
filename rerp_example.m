%% Startup script: load RSVP dataset first 
%http://headit-beta.ucsd.edu/studies/8004e8ee-a236-11e2-b5e7-0050563f2612
path_to_dataset=''; 
EEG=pop_loadset(path_to_dataset);

% Add HED tags to EEG struct
% For GUI tagging, use EEG = tageeg(EEG); requires ctagger plugin (http://visual.cs.utsa.edu/software/ctagger)
for i=1:length(EEG.event)
    switch EEG.event(i).type
        case 1
            EEG.event(i).hedTag='stimulus/visual;stimulus/onset;stimulus/expected';
        case 2 
            EEG.event(i).hedTag='stimulus/visual;stimulus/onset;stimulus/expected/target';
        case 4
            EEG.event(i).hedTag='response/button press';
        case 5
            EEG.event(i).hedTag='response/button press';
        case 6
            EEG.event(i).hedTag='time-locked event';
        case 16
            EEG.event(i).hedTag='stimulus/visual;stimulus/onset;stimulus/instruction/fixate';
        case 32
            EEG.event(i).hedTag='stimulus/visual;stimulus/feedback/correct';
        case 64
            EEG.event(i).hedTag='stimulus/visual;stimulus/feedback/incorrect';
        case 129
            EEG.event(i).hedTag='stimulus/visual;stimulus/expected';
    end 
end

%% This will get you started with the main setup GUI for the first time
rerp_result_study = pop_rerp_study('eeg', EEG); 


%% If you have profiles saved to disk, you can load the ones you want and run them against new datasets
rerp_profiles = RerpProfile.loadRerpProfile;

%% You can easily run multiple datasets against multiple profiles
[STUDY ALLEEG] = pop_loadstudy(path_to_study); 
rerp_result_study = pop_rerp_study('eeg', EEG, 'rerp_profiles', rerp_profiles, 'force_gui', 1);  
%or
%rerp_result_study = pop_rerp_study('eeg', ALLEEG, 'rerp_profiles', rerp_profiles, 'force_gui', 1);
%or if STUDY is populated
%rerp_result_study = pop_rerp_study('study', STUDY, 'rerp_profiles', rerp_profiles, 'force_gui', 1);

%Run analysis with a single dataset and a single profile
rerp_result = pop_rerp(EEG(1), rerp_profiles{1}, 'force_gui', 1);

%Run analysis with a single dataset and a single profile
rerp_result = pop_rerp(EEG(1), rerp_result_study{1}.rerp_profile, 'force_gui', 1);

%Plot results. This will look in the default directory /results and load
%all .rerp_result files.
rerp_result_gui; 

%Modify an RerpProfile object, but don't run analysis.
rerp_profile_gui(rerp_profiles{1});


