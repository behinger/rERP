
EEG=pop_loadset(fullfile(dropbox_path,'SCCN','RSVP','exp53_continuous_with_ica.set'));

% for i=1:length(EEG.event)
%     pulse_tag = sprintf('Custom/Pulse/#/%f', 20+100*rand(1)); 
%     if i < length(EEG.event)/2
%        
%         EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/|/1',pulse_tag},';');
%         
%     else
%         EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/|/2',pulse_tag},';');
%     end
% end

%%
% clear cp;
% clear RerpProfile;
% cp=RerpProfile(EEG);
% s=cp.settings; 
% cp.saveRerpProfile('path', fullfile(RerpProfile.rerp_path,'profiles','test.rerp_profile'));

%%
clear cp;
clear RerpProfile;
cp = RerpProfile.loadRerpProfile('path', fullfile(RerpProfile.rerp_path, 'profiles','test.rerp_profile'));

rerp_result = pop_rerp(EEG, cp);

cp=rerp_result.rerp_profile; 
cp.settings.regularization_enable=0;
rerp_result(2)=pop_rerp(EEG, cp);

%rerp_result = pop_rerp(EEG, cp);
%%
rerp_result_gui('results', rerp_result);
%EEG=pop_loadset(fullfile(dropbox_path,'SCCN','RSVP', 'Gaby Data', 'GabyData2', 'S02_contData_cudaica.set'));
