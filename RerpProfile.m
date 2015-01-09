%RERP_PROFILE Define the regression settings used to call to rerp()
%   Usage:
%       rerp_profile = RerpProfile(EEG);
%           Create a profile for EEG using default settings from default.rerp_profile
%           or hard coded defaults if file is not available
%
%       rerp_profile = RerpProfile(EEG, settings);
%           Create a profile for EEG using the settings from another profile
%           (settings=rerp_profile.settings)
%
%       rerp_profile = RerpProfile(EEG, other_rerp_profile);
%           Create a profile for EEG based on another RerpProfile object
%
%       rerp_profile = RerpProfile(EEG, rerp_result);
%           Create a profile for EEG based on RerpResult object (extracts
%           the settings used to get that result)
%
%   See also: rerp_profile_gui, pop_rerp, rerp, RerpResult
classdef RerpProfile < matlab.mixin.Copyable
    properties
        %This struct can be applied to many datasets with the same experimental event types/ hed tag structure.
        %Can use it to instantiate new RerpProfile objects.
        %See RerpProfile.getDefaultRerpProfile method for default settings.
        settings;
        
        eeglab_dataset_name=''; % Full path to dataset
        sample_rate=[]; %Smaple rate of dataset
        pnts=[]; %Number of samples in dataset
        nbchan=[];%Number of channels in dataset
        
        include_chans=[];        % Channel numbers to include in regression
        include_comps=[];        % Component numbers to include in regression
        
        these_events=[];        % Object of class event stores all event information for dataset
        event_types={};         % Unique event types in dataset 
        
        num_event_types=[];        % Number of times each event occurs
        event_type_descriptions={};        % Description of each event type (must enter this manually)
        include_event_types={};        % Event types to include in regression
        include_separator_tag={};
        include_continuous_tag={};
        
        variable_artifact_indexes=[];        % Artifact indexes to use when settings.artifact_variable_enable==1
        artifact_variable_name='';        % Name of the variable used as source for variable_artifact_indexes
        computed_artifact_indexes=[];        % Artifact indexes to use when settings.artifact_variable_enable==0
        computed_artifact_indexes_function_name = '';        % Name of function used to generate computed_artifact_indexes
        
        hed_tree={};        % hedTree object compiled from included hed tags
        include_tag={};        % unique hed tags to include in regression
        include_ids={};        % for each unique tag, the index of the events which are hit by that tag
        
        context_group={};        % cell array of groups generated by seperator tags; 1 group per seperator tag (see pop_rerp for additional info)
        continuous_var={};        % cell array of continuous variables
        
        name    %Name of the file this profile was loaded from (only valid immediately after calling RerpProfile.loadRerpProfile)
        user_data    %variable that can be used to store any other information
    end
    
    methods
        function obj = RerpProfile(EEG, varargin)
            
            import rerp_dependencies.*
            
            if nargin == 0
                help RerpProfile;
                
            elseif nargin == 1
                obj = RerpProfile.getDefaultProfile(EEG);
                
            else
                events = event;
                obj.these_events = events.eeglab2event(EEG);
                
                obj.event_types = obj.these_events.uniqueLabel;
                obj.num_event_types = obj.these_events.getNumberOfOccurancesForEachEvent;
                obj.event_type_descriptions = cell(size(obj.event_types));
                [obj.event_type_descriptions{:}] = deal('');
                
                p=makeParser;
                passed_profile=[];
                if length(varargin)==1
                    if isa(varargin{1},'RerpResult')
                        theseargs={varargin{1}.rerp_profile.settings};
                        passed_profile=varargin{1}.rerp_profile;
                    elseif isa(varargin{1},'RerpProfile')
                        theseargs={varargin{1}.settings};
                        passed_profile=varargin{1};
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
                    msg = [msg '\r\t' missing{i} '\n'];
                end
                
                if ~isempty(missing)
                    fprintf(msg);
                    error('RerpProfile: failed to create profile');
                end
                
                fprintf('RerpProfile: creating initial hierarchy\n');
                [obj.continuous_var, new_all_tags, s.continuous_tag, s.separator_tag, s.separator_tag_children] = make_continuous_var(obj.these_events);
                obj.hed_tree = hedTree(new_all_tags);
                
                %Decide whether we include all channels or components based on
                %passed in profile. If that profile included all channels or comps, we do the same.
                %Otherwise, we use only the channels or components used in that profile.
                all_ts_idx=1:EEG.nbchan;
                if ~isempty(passed_profile)
                    %Did we include all components in prototype profile?
                    if length(passed_profile.include_comps)==passed_profile.nbchan
                        include_all_comps=1;
                    else
                        include_all_comps=0;
                    end
                    %Did we include all channels in prototype profile?
                    if length(passed_profile.include_chans)==passed_profile.nbchan
                        include_all_chans=1;
                    else
                        include_all_chans=0;
                    end
                    %Decide whether to include all or subset of components in
                    %this new profile
                    if ~include_all_comps
                        obj.include_comps=intersect(passed_profile.include_comps, all_ts_idx);
                    else
                        obj.include_comps=all_ts_idx;
                    end
                    
                    %Decide whether to include all or subset of channels in
                    %this new profile
                    if ~include_all_chans
                        obj.include_chans=intersect(passed_profile.include_chans, all_ts_idx);
                    else
                        obj.include_chans=all_ts_idx;
                    end
                    
                    %Copy over descriptions for common event types
                    [~, idx1, idx2] = intersect(passed_profile.event_types, obj.event_types);
                    obj.event_type_descriptions(idx2) = passed_profile.event_type_descriptions(idx1);
                    
                    %If passed profile is from same dataset, copy artifact
                    %indexes and function name
                    passed_datasetname = regexp(char(passed_profile.eeglab_dataset_name), '.*[\\\/](.*\.set)','tokens');
                    if ~isempty(passed_datasetname)
                        if strcmp(EEG.filename, passed_datasetname{1}{1})
                            disp('RerpProfile: copying artifact indexes from template profile');
                            obj.computed_artifact_indexes = passed_profile.computed_artifact_indexes;
                            obj.computed_artifact_indexes_function_name = passed_profile.computed_artifact_indexes_function_name;
                        end
                    end
                    
                else
                    %No protptype profile was passed, so we include all chans
                    %and comps
                    obj.include_comps=all_ts_idx;
                    obj.include_chans=all_ts_idx;
                end
                               
                
                obj.eeglab_dataset_name = fullfile(EEG.filepath, EEG.filename);          
                obj.sample_rate = EEG.srate;
                obj.pnts = EEG.pnts;
                obj.nbchan=EEG.nbchan;
                
                assert(isempty(setdiff(s.penalty_func, s.penalty_options)), 'RerpProfile: settings.penalty_func must be a subset of settings.penalty_options');
                
                % If this is a brand new profile, assign all tags to
                % exclude_tags, all continuous tags to exclude_continuous_tags.
                if ~iscell(s.exclude_tag)
                    s.exclude_tag = obj.hed_tree.uniqueTag;
                    s.exclude_continuous_tag = s.continuous_tag;
                    s.exclude_separator_tag = s.separator_tag;
                else
                    s.exclude_tag=intersect(s.exclude_tag, obj.hed_tree.uniqueTag);
                end
                
                fprintf('RerpProfile: parsing hierarchy\n');
                parse_hed_tree(obj, s);
                
                possible_excluded = intersect(obj.event_types, s.exclude_event_types);
                obj.include_event_types = setdiff(obj.event_types, possible_excluded);
                
                rerp_path_components=regexp(char(strtrim(mfilename('fullpath'))),'[\/\\]','split');
                results_path = [fullfile(rerp_path_components{1:(end-1)}) filesep 'results'];
                s.autosave_results_path=results_path;
                
                obj.settings = s;
                
                disp('RerpProfile: finished');
            end
        end
        
        function saveRerpProfile(obj, varargin)
            %Save a profile to disk
            %   Usage:
            %       rerp_profile.saveRerpProfile;
            %           opens a gui to choose the path to save profile
            %
            %       rerp_profile.saveRerpProfile('rerp_path', '/data/projects/RSVP');
            %           opens gui starting at that path
            %
            %       rerp_profile.saveRerpProfile('path', '/data/projects/RSVP/exp_53.rerp_profile');
            %           save this profile to the specific path (will create the
            %           dir if does not exist)
            import rerp_dependencies.*
            
            p=inputParser;
            addOptional(p,'path',[]);
            addOptional(p,'rerp_path', fullfile(RerpProfile.rerp_path, 'profiles'));
            
            parse(p, varargin{:});
            path = p.Results.path;
            rerp_path= p.Results.rerp_path;
            
            if isempty(path)
                %No path specified, launch GUI
                temp = regexp(obj.eeglab_dataset_name, '.*[\\\/](.*)\.set', 'tokens');
                if ~isempty(temp)
                    fn = temp{1}{1};
                else
                    fn='';
                end
                
                [filename, pathname] = uiputfile('*.rerp_profile', 'Save rerp profile as:', fullfile(rerp_path, fn));
                
                path = [pathname filename];
                
            else
                path2file = regexp(path, '(.*)[\\\/].*','tokens');
                path2file = path2file{1}{1};
                
                if isempty(dir(path2file))
                    mkdir(path2file);
                end
                
                filename=1;
            end
            
            
            %Save profile to disk
            if filename
                this_path = regexp(path, '(.*)(?:\.rerp_profile)','tokens');
                this_path = this_path{1}{1};
                try
                    save([this_path '.rerp_profile'], 'obj','-mat');
                    disp(['RerpProfile: saved profile to disk ' path]);
                catch e
                    fprintf('RerpProfile: could not save the specified profile, %s\n', path);
                    rethrow(e);
                end
            end
        end
        
        function compute_artifact_indexes(obj, EEG)
            %Compute artifact frames using the function specified in rerp_profile.settings.artifact_function_name and store the indexes in the profile
            %   Usage:
            %       rerp_profile.compute_artifact_indexes(EEG);
            %           computes artifact indexes and saves them in
            %           rerp_profile.computed_artifact_indexes;
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
            %Set the artifact indexes of the profile directly
            %   Usage:
            %       rerp_profile.set_artifact_indexes(artifact_indexes)
            %           artifact indexes must be a logical vector same length
            %           as data.
            assert(length(artifact_indexes)==obj.pnts, 'RerpProfile: artifact indexes must be logical vector same length as data');
            obj.variable_artifact_indexes= artifact_indexes;
            obj.artifact_variable_name='passed in';
            obj.settings.artifact_variable_enable=1;
        end
        
        
        function setDefaultProfile(obj)
            %Save stripped down profile to be used as a template for new profiles
            %   Usage:
            %       rerp_profile.setDefaultProfile;
            %           saves a template version of the profile in profiles/default.rerp_profile
            defpro=copy(obj);
            defpro.settings.exclude_tag=0;
            
            [defpro.eeglab_dataset_name,...
                defpro.sample_rate,...
                defpro.pnts,...
                defpro.these_events,...
                defpro.event_types,...
                defpro.num_event_types,...
                defpro.event_type_descriptions,...
                defpro.include_event_types,...
                defpro.variable_artifact_indexes,...
                defpro.artifact_variable_name,...
                defpro.computed_artifact_indexes,...
                defpro.computed_artifact_indexes_function_name] = deal([]);
            
            [defpro.hed_tree,...
                defpro.include_tag,...
                defpro.include_ids,...
                defpro.context_group,...
                defpro.continuous_var]= deal({});
            
            defpro.saveRerpProfile('path',fullfile(RerpProfile.rerp_path, 'profiles','default.rerp_profile'));
        end
        
        
        function setLastProfile(obj)
            %Save profile as profiles/last.rerp_profile
            %   Usage:
            %       rerp_profile.setLastProfile;
            obj.saveRerpProfile('path', fullfile(RerpProfile.rerp_path, 'profiles','last.rerp_profile'));
        end
        
        function [predictor_matrix, data_pad, parameter_idx_layout] = predictor(obj)
            %Get the predictor matrix for this profile
            %   Usage:
            %       [predictor, data_pad, parameter_idx_layout] = rerp_profile.predictor;
            %
            %   Output:
            %       predictor: Toeplitz matrix describing the occurance of
            %           events in experiment
            %
            %       data_pad: predictor has been padded with zeros along
            %           its first dimension. to compare original data with modeled data,
            %           it is necessary to pad the original data to match
            %           the predictor. pad original data with data_pad(1)
            %           zeros at the beginning and data_pad(2) zeros at the
            %           end.
            %
            %       parameter_idx_layout: cell array of indexes into second
            %           dimension of predictor. each set of indexes
            %           corresponds to a distinct event type.
            import rerp_dependencies.predictor_gen
            [predictor_matrix, data_pad, parameter_idx_layout] = predictor_gen(obj);
        end
    end
    
    methods(Static=true)
        
        function h = get_artifact_handle(instr)
            %Get the artifact function handle with new string. Function must be in a file.
            %This will throw an error if the file is not found.
            %   Usage:
            %       artifact_function_handle = get_artifact_handle('rerp_reject_samples_robcov');
            %           gets the function handle from the file
            %           rerp_reject_samples_robcov.m or returns an error
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
        
        function rerp_profile = getDefaultProfile(EEG)
            %Get default RerpProfile for single EEG dataset. Same as calling RerpProfile(EEG).
            %   Usage:
            %       rerp_profile = RerpProfile.getDefaultRerpProfile(EEG);
            import rerp_dependencies.*
            
            disp('RerpProfile: loading default settings');
            %Create profile based on profiles/default.rerp_profile
            try
                default_path = fullfile(RerpProfile.rerp_path, 'profiles','default.rerp_profile');
                default_profile = RerpProfile.loadRerpProfile('path', default_path);
                rerp_profile = RerpProfile(EEG, default_profile);
                
                %If it doesn't exist, start a brand new default profile
            catch e
                default_settings = {...
                    'type_proc', 0,... 0 for ICA or 1 for channels
                    'include_exclude', 0,...
                    'ersp_enable',0,...perform time-frequency decomposition first
                    'nbins', 64,...number of freq bins to use when ersp_enable==1
                    'rerp_result_autosave', 1,...automatically save the regression result
                    'autosave_results_path',[],... % pop_rerp automatically saves a copy of the regression result to this path if settings.rerp_result_autosave==1
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
                    'hed_enable', 0,...enable hierarchical regression
                    'enforce_hed_spec',0,...throw an error if a hed tag does not comply with the hed spec (very slow)
                    'hed_spec_path',fullfile('hed', 'hed_specification_1.3.xml'),...
                    ...
                    'exclude_tag',0,...tags to exclude from regresion
                    'separator_tag',{},...tags to generate seperate groups of variables based on which events are hit by the tag's children.
                    'separator_tag_children',{},...
                    'exclude_separator_tag',{},...
                    'continuous_tag',{},...tags which have a magnitude associated (e.g. Stimulus/Visual/Luminance/#/.25)
                    'exclude_continuous_tag',{},...
                    ...
                    'regularization_enable', 1,...enable penalized regression
                    'lambda',[1 1],...specify lambda to use if cross validation is disabled
                    'cross_validate_enable', 1,...do a grid search for lambda
                    'num_xvalidation_folds', 5,...number of folds to use during cross validation
                    'num_grid_zoom_levels', 2,...number of levels of grid search zooming
                    'num_grid_points', 10,...number of points to sample at each grid level
                    'first_phase_lambda', [0 logspace(log10(1e-6), log10(1e8), 20)]',... the initial sample space for grid search
                    'elasticnet_quick_zoom', 1,...for ElasticNet (L1+L2) penalty. find optimal lambda1 and lambda2 serpately first, then 2D grid search around those values
                    'penalty_func',{'L2 norm'},...penalty function
                    'penalty_options',{'L1 norm' 'L2 norm' 'Elastic net'},... available options for penalty function
                    'save_grid_search',0,...
                    };
                
                %Initialize profile
                rerp_profile = RerpProfile(EEG, default_settings{:});
                rerp_profile.setDefaultProfile;
            end
        end
        
        function path = rerp_path
            %Get path to rERP toolbox
            %   Usage:
            %       path=RerpProfile.rerp_path;
            rerp_path=mfilename('fullpath');
            rerp_path=regexp(rerp_path, ['^(.*)' filesep '.*$'], 'tokens');
            path=rerp_path{:}{:};
        end
        
        function rerp_profile = loadRerpProfile(varargin)
            %Load profiles from disk.
            %   Usage:
            %       rerp_profile = RerpProfile.loadRerpProfile;
            %           Select .rerp_profile file using GUI
            %
            %       rerp_profile = RerpProfile.loadRerpProfile('rerp_path', '/data/projects/RSVP');
            %           Open GUI starting at that path
            %
            %       rerp_profile = RerpProfile.loadRerpProfile('path', '/data/projects/RSVP/exp_53.rerp_profile');
            %           Loads rerp_profile from that path, if present
            %
            %       rerp_profile = RerpProfile.loadRerpProfile('path', '/data/projects/RSVP');
            %           Loads all .rerp_profile files from that directory
            %
            import rerp_dependencies.*
            
            rerp_profile=[];
            p=inputParser;
            addOptional(p,'path',[]);
            addOptional(p,'rerp_path', fullfile(RerpProfile.rerp_path,'profiles'));
            parse(p, varargin{:});
            
            if isempty(p.Results.path)
                %No path specified, launch GUI
                [filename, pathname] = uigetfile('*.rerp_profile;*.rerp_result', 'Load rerp profile:', p.Results.rerp_path, 'multiselect','on');
                if iscell(filename)
                    path = cellfun(@(x) [pathname x], filename, 'UniformOutput', false);
                elseif filename
                    path = cellstr(fullfile(pathname, filename));
                    filename=cellstr(filename);
                else
                    return;
                end
            else
                pathname = p.Results.path;
                %If path was a directoy, we load all the .rerp_result files
                %in that directory
                if isdir(pathname)
                    profdir=dir(fullfile(pathname, '*.rerp_profile'));
                    filename={profdir(:).name};
                    path=cellfun(@(x) fullfile(pathname, x), filename, 'uniformoutput', false);
                else
                    filename=regexp(pathname, '.*[\\\/](.*\.rerp_profile)','match');
                    path={pathname};
                end
            end
            
            %Read profile from disk
            rerp_profile=cell(1,length(path));
            for i=1:length(path)
                if path{i}
                    try
                        res = load(path{i}, '-mat');
                        rerp_profile{i} = res.obj;
                        
                        %Extract the profile if loading from .rerp_result file
                        if isa(rerp_profile{i}, 'RerpResult')
                            rerp_profile{i} = rerp_profile{i}.rerp_profile;
                        end
                        
                        rerp_profile{i}.name = filename{i};
                    catch e
                        fprintf('RerpProfile: could not read the specified profile, %s\n', path{i});
                        rethrow(e);
                    end
                end
            end
            
            rerp_profile = rerp_profile(cell2mat(cellfun(@(x) ~isempty(x), rerp_profile, 'UniformOutput', false)));
            rerp_profile = [rerp_profile{:}];
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function cpObj = copyElement(obj)
            import rerp_dependencies.*

            % Make a shallow copy of all properties
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            
            % Make a deep copy of these_events and hed_tree
            if isa(obj.these_events, 'event')
                cpObj.these_events = copy(obj.these_events);
            end
            
            if isa(obj.hed_tree, 'hedTree')
                cpObj.hed_tree = copy(obj.hed_tree);
            end
        end
    end
end

function p = makeParser
%Define the contract for instantiating RerpProfile.
%You must provide these exact fields in order to instantiate RerpProfile.p=inputParser;
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
addOptional(p,'include_exclude', [], validateBinary);

addOptional(p,'ersp_enable', [], validateBinary);
addOptional(p,'nbins', [], validateNumeric);

addOptional(p,'rerp_result_autosave', [], validateBinary);
addOptional(p,'autosave_results_path',[]);

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
addOptional(p,'separator_tag',[]);
addOptional(p,'separator_tag_children',[]);
addOptional(p,'exclude_separator_tag',[]);
addOptional(p,'continuous_tag',[]);
addOptional(p,'exclude_continuous_tag',[]);

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
addOptional(p,'save_grid_search',[],validateBinary);
end


