% Copyright (C) 2013 Matthew Burns, Swartz Center for Computational
% Neuroscience. 
%
% User feedback welcome: email rerptoolbox@gmail.com
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met: 
% 
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer. 
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution. 
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% The views and conclusions contained in the software and documentation are those
% of the authors and should not be interpreted as representing official policies, 
% either expressed or implied, of the FreeBSD Project.

%% Startup script 
%Example using Rapid Serial Visual Presentation dataset
%http://headit-beta.ucsd.edu/studies/8004e8ee-a236-11e2-b5e7-0050563f2612
path2rsvpdataset='/data/projects/RSVP/exp53/realtime/';
EEG = pop_loadset('filepath', path2rsvpdataset, 'filename', 'exp53_continuous_with_ica.set');
EEG.icaact=eeg_getica(EEG);

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

rerp_profile = RerpProfile.loadRerpProfile('path', fullfile('profiles', 'default.rerp_profile'));
rerp_profile.settings.num_xvalidation_folds=10; 
rerp_profile.settings.nbins=128;
rerp_profile.settings.num_grid_zoom_levels=3;
rerp_profile.settings.num_grid_points=8;
rerp_profile.settings.type_proc=0; % Operate on ICs 
rerp_profile.settings.autosave_enable=0; 

rersp_comps=17;
rerp_comps=1:EEG.nbchan;

%% GUI functionality

rerp_result = pop_rerp(EEG);
rerp_result = pop_rerp(EEG, rerp_profile, 'force_gui', 1);
rerp_result = pop_rerp({}, rerp_profile, 'view_only', 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Penalized estimation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parallel job, L2 penalty, rERP

rerp_profile.settings.hed_enable=0;
rerp_profile.settings.regularization_enable=1; 
rerp_profile.include_comps=rerp_comps; 
rerp_profile.settings.ersp_enable=0; 

result = rerp_parfor( EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_L2_Penalty_rERP.rerp_result')); 

%% Parallel job, L2 penalty, rERSP

rerp_profile.settings.hed_enable=0;
rerp_profile.settings.regularization_enable=1; 
rerp_profile.include_comps=rersp_comps;
rerp_profile.settings.ersp_enable=1; 

result = rerp_parfor( EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_L2_Penalty_rERSP.rerp_result')); 

%% Parallel job, L2 penalty, Hierarchical rERP

rerp_profile.settings.hed_enable=1;
rerp_profile.settings.regularization_enable=1; 
rerp_profile.include_comps=rerp_comps; 
rerp_profile.settings.ersp_enable=0; 

result = rerp_parfor( EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_L2_Penalty_rERP_HED.rerp_result')); 

%% Parallel job, L2 penalty, Hierarchical rERSP

rerp_profile.settings.hed_enable=1; % Profile has already been configured using pop_rerp
rerp_profile.settings.regularization_enable=1; 
rerp_profile.include_comps=rersp_comps;
rerp_profile.settings.ersp_enable=1; 

result = rerp_parfor(EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_L2_Penalty_rERSP_HED.rerp_result'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Least Squares estimation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parallel job, Least Squares, rERP 

rerp_profile.settings.hed_enable=0;
rerp_profile.settings.regularization_enable=0; 
rerp_profile.include_comps=rerp_comps; 
rerp_profile.settings.ersp_enable=0; 

result = rerp_parfor( EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_Least_Squares_rERP.rerp_result')); 

%% Parallel job, Least Squares, rERSP 

rerp_profile.settings.hed_enable=0;
rerp_profile.settings.regularization_enable=0; 
rerp_profile.include_comps=rersp_comps;
rerp_profile.settings.ersp_enable=1; 

result = rerp_parfor(EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_Least_Squares_rERSP.rerp_result')); 

%% Parallel job, Least Squares, Hierarchical rERP

rerp_profile.settings.hed_enable=1;
rerp_profile.settings.regularization_enable=0; 
rerp_profile.include_comps=rerp_comps; 
rerp_profile.settings.ersp_enable=0; 

result = rerp_parfor( EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_Least_Squares_rERP_HED.rerp_result')); 

%% Parallel job, Least Squares, Hierarchical rERSP

rerp_profile.settings.hed_enable=1; % Profile has already been configured using pop_rerp
rerp_profile.settings.regularization_enable=0; 
rerp_profile.include_comps=rersp_comps;
rerp_profile.settings.ersp_enable=1; 

result = rerp_parfor(EEG, rerp_profile);
result.saveRerpResult('path', fullfile('results', 'exp53_continuous_with_ica_Least_Squares_rERSP_HED.rerp_result'));

%% Plot results

rerp_result_gui;

