% Facilitate calling the lower level rerp function
%   Usage:
%       rerp_result = pop_rerp(EEG); 
%           Create a default profile for EEG in rerp_profile_gui before
%           executing
%
%       rerp_result = pop_rerp(EEG, rerp_profile);
%           Call rerp with rerp_profile, WITHOUT launching
%           GUI (for scripts)
%
%       rerp_result = pop_rerp(EEG, rerp_profile, 'force_gui', 1);
%           Call rerp with rerp_profile, but launch GUI
%
%   Parameters:
%       EEG (required)
%           The EEGLAB structure of a single dataset, with the
%           relevent data fields populated
%
%       rerp_profile
%           Object of RerpProfile class
%
%       rerp_result
%           Object of RerpResult class
%   
%   See also: 
%       pop_rerp_study, rerp, RerpProfile, rerp_profile_gui, RerpResult, rerp_result_gui
%           
function [rerp_result, EEGOUT, com] = pop_rerp(EEG, rerp_profile, varargin)
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

import rerp_dependencies.*

% display help if not enough arguments
% ------------------------------------
if nargin < 1
    help pop_rerp;
    return;
end;
p=inputParser;
addOptional(p,'force_gui', 0);
parse(p, varargin{:});
force_gui=p.Results.force_gui;

% the command output is a hidden output that does not have to
% be described in the header
com = ''; % this initialization ensure that the function will return something
EEGOUT = EEG;

exitcode=1; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initialize profile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cp is current RerpProfile, s is current settings (i.e. the part which can be applied to other
% datasets)
if nargin > 1
    assert(isa(rerp_profile,'RerpProfile'), 'pop_rerp: rerp_profile must be object of class RerpProfile; pop_rerp(EEG) if you don''t know what this is');
    
    %We are passed a profile, use it
    cp = rerp_profile;
    
    %Unless it was derived from a different dataset, then we have to
    %rebuild the profile.
    tmp=regexp(rerp_profile.eeglab_dataset_name , '.*[\\\/](.*\.set)', 'tokens'); 
    fn=tmp{1}{1};
    if ~strcmp(fn, EEG.filename)
        cp=RerpProfile(rerp_profile);
    end
    
else
    %Otherwise, use default profile
    cp = RerpProfile.getDefaultProfile(EEG);
    force_gui=1; 
end


if force_gui
    exitcode = rerp_profile_gui(cp);
end

if exitcode
    s=cp.settings; 

    %Dummy var, used to update profile
    artifact_indexes = [];
    % Set up artifact indexes based on profile
    if s.artifact_rejection_enable

        if ~isempty(cp.computed_artifact_indexes)
            artifact_indexes=cp.computed_artifact_indexes;
        end

        if s.artifact_variable_enable
            if ~isempty(cp.variable_artifact_indexes)
                artifact_indexes=cp.variable_artifact_indexes;
            else
                error('pop_rerp: artifact variable enabled, but not found');
            end
        end

        %Need to recompute the artifact indexes
        if isempty(artifact_indexes) || ~strcmp(s.artifact_function_name, cp.computed_artifact_indexes_function_name)
            try
                artifact_function = str2func(s.artifact_function_name);
                S = functions(artifact_function);

                if isempty(S.file)
                    disp(['pop_rerp: could not find artifact function ' s.artifact_function_name]);
                    error('pop_rerp: artifact rejection is enabled, but could not find or compute artifact indexes');
                else
                    disp(['pop_rerp: computing artifact indexes with ' s.artifact_function_name]);
                    cp.compute_artifact_indexes(EEG);
                end

            catch
            end
        end
    end

    cp.settings = s;
    cp.setLastProfile;

    EEGOUT.rerp_profile = cp;

    % Compute estimates in parallel if we are using regularization
    if ~isempty(s.penalty_func) && (matlabpool('size') > 0)
        rerp_result = rerp_parfor(EEG, cp);
    else
        rerp_result = rerp_parfor(EEG, cp, 'disable_parfor', 1);
    end
    
    tmp = regexp(EEG.filename,'(.*)\.set','tokens'); 
    dsname= tmp{1}{1};
    
    %Save results
    rerp_result.setLastResult;
    if cp.settings.rerp_result_autosave
        resultfilename=[dsname ' ' rerp_result.analysis_name ' ' rerp_result.date_completed '.rerp_result'];
        
        try
            rerp_result.saveRerpResult('path', fullfile(s.autosave_results_path, resultfilename));
        catch
            disp('pop_rerp: auto-save results path not valid, saving in "rerp/results" folder');
            rerp_result.saveRerpResult('path', fullfile(RerpProfile.rerp_path,'results', resultfilename));
        end
    end
end

disp('pop_rerp: done');





