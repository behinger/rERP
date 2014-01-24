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

classdef RerpResult < matlab.mixin.Copyable
    %RERP_RESULT class defines results from rerp function and related plotting functions.
    % rerp_result_gui will assist calling the methods in this function.
    %
    % Methods:
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   Inputs (common):
    %       event_idx: index into tags array returned by
    %           obj.get_plotting_params. Used to specify which events or hed
    %           tags are to be plotted.
    %       ts_idx: the channel or component index of the
    %           rerp_estimate array. Used to specify which time series to plot.
    %       h: handle to figure used for plotting (OPTIONAL)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   rerp_result = RerpResult(rerp_profile) (CONSTRUCTOR)
    %       Input:
    %           rerp_profile: the RerpProfile object used to generate the
    %           result.
    %       Output:
    %           rerp_result: the RerpResult object
    %
    %   plotRerpEventTypes(event_idx, ts_idx, h)
    %       Description: Plots rerp estimates for event types from multiple time series
    %           on same axis (one plot per event type). ts_idx specifies which time
    %           series are included, event_idx indicates which event types to
    %           include
    %
    %   plotRerpTimeSeries(event_idx, ts_idx, h)
    %       Description: Plot rerp estimates for event types on same axis (one plot
    %           per time series). ts_idx specifies which time
    %           series are included, event_idx indicates which event types to
    %           include
    %
    %   plotRerpTotalRsquared(ts_idx, significance_level, h)
    %       Description: Plots the average rsquare for the time series as a whole with significance markings.
    %           Time series are ranked on average rsquare, with ttest taken
    %           across xvalidation folds.
    %       Input:
    %           significance_level: used for ttest across cross validation
    %               folds
    %
    %   plotRerpEventRsquared(ts_idx, significance_level, event_idx, h)
    %       Description: Plots the average rsquare taking into account only specific event types,
    %           with significance markings. Time series are ranked on average rsquare, with ttest taken
    %           across xvalidation folds.
    %       Input:
    %           significance_level: used for ttest across cross validation
    %               folds
    %
    %   plotRerpImage(EEG, locking_idx, delay_idx, ts_idx, window_size_ms, h)
    %       Description: Plots raw epochs, modeled epochs and the difference (3 plots)
    %           Sorts epochs based on the delay from the locking event onset to
    %           delay event onset.
    %       Input:
    %           EEG: the EEG struct of the dataset that was analyzed
    %           locking_idx: index into tags array returned by
    %               obj.get_plotting_params. Used as the locking event for
    %               epoch extraction.
    %           delay_idx: index into tags array returned by
    %               obj.get_plotting_params. For each locking event, calculates
    %               the delay to the next delay event and sort eopchs based on
    %               delay.
    %           window_size_ms: the epoch length
    %
    %   plotRersp(event_idx, ts_idx, h)
    %       Description: Plots regressed ERSP estimates
    %
    %   plotGridSearch(ts_idx, h)
    %       Description: Plots predictive surfaces and optimal values for all
    %           grid search zoom levels, if available
    %
    %   [tags, estimates, xaxis_ms, epoch_boundaries] = get_plotting_params
    %       Description: Plots predictive surfaces and optimal values for all
    %           grid search zoom levels, if available
    %       Output:
    %           tags:
    %           estimates:
    %           xaxis_ms:
    %           epoch_boundaries:
    %
    %   saveRerpResult(varargin)
    %       Description: Saves this result to disk; opens GUI if 'path' is not
    %           specified.
    %       Input:
    %           varargin:
    %               path: when specified, automatically saves to that path
    %               rerp_path: path where GUI will start looking
    %
    % Static methods:
    %   rerp_result = loadRerpResult(varargin)
    %       Description: Loads RerpResult from disk (*.rerp_result); opens GUI if 'path' is not
    %           specified.
    %       Input:
    %           varargin:
    %               path: when specified, automatically loads from that path
    %               rerp_path: path where GUI will start looking
    %       Output:
    %           rerp_result: the RerpResult object
    %
    %   result = combineRerpResults(rerp_results)
    %       Description: Allows us to split the dataset into individual time courses for
    %           parallel processing, then combine the results back into a single object. rerp_results
    %           parameter is a cell array of RerpResult objects in increasing channel/IC number order.
    %       Input:
    %           rerp_results: a cell array of RerpResult objects
    %       Output:
    %           result: the combined RerpResult object
    %
    %   xaxis_ms = get_xaxis_ms(epoch_boundaries, sample_rate)
    %       Description: Get x axis ticks for plotting erp waveform
    %       Input:
    %           epoch_boundaries: the boundaries of the window in seconds
    %           sample_rate
    %       Output:
    %           xaxis_ms: time vector in ms.
    
    properties
        rerp_profile % Profile used to derive this result
        analysis_name % A title assigned by the rerp function
        
        date_completed
        compute_time_seconds;
        
        lambda=[] % The optimal lambda if grid search was used, or the only lambda otherwise
        ersp_flag=0 % 1 if this result was computed from time-frequency decomposed data
        
        rerp_estimate % The rerp or rersp esitmates for each channel and frequency. must be reshaped for ersp.
        admm_residual % If regularization required alternating direction method of multipliers
        
        average_total_rsquare % Rsquare as computed on the entire data with full signal estimate
        average_event_rsquare % Rsquare as computed only on the part of the data affected by the variable, with it's part of the signal estimate
        
        total_xval_folds=[] % Cross validation structures for each fold
        event_xval_folds=[] % Cross validation structures for each fold
        
        gridsearch % A complete history of the grid search process, if any
    end
    
    methods
        
        % Constructor
        function obj = RerpResult(rerp_profile)
            obj.rerp_profile = rerp_profile;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Plotting Functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Plots rerp estimates for all event types from multiple time series
        % on same axis (one plot per event type). ts_idx specifies which time
        % series are included, event_idx indicates which event types to
        % include
        function plotRerpEventTypes(obj, event_idx, ts_idx, h, exclude_insignificant, significance_level)
            import rerp_dependencies.*
            
            if ~exist('h','var')
                h=figure;
            end
            
            if ~exist('exclude_insignificant','var')
                exclude_insignificant=0;
            end
            
            if ~exist('significance_level','var')
                significance_level=.05;
            end
            
            if exclude_insignificant
                significance_label = [' ( significant @ p < ' num2str(significance_level) ' )'];
            else
                significance_label = '';
            end
            
            rsquare_significance = obj.get_event_rsquare_significance(significance_level);
            
            hold all;
            assert(~obj.ersp_flag, 'RerpResult: plotRerpEventTypes is invalid, use plotRersp instead');
            
            [tags, estimates, xaxis_ms] = obj.get_plotting_params;
            
            x_label='time (ms)';
            y_label='amplitude (RMS microvolt)';
            
            if isempty(event_idx)
                event_idx = 1:length(tags);
            end
            
            if isempty(ts_idx)
                ts_idx = 1:size(estimates,2);
            end
            
            datasetname = regexp(obj.rerp_profile.eeglab_dataset_name,'.*[\\\/](.*).set','tokens');
            datasetname = {{regexprep(datasetname{1}{1},'[\_]','\\\_')}};
            
            m=1;
            props=get(findobj(h, 'tag', 'legend'));
            for i=event_idx
                
                if exclude_insignificant
                    ts_idx = ts_idx(rsquare_significance(i, ts_idx)==1);
                end
                
                if ~isempty(ts_idx)
                    scrollsubplot(4,1,m,h);
                    hold all;
                    plot(xaxis_ms{i}', [estimates{i, ts_idx}]);
                    
                    hcmenu = uicontextmenu;
                    uimenu(hcmenu, 'Label', 'Publish graph', 'Callback', @RerpResult.gui_publish);
                    set(gca,'uicontextmenu', hcmenu);
                    
                    if obj.rerp_profile.settings.hed_enable
                        titl = ['Tag:' tags{i}];
                    else
                        titl = ['Event type:' tags{i}];
                    end
                    
                    if obj.rerp_profile.settings.type_proc
                        leg = [datasetname{1}{1} ' - ' obj.analysis_name ', Channel: '];
                        ts_label=obj.rerp_profile.include_chans(ts_idx);
                    else
                        leg = [datasetname{1}{1} ' - ' obj.analysis_name ', Component: '];
                        ts_label=obj.rerp_profile.include_comps(ts_idx);
                    end
                    
                    title([titl significance_label]);
                    xlim([min(xaxis_ms{i}) max(xaxis_ms{i})]);
                    
                    legend_idx = cellfun(@(x) [leg x], regexp(num2str(ts_label),'\s*','split'), 'UniformOutput' ,false);
                    
                    if isempty(props)
                        a=legend(legend_idx);
                    else
                        a=legend({props(m).UserData.lstrings{:} legend_idx{:}});
                    end
                    
                    pr= get(gca,'UserData');
                    pr.legend=a;
                    set(gca, 'UserData',pr);
                    
                    xlabel(x_label);
                    ylabel(y_label);
                end
                m=m+1;
            end
        end
        
        % Plot rerp estimates for all event types on same axis (one plot
        % per time series). ts_idx specifies which time
        % series are included, event_idx indicates which event types to
        % include
        function plotRerpTimeSeries(obj, event_idx, ts_idx, h, exclude_insignificant, significance_level)
            import rerp_dependencies.*
            
            if ~exist('h','var')
                h=figure;
            end
            
            if ~exist('exclude_insignificant','var')
                exclude_insignificant=0;
            end
            
            if ~exist('significance_level','var')
                significance_level=.05;
            end
            
            if exclude_insignificant
                significance_label = [' ( significant @ p < ' num2str(significance_level) ' )'];
            else
                significance_label = '';
            end
            
            rsquare_significance = obj.get_event_rsquare_significance(significance_level);
            assert(~obj.ersp_flag, 'RerpResult: plotRerpTimeSeries is invalid, , use plotRersp instead');
            
            [tags, estimates, xaxis_ms] = obj.get_plotting_params;
            
            x_label='time (ms)';
            y_label='amplitude (RMS microvolt)';
            
            if isempty(event_idx)
                event_idx = 1:length(tags);
            end
            
            if isempty(ts_idx)
                ts_idx = 1:size(estimates,2);
            end
            
            datasetname = regexp(obj.rerp_profile.eeglab_dataset_name,'.*[\\\/](.*).set','tokens');
            datasetname = {{regexprep(datasetname{1}{1},'[\_]','\\\_')}};
            
            m=1;
            props=get(findobj(h, 'tag', 'legend'));
            
            new_idx=[];
            for i=ts_idx
                scrollsubplot(4,1,m,h);
                
                n=1;
                for j=event_idx
                    if ~exclude_insignificant||rsquare_significance(j, i)
                        plot(xaxis_ms{j}, estimates{j, i});
                        new_idx(n)=j;
                        hold all;
                        n=n+1;
                    end
                end
                
                event_idx=new_idx;
                if ~isempty(event_idx)
                    hcmenu = uicontextmenu;
                    uimenu(hcmenu, 'Label', 'Publish graph', 'Callback', @RerpResult.gui_publish);
                    set(gca,'uicontextmenu', hcmenu)
                    
                    if obj.rerp_profile.settings.type_proc
                        titl = ['Channel:' num2str(obj.rerp_profile.include_chans(i))];
                    else
                        titl = ['Component:' num2str(obj.rerp_profile.include_comps(i))];
                    end
                    
                    if obj.rerp_profile.settings.hed_enable
                        leg = [datasetname{1}{1} ' - ' obj.analysis_name ', Tag: '];
                    else
                        leg = [datasetname{1}{1} ' - ' obj.analysis_name ', Event type: '];
                    end
                    
                    title([titl significance_label]);
                    xlim([min(cell2mat(xaxis_ms(event_idx))) max(cell2mat(xaxis_ms(event_idx)))]);
                    legend_idx = cellfun(@(x) [leg x], tags(event_idx) , 'UniformOutput' ,false);
                    if isempty(props)
                        a=legend(legend_idx);
                    else
                        a=legend({props(m).UserData.lstrings{:} legend_idx{:}});
                    end
                    pr= get(gca,'UserData');
                    pr.legend=a;
                    set(gca, 'UserData',pr);
                    
                    xlabel(x_label);
                    ylabel(y_label);
                    m=m+1;
                end
            end
        end
        
        % Plots the average rsquare for the time series as a whole with significance markings.
        % Time series are ranked on average rsquare, with ttest taken
        % across xvalidation folds.
        function plotRerpTotalRsquared(obj, ts_idx, significance_level, h)
            import rerp_dependencies.*
            
            if ~exist('h','var')
                h=figure;
            end
            
            vals = obj.average_total_rsquare(ts_idx);
            
            tmax = max(vals);
            tmin = min(min(vals), 0);
            
            if ~isempty(significance_level)
                rsquare_significance = obj.get_total_rsquare_significance(significance_level);
                rsquare_significance = rsquare_significance(ts_idx);
            end
            
            datasetname = regexp(obj.rerp_profile.eeglab_dataset_name,'.*[\\\/](.*).set','tokens');
            datasetname = {{regexprep(datasetname{1}{1},'[\_]','\\\_')}};
            
            p=plot(1:length(ts_idx), vals);
            line_props = get(p);
            
            set(gca,'xtickmode','manual');
            set(gca, 'xtick', 1:length(ts_idx));
            legend_idx=[datasetname{1}{1} ' - ' obj.analysis_name];
            
            props=get(findobj(h, 'tag', 'legend'));
            if isempty(props)
                leg = legend(legend_idx);
                props = get(leg);
                props.UserData.plotHandles = p;
                props.UserData.lstrings={legend_idx};
                set(gca, 'xticklabel', ts_idx);
            else
                plotHandles = [props.UserData.plotHandles p];
                leg = legend(plotHandles, {props.UserData.lstrings{:} legend_idx});
                props = get(leg);
                props.UserData.plotHandles = plotHandles;
                set(gca, 'xticklabel', 1:length(ts_idx));
            end
            
            set(leg, 'UserData', props.UserData);
            pr= get(gca,'UserData');
            pr.legend=leg;
            set(gca, 'UserData',pr);
            grid on;
            
            for j=1:length(ts_idx)
                if rsquare_significance(j)
                    hold all;
                    plot(j, vals(j) ,'s', 'LineWidth', 1, 'MarkerEdgeColor',line_props.Color,'MarkerSize', 14);
                end
            end
            
            hcmenu = uicontextmenu;
            uimenu(hcmenu, 'Label', 'Publish graph', 'Callback', @RerpResult.gui_publish);
            set(gca,'uicontextmenu', hcmenu);
            
            xlabel('Time series - decreasing R ^2 order');
            ylabel('R ^2');
            title('Rsquare performance by time series');
            
            a = get(gca);
            tmin = min(tmin, a.YLim(1));
            tmax = max(tmax, a.YLim(2));
            
            axis([0 length(ts_idx) tmin tmax]);
        end
        
        % Plots the average rsquare taking into account only specific event types,
        % with significance markings. Time series are ranked on average rsquare, with ttest taken
        % across xvalidation folds.
        function plotRerpEventRsquared(obj, ts_idx, significance_level, event_idx, h)
            import rerp_dependencies.*
            
            if ~exist('h','var')
                h=figure;
            end
            
            hold all;
            tags=obj.get_plotting_params;
            
            if isempty(event_idx)
                event_idx = 1:size(obj.average_event_rsquare, 1);
            end
            
            if ~isempty(significance_level)
                rsquare_significance = obj.get_event_rsquare_significance(significance_level);
                rsquare_significance = rsquare_significance(event_idx, ts_idx);
            end
            
            datasetname = regexp(obj.rerp_profile.eeglab_dataset_name,'.*[\\\/](.*).set','tokens');
            datasetname = {{regexprep(datasetname{1}{1},'[\_]','\\\_')}};
            
            m=1;
            for i=1:length(event_idx)
                
                vals = obj.average_event_rsquare(event_idx(i),ts_idx);
                this_rsquare_significance = rsquare_significance(i,:);
                
                tmax = max(vals);
                tmin = min(min(vals), 0);
                
                hold all;
                scrollsubplot(3,1,m,h);
                
                p=plot(1:length(ts_idx), vals);
                line_props = get(p);
                set(gca,'xtickmode','manual');
                set(gca, 'xtick', 1:length(ts_idx));
                props=get(findobj(h,'Tag', ['legend_' num2str(i)]));
                legend_idx=[datasetname{1}{1} ' - ' obj.analysis_name];
                
                if isempty(props)
                    leg = legend(legend_idx);
                    props = get(leg);
                    props.UserData.plotHandles = p;
                    props.UserData.lstrings={legend_idx};
                    set(leg,'UserData', props.UserData, 'Tag',['legend_' num2str(i)]);
                    set(gca, 'xticklabel', ts_idx);
                else
                    plotHandles = [props.UserData.plotHandles p];
                    leg = legend(plotHandles, {props.UserData.lstrings{:} legend_idx});
                    props = get(leg);
                    props.UserData.plotHandles = plotHandles;
                    set(leg,'UserData', props.UserData);
                    set(gca, 'xticklabel', 1:length(ts_idx));
                end
                
                set(leg,'UserData', props.UserData);
                pr= get(gca,'UserData');
                pr.legend=leg;
                set(gca, 'UserData',pr);
                grid on;
                
                for j=1:length(ts_idx)
                    if this_rsquare_significance(j)
                        hold all;
                        plot(j, vals(j) ,'s', 'LineWidth', 1, 'MarkerEdgeColor',line_props.Color,'MarkerSize', 14);
                    end
                end
                
                hcmenu = uicontextmenu;
                uimenu(hcmenu, 'Label', 'Publish graph', 'Callback', @RerpResult.gui_publish);
                set(gca,'uicontextmenu', hcmenu);
                
                xlabel('Time series - decreasing R ^2 order');
                ylabel('R ^2');
                title(['Rsquare performance by time series: ' tags{event_idx(i)}]);
                
                a = get(gca);
                tmin = min(tmin, a.YLim(1));
                tmax = max(tmax, a.YLim(2));
                
                axis([0 length(ts_idx) tmin tmax]);
                m=m+1;
            end
        end
        
        % Plots raw epochs, modeled epochs and the difference (3 plots)
        function plotRerpImage(obj, EEG, locking_idx, delay_idx, ts_idx, window_size_ms, h)
            import rerp_dependencies.*
            
            if ~exist('h','var')
                h=figure;
            end
            
            assert(obj.ersp_flag~=1, 'RerpResult: this profile was run on time-fequency data (rERSP); plotRerpImage is invalid');
            
            if isempty(ts_idx)
                ts_idx = 1:size(EEG.data,1);
            end
            
            if obj.rerp_profile.settings.type_proc==0
                assert(~isempty(EEG.icaact)&& size(EEG.icaact,3)==1,'RerpResult: this profile is set for ICA; populate EEG.icaact with continuous ICA activations');
                data = EEG.icaact(ts_idx,:)';
            else
                assert(~isempty(EEG.data) && size(EEG.data,3)==1,'RerpResult: EEG.data must be populated with continuous data');
                data = EEG.data(ts_idx,:)';
            end
            
            % Replace artifact indexes with data mean for plotting
            if obj.rerp_profile.settings.artifact_rejection_enable
                if obj.rerp_profile.settings.artifact_variable_enable
                    data(obj.rerp_profile.variable_artifact_indexes,:)=repmat(median(data), [nnz(obj.rerp_profile.variable_artifact_indexes), 1]);
                else
                    data(obj.rerp_profile.computed_artifact_indexes,:)=repmat(median(data), [nnz(obj.rerp_profile.computed_artifact_indexes), 1]);
                end
            end
            
            num_samples = ceil(obj.rerp_profile.sample_rate*(window_size_ms/1000));
            
            disp('RerpResult: generating modeled data');
            [predictor, data_pad] = predictor_gen(obj.rerp_profile);
            data = [zeros(data_pad(1), size(data,2)); data; zeros(data_pad(2), size(data,2)); zeros(num_samples,size(data,2))];
            modeled_data = [predictor*obj.rerp_estimate(:,ts_idx); zeros(num_samples,size(data,2))];
            noise = data-modeled_data;
            
            [tags, estimates, xaxis_ms, epoch_boundaries] = obj.get_plotting_params;
            locking_tag = tags{locking_idx};
            locking_estimate = estimates(locking_idx, ts_idx);
            sorting_tag = tags{delay_idx};
            
            if ~isempty(delay_idx)
                delay_tag = tags{delay_idx};
                delay_estimate = estimates(delay_idx, ts_idx);
            else
                delay_tag=[];
                delay_estimate = [];
            end
            
            this_epoch_boundaries = epoch_boundaries{locking_idx};
            this_xaxis_ms = ((0:(num_samples-1))'/obj.rerp_profile.sample_rate + this_epoch_boundaries(1))*1000;
            
            disp('RerpResult: getting epochs');
            [data_epochs, event_nums] = obj.get_rerp_epochs(data, locking_tag, num_samples);
            [modeled_epochs] = obj.get_rerp_epochs(modeled_data, locking_tag, num_samples);
            [noise_epochs] = obj.get_rerp_epochs(noise, locking_tag, num_samples);
            
            if ~isempty(delay_tag)
                disp('RerpResult: calculating order of trials');
                sorting_var = (obj.get_delay_times(event_nums, delay_tag, num_samples)/obj.rerp_profile.sample_rate)*1000;
            else
                sorting_var=[];
            end
            
            m=1;
            for i=1:length(ts_idx)
                this_ts = ts_idx(i);
                
                if obj.rerp_profile.settings.type_proc
                    ts = 'Channel';
                    tsn = num2str(obj.rerp_profile.include_chans(this_ts));
                else
                    ts = 'Component';
                    tsn = num2str(obj.rerp_profile.include_comps(this_ts));
                end
                
                if obj.rerp_profile.settings.hed_enable
                    v = 'Tag';
                else
                    v = 'Event type';
                end
                
                % Plot the data epochs
                scrollsubplot(4,1,m,h);
                erpimage(data_epochs(:,:,i), sorting_var, this_xaxis_ms, ['Data epochs - ' v ': ' locking_tag ', ' ts ': ' tsn]);
                
                % Plot the modeled epochs
                scrollsubplot(4,1,m+1,h);
                erpimage(modeled_epochs(:,:,i), sorting_var, this_xaxis_ms, ['Modeled epochs - ' v ': ' locking_tag ', ' ts ': ' tsn]);
                
                % Plot the noise epochs
                scrollsubplot(4,1,m+2,h);
                erpimage(noise_epochs(:,:,i), sorting_var, this_xaxis_ms, ['Difference epochs - ' v ': ' locking_tag ', ' ts ': ' tsn]);
                
                % Plot the rerp estimates
                scrollsubplot(4,1,m+3,h);
                plot(xaxis_ms{locking_idx}', locking_estimate{i}, xaxis_ms{delay_idx}', delay_estimate{i});
                title('rERP estimates');
                xlabel('time (ms)');
                ylabel('epoch number');
                legend([v '(locking): ' locking_tag], [v '(sorting): ' sorting_tag]);
                
                hcmenu = uicontextmenu;
                uimenu(hcmenu, 'Label', 'Publish graph', 'Callback', @RerpResult.gui_publish);
                set(gca,'uicontextmenu', hcmenu);
                m=m+4;
            end
            
        end
        
        % Plots regressed ERSP estimates
        function plotRersp(obj, event_idx, ts_idx, h)
            import rerp_dependencies.*
            
            assert(obj.ersp_flag==1, 'RerpResult: plotRersp is invalid for this result, use plotRerpEventTypes or plotRerpTimeSeries instead');
            
            if ~exist('h','var')
                figure;
            end
            
            
            nbins = obj.rerp_profile.settings.nbins;
            sr = obj.rerp_profile.sample_rate;
            y_axis_hz = ((1:floor(nbins/2)))*sr/nbins;
            
            [tags, estimates, xaxis_ms] = obj.get_plotting_params;
            
            m=1;
            for i=ts_idx
                if obj.rerp_profile.settings.type_proc
                    ts = 'Channel';
                    tsn = num2str(obj.rerp_profile.include_chans(i));
                else
                    ts = 'Component';
                    tsn = num2str(obj.rerp_profile.include_comps(i));
                end
                
                if obj.rerp_profile.settings.hed_enable
                    v = 'Tag';
                else
                    v = 'Event type';
                end
                
                for j=event_idx
                    % Plot the rERSP estimates
                    this_xaxis_ms = xaxis_ms{i,j};
                    this_estimate = estimates{j,i};
                    this_tag = tags{i,j};
                    
                    scrollsubplot(1,1,m,h);
                    a=imagesc(this_xaxis_ms, y_axis_hz, this_estimate');
                    colormap('jet');
                    title(['rERSP, ' ts ': ' tsn ', ' v ': ' this_tag]);
                    xlabel('time ( ms )');
                    ylabel('frequency ( Hz ) ');
                    axis xy;
                    %                     num_yticks=20;
                    %                     y_axis_hz_tick = (1:(num_yticks-1))*sr/(num_yticks*2);
                    %                     set(gca, 'ytick', 1:num_yticks);
                    %                     set(gca, 'yticklabel', flipdim(y_axis_hz_tick,2));
                    
                    hcmenu = uicontextmenu;
                    uimenu(hcmenu, 'Label', 'Publish graph', 'Callback', @RerpResult.gui_publish);
                    set(a,'uicontextmenu', hcmenu)
                    
                    m=m+1;
                end
            end
            
        end
        
        % Plots a predictive surfaces and optimal values
        function plotGridSearch(obj, ts_idx, h)
            import rerp_dependencies.*
            
            if ~exist('h', 'var')
                h=figure;
            end
            
            assert(obj.rerp_profile.settings.regularization_enable==1, 'RerpResult: regularization is not enabled for this profile');
            assert(obj.rerp_profile.settings.cross_validate_enable==1, 'RerpResult: cross validation is not enabled for this profile');
            
            this_level = obj.gridsearch;
            m=1;
            if obj.rerp_profile.settings.type_proc
                incl_ts=obj.rerp_profile.include_chans;
                ts = 'Channel';
            else
                incl_ts=obj.rerp_profile.include_comps;
                ts = 'Component';
            end
            
            while 1
                gr = this_level.grid_results;
                
                % Plot surfaces for indicated time series at this level
                for i=ts_idx
                    this_lambda_range = this_level.lambda_range{i};
                    pred_surf = zeros(1,numel(gr));
                    
                    for j=1:numel(gr)
                        pred_surf(j) = gr{j}.average_total_rsquare(i);
                    end
                    
                    scrollsubplot(1,1,m,h);
                    
                    if strcmp(obj.rerp_profile.settings.penalty_func, 'Elastic net')
                        [lambda_grid_L1, lambda_grid_L2] = meshgrid(this_lambda_range(:,1), this_lambda_range(:, 2));
                        p=mesh(lambda_grid_L1, lambda_grid_L2, reshape(pred_surf, size(lambda_grid_L2)));
                        props=get(p);
                        grid on;
                        colormap('jet');
                        
                        title(['Predictive surface, Elastic net, '  ts ': ' num2str(incl_ts(i)) ', level ' num2str(m)]);
                        xlabel('\lambda  1');
                        ylabel('\lambda  2');
                        zlable('average rsquare');
                        zlim([max(0,min(min(pred_surf))) max(max(pred_surf))]);
                        
                        hold on;
                        opt_lambda1 = this_lambda_range(lambda_grid_L1==max(max(pred_surf)));
                        opt_lambda2 = this_lambda_range(lambda_grid_L2==max(max(pred_surf)));
                        line([opt_lambda1 opt_lambda1], [opt_lambda2 opt_lambda2], [0 max(max(pred_surf))],'Color',props.Color,'LineStyle',props.LineStyle, 'linewidth',1);
                        
                        zpos = (max(max(pred_surf)) + max(0,min(min(pred_surf))))/2;
                        text(opt_lambda1, opt_lambda2, zpos, ['   lambda  =  (' num2str(opt_lambda1) ', ' num2str(opt_lambda2) ')'], 'color',props.Color);
                    end
                    
                    if strcmp(obj.rerp_profile.settings.penalty_func, 'L1 norm')
                        p=plot(this_lambda_range, pred_surf');
                        props=get(p);
                        grid on;
                        title(['Predictive surface, L1 norm penalty, ' ts ': ' num2str(incl_ts(i)) ', level ' num2str(m)]);
                        ylim([max(0, min(pred_surf)), max(pred_surf)]);
                        xlabel('\lambda');
                        ylabel('R ^2');
                        
                        hold on;
                        opt_lambda = this_lambda_range(pred_surf==max(pred_surf));
                        line([opt_lambda opt_lambda],[0 max(pred_surf)*1.1],'Color',props.Color,'LineStyle',props.LineStyle, 'linewidth',1);
                        
                        ypos = (max(pred_surf) + max(0, min(pred_surf)))/2;
                        text(opt_lambda, ypos, ['   lambda  =  ' num2str(opt_lambda)], 'Color',props.Color);
                    end
                    
                    if strcmp(obj.rerp_profile.settings.penalty_func, 'L2 norm')
                        p=plot(this_lambda_range, pred_surf');
                        props=get(p);
                        grid on;
                        title(['Predictive surface, L2 norm penalty, ' ts ': ' num2str(incl_ts(i)) ', level ' num2str(m)]);
                        ylim([max(0, min(pred_surf)), max(pred_surf)]);
                        xlabel('\lambda');
                        ylabel('R ^2');
                        hold on;
                        opt_lambda = this_lambda_range(pred_surf==max(pred_surf));
                        line([opt_lambda opt_lambda],[0 max(pred_surf)],'Color',props.Color,'LineStyle',props.LineStyle, 'linewidth',1);
                        
                        ypos = (max(pred_surf) + max(0, min(pred_surf)))/2;
                        text(opt_lambda, ypos, ['   lambda  =  ' num2str(opt_lambda)],'Color',props.Color);
                    end
                    
                    
                    hcmenu = uicontextmenu;
                    uimenu(hcmenu, 'Label', 'Publish graph', 'Callback', @RerpResult.gui_publish);
                    set(gca,'uicontextmenu', hcmenu)
                    
                end
                
                % Proceed to next level in grid search
                try
                    this_level=this_level.next_stage.gridsearch;
                    m=m+1;
                catch
                    break;
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Utility Functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Returns a representation of the rerp estimate that is convenient
        %for plotting
        function [tags, estimates, xaxis_ms, epoch_boundaries] = get_plotting_params(obj)
            import rerp_dependencies.*
            
            p=obj.rerp_profile;
            
            category_epoch_length = p.settings.category_epoch_boundaries(2) - p.settings.category_epoch_boundaries(1);
            continuous_epoch_length = p.settings.continuous_epoch_boundaries(2) - p.settings.continuous_epoch_boundaries(1);
            
            %Number of samples per epoch
            category_ns = ceil(continuous_epoch_length*p.sample_rate);
            continuous_ns = ceil(category_epoch_length*p.sample_rate);
            
            if obj.ersp_flag
                nbins = obj.rerp_profile.settings.nbins;
                raw_estimate = reshape(obj.rerp_estimate, [size(obj.rerp_estimate,1), size(obj.rerp_estimate,2)/nbins, nbins]);
            else
                raw_estimate = obj.rerp_estimate;
            end
            
            if p.settings.hed_enable
                cat_tags = RerpTagList.strip_subtags(p.include_tag);
                
                continuous_tags=cell(1,length(p.continuous_var));
                for i=1:length(p.continuous_var)
                    continuous_tags{i} = p.continuous_var{i}.name;
                end
                
                context_tags=cell(0,0);
                m=1;
                for i=1:length(p.context_group)
                    this_group = p.context_group{i};
                    for j=1:length(this_group.children)
                        this_child = this_group.children(j);
                        for k=1:length(this_child.included_tag)
                            this_included_tag = this_child.included_tag{i};
                            context_tags{m} = [this_included_tag '(' this_child.tag ')'];
                            m=m+1;
                        end
                    end
                    
                end
                
                tags = {cat_tags{:} continuous_tags{:} context_tags{:}};
                estimates=cell(length(tags), size(raw_estimate,2));
                xaxis_ms=cell(size(tags));
                epoch_boundaries=cell(size(tags));
                
                m=1;
                for i=1:length(cat_tags)
                    
                    start_idx=category_ns*(m-1)+1;
                    end_idx = start_idx+category_ns-1;
                    for j=1:size(raw_estimate,2)
                        estimates{m,j} = squeeze(raw_estimate(start_idx:end_idx, j,:));
                        xaxis_ms{m} = RerpResult.get_xaxis_ms(p.settings.category_epoch_boundaries, p.sample_rate);
                        epoch_boundaries{m}=p.settings.category_epoch_boundaries;
                    end
                    
                    m=m+1;
                end
                
                for i=1:length(continuous_tags)
                    
                    start_idx=continuous_ns*(m-1)+1;
                    end_idx = start_idx+continuous_ns-1;
                    for j=1:size(raw_estimate,2)
                        estimates{m,j} = squeeze(raw_estimate(start_idx:end_idx, j,:));
                        xaxis_ms{m} = RerpResult.get_xaxis_ms(p.settings.continuous_epoch_boundaries, p.sample_rate);
                        epoch_boundaries{m}=p.settings.continuous_epoch_boundaries;
                    end
                    
                    m=m+1;
                end
                
                for i=1:length(context_tags)
                    
                    start_idx=category_ns*(m-1)+1;
                    end_idx = start_idx+category_ns-1;
                    for j=1:size(raw_estimate,2)
                        estimates{m,j} = squeeze(raw_estimate(start_idx:end_idx, j,:));
                        xaxis_ms{m} = RerpResult.get_xaxis_ms(p.settings.category_epoch_boundaries, p.sample_rate);
                        epoch_boundaries{m}=p.settings.category_epoch_boundaries;
                    end
                    
                    m=m+1;
                end
                
            else
                
                tags = p.include_event_types;
                estimates=cell(length(tags), size(raw_estimate,2));
                xaxis_ms=cell(size(tags));
                epoch_boundaries=cell(size(tags));
                
                for i=1:length(tags)
                    start_idx=category_ns*(i-1)+1;
                    end_idx = start_idx+category_ns-1;
                    for j=1:size(raw_estimate,2)
                        estimates{i,j} = squeeze(raw_estimate(start_idx:end_idx, j, :));
                        xaxis_ms{i} = RerpResult.get_xaxis_ms(p.settings.category_epoch_boundaries, p.sample_rate);
                        epoch_boundaries{i}=p.settings.category_epoch_boundaries;
                    end
                end
            end
        end
        
        %Save a profile to disk
        function saveRerpResult(obj, varargin)
            import rerp_dependencies.*
            
            p=inputParser;
            addOptional(p,'path',[]);
            addOptional(p,'rerp_path', pwd);
            
            parse(p, varargin{:});
            temp = regexp(obj.rerp_profile.eeglab_dataset_name, '.set', 'split');
            fn = temp{1};
            
            if isempty(p.Results.path)
                %No path specified, launch GUI
                if ~isempty(fn)
                    [filename, pathname] = uiputfile('*.rerp_result', 'Save rerp result as:', [fn, '.rerp_result']);
                else
                    [filename, pathname] = uiputfile('*.rerp_result', 'Save rerp result as:', fullfile(p.Results.rerp_path, '.rerp_result'));
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
                    disp(['RerpResult: saved result to disk ' path]);
                catch e
                    disp(['RerpResult: could not save the specified result to disk ' path]);
                    rethrow(e);
                end
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Static methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Static=true)
        
        %Load a profile from disk
        function rerp_result = loadRerpResult(varargin)
            import rerp_dependencies.*
            
            p=inputParser;
            addOptional(p,'path',[]);
            addOptional(p,'rerp_path', pwd);
            parse(p, varargin{:});
            rerp_result=0;
            
            if isempty(p.Results.path)
                %No path specified, launch GUI
                [filename, pathname] = uigetfile({'*.rerp_result'}, 'Load rerp result:', p.Results.rerp_path);
                path = [pathname filename];
            else
                path = p.Results.path;
                filename=1;
            end
            
            %Read profile from disk
            if ~filename==0
                
                res = load(path, '-mat');
                label=fieldnames(res);
                rerp_result = res.(label{1});
                
                %Extract the profile if loading from .rerp_result file
                assert(isa(rerp_result,'RerpResult'),'RerpResult: the file does not contain a RerpResult object');
            end
        end
        
        % Allows us to split the dataset into individual time courses for
        % regression, then combine those results back into a single object. rerp_results
        % parameter is a cell array of RerpResult objects in increasing channel/IC number order.
        function result = combineRerpResults(rerp_results)
            
            rerp_results=rerp_results(~cellfun('isempty',rerp_results));
            result =  copy(rerp_results{1});
            
            m=length(result.lambda)+1;
            for i=2:length(rerp_results)
                this_result = rerp_results{i};
                nchans = size(this_result.rerp_estimate,2);
                idx = m:(m+nchans-1);
                
                if ~isempty(result.rerp_profile)
                    if result.rerp_profile.settings.type_proc
                        result.rerp_profile.include_chans(idx) = this_result.rerp_profile.include_chans;
                    else
                        result.rerp_profile.include_comps(idx) = this_result.rerp_profile.include_comps;
                    end
                end
                
                try
                    result.lambda(idx) = this_result.lambda;
                catch
                end
                
                result.rerp_estimate(:, idx) = this_result.rerp_estimate;
                
                try
                    result.admm_residual(:, idx) = this_result.admm_residual;
                catch
                end
                
                if ~isempty(result.average_total_rsquare);
                    result.average_total_rsquare(idx) = this_result.average_total_rsquare;
                end
                
                if ~isempty(result.average_event_rsquare);
                    result.average_event_rsquare(:,idx) = this_result.average_event_rsquare;
                end
                
                for j=1:length(result.total_xval_folds)
                    result.total_xval_folds(j).noise_variance(idx)=this_result.total_xval_folds(j).noise_variance;
                    result.total_xval_folds(j).data_variance(idx)=this_result.total_xval_folds(j).data_variance;
                end
                
                for j=1:length(result.event_xval_folds)
                    result.event_xval_folds(j).noise_variance(:,idx)=this_result.event_xval_folds(j).noise_variance;
                    result.event_xval_folds(j).data_variance(:,idx)=this_result.event_xval_folds(j).data_variance;
                end
                
                result.gridsearch = RerpResult.mergeGridSearch(result, this_result, idx);
                
                m=m+nchans;
            end
        end
        
        % Get x axis ticks for plotting erp waveform
        function xaxis_ms = get_xaxis_ms(epoch_boundaries, sample_rate)
            epoch_length = epoch_boundaries(2)-epoch_boundaries(1);
            ns=sample_rate*epoch_length;
            xaxis_ms=((0:(ns-1))+epoch_boundaries(1)*sample_rate)*1000/sample_rate;
        end
        
    end
    
    methods (Hidden=true)
        % Returns time series numbers where rsquare was statistically
        % different from zero mean at p<significance_level.
        function rsquare_significance = get_total_rsquare_significance(obj, significance_level)
            data_variance=zeros(length(obj.total_xval_folds), length(obj.total_xval_folds(1).data_variance));
            noise_variance=zeros(length(obj.total_xval_folds), length(obj.total_xval_folds(1).noise_variance));
            for i=1:length(obj.total_xval_folds)
                data_variance(i,:) = obj.total_xval_folds(i).data_variance;
                noise_variance(i,:) = obj.total_xval_folds(i).noise_variance;
            end
            
            rsquare = 1 - noise_variance./data_variance;
            rsquare_significance = squeeze(ttest(rsquare, 0, 'Alpha', significance_level));
        end
        
        % Returns time series numbers where rsquare was statistically
        % different from zero mean at p<significance_level.
        function rsquare_significance = get_event_rsquare_significance(obj, significance_level)
            data_variance=zeros([length(obj.event_xval_folds) size(obj.event_xval_folds(1).data_variance)]);
            noise_variance=zeros([length(obj.event_xval_folds) size(obj.event_xval_folds(1).noise_variance)]);
            
            for i=1:length(obj.event_xval_folds)
                data_variance(i,:,:) = obj.event_xval_folds(i).data_variance;
                noise_variance(i,:,:) = obj.event_xval_folds(i).noise_variance;
            end
            
            rsquare = 1 - noise_variance./data_variance;
            rsquare_significance = squeeze(ttest(rsquare, 0, 'Alpha', significance_level));
        end
        
        function delay = get_delay_times(obj, event_nums, delay_var, num_samples)
            import rerp_dependencies.*
            
            regexp_str_in_parentheses = '.*\((.*)\).*';
            regexp_str_out_parentheses = '(.*)(?:\s*\(.*\))?';
            
            delay_context_tag = strtrim(regexp(delay_var, regexp_str_in_parentheses, 'tokens'));
            delay_locking_tag = strtrim(regexp(delay_var, regexp_str_out_parentheses, 'tokens'));
            
            delay=zeros(1,length(event_nums));
            events = obj.rerp_profile.these_events;
            
            m=1;
            if obj.rerp_profile.settings.hed_enable
                % Now find the delay for each delay_var event
                for i=1:length(event_nums)
                    this_evt_num=event_nums(i);
                    this_latency = events.latencyInFrame(this_evt_num);
                    if ~isempty(delay_var)
                        for j=this_evt_num:length(events.label)
                            
                            if events.latencyInFrame(j) > (this_latency + num_samples)
                                delay(m) = num_samples;
                                break;
                            end
                            
                            these_hed_tags = hedTree.hed_tag_count(regexp(events.hedTag{j}, '[,;]','split'), 0, 0);
                            if ~isempty(intersect(these_hed_tags, delay_locking_tag{1}{1}))
                                if isempty(delay_context_tag)
                                    delay_latency=events.latencyInFrame(j);
                                    delay(m) = delay_latency-this_latency;
                                    break;
                                else
                                    if ~isempty(intersect(these_hed_tags, delay_context_tag{1}{1}))
                                        delay_latency=events.latencyInFrame(j);
                                        delay(m) = delay_latency-this_latency;
                                        break;
                                    end
                                end
                            end
                        end
                    end
                    m=m+1;
                end
                
            else
                for i=event_nums
                    this_latency = events.latencyInFrame(i);
                    for j=i:length(events.label)
                        if events.latencyInFrame > (this_latency + num_samples)
                            delay(m) = num_samples;
                            break;
                        end
                        
                        this_event = events.label{j};
                        if strcmp(delay_var, this_event)
                            delay_latency=events.latencyInFrame(j);
                            delay(m) = delay_latency-this_latency;
                            break;
                        end
                    end
                    m=m+1;
                end
            end
        end
        
        % Extract epochs corresponding to tags or event codes
        function [rerp_epochs, event_nums] = get_rerp_epochs(obj, data, locking_var,  num_samples)
            
            events = obj.rerp_profile.these_events;
            rerp_epochs = zeros([num_samples, length(events.label), size(data,2)]);
            m=1;
            
            if obj.rerp_profile.settings.hed_enable
                regexp_str_in_parentheses = '.*\((.*)\).*';
                regexp_str_out_parentheses = '(.*)(?:\s*\(.*\))?';
                
                context_tag = regexp(locking_var, regexp_str_in_parentheses, 'tokens');
                locking_tag = regexp(locking_var, regexp_str_out_parentheses, 'tokens');
                
                % Get event numbers for locking_var (possibly in a context
                % group).
                
                if ~isempty(context_tag)
                    for i=1:length(obj.rerp_profile.context_group)
                        this_group = obj.rerp_profile.context_group{i};
                        for j=1:length(this_group.children)
                            this_child = this_group.children{i};
                            if strcmp(context_tag{1}{1}, this_child.tag)
                                idx = find(strcmp(locking_tag{1}{1}, this_child.included_tag), 1);
                                event_nums = this_child.ids(this_child.included_id{idx});
                            end
                        end
                    end
                else
                    tag_idx = strcmp(locking_tag{1}{1}, obj.rerp_profile.hed_tree.uniqueTag);
                    event_nums = obj.rerp_profile.hed_tree.originalHedStringId{tag_idx};
                end
                
                for i=event_nums(:)'
                    this_latency = events.latencyInFrame(i);
                    rerp_epochs(:,m,:) = data(this_latency:(this_latency+num_samples-1),:);
                    m=m+1;
                end
                
            else
                event_nums=zeros(0,1);
                for i=1:length(events.label)
                    this_event = events.label{i};
                    if strcmp(locking_var, this_event)
                        this_latency=events.latencyInFrame(i);
                        rerp_epochs(:,m,:) = data(this_latency:(this_latency+num_samples-1),:);
                        event_nums(m) = i;
                        m=m+1;
                    end
                    
                end
            end
            
            rerp_epochs=rerp_epochs(:,1:(m-1),:);
        end
    end
    
    methods (Static=true, Hidden=true)
        % Recursively combine grid search results from two rerp_results
        function main_gridsearch = mergeGridSearch(main_result, added_result, idx)
            main_gridsearch=main_result.gridsearch;
            added_gridsearch=added_result.gridsearch;
            
            if (~isempty(main_gridsearch)) && (~length(fieldnames(main_gridsearch))==0)
                main_gridsearch.lambda_range(idx) = added_gridsearch.lambda_range;
                
                for i=1:length(main_gridsearch.grid_results)
                    main_gridsearch.grid_results{i} = RerpResult.combineRerpResults({main_gridsearch.grid_results{i}, added_gridsearch.grid_results{i}});
                end
                
                try
                    main_gridsearch.next_stage.gridsearch = RerpResult.mergeGridSearch(main_gridsearch.next_stage, added_gridsearch.next_stage, idx);
                catch
                end
            end
        end
        
        % Callback for axes context menu: publishes the figure
        function gui_publish(varargin)
            ax=gca;
            h=figure;
            set(h,'color',[1 1 1]);
            
            newax=copyobj(ax, h);
            pr=get(ax,'UserData');
            
            try
                lstr = get(pr.legend,'String');
                legend(lstr);
                lprops=get(pr.legend,'UserData');
                try
                    p=copyobj(lprops.plotHandles,newax);
                    legend(p,lstr);
                catch
                    legend(lstr);
                end
            catch
                
            end
            
            set(gca,  'ActivePositionProperty', 'OuterPosition',...
                'OuterPosition', [0 0 1 1]);
            
            rerp_publish_gui('hFig', h);
        end
    end
end

