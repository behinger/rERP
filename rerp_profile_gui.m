%Provide GUI access to RerpProfile objects
%   Usage:
%       exitcode = rerp_profile_gui(rerp_profile);
%           After presing OK on the gui, rerp_profile will be altered.
%           Cancel aborts the changes.
%
%   Parameters:
%       exitcode:
%           Set to 1 if the user pressed OK, 0 otherwise
%
%       rerp_profile:
%           The RerpProfile object to modify
function exitcode = rerp_profile_gui( rerp_profile )
%RERP_PROFILE_GUI GUI Modifies RerpProfile objects
assert(isa(rerp_profile,'RerpProfile'),'rerp_profile_gui: can only be called on an RerpProfile object');

exitcode=0;
view_only=0;
cp = rerp_profile;
s = cp.settings;
current_included_hed_tree={};
processing_types = {'components' 'channels'};
hed_list_selected = [];
gui_handle=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pop up window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% popup window parameters
% -----------------------

g2 = [25 25];
g3 = [16.67 16.66 16.67];
g4 = [12.5 12.5 12.5 12.5];
g5 = [10 10 10 10 10];

geomhoriz    = { [17 22 11]  [17 11 11 11]     [17 11 11 11]  [17 8 17 8]    [17 16 17] 1      g2 g2 g2   g2 g2   g2 g2 g2 1 1     [15 10 12.5 12.5] [15 10 12.5 12.5] [15 10 12.5 12.5] };
geomvert = [1 1      1 1       1 1        1 5 1    1 1   1 8 1 1 1       1 1 2 ];

title = ['RerpProfile: ' cp.name];


%Make sure gui handles are scoped to this level, available to nested functions
[ui_enterExcludeChans, ui_typeProcLabel, ui_switchIncludeExcludeButton, ui_enterNumBins, ui_numBinsLabel, ui_switchTypeButton, ui_rejectedFramesCounter,...
    ui_enableArtifactVariable, ui_enterArtifactVariable, ui_enterArtifactFunction, ui_artifactFunction,...
    ui_computeArtifactButton, ui_includeUniqueevent_typesList, ui_excludeUniqueevent_typesList, ui_enableHed,...
    ui_enforceHed, ui_changeHedSpec, ui_displayHierarchy, ui_includeUniqueTagsList, ui_excludeUniqueTagsList,...
    ui_continuousTagsList, ui_seperatorTagsList, ui_tagIncludeButton, ui_tagExcludeButton, ui_tagSeperatorButton,...
    ui_tagContinuousButton, ui_parameterCountLabel, ui_includeTagsLabel, ui_excludeTagsLabel, ui_continuousTagsLabel,...
    ui_seperatorTagsLabel, ui_enterLambda, ui_enableXValidate, ui_enterNumFolds, ui_penaltyFunctionList, ui_lambdaLabel,...
    ui_penaltyLabel, ui_autosavePathLabel, enableHedStatus,enableArtifactRejectionStatus,enableArtifactVariableStatus,enableLambdaStatus,...
    enableRegularizationStatus,enableXvalidationStatus,enableAutosaveStatus,include_exclude_status,...
    enableErspStatus] = deal([]);

make_gui;
reload_hed; 
uiwait(gui_handle);
cp.settings=s;
drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GUI Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%EXCLUDE channels/ICs
    function cllbk_get_time_series(src, eventdata)
        src_props = get(src);
        time_series = str2num(src_props.String);
        if s.type_proc==0
            if s.include_exclude
                cp.include_comps = time_series;
            else
                cp.include_comps = setdiff(1:cp.nbchan,time_series);
            end
        else
            if s.include_exclude
                cp.include_chans = time_series;
            else
                cp.include_chans = setdiff(1:cp.nbchan, time_series);
            end
        end
    end

%CHOOSE ICs or channels
    function cllbk_switch_type(src, eventdata)
        if s.type_proc==1
            s.type_proc = 0;
        else
            s.type_proc = 1;
        end
        
        [type_of_processing, other_type, time_series, message] = get_proc_types;
        
        set(ui_typeProcLabel, 'string', message);
        set(ui_switchTypeButton, 'string', [upper(type_of_processing(1)) type_of_processing(2:end)]);
        set(ui_enterExcludeChans, 'string', num2str(time_series));
        cllbk_get_time_series(ui_enterExcludeChans);
    end

%CHOOSE whether to include or exclude ICs or channels
    function cllbk_switch_include_exclude(src, eventdata)
        
        if s.include_exclude
            s.include_exclude=0;
            include_exclude_status='Exclude';
            cp.include_comps=1:cp.nbchan;
            cp.include_chans=1:cp.nbchan;
            
        else
            s.include_exclude=1;
            include_exclude_status='Include';
            cp.include_comps=[];
            cp.include_chans=[];
        end
        
        [type_of_processing, other_type, time_series, message] = get_proc_types;
        
        set(ui_typeProcLabel, 'string', message);
        set(ui_switchIncludeExcludeButton, 'string',include_exclude_status);
        set(ui_enterExcludeChans, 'string', num2str(time_series));
        cllbk_get_time_series(ui_enterExcludeChans);
    end

%USE profile last.rerp_profile
    function cllbk_enable_ersp(src, eventdata)
        src_props = get(src);
        a=ver;
        toolboxes={a(:).Name};
        
        if ~any(strcmp('Wavelet Toolbox',toolboxes))
            s.ersp_enable=0;
            set(src, 'Value',0);
            warning('rerp_profile_gui: time frequncy decmposition for rERSP requires wavelet toolbox');
        else
            s.ersp_enable=src_props.Value;
        end
        
        if s.ersp_enable
            enableErspStatus='on';
        else
            enableErspStatus='off';
        end
        
        set([ui_enterNumBins ui_numBinsLabel],'enable', enableErspStatus);
        [type_of_processing, other_type, time_series, message] = get_proc_types;
        set(ui_typeProcLabel, 'string', message);
        cllbk_get_time_series(ui_enterExcludeChans);
    end

    function cllbk_result_autosave_enable(src, eventdata)
        prop = get(src);
        if prop.Value==1
            s.rerp_result_autosave=1;
            enableAutosaveStatus='on';
        else
            s.rerp_result_autosave=0;
            enableAutosaveStatus='off';
        end
        cllbk_autosave_path_label;
    end

    function cllbk_result_autosave_path(src, eventdata)
        newpath=uigetdir(EEG.filepath);
        if newpath
            s.autosave_results_path = newpath;
            cllbk_autosave_path_label;
        end
    end

    function cllbk_autosave_path_label(src, eventdata)
        set(ui_autosavePathLabel, 'enable', enableAutosaveStatus, 'string', s.autosave_results_path);
    end

%ENTER epoch boundary
    function cllbk_enter_epoch_boundaries(src, eventdata)
        src_props = get(src);
        if strcmp(src_props.Tag, 'enterCatEpochBoundary')
            s.category_epoch_boundaries = str2num(src_props.String);
        elseif strcmp(src_props.Tag, 'enterConEpochBoundary')
            s.continuous_epoch_boundaries = str2num(src_props.String);
        end
    end

%ENABLE artifact rejection
    function cllbk_enable_artifact_rejection(src, eventdata)
        props = get(src);
        s.artifact_rejection_enable=props.Value;
        
        if s.artifact_rejection_enable==1
            enableArtifactRejectionStatus = 'on';
        else
            enableArtifactRejectionStatus = 'off';
        end
        
        set(ui_rejectedFramesCounter, 'enable', enableArtifactRejectionStatus);
        set(ui_enableArtifactVariable, 'enable', enableArtifactRejectionStatus);
        set(ui_artifactFunction, 'enable', enableArtifactRejectionStatus);
        set(ui_enterArtifactFunction, 'enable', enableArtifactRejectionStatus);
        set(ui_computeArtifactButton, 'enable', enableArtifactRejectionStatus);
        
        %        cllbk_enable_artifact_name(ui_enableArtifactVariable);
    end

%ENTER artifact function name
    function cllbk_enter_artifact_function_name(src, eventdata)
        src_props = get(src);
        instr = strtrim(src_props.String);
        try
            RerpProfile.get_artifact_handle(instr);
            s.artifact_function_name = instr;
            cp.settings.artifact_function_name=instr;
            fprintf('rerp_profile_gui: using artifact function %s\n', s.artifact_function_name);
        catch e
            set(src, 'String', s.artifact_function_name);
            disp(e.message);
        end
    end

% %COMPUTE artifact frames
%     function cllbk_compute_artifact(src, eventdata)
%         cp.compute_artifact_indexes(EEG);
%         refresh_artifact_counter;
%         drawnow;
%     end

%ENABLE use of artifact variable from workspace
    function cllbk_enable_artifact_name(src, eventdata)
        src_props = get(src);
        s.artifact_variable_enable=src_props.Value;
        enableArtifactVariableStatus=src_props.Enable;
        
        if ~s.artifact_variable_enable
            set(ui_enterArtifactVariable, 'enable','off');
            set(ui_artifactFunction, 'enable', enableArtifactRejectionStatus);
            set(ui_enterArtifactFunction, 'enable', enableArtifactRejectionStatus);
            set(ui_computeArtifactButton, 'enable', enableArtifactRejectionStatus);
            
        else
            
            set(ui_enterArtifactVariable, 'enable', enableArtifactVariableStatus);
            set(ui_artifactFunction, 'enable', 'off');
            set(ui_enterArtifactFunction, 'enable', 'off');
            set(ui_computeArtifactButton, 'enable', 'off');
            
            cllbk_enter_artifact_name(ui_enterArtifactVariable);
        end
        
        refresh_artifact_counter;
    end

%ENTER artifact variable name from workspace
    function cllbk_enter_artifact_name(src, eventdata)
        src_props = get(src);
        instr = strtrim(src_props.String);
        
        if ~isempty(instr)
            try
                retvar = evalin('base', instr);
                try
                    if isempty(setdiff(retvar, [0 1]));
                        if length(retvar)==EEG.pnts
                            fprintf('rerp_profile_gui: artifact variable %s successfully imported from workspace\n', instr);
                            cp.variable_artifact_indexes = retvar;
                            cp.artifact_variable_name = instr;
                        else
                            fprintf('rerp_profile_gui: artifact variable %s not same length as data... should be a binary index vector same length as data\n', instr);
                        end
                    else
                        fprintf('rerp_profile_gui: artifact variable %s not binary index vector\n', instr);
                    end
                catch
                    fprintf('rerp_profile_gui: unknown error importing artifact variable %s from workspace\n', instr);
                end
            catch
                if ~strcmp(instr, cp.artifact_variable_name)
                    fprintf('rerp_profile_gui: artifact variable %s not found in workspace\n', instr);
                else
                    fprintf('rerp_profile_gui: using previous artifact variable %s\n', instr);
                end
            end
        end
        
        set(src,'string', cp.artifact_variable_name);
        refresh_artifact_counter;
        
    end

%ENTER event type descriptions
    function cllbk_description_edit(src, eventdata)
        if strcmpi(eventdata.Key, 'return')||strcmpi(eventdata.Key, 'enter')
            [new_descriptions, thisexitcode] = event_descriptions_gui(...
                'event_descriptions', cp.event_type_descriptions,...
                'event_types', cp.event_types);
            
            if thisexitcode
                cp.event_type_descriptions = new_descriptions;
            end
            
            [cp.include_event_types, include_event_types_idx, exclude_event_types_idx, include_descriptions_event_types, exclude_descriptions_event_types] = get_event_type_split(...
                cp.event_types, s.exclude_event_types, cp.event_type_descriptions);
            
            set(ui_includeUniqueevent_typesList, 'string', include_descriptions_event_types,...
                'value', []);
            
            set(ui_excludeUniqueevent_typesList, 'string', exclude_descriptions_event_types,...
                'value', []);
        end
    end

%INCLUDE selected event_types
    function cllbk_event_type_add(src, eventdata)
        exclude_props = get(ui_excludeUniqueevent_typesList);
        exc_str = strip_descriptions(exclude_props.String);
        exc_idx = exclude_props.Value;
        
        s.exclude_event_types = setdiff(s.exclude_event_types, exc_str(exc_idx));
        
        [cp.include_event_types, include_event_types_idx, exclude_event_types_idx, include_descriptions_event_types, exclude_descriptions_event_types] = get_event_type_split(...
            cp.event_types, s.exclude_event_types, cp.event_type_descriptions);
        
        set(ui_includeUniqueevent_typesList, 'string', include_descriptions_event_types,...
            'value', []);
        
        set(ui_excludeUniqueevent_typesList, 'string', exclude_descriptions_event_types,...
            'value', []);
        
        if s.hed_enable
            set(ui_enableHed,'String','Hierarchical regression - wait, loading hierarchy ... ');
            drawnow;
            reload_hed;
        end
    end

%EXCLUDE selected event_types
    function cllbk_event_type_remove(src, eventdata)
        include_props = get(ui_includeUniqueevent_typesList);
        inc_str = strip_descriptions(squeeze(include_props.String));
        inc_idx = include_props.Value;
        
        s.exclude_event_types = {inc_str{inc_idx} s.exclude_event_types{:}};
        
        [cp.include_event_types, include_event_types_idx, exclude_event_types_idx, include_descriptions_event_types, exclude_descriptions_event_types] = get_event_type_split(...
            cp.event_types, s.exclude_event_types, cp.event_type_descriptions);
        
        set(ui_includeUniqueevent_typesList, 'string', include_descriptions_event_types,...
            'value', []);
        
        set(ui_excludeUniqueevent_typesList, 'string', exclude_descriptions_event_types,...
            'value', []);
        
        if s.hed_enable
            set(ui_enableHed,'String','Hierarchical regression - wait, loading hierarchy ... ');
            drawnow;
            reload_hed;
        end
    end

%ENABLE hed tags instead of orignial event event_types
    function cllbk_hed_enable(src, eventdata)
        props = get(src);
        
        if props.Value==1
            enableHedStatus = 'on';
            set(ui_enableHed,'String','Hierarchical regression - wait... loading');
            drawnow;
            
            s.hed_enable=1;
            if s.enforce_hed_spec
                set(ui_enforceHed,'String','Enforce HED specification - wait... loading');
                drawnow;
            end
        else
            enableHedStatus = 'off';
            s.hed_enable=0;
            set(ui_enableHed,'String','Hierarchical regression');
            set(ui_enforceHed,'String','Enforce HED specification');
        end
        
        if s.hed_enable
            reload_hed;
        end
        
        set(ui_changeHedSpec, 'enable', enableHedStatus);
        set(ui_enforceHed, 'enable', enableHedStatus);
        set(ui_displayHierarchy, 'enable', enableHedStatus);
        
        set(ui_includeUniqueTagsList, 'enable', enableHedStatus);
        set(ui_excludeUniqueTagsList, 'enable', enableHedStatus);
        set(ui_continuousTagsList, 'enable', enableHedStatus);
        set(ui_seperatorTagsList, 'enable', enableHedStatus);
        
        set(ui_tagExcludeButton, 'enable', enableHedStatus);
        set(ui_tagSeperatorButton, 'enable', enableHedStatus);
        set(ui_tagContinuousButton, 'enable', enableHedStatus);
        set(ui_tagIncludeButton, 'enable', enableHedStatus);
        
        set(ui_seperatorTagsLabel, 'enable', enableHedStatus);
        set(ui_continuousTagsLabel, 'enable', enableHedStatus);
        set(ui_includeTagsLabel, 'enable', enableHedStatus);
        set(ui_excludeTagsLabel, 'enable', enableHedStatus);
    end

%ENFORCE hed specification using hedManager.m
    function cllbk_enforce_hedspec(src, eventdata)
        props = get(src);
        s.enforce_hed_spec=props.Value;
        
        if s.enforce_hed_spec
            set(ui_enforceHed,'String','Enforce HED specification - wait... loading');
            drawnow;
        end
        
        reload_hed;
    end

%CHANGE the HED specification
    function cllbk_change_hedspec(src, eventdata)
        [fn,pn] = uigetfile('*.xml','Select the HED specification XML file');
        fprintf('\nrerp_profile_gui: using %s\n',fn);
        if fn
            s.hed_spec_path = [pn fn];
        end
        reload_hed;
    end

%VIEW hierarchical java panel
    function cllbk_view_hierarchy(src, eventdata)
        if ~isempty(current_included_hed_tree)
            current_included_hed_tree.plot;
        else
            disp('rerp_profile_gui: could not display hierarchy - no hed_tree found');
        end
    end

%DESIGNATE selected tags as seperator tags
%     function cllbk_tag_seperator(src, eventdata)
%         import rerp_dependencies.*
%         if hed_list_selected == ui_seperatorTagsList
%             return;
%             
%         else
%             this_selected_list = get(hed_list_selected);
%             this_selected_value = this_selected_list.Value;
%             this_selected_str = this_selected_list.String;
%             these_tags = RerpTagList.strip_brackets(this_selected_str(this_selected_value));
%             
%             sep_props = get(ui_seperatorTagsList);
%             sep_string = sep_props.String;
%             
%             if isempty(sep_string)
%                 sep_string={};
%             end
%             
%             sep_tag = sort({these_tags{:} sep_string{:}});
%             
%             set(hed_list_selected, 'string',this_selected_str(setdiff(1:length(this_selected_str),this_selected_value)),'value', []);
%             set(ui_seperatorTagsList, 'string', sep_tag,'value', []);
%             
%             try
%                 reload_hed;
%                 
%             catch e
%                 %Didn't work, reset GUI to previous state
%                 set(hed_list_selected, 'string',this_selected_str, 'value', []);
%                 set(ui_seperatorTagsList, 'string', sep_string,'value', []);
%                 rethrow(e);
%             end
%         end
%     end

% %DESIGNATE selected tags as continuous tags
%     function cllbk_tag_continuous(src, eventdata)
%         import rerp_dependencies.*
%         if hed_list_selected == ui_continuousTagsList
%             return;
%             
%         else
%             this_selected_list = get(hed_list_selected);
%             this_selected_value = this_selected_list.Value;
%             this_selected_str = this_selected_list.String;
%             these_tags = RerpTagList.strip_brackets(this_selected_str(this_selected_value));
%             
%             cont_props = get(ui_continuousTagsList);
%             cont_string = cont_props.String;
%             
%             if isempty(cont_string)
%                 cont_string={};
%             end
%             
%             cont_tag = sort({these_tags{:} cont_string{:}});
%             
%             set(hed_list_selected, 'string',this_selected_str(setdiff(1:length(this_selected_str),this_selected_value)),'value', []);
%             set(ui_continuousTagsList, 'string', cont_tag,'value', []);
%             
%             try
%                 reload_hed;
%             catch e
%                 %Didn't work, reset GUI to previous state
%                 set(hed_list_selected, 'string',this_selected_str, 'value', []);
%                 set(ui_continuousTagsList, 'string', cont_string,'value', []);
%                 rethrow(e);
%             end
%         end
%     end

%DESIGNATE selected tags as included tags
    function cllbk_tag_include(src, eventdata)
        import rerp_dependencies.*
        if hed_list_selected == ui_includeUniqueTagsList
            return;
            
        else
            %Get the selected tags
            this_selected_list = get(hed_list_selected);
            this_selected_value = this_selected_list.Value;
            this_selected_str = this_selected_list.String;
            these_tags = RerpTagList.strip_brackets(this_selected_str(this_selected_value));
            
            %Get continous and sep tags
            these_sep_tags = intersect(these_tags, s.separator_tag);
            these_con_tags = intersect(these_tags, s.continuous_tag);
            cp.include_separator_tag=sort([cp.include_separator_tag; these_sep_tags]);
            cp.include_continuous_tag=sort([cp.include_continuous_tag; these_con_tags]);
            s.exclude_separator_tag=sort(setdiff(cp.include_separator_tag, s.separator_tag));
            s.exclude_continuous_tag=sort(setdiff(cp.include_continuous_tag, s.continuous_tag));
            
            %Get already included tags
            include_props = get(ui_includeUniqueTagsList);
            include_string = RerpTagList.strip_brackets(include_props.String);

            if isempty(include_string)
                include_string={};
            end
            
            include_tag = sort([these_tags; include_string]);
            
            set(hed_list_selected, 'string',this_selected_str(setdiff(1:length(this_selected_str),this_selected_value)),'value', []);
            set(ui_includeUniqueTagsList, 'string', include_tag, 'value', []);
            try
                reload_hed;
                
            catch e
                %Didn't work, reset GUI to previous state
                set(hed_list_selected, 'string',this_selected_str, 'value', []);
                set(ui_includeUniqueTagsList, 'string', include_string,'value', []);
                rethrow(e);
            end
        end
    end

%%DESIGNATE selected tags as excluded tags
    function cllbk_tag_exclude(src, eventdata)
        import rerp_dependencies.*
        if hed_list_selected == ui_excludeUniqueTagsList
            return;
            
        else
            this_selected_list = get(hed_list_selected);
            this_selected_value = this_selected_list.Value;
            this_selected_str = this_selected_list.String;
            these_tags = RerpTagList.strip_brackets(this_selected_str(this_selected_value));
            
            these_sep_tags = intersect(these_tags, s.separator_tag);
            these_con_tags = intersect(these_tags, s.continuous_tag);
            
            s.exclude_separator_tag=sort([these_sep_tags; s.exclude_separator_tag]);
            s.exclude_continuous_tag=sort([these_con_tags; s.exclude_continuous_tag]);
            
            cp.include_separator_tag=sort(setdiff(s.separator_tag, s.exclude_separator_tag));
            cp.include_continuous_tag=sort(setdiff(s.continuous_tag, s.exclude_continuous_tag));
   
            exclude_props = get(ui_excludeUniqueTagsList);
            exclude_string = exclude_props.String;
            
            if isempty(exclude_string)
                exclude_string={};
            end
            
            not_selected = this_selected_str(setdiff(1:length(this_selected_str),this_selected_value));
            set(hed_list_selected, 'string',not_selected,'value', []);
            
            exclude_tag = sort({these_tags{:} exclude_string{:}});
            set(ui_excludeUniqueTagsList, 'string', exclude_tag,'value', []);
            
            try
                reload_hed;
            catch e
                %Didn't work, reset GUI to previous state
                set(hed_list_selected, 'string',this_selected_str, 'value', []);
                set(ui_excludeUniqueTagsList, 'string', exclude_string,'value', []);
                rethrow(e);
            end
        end
    end

% TRACK which list is being selected from
    function cllbk_list_select(src, eventdata)
        hed_list_selected=src;
    end

% ENABLE regularization
    function cllbk_enable_regularization(src, eventdata)
        props = get(src);
        
        if props.Value==1
            enableRegularizationStatus = 'on';
            s.regularization_enable=1;
            penalties = get(ui_penaltyFunctionList);
            s.penalty_func = penalties.String(penalties.Value);
            cllbk_enable_xvalidation(ui_enableXValidate);
        else
            enableRegularizationStatus = 'off';
            s.regularization_enable=0;
            s.penalty_func={};
            cllbk_enable_xvalidation(ui_enableXValidate);
        end
        
        set(ui_enableXValidate, 'enable', enableRegularizationStatus);
        set(ui_penaltyFunctionList, 'enable', enableRegularizationStatus);
        set(ui_penaltyLabel , 'enable', enableRegularizationStatus);
    end

%ENTER lamba. lambda can be a vector.
    function cllbk_enter_lambda(src, eventdata)
        src_props = get(src);
        instr = strtrim(src_props.String);
        try
            new_lambda = str2num(instr);
            assert(length(new_lambda)==2, 'rerp_profile_gui: Lambda must have two entries [L1 norm, L2 norm]');
            assert(~any(new_lambda < 0), 'rerp_profile_advanced_gui: lambda must be >= 0');
        
        catch e
            set(src, 'String', num2str(s.lambda)); 
            throw(e); 
        end
        
        s.lambda = new_lambda;
    end

%ENABLE internal cross validation, instead of specifying lambda
    function cllbk_enable_xvalidation(src, eventdata)
        props = get(src);
        if s.regularization_enable
            if props.Value==1
                enableLambdaStatus = 'off';
                enableXvalidationStatus = 'on';
                s.cross_validate_enable=1;
            else
                enableLambdaStatus = 'on';
                enableXvalidationStatus = 'off';
                s.cross_validate_enable=0;
            end
        else
            enableLambdaStatus = 'off';
            enableXvalidationStatus = 'off';
            s.cross_validate_enable=0;
        end
        
        set(ui_lambdaLabel , 'enable', enableLambdaStatus);
        set(ui_enterLambda, 'enable', enableLambdaStatus);
        %set(ui_enterNumFolds, 'enable', enableXvalidationStatus);
    end

%CHOOSE penalty funtion
    function cllbk_choose_penalty(src, eventdata)
        props = get(src);
        s.penalty_func = props.String(props.Value);
    end

%SET current profile as default
    function cllbk_set_default_profile(src, eventdata)
        cp.settings=s;
        cp.setDefaultProfile;
    end

%SAVE current profile
    function cllbk_save_profile(src, eventdata)
        cp.settings=s;
        cp.saveRerpProfile('rerp_path', fullfile(RerpProfile.rerp_path, 'profiles'));
    end

%LOAD previously saved profile
    function cllbk_load_profile(src, eventdata)
        cp = RerpProfile.loadRerpProfile('rerp_path', fullfile(RerpProfile.rerp_path,'profiles'));
        s = cp.settings;
        close(gui_handle);
        make_gui;
    end

%SET advanced options for profile
    function cllbk_set_advanced_options(src, eventdata)
        cp.settings=s;
        uiwait(rerp_profile_advanced_gui('rerp_profile', cp));
        s=cp.settings;
    end

%CANCEL gui
    function cllbk_cancel(src, eventdata)
        close(gui_handle);
    end

%EXECUTE rerp call
    function cllbk_ok(src, eventdata)
        exitcode=1;
        close(gui_handle);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Other nested functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%RECOMPUTE the hed tree if the HED parameters are changed
    function reload_hed
        import rerp_dependencies.*
        
        if ~isempty(cp.hed_tree)
            
            ls = get(ui_excludeUniqueTagsList);
            s.exclude_tag = ls.String;
                  
            %Derive variables based on the GUI lists
            parse_hed_tree(cp, s);
            
            marked_sep_tags = cellfun(@(x) ['{ ' x ' }'], cp.include_separator_tag,'uniformoutput',false); 
            cp.include_tag=[cp.include_tag(:); marked_sep_tags(:)];
            cp.include_ids=[cp.include_ids(:); repmat({'s'}, [length(cp.include_separator_tag) 1])];
                
            set(ui_includeUniqueTagsList, 'String', cp.include_tag, 'Value', []); 
            if ~isempty(cp.context_group);
                excluded=setdiff(s.exclude_tag, {cp.context_group(:).children.tag});  
            else
                excluded=s.exclude_tag;
            end
                
            set(ui_excludeUniqueTagsList, 'String', excluded, 'Value', []);
            
            %Load the HED specification if desired
            if s.enforce_hed_spec
                try
                    hed_manager = hedManager(s.hed_spec_path);
                    current_included_hed_tree = hedTree(cp.include_tag, hed_manager);
                catch e
                    disp('rerp_profile_gui: could not load the designated HED specification');
                    current_included_hed_tree = hedTree(cp.include_tag);
                    rethrow(e);
                end
                
                %If the GUI is running, update the components
                if exist('ui_enforceHed','var')
                    set(ui_enforceHed,'String',['Enforce HED specification - version ' get_hed_version]);
                end
            else
                current_included_hed_tree = hedTree(cp.include_tag);
                set(ui_enforceHed,'String','Enforce HED specification');
            end
            set(ui_enableHed,'String','Hierarchical regression');
            update_parameter_count;
        end
    end

%RETURN hed version from hedManager class
    function hed_version = get_hed_version
        hed_version = '< not found >';
        if ~isempty(current_included_hed_tree)
            hed_version = num2str(current_included_hed_tree.hedVersion);
        end
    end

%STRIP event type desrcriptions from event type listbox items (i.e.
%included/excluded event types
    function these_event_types = strip_descriptions(these_event_type_descriptions)
        these_event_types = cell(length(these_event_type_descriptions),1);
        this_list = regexp(these_event_type_descriptions,'[  ]','split', 'once');
        for i=1:length(this_list)
            these_event_types{i} = this_list{i}{1};
        end
    end


    function refresh_artifact_counter
        if s.artifact_variable_enable
            set(ui_rejectedFramesCounter, 'string', sprintf('%d artifact frames identified (%s)', nnz(cp.variable_artifact_indexes), cp.artifact_variable_name));
        else
            set(ui_rejectedFramesCounter, 'string', sprintf('%d artifact frames identified (%s)', nnz(cp.computed_artifact_indexes), cp.computed_artifact_indexes_function_name));
        end
    end

%Gets the appropriate channel or component numbers which correspond to
%the current type of processing {rERP, rERSP} x {ICA Channels}
    function [type_of_processing, other_type, time_series, message] = get_proc_types
        if s.type_proc==0
            type_of_processing = 'components';
            temp = setdiff(processing_types, {type_of_processing});
            other_type = temp{:};
            
            if s.include_exclude
                time_series = cp.include_comps;
            else
                time_series = setdiff(1:cp.nbchan, cp.include_comps);
            end
            
        else
            type_of_processing = 'channels';
            temp = setdiff(processing_types, {type_of_processing});
            other_type = temp{:};
            
            if s.include_exclude
                time_series = cp.include_chans;
            else
                time_series = setdiff(1:cp.nbchan, cp.include_chans);
            end
        end
        
        if s.ersp_enable
            message = [include_exclude_status ' ' type_of_processing ' (rERSP)'];
        else
            message = [include_exclude_status ' ' type_of_processing];
        end
        
        time_series=unique(time_series);
    end

    function update_parameter_count
        import rerp_dependencies.*
        
        mess = '(#parameters / #data points) : (';
        %Calculate offset and length of epoch (two types of variables, continuous and categorical)
        continuous_epoch_length = s.continuous_epoch_boundaries(2) - s.continuous_epoch_boundaries(1);
        category_epoch_length = s.category_epoch_boundaries(2) - s.category_epoch_boundaries(1);
        
        %Number of samples per epoch
        category_ns = ceil(continuous_epoch_length*cp.sample_rate);
        continuous_ns = ceil(category_epoch_length*cp.sample_rate);
        
        cp.settings=s; 
        if s.hed_enable
            [ncontinvars, ncatvars, ncontextvars, ncontextchldrn] = RerpTagList.cntVarsParams(cp);
            parameter_cnt = (ncatvars + ncontextvars(1))*category_ns + (ncontinvars +ncontextvars(2))*continuous_ns; 
        else
            parameter_cnt = length(cp.include_event_types)*category_ns;
        end
        
        mess = [mess num2str(parameter_cnt) ' / ' num2str(cp.pnts) ')'];
        
        if s.hed_enable
            mess = [mess ' - (# seperator tag children / # normal and continuous tags created) : (' num2str(ncontextchldrn) ' / ' num2str(ncontextvars) ')'];
        end
        
        set(ui_parameterCountLabel, 'string', mess);
    end

% Creates a new gui window based on the current profile, refreshes
% handles
    function make_gui
        try
            if view_only
                okbuttonstatus='off';
            else
                okbuttonstatus='on';
            end
            
            try
                close(gui_handle);
            catch
            end
            
            if s.hed_enable
                enableHedStatus = 'on';
            else
                enableHedStatus = 'off';
            end
            
            if s.artifact_rejection_enable
                enableArtifactRejectionStatus='on';
            else
                enableArtifactRejectionStatus='off';
            end
            
            if s.rerp_result_autosave
                enableAutosaveStatus='on';
            else
                enableAutosaveStatus='off';
            end
            
            if s.artifact_variable_enable
                artifact_src = cp.artifact_variable_name;
                mess = sprintf('%d artifact frames', nnz(cp.variable_artifact_indexes));
                
                if s.artifact_rejection_enable
                    enableArtifactVariableStatus='on';
                else
                    enableArtifactVariableStatus='off';
                end
            else
                artifact_src = cp.computed_artifact_indexes_function_name;
                mess = sprintf('%d artifact frames', nnz(cp.computed_artifact_indexes));
                enableArtifactVariableStatus='off';
            end
            
            %Set regularization section enable
            if s.regularization_enable
                enableRegularizationStatus = 'on';
                if s.cross_validate_enable
                    enableLambdaStatus='off';
                    enableXvalidationStatus='on';
                    
                else
                    enableLambdaStatus='on';
                    enableXvalidationStatus='off';
                end
            else
                enableRegularizationStatus='off';
                enableLambdaStatus='off';
                enableXvalidationStatus='off';
            end
            
            if s.include_exclude
                include_exclude_status='Include';
            else
                include_exclude_status='Exclude';
            end
            
            if s.ersp_enable
                enableErspStatus='on';
            else
                enableErspStatus='off';
            end
            
            [~, pen_idx] = intersect(s.penalty_options, s.penalty_func);
            if isempty(pen_idx)
                pen_idx=2;
            end
            
            [cp.include_event_types, include_event_types_idx, exclude_event_types_idx, include_descriptions_event_types, exclude_descriptions_event_types ] = get_event_type_split(cp.event_types, s.exclude_event_types, cp.event_type_descriptions);
            [type_of_processing, other_type, time_series, message] = get_proc_types;
            
            exclude = setdiff(s.exclude_tag, s.separator_tag_children);
            separator_intermediate_tag=cellfun(@(x) [x '/|'], s.separator_tag, 'uniformoutput', false);  
            exclude = setdiff(exclude, [s.separator_tag; separator_intermediate_tag; s.continuous_tag]);
            exclude = sort([exclude; s.exclude_separator_tag; s.exclude_continuous_tag]);
            
            uilist = { ...
                { 'Style', 'checkbox', 'string', 'Auto-save results','tag', 'autoSaveResultsEnable', 'value', s.rerp_result_autosave,'callback', @cllbk_result_autosave_enable,'tooltipstring','Automatically save results in directory to the right'},...
                { 'Style', 'edit', 'string', s.autosave_results_path, 'horizontalalignment', 'left', 'fontsize', 8, 'tag','autosavePathLabel','enable', enableAutosaveStatus},...
                { 'Style', 'Pushbutton', 'string', 'Browse path', 'horizontalalignment', 'left','callback',@cllbk_result_autosave_path,'enable', enableAutosaveStatus,'tooltipstring','Set the autosave path for this profile'},...
                ...
                { 'Style', 'checkbox', 'string', 'rERSP','tag', 'erspEnable', 'value', s.ersp_enable,'callback', @cllbk_enable_ersp,'tooltipstring','perform time-frequency decomposition on the time-series, then perform analysis on each frequency seperately. if performing time-frequency decomposition outside of this GUI, DO NOT check this box'},...
                { 'Style', 'text', 'string', 'Number of bins', 'horizontalalignment', 'left', 'fontsize', 12,'tag','numBinsLabel','enable', enableErspStatus},...
                { 'Style', 'edit', 'string', num2str(s.nbins), 'horizontalalignment', 'left', 'fontsize', 12, 'tag','enterNumBins','enable', enableErspStatus},...
                {},...
                ...
                { 'Style', 'text', 'string', message, 'horizontalalignment', 'left','fontweight', 'bold', 'tag','typeProcLabel'},...
                { 'Style', 'edit', 'string', num2str(time_series),'tag', 'enterExcludeChans','callback',@cllbk_get_time_series},...
                { 'Style', 'togglebutton', 'string', include_exclude_status, 'horizontalalignment', 'left','tag', 'switchIncludeExcludeButton','callback',@cllbk_switch_include_exclude,'tooltipstring','choose whether to include or exclude certain ICs or channels'},...
                { 'Style', 'togglebutton', 'string', [upper(type_of_processing(1)) type_of_processing(2:end)] , 'horizontalalignment', 'left','tag', 'switchTypeButton','callback',@cllbk_switch_type},...
                ...%Channel selection, Epoch/HED settings
                { 'Style', 'text', 'string', 'Category epoch boundaries (sec)', 'horizontalalignment', 'left','fontweight', 'bold', 'tag','catepoch','tooltipstring','determines number of parameters and position for categorical variables'},...
                { 'Style', 'edit', 'string', num2str(s.category_epoch_boundaries),'tag', 'enterCatEpochBoundary', 'callback',@cllbk_enter_epoch_boundaries},...
                { 'Style', 'text', 'string', 'Continuous epoch boundaries (sec)', 'horizontalalignment', 'left','fontweight', 'bold' , 'tag','conepoch','tooltipstring','determines number of parameters and position for continuous variables'},...
                { 'Style', 'edit', 'string', num2str(s.continuous_epoch_boundaries),'tag', 'enterConEpochBoundary', 'callback',@cllbk_enter_epoch_boundaries},...
                ...%Artifact handling
                { 'Style', 'checkbox', 'string', 'Artifact reject function:', 'horizontalalignment', 'left','tag', 'enableArtifactRejection','fontweight', 'bold','value',s.artifact_rejection_enable,'callback', @cllbk_enable_artifact_rejection,'tooltipstring','Automatically ensure that artifact frames are excluded from analysis (recommended)'},...
                { 'Style', 'edit', 'string', s.artifact_function_name, 'horizontalalignment', 'left', 'tag', 'enterArtifactFunction', 'enable', enableArtifactRejectionStatus,'callback',@cllbk_enter_artifact_function_name,'tag','enterArtifactFunction'},...
                { 'Style', 'text', 'string', mess, 'horizontalalignment', 'left','tag', 'rejectedFramesCounter', 'enable',enableArtifactRejectionStatus },...
                ...
                {},...Spacer
                ...%Event event_types
                { 'Style', 'text', 'string', 'Included event types', 'horizontalalignment', 'left','fontweight', 'bold','tag','includeevttypelabel','tooltipstring','event types included in the regression; removing event types will affect which hed tags are available in the HED section. Press enter or return when selecting event types to edit descriotions.'},...
                { 'Style', 'text', 'string', 'Excluded event types', 'horizontalalignment', 'left','fontweight', 'bold','tag','excludeevttypelabel','tooltipstring','event types excluded from the regression; removing event types will affect which hed tags are available in the HED section. Press enter or return when selecting event types to edit descriotions.'},...
                { 'Style', 'listbox', 'string', include_descriptions_event_types, 'Max', 1e7,'tag', 'includeUniqueevent_typesList', 'keypressfcn', @cllbk_description_edit},...
                { 'Style', 'listbox', 'string', exclude_descriptions_event_types, 'Max', 1e7,'tag', 'excludeUniqueevent_typesList', 'keypressfcn', @cllbk_description_edit},...
                { 'Style', 'pushbutton', 'string', 'Remove >>', 'horizontalalignment', 'left','tag', 'removeevent_typeButton', 'callback',@cllbk_event_type_remove,'tooltipstring','move the included tag to the excluded list'},...
                { 'Style', 'pushbutton', 'string', '<< Add', 'horizontalalignment', 'left','tag', 'addevent_typeButton', 'callback',@cllbk_event_type_add,'tooltipstring','move the excluded tag to the included list'},...
                ...%HED tags
                { 'Style', 'checkbox', 'tag', 'enableHed', 'string', 'Hierarchical Regression', 'value', s.hed_enable,'fontweight', 'bold','callback',@cllbk_hed_enable},...
                { 'Style', 'checkbox', 'tag', 'enforceHed', 'string', 'Enforce HED specification', 'value', s.enforce_hed_spec,'enable',enableHedStatus,'callback',@cllbk_enforce_hedspec,'tooltipstring','perform regression on HED tags; tags are stored in the EEG.event(i).hedTag field' },...
                { 'Style', 'pushbutton', 'string', 'Change HED specification', 'horizontalalignment', 'left','tag', 'changeHedSpec','enable',enableHedStatus,'callback', @cllbk_change_hedspec,'tooltipstring','check each tag for HED specification compliance; runs much slower' },...
                { 'Style', 'pushbutton', 'string', 'Display HED hierarchy', 'horizontalalignment', 'left','tag', 'displayHierarchy','enable',enableHedStatus,'callback',@cllbk_view_hierarchy,'tooltipstring','show a tree of the included HED tags'},...
                ...
                { 'Style', 'text', 'string', 'Include HED tags', 'horizontalalignment', 'left','fontweight', 'bold','enable',enableHedStatus, 'tag','includeTagsLabel','tooltipstring','tags which are included in regression'},...
                { 'Style', 'text', 'string', '*  Exclude HED tags  *', 'horizontalalignment', 'left','fontweight', 'bold','enable',enableHedStatus, 'tag','excludeTagsLabel','tooltipstring','tags which are excluded from regression'},...
                { 'Style', 'listbox', 'string', cp.include_tag,'Max',1e7,'tag', 'includeUniqueTagsList','enable',enableHedStatus,'callback',@cllbk_list_select},...
                { 'Style', 'listbox', 'string', exclude,'Max',1e7,'tag', 'excludeUniqueTagsList','enable',enableHedStatus,'callback',@cllbk_list_select},...
                ...
                { 'Style', 'pushbutton', 'string', 'Include', 'horizontalalignment', 'left','tag', 'tagIncludeButton','enable',enableHedStatus, 'callback', @cllbk_tag_include},...
                { 'Style', 'pushbutton', 'string', 'Exclude', 'horizontalalignment', 'left','tag', 'tagExcludeButton','enable',enableHedStatus,'callback',@cllbk_tag_exclude},...
                { 'Style', 'text','string','parameter count: <unknown>', 'tag','parameterCountLabel'},...
                {},...
                ...%Regularization options
                { 'Style', 'checkbox', 'string', 'Regularization','tag', 'enableRegularization', 'value', s.regularization_enable,'fontweight', 'bold', 'callback',@cllbk_enable_regularization,'tooltipstring', 'enables penalized regression; discourages overfitting'},...
                { 'Style', 'checkbox', 'string', 'Grid search','tag', 'enableXValidate', 'value', s.cross_validate_enable, 'enable', enableRegularizationStatus, 'callback',@cllbk_enable_xvalidation ,'tooltipstring', 'search for lambda using cross-validation based on R-Square;'},...
                { 'Style', 'pushbutton', 'string', 'Load profile', 'horizontalalignment', 'left','tag', 'loadProfileButton','callback',@cllbk_load_profile},...
                { 'Style', 'pushbutton', 'string', 'Save profile', 'horizontalalignment', 'left','tag', 'saveProfileButton','callback',@cllbk_save_profile},...
                ...
                { 'Style', 'text', 'string', 'Lambda [L1 Norm, L2 Norm]', 'horizontalalignment', 'left', 'tag','lambdaLabel', 'enable', enableRegularizationStatus,'tooltipstring', 'two entry vector; specify the penalty multiplier for L1 norm and L2 norm penalty functions'},...
                { 'Style', 'edit','horizontalalignment', 'left','tag', 'enterLambda','string', num2str(s.lambda), 'enable', enableLambdaStatus,'callback', @cllbk_enter_lambda},...
                { 'Style', 'pushbutton', 'string', 'Set default profile', 'horizontalalignment', 'left','tag', 'setDefaultProfileButton','callback',@cllbk_set_default_profile,'tooltipstring', 'sets profile which will be loaded when starting a new profile'},...
                { 'Style', 'pushbutton', 'string', 'Set advanced options', 'horizontalalignment', 'left','tag', 'setAdvancedOptionsButton','callback', @cllbk_set_advanced_options, 'tooltipstring', 'sets advanced profile options'},...
                ...
                { 'Style', 'text', 'string', 'Penalty function ', 'tag','penaltyLabel', 'horizontalalignment', 'left','enable', enableRegularizationStatus,'tooltipstring', 'choose a penalty function; L2 norm recommended, fastest'},...
                { 'Style', 'listbox', 'string', s.penalty_options, 'horizontalalignment', 'left','Max',1,'value', pen_idx,'tag', 'penaltyFunctionList', 'enable', enableRegularizationStatus,'callback', @cllbk_choose_penalty},...
                { 'Style', 'pushbutton', 'string', 'Cancel', 'tag', 'cancel', 'fontweight', 'bold', 'callback', @cllbk_cancel,'visible', okbuttonstatus},...
                { 'Style', 'pushbutton', 'tag', 'ok', 'string', 'Ok', 'fontweight', 'bold','visible', okbuttonstatus,'callback',@cllbk_ok,'tooltipstring', 'execute rerp function'},...
                };
            
            [ ~, ~, all_handlers ] = supergui(...
                'geomhoriz', geomhoriz,...
                'geomvert', geomvert,...
                'uilist', uilist,...
                'title', title);
            
            gui_handle = gcf;
            
            %Bring relevent ui handles into scope.
            ui_enterExcludeChans = findobj([all_handlers{:}],'flat', 'tag','enterExcludeChans');
            ui_typeProcLabel = findobj([all_handlers{:}],'flat','tag', 'typeProcLabel');
            ui_switchTypeButton = findobj([all_handlers{:}],'flat','tag', 'switchTypeButton');
            ui_switchIncludeExcludeButton = findobj([all_handlers{:}],'flat','tag', 'switchIncludeExcludeButton');
            
            ui_autoSaveResultsEnable=findobj([all_handlers{:}],'flat','tag', 'autoSaveResultsEnable');
            ui_erspEnable=findobj([all_handlers{:}],'flat','tag', 'erspEnable');
            ui_enableArtifactRejection=findobj([all_handlers{:}],'flat','tag', 'enableArtifactRejection');
            ui_enableRegularization = findobj([all_handlers{:}],'flat','tag', 'enableRegularization');
            
            ui_enterNumBins=findobj([all_handlers{:}],'flat','tag', 'enterNumBins');
            ui_numBinsLabel=findobj([all_handlers{:}],'flat','tag', 'numBinsLabel');
            
            ui_rejectedFramesCounter = findobj([all_handlers{:}],'flat', 'tag','rejectedFramesCounter');
            ui_enableArtifactVariable = findobj([all_handlers{:}],'flat', 'tag','enableArtifactVariable');
            ui_enterArtifactVariable = findobj([all_handlers{:}],'flat', 'tag','enterArtifactVariable');
            ui_enterArtifactFunction = findobj([all_handlers{:}],'flat', 'tag','enterArtifactFunction');
            ui_artifactFunction = findobj([all_handlers{:}],'flat', 'tag','artifactFunction');
            ui_computeArtifactButton = findobj([all_handlers{:}],'flat', 'tag','computeArtifactButton');
            
            ui_catepoch = findobj([all_handlers{:}],'flat', 'tag','catepoch');
            ui_conepoch = findobj([all_handlers{:}],'flat', 'tag','conepoch');
            ui_inclevttypelabel= findobj([all_handlers{:}],'flat', 'tag','includeevttypelabel');
            ui_exclevttypelabel= findobj([all_handlers{:}],'flat', 'tag','excludeevttypelabel');
            ui_includeUniqueevent_typesList= findobj([all_handlers{:}],'flat', 'tag','includeUniqueevent_typesList');
            ui_excludeUniqueevent_typesList = findobj([all_handlers{:}],'flat', 'tag','excludeUniqueevent_typesList');
            
            ui_enableHed = findobj([all_handlers{:}],'flat', 'tag','enableHed');
            ui_enforceHed = findobj([all_handlers{:}],'flat', 'tag','enforceHed');
            
            ui_changeHedSpec = findobj([all_handlers{:}],'flat', 'tag','changeHedSpec');
            ui_displayHierarchy = findobj([all_handlers{:}],'flat', 'tag','displayHierarchy');
            
            ui_includeUniqueTagsList = findobj([all_handlers{:}],'flat', 'tag','includeUniqueTagsList');
            ui_excludeUniqueTagsList = findobj([all_handlers{:}],'flat', 'tag','excludeUniqueTagsList');
            ui_continuousTagsList = findobj([all_handlers{:}],'flat', 'tag','continuousTagsList');
            ui_seperatorTagsList = findobj([all_handlers{:}],'flat', 'tag','seperatorTagsList');
            
            ui_tagIncludeButton= findobj([all_handlers{:}],'flat', 'tag','tagIncludeButton');
            ui_tagExcludeButton= findobj([all_handlers{:}],'flat', 'tag','tagExcludeButton');
            ui_tagSeperatorButton= findobj([all_handlers{:}],'flat', 'tag','tagSeperatorButton');
            ui_tagContinuousButton= findobj([all_handlers{:}],'flat', 'tag','tagContinuousButton');
            
            ui_parameterCountLabel= findobj([all_handlers{:}],'flat', 'tag','parameterCountLabel');
            
            ui_includeTagsLabel = findobj([all_handlers{:}],'flat', 'tag','includeTagsLabel');
            ui_excludeTagsLabel = findobj([all_handlers{:}],'flat', 'tag','excludeTagsLabel');
            ui_continuousTagsLabel = findobj([all_handlers{:}],'flat', 'tag','continuousTagsLabel');
            ui_seperatorTagsLabel = findobj([all_handlers{:}],'flat', 'tag','seperatorTagsLabel');
            
            ui_enterLambda = findobj([all_handlers{:}],'flat', 'tag','enterLambda');
            ui_enableXValidate = findobj([all_handlers{:}],'flat', 'tag','enableXValidate');
            ui_enterNumFolds = findobj([all_handlers{:}],'flat', 'tag','enterNumFolds');
            ui_penaltyFunctionList = findobj([all_handlers{:}],'flat', 'tag','penaltyFunctionList');
            ui_lambdaLabel = findobj([all_handlers{:}],'flat', 'tag','lambdaLabel');
            ui_penaltyLabel = findobj([all_handlers{:}],'flat', 'tag','penaltyLabel');
            ui_autosavePathLabel = findobj([all_handlers{:}],'flat', 'tag','autosavePathLabel');
            
            % We have an earlier version RerpProfile: initialize the field and
            % recall make_gui.
        catch e
            field=regexp(e.message,'.*''(.*)''','tokens');
            if (~isempty(field))
                s.(field{1}{1})=[];
                make_gui;
            else
                disp('rerp_profile_gui: problem with profile, possibly an outdated version');
                throw(e);
            end
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Utility functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Splits a list into two parts (included and excluded items)
    function [include_event_types, include_event_types_idx, exclude_event_types_idx, include_descriptions, exclude_descriptions] = get_event_type_split(event_types, exclude_event_types, event_type_descriptions)
        idx_range = 1:length(event_types);
        
        [~, include_event_types_idx] = setdiff(event_types, exclude_event_types);
        
        include_event_types_idx = sort(include_event_types_idx,'ascend');
        include_event_types = event_types(include_event_types_idx);
        
        exclude_event_types_idx = setdiff(idx_range, include_event_types_idx);
        exclude_event_types_idx = sort(exclude_event_types_idx,'ascend');
        
        %If descriptions were provided, include them in the event type listboxes
        include_descriptions = cell(size(include_event_types_idx));
        exclude_descriptions = cell(size(exclude_event_types_idx));
        if ~isempty(event_type_descriptions)
            
            for i=1:length(include_descriptions)
                include_descriptions{i} = strtrim([event_types{include_event_types_idx(i)} '   ' event_type_descriptions{include_event_types_idx(i)}]);
            end
            
            if length(event_type_descriptions) < max(exclude_event_types_idx)
                num2add=max(exclude_event_types_idx)-length(event_type_descriptions);
                [event_type_descriptions{end+1:end+num2add}] = deal('');
            end
            
            for i=1:length(exclude_event_types_idx)
                exclude_descriptions{i} = strtrim([event_types{exclude_event_types_idx(i)} '   ' event_type_descriptions{exclude_event_types_idx(i)}]);
            end
        end
    end
end