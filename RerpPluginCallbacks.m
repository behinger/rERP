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
            rerp_profile = RerpProfile.loadRerpProfile('rerp_path',EEG.filepath);
            
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
                rerp_result_gui('EEG', EEG);
            end
        end
        
        function defaultProfile(EEG)

            res = pop_rerp(EEG);
            
            if isa(res,'RerpResult')
                rerp_result_gui('EEG', EEG);
            end
        end
        
        function lastProfile(EEG)
            tok=regexp(strtrim(mfilename('fullpath')),'(.*)[\\\/].*', 'tokens');
            rerp_path = tok{1}{1};
            rerp_profile = RerpProfile.loadRerpProfile('path', fullfile(rerp_path,'profiles','last.rerp_profile'));
            
            tok = regexp(rerp_profile.eeglab_dataset_name,'.*[\/\\](.*.set)','tokens');
            if ~strcmp(EEG.filename, tok{1}{1})
                rerp_profile = RerpProfile(EEG, rerp_profile);
            end
            
            rerp_profile.settings.rerp_result_autosave=1;            
            res = pop_rerp(EEG, rerp_profile, 'force_gui',1);
            
            if isa(res,'RerpResult')
                rerp_result_gui('EEG', EEG);
            end 
        end
        
        function newProfile(EEG)
            res = pop_rerp(EEG);
            if isa(res,'RerpResult')
                rerp_result_gui('EEG', EEG);
            end
        end
        
        function profileStudyFromDisk(STUDY) 
        end
        
        function defaultStudyProfile(STUDY)
        end
        
        function lastStudyProfile(STUDY)
        end
        
        function newStudyProfile(STUDY)
        end
        
    end   
end

