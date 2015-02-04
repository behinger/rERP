EEG=pop_loadset(fullfile(dropbox_path,'SCCN','RSVP','exp53_continuous_with_ica.set'));
clear cp;
clear RerpProfile;
cp=RerpProfile(EEG);
rerp_profile_gui(cp); 
s=cp.settings; 
cp.saveRerpProfile('path', fullfile(RerpProfile.rerp_path,'profiles','test.rerp_profile'));

%%
cp=RerpProfile.loadRerpProfile('path', fullfile(RerpProfile.rerp_path,'profiles','test.rerp_profile'));
P=cp.predictor; 
C=P'*P; 
lambda = logspace(0, 6, 20);

msv=zeros(2,length(lambda)); 
svd_sl=cell(2,length(lambda));
tic;
for i=1:length(lambda)
    B=C+lambda(i)*speye(size(C)); 
    [svd_sl{1,i}.U, svd_sl{1,i}.S] = svds(B,6, 0);
    [svd_sl{2,i}.U, svd_sl{2,i}.S] = svds(B,6,'L');
    svd_sl{1,i}.lambda=lambda(i);
    svd_sl{2,i}.lambda=lambda(i);
    disp(i); 
end
toc; 

save('L2_scale_test_svds', 'svd_sl');

%%
load('L2_scale_test_svds');
cp=RerpProfile.loadRerpProfile('path', fullfile(RerpProfile.rerp_path,'profiles','test.rerp_profile'));
P=cp.predictor; 
C=P'*P;
[Ucs, Scs]=svds(C,10, 0);
[Ucl, Scl]=svds(C,10, 'L');

min_max_scale_factor=zeros(3,length(svd_sl));
for i=1:11
    Ubs=svd_sl{1,i}.U; 
    Sbs=svd_sl{1,i}.S;
    
    Ubl=svd_sl{2,i}.U; 
    Sbl=svd_sl{2,i}.S;
    
    min_max_scale_factor(1, i)=svd_sl{1,i}.lambda;
    
    %find minimum scale factors
    W=diag(Sbl)./diag(Scl);
    gz = W > 0; 
    min_max_scale_factor(2, i)=min(W(gz)); 
    
    %find maximum scale factors
    W=diag(Sbs)./diag(Scs);
    gz = W > 0; 
    min_max_scale_factor(3, i)=min(W(gz)); 
end

%%

rerp_profile_gui(cp); 
