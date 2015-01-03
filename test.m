
EEG=pop_loadset(fullfile(dropbox_path,'SCCN','RSVP','exp53_continuous_with_ica.set'));

for i=1:length(EEG.event)
    pulse_tag = sprintf('Custom/Pulse/#/%f', 20+100*rand(1)); 
    if i < length(EEG.event)/2
       
        EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/|/1',pulse_tag},';');
        
    else
        EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/|/2',pulse_tag},';');
    end
end

%%
cp=RerpProfile(EEG);
s=cp.settings; 
cp.saveRerpProfile('path', '/Users/MattB/Documents/Code/eeglab/plugins/rERP/profiles/test.rerp_profile');
%%
cp = RerpProfile.loadRerpProfile('path', '/Users/MattB/Documents/Code/eeglab/plugins/rERP/profiles/test.rerp_profile');
s=cp.settings;
rerp_result = pop_rerp(EEG, cp, 'force_gui', 1);
%EEG=pop_loadset(fullfile(dropbox_path,'SCCN','RSVP', 'Gaby Data', 'GabyData2', 'S02_contData_cudaica.set'));