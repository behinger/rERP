function [ rerp_result_study ] = rerp_study( eeg_set_paths, rerp_profile)
%POP_RERP_STUDY Summary of this function goes here
%   Detailed explanation goes here

for i=1:length(eeg_set_paths)
    EEG=pop_loadset(eeg_set_paths{i});
    result{i}=pop_rerp(EEG,rerp_profile); 
end
