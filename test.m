
EEG=pop_loadset('C:\Dropbox\SCCN\RSVP\exp53_continuous_with_ica.set');

for i=1:length(EEG.event)
    pulse_tag = sprintf('Custom/Pulse/#/%f', 20+100*rand(1)); 
    if i < length(EEG.event)/2
       
        EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/1',pulse_tag},';');
        
    else
        EEG.event(i).hedTag=strjoin({EEG.event(i).hedTag, 'Custom/Block/2',pulse_tag},';');
    end
end

pop_rerp(EEG);
