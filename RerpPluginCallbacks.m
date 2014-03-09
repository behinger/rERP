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

classdef RerpPluginCallbacks
    %RERPPLUGINCALLBACKS Callbacks implemented for the the eegplugin_rerp
    %function
    properties
    end
    
    methods (Static=true)
        
        function profileFromDisk(EEG)
            rerp_path = regexp(strtrim(mfilename('fullpath')),'(.*)[\\\/].*','tokens');
            rerp_profile = RerpProfile.loadRerpProfile('rerp_path', fullfile(rerp_path{1}{1}, 'profiles'));
            
            if rerp_profile==0
                return
            end
            
            tok = regexp(rerp_profile.eeglab_dataset_name,'.*[\/\\](.*.set)','tokens');
            
            if ~strcmp(EEG.filename, tok{1}{1})
                rerp_profile = RerpProfile(EEG, rerp_profile);
            end
            
            rerp_profile.settings.rerp_result_autosave=1;
            res = pop_rerp(EEG, rerp_profile, 'force_gui',1);
            
            if isa(res,'RerpResult')
                rerp_result_gui('results_dir', res.rerp_profile.settings.autosave_results_path);
            end
        end
        
        function defaultProfile(EEG)
            
            res = pop_rerp(EEG);
            
            if isa(res,'RerpResult')
                rerp_result_gui('results_dir', res.rerp_profile.settings.autosave_results_path);
            end
        end
        
        function lastProfile(EEG)
            tok=regexp(strtrim(mfilename('fullpath')),'(.*)[\\\/].*', 'tokens');
            rerp_path = tok{1}{1};
            last_path=fullfile(rerp_path,'profiles','last.rerp_profile');
            if exist(last_path, 'file')
                rerp_profile = RerpProfile.loadRerpProfile('path', last_path);
                
                tok = regexp(rerp_profile.eeglab_dataset_name,'.*[\/\\](.*.set)','tokens');
                if ~strcmp(EEG.filename, tok{1}{1})
                    rerp_profile = RerpProfile(EEG, rerp_profile);
                end
                
                rerp_profile.settings.rerp_result_autosave=1;
                res = pop_rerp(EEG, rerp_profile, 'force_gui',1);
                
                if isa(res,'RerpResult')
                    rerp_result_gui('results_dir', res.rerp_profile.settings.autosave_results_path);
                end
                
            else
                disp('rerp: last profile not found');
            end
        end
        
        function plotResultsFromDirectory
            rerp_path = regexp(strtrim(mfilename('fullpath')),'(.*)[\\\/].*','tokens');
            dirname = uigetdir(fullfile(rerp_path{1}{1},'results'), 'Choose results directory: ');
            rerp_result_gui('results_dir', dirname);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % STUDY callbacks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function studyProfileFromDisk(STUDY)
            rerp_path = regexp(strtrim(mfilename('fullpath')),'(.*)[\\\/].*','tokens');
            rerp_profile = RerpProfile.loadRerpProfile('rerp_path', rerp_path{1}{1});
            
            if rerp_profile==0
                return
            end
            
            rerp_profile.settings.rerp_result_autosave=1;
            res = pop_rerp_study('eeg_study', STUDY, 'rerp_profile', rerp_profile, 'force_gui', 1);
            
            
            if ~isempty(res.result)
                aresult=res.result{1};
                rerp_result_gui('results_dir', aresult.rerp_profile.settings.autosave_results_path);
            end
            
            
        end
        
        function studyDefaultProfile(STUDY)
            res = pop_rerp_study(STUDY);
            
            if isa(res,'RerpResult') && res.rerp_profile.settings.rerp_result_autosave
                rerp_result_gui('results_dir', res.rerp_profile.settings.autosave_results_path);
            end
        end
        
        function setupGui(EEG, STUDY)
        end
        
        
    end
end

