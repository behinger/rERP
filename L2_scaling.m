EEG=pop_loadset(fullfile(dropbox_path,'SCCN','RSVP','exp53_continuous_with_ica.set'));
clear cp;
clear RerpProfile;
cp=RerpProfile(EEG);
rerp_profile_gui(cp); 
s=cp.settings; 
cp.saveRerpProfile('path', fullfile(RerpProfile.rerp_path,'profiles','test.rerp_profile'));
P=cp.predictor; 

%%

C=P'*P; 
[Uc,Sc,Vc]=svds(C);
lambda = logspace(-1, 6, 20);
msv=zeros(size(lambda)); 

tic;
for i=1:length(lambda)
    B=(C+lambda(i)*eye(size(C)));
    msv(i)=get_largest_sv(B, Uc, Sc);
    disp(i); 
end
toc; 

tic;
for i=1:length(lambda)
    B=(C+lambda(i)*eye(size(C)));
    msv2(i)=get_largest_sv(B, Uc, Sc);
    disp(i); 
end
toc; 