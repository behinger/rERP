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

classdef RerpProfile < matlab.mixin.Copyable
%RERP_PROFILE Defines the state of the pop_rerp() GUI and used as required argument to rerp().
% Methods: 
%   rerp_profile = RerpProfile(EEG, settings) (Constructor)
%   	Inputs:
%           EEG: the EEGLAB struct
%           settings: one of the following - RerpProfile, RerpResult,
%               RerpProfile.settings, or a cell array of name value pairs
%               completely describing the RerpProfile.settings struct.
%       Outputs:
%           rerp_profile: the RerpProfile object
%
%   saveRerpProfile(varargin) (save RerpProfile to disk)
%       Inputs: 
%           varargin: 
%               path: when specified, automatically saves to that path
%               rerp_path: path which GUI will start looking at
%
%   compute_artifact_indexes(EEG) (compute artifact indexes using function in settings.artifact_function_name)
%
%   set_artifact_indexes(artifact_indexes) (assign artifact indexes to profile)
%
% Static Methods:
%   rerp_profile = getDefaultRerpProfile (Generates RerpProfile object with the settings defined in this file)
%       Outputs:
%           rerp_profile: the RerpProfile object
%
%   rerp_profile = loadRerpProfile(varargin) (Load RerpProfile from disk)
%       Inputs: 
%           varargin 
%               path: when specified, automatically loads from that path
%               rerp_path: path which GUI will start looking at
%       Outputs: 
%           rerp_profile: the RerpProfile object
%
%   h = get_artifact_handle(artifact_function_name) (returns handle of function specifie by artifact_function_name string
%       Inputs: 
%           artifact_function_name: string name of artifact function
%       Outputs:
%           h: handle to artifact function
%
        
    properties
        %This struct can be applied to many datasets with the same experimental
        %event types/ hed tag structure. Can use it to instantiate new RerpProfile objects.
        %See RerpProfile.getDefaultRerpProfile method for details. 
        settings;
        
        eeglab_dataset_name=[];% Full path to dataset 
        autosave_results_path=[];        % pop_rerp automatically saves a copy of the regression result to this path if settings.rerp_result_autosave==1
        sample_rate=[];
        pnts=[];
        nbchan=[]; 
        
        include_chans=[];        % Channel numbers to include in regression
        include_comps=[];        % Component numbers to include in regression
        
        these_events=[];        % Object of class event stores all event information for dataset
        event_types=[];         % Unique event types in dataset
        num_event_types=[];        % Number of times each event occurs
        event_type_descriptions=[];        % Description of each event type (must enter this manually)
        include_event_types=[];        % Event types to include in regression

        variable_artifact_indexes=[];        % Artifact indexes to use when settings.artifact_variable_enable==1
        artifact_variable_name='';        % Name of the variable used as source for variable_artifact_indexes
        computed_artifact_indexes=[];        % Artifact indexes to use when settings.artifact_variable_enable==0
        computed_artifact_indexes_function_name = '';        % Name of function used to generate computed_artifact_indexes
    
        hed_tree={};        % hedTree object compiled from included hed tags
        include_tag={};        % unique hed tags to include in regression
        include_ids={};        % for each unique tag, the index of the events which are hit by that tag

        context_group={}        % cell array of groups generated by seperator tags; 1 group per seperator tag (see pop_rerp for additional info)
        continuous_var={};        % cell array of continuous variables

    end
    
    methods
        %Constructor verifies that all required fields are present. Accepts
        %another RerpProfile object as an argument, a structure
        %corresponding to the "settings" property or name-value pairs as
        %cell array.
        function obj = RerpProfile(EEG, varargin)
            
            import rerp_dependencies.*
            
            obj.include_chans=1:EEG.nbchan;
            obj.include_comps=1:EEG.nbchan;
            
            events = event;
            obj.these_events = events.eeglab2event(EEG);
            
            obj.event_types = obj.these_events.uniqueLabel;
            obj.num_event_types = obj.these_events.getNumberOfOccurancesForEachEvent;
            
            obj.event_type_descriptions = cell(size(obj.event_types));
            
            p=makeParser;
            if length(varargin)==1 
                if isa(varargin{1},'RerpResult')
                    theseargs={varargin{1}.rerp_profile.settings};
                elseif isa(varargin{1},'RerpProfile')
                    theseargs={varargin{1}.settings};
                end
            else
                theseargs=varargin; 
            end
            
            parse(p, theseargs{:});
            params = p.Parameters;
            
            if length(theseargs)==1 && isstruct(theseargs{1})
                %Passed a structure
                missing = setdiff(params, fieldnames(theseargs{1}));
            else

                if iscell(theseargs)
                    %Passed name-value pairs as cell array
                    missing = setdiff(params, theseargs(1:2:end));
                end
            end
            
            s=p.Results;
            
            msg = 'RerpProfile: profile not completely specified, missing parameters\n';
            for i=1:length(missing)
                msg = [msg '\t\t' missing{i} '\n'];
            end
            
            if ~isempty(missing)
                fprintf(msg);
                error('RerpProfile: failed to create profile');
            end
            
            obj.eeglab_dataset_name = fullfile(EEG.filepath, EEG.filename);
            obj.sample_rate = EEG.srate;
            obj.pnts = EEG.pnts;
            obj.nbchan=EEG.nbchan;
            
            fprintf('RerpProfile: creating intitial hierarchy\n');
            obj.hed_tree = hedTree(obj.these_events.hedTag);
            
            assert(isempty(setdiff(s.penalty_func, s.penalty_options)), 'RerpProfile: settings.penalty_func must be a subset of settings.penalty_options');
            
            if ~iscell(s.exclude_tag)
                s.exclude_tag = obj.hed_tree.uniqueTag;
            end
            
            if isempty(obj.hed_tree.uniqueTag)
                s.hed_enable=0; 
            end     

            fprintf('RerpProfile: parsing intitial hierarchy\n');
            [obj.include_tag, obj.include_ids, obj.context_group, obj.continuous_var] = parse_hed_tree(obj.hed_tree, s.exclude_tag, s.seperator_tag, s.continuous_tag);
            
            [~, idx] = setdiff(obj.event_types, s.exclude_event_types);
            obj.include_event_types = obj.event_types(sort(idx));    
            
            rerp_path_components=regexp(strtrim(mfilename('fullpath')),'[\/\\]','split');
            results_path = [filesep fullfile(rerp_path_components{1:(end-1)}) filesep 'results'];
            obj.autosave_results_path=results_path;
            
            obj.settings = s;
            
            disp('RerpProfile: finished');
        end
        
        %Save a profile to disk
        function saveRerpProfile(obj, varargin)
            import rerp_dependencies.*
            
            p=inputParser;
            addOptional(p,'path',[]);
            addOptional(p,'rerp_path', pwd);
            
            parse(p, varargin{:});
            temp = regexp(obj.eeglab_dataset_name, '.set', 'split');
            fn = temp{1};
            
            if isempty(p.Results.path)
                %No path specified, launch GUI
                if ~isempty(fn)
                    [filename, pathname] = uiputfile('*.rerp_profile', 'Save rerp profile as:', [fn, '.rerp_profile']);
                else
                    [filename, pathname] = uiputfile('*.rerp_profile', 'Save rerp profile as:', fullfile(p.Results.rerp_path, '.rerp_profile'));
                end
                path = [pathname filename];
                
            else
                path = p.Results.path;
                filename=1;
            end
            
            %Save profile to disk
            if ~filename==0
                try
                    save(path, 'obj','-mat');
                    disp(['RerpProfile: saved profile to disk ' path]);
                catch e
                    disp(['RerpProfile: could not save the specified profile to disk ' path]);
                    rethrow(e);
                end
            end
        end
        
        function compute_artifact_indexes(obj, EEG)
            import rerp_dependencies.*
           
            assert(size(EEG.data,3)==1, 'pop_rerp: must compute artifact indexes on continuous channel data (not time-frequency or epoched)'); 
            
            artifact_function = RerpProfile.get_artifact_handle(obj.settings.artifact_function_name);
            
            if ~isempty(obj.settings.artifact_function_name)
                fprintf('RerpProfile: detecting artifact frames with %s\n', obj.settings.artifact_function_name);
                obj.computed_artifact_indexes =  artifact_function(EEG);
                obj.computed_artifact_indexes_function_name = obj.settings.artifact_function_name;
                fprintf('RerpProfile: detected %d artifact frames\n', nnz(obj.computed_artifact_indexes));
            end
        end   
        
        function set_artifact_indexes (obj, artifact_indexes)
            assert(length(artifact_indexes)==obj.pnts, 'RerpProfile: artifact indexes must be logical vector same length as data'); 
            obj.variable_artifact_indexes= artifact_indexes;
            obj.artifact_variable_name='passed in'; 
            obj.settings.artifact_variable_enable=1;  
        end
        
    end
    
    methods(Static=true)
        
        %Updates the artifact function handle with new string. Function must be in a file.
        %This will throw an error if the file is not found.
        function h = get_artifact_handle(instr)    
            h=[]; 
            if ~isempty(instr)
                try
                    retvar = str2func(strtrim(instr));
                    vals = functions(retvar);
                    
                    %Check if the file exists
                    if ~isempty(vals.file)
                        h=retvar;
                    else
                        err(sprintf('pop_rerp: %s was not found\n', [instr '.m']));
                    end
                catch
                    error('pop_rerp: %s not a valid artifact function name', instr);
                end
            end
        end   
        
        %Returns an RerpProfile initialized to EEG struct.
        function rerp_profile = getDefaultProfile(EEG)
            import rerp_dependencies.*

            disp('RerpProfile: loading default settings');
            default_settings = {...
                'type_proc', 0,... 0 for ICA or 1 for channels
                'ersp_enable',0,...perform time-frequency decomposition first
                'nbins', 64,...number of freq bins to use when ersp_enable==1          
                'rerp_result_autosave', 1,...automatically save the regression result 
                ...
                'category_epoch_boundaries',[-1 2],...sets window for categorical variables like event types
                'continuous_epoch_boundaries',[-1 2],...sets window for continuous variables; only for hed
                ...
                'artifact_rejection_enable', 1,...automatically ensure artifact frames are identified and excluded (recommended)
                'artifact_variable_enable', 0,...use an artifact variable from the workspace (RerpProfile.variable_artifact_indexes)
                'artifact_function_name', 'rerp_reject_samples_robcov',...name of function used to compute artifact indexes - reject_samples_robcov uses much more resources than reject_samples_probability, but it is also more thorough
                ...
                'exclude_event_types',{},...event types to exclude from regression
                ...
                'hed_enable', 1,...enable hierarchical regression
                'enforce_hed_spec',0,...throw an error if a hed tag does not comply with the hed spec (very slow)
                'hed_spec_path',fullfile('hed', 'hed_specification_1.3.xml'),...
                ...
                'exclude_tag',0,...tags to exclude from regresion 
                'seperator_tag',{},...tags to generate seperate groups of variables based on which events are hit by the tag's children.
                'continuous_tag',{},...tags which have a magnitude associated (e.g. Stimulus/Visual/Luminance/.25)
                ...
                'regularization_enable', 1,...enable penalized regression 
                'lambda',[1 1],...specify lambda to use if cross validation is disabled
                'cross_validate_enable', 1,...do a grid search for lambda 
                'num_xvalidation_folds', 5,...number of folds to use during cross validation 
                'num_grid_zoom_levels', 1,...number of levels of grid search zooming
                'num_grid_points', 8,...number of points to sample at each grid level
                'first_phase_lambda', [0 logspace(log10(1e-6), log10(1e8), 15)]',... the initial sample space for grid search
                'elasticnet_quick_zoom', 0,...for ElasticNet (L1+L2) penalty. find optimal lambda1 and lambda2 serpately first, then 2D grid search around those values
                'penalty_func',{'L2 norm'},...penalty function
                'penalty_options',{'L1 norm' 'L2 norm' 'Elastic net'}... available options for penalty function
                }; 
            
            %Initialize profile
            rerp_profile = RerpProfile(EEG, default_settings{:});
        end
        
        %Load a profile from disk
        function rerp_profile = loadRerpProfile(varargin)
            import rerp_dependencies.*
            
            p=inputParser;
            addOptional(p,'path',[]);
            addOptional(p,'rerp_path', pwd);
            parse(p, varargin{:});
            rerp_profile=0;
            
            if isempty(p.Results.path)
                %No path specified, launch GUI
                [filename, pathname] = uigetfile({'*.rerp_profile';'*.rerp_result'}, 'Load rerp profile:', p.Results.rerp_path);
                path = [pathname filename];
            else
                path = p.Results.path;
                filename=1;
            end
            
            %Read profile from disk
            if ~filename==0
                try
                    res = load(path, '-mat');
                    
                    rerp_profile = res.obj;
                    
                    %Extract the profile if loading from .rerp_result file
                    if isa(rerp_profile,'RerpResult')
                        rerp_profile = rerp_profile.rerp_profile;
                    end
                    
                catch e
                    disp(['RerpProfile: could not read the specified profile from disk ' path]);
                    rethrow(e);
                end
            end
        end            
    end
end

%Defines the contract for instantiating RerpProfile.
function p = makeParser
p=inputParser;

%Validation functions
validateBinary = @(x) isempty(setdiff(x, [0 1])) && isscalar(x);
validateBoundaries = @(x) length(x)==2 && isnumeric(x);
validateChar = @(x) ischar(x);
validateCell = @(x) iscell(x);
validateNumeric = @(x) isnumeric(x);

%These arguments are all required, but it is more readable to use
%name-value pairs (i.e. addOptional).
addOptional(p,'type_proc', [], validateBinary);
addOptional(p,'ersp_enable', [], validateBinary);
addOptional(p,'nbins', [], validateNumeric);
addOptional(p,'rerp_result_autosave', [], validateBinary);

addOptional(p,'category_epoch_boundaries', [], validateBoundaries);
addOptional(p,'continuous_epoch_boundaries', [], validateBoundaries);

addOptional(p,'artifact_rejection_enable',[], validateBinary);
addOptional(p,'artifact_variable_enable',[], validateBinary);
addOptional(p,'artifact_function_name', [], validateChar);

addOptional(p,'exclude_event_types',[],validateCell);

addOptional(p,'hed_enable',[], validateBinary);
addOptional(p,'enforce_hed_spec',[], validateBinary);
addOptional(p,'hed_spec_path',[], validateChar);

addOptional(p,'exclude_tag',[]);
addOptional(p,'seperator_tag',[]);
addOptional(p,'continuous_tag',[]);

addOptional(p,'regularization_enable',[], validateBinary);
addOptional(p,'lambda',[], validateNumeric);
addOptional(p,'cross_validate_enable',[], validateBinary);
addOptional(p,'num_xvalidation_folds',[],validateNumeric);
addOptional(p,'num_grid_zoom_levels',[],validateNumeric);
addOptional(p,'num_grid_points',[],validateNumeric);
addOptional(p,'first_phase_lambda',[],validateNumeric);
addOptional(p,'elasticnet_quick_zoom',[],validateBinary);
addOptional(p,'penalty_func',[]);
addOptional(p,'penalty_options',[], validateCell);
end


