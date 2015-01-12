%Used for combining multiple RerpResults for plotting and statistics.
%All methods of this class currently mirror RerpResult. If constructed with
%a single RerpResult object, simply calls the corresponding method of that
%result. If constructed with multiple results, certain functions will
%combine results for more powerful statistics.
%
%       rerp_result_study = RerpResultStudy(rerp_results);
%           Standard constructor copies rerp_results and puts them into a
%           standard template with the same number of channels and event
%           types. 
%
%       rerp_result_study = RerpResultStudy(rerp_results, rerp_plot_spec);
%           Initiate all results in rerp_results with
%           rerp_plot_spec
%
%   Parameters:
%       rerp_results:
%           Array of RerpResult objects
%
%       rerp_plot_spec:
%           RerpPlotSpec object
%
%   See also:
%       RerpResult, rerp_result_gui, pop_rerp
classdef RerpResultStudy
    properties
        result %Array of RerpResult object
        rerp_plot_spec %RerpPlotSpec object
    end
    
    methods
        function obj = RerpResultStudy(rerp_results, rerp_plot_spec)
            import rerp_dependencies.RerpPlotSpec
            
            %If we wanted to control all rerp_plot_spec objects with one
            %instance, we can pass it in.
            if nargin > 1
                obj.rerp_plot_spec = rerp_plot_spec;
                [obj.result(:).rerp_plot_spec] = deal(obj.rerp_plot_spec);
            else
                obj.rerp_plot_spec = RerpPlotSpec;
            end
            
            if nargin == 0
                help RerpResultStudy;
            elseif ~isempty(rerp_results)
                obj.result=copy(rerp_results(:));
            end
            
            %Find result with most channels
            max_length=0;
            tags_list=cell(1,length(obj.result));
            master_tags_list={};
            for i=1:length(obj.result)
                max_length = max(max_length, length(obj.result(i).average_total_rsquare));
                tags_list{i} = obj.result(i).get_plotting_params;
                master_tags_list = union(master_tags_list, tags_list{i});
            end
            
            %Force each result to have same number of channels and event types as the
            %maximum by inserting NaNs
            for i=1:length(obj.result)
                
                %Map this results event type indexing into the master index
                %scheme for combining results
                this_master_map = NaN(1,length(master_tags_list));
                for j=1:length(tags_list{i})
                    this_tag = tags_list{i}{j};
                    this_master_idx = strcmp(this_tag, master_tags_list);
                    this_master_map(this_master_idx) = j;
                end

                %Adjust event type indexes for this result to the master
                %index scheme
                nan_idx = isnan(this_master_map);
                new_idx = find(~nan_idx);
                obj.result(i).rerp_plot_spec.event_idx=new_idx(obj.result(i).rerp_plot_spec.event_idx); 
                
                %Assign new parameters to this result w/NaN if the time
                %series or event type is not available according to master
                %layout. 
                rerp_estimate=NaN(size(obj.result(i).rerp_estimate, 1), max_length);
                rerp_estimate(:, 1:size(obj.result(i).rerp_estimate, 2))=obj.result(i).rerp_estimate;
                admm_residual=NaN(size(obj.result(i).admm_residual, 1), max_length);
                admm_residual(:, 1:size(obj.result(i).admm_residual, 2))=obj.result(i).admm_residual;
                lambda=cell(max_length);
                [lambda{:}]=deal(NaN);
                lambda(1:length(obj.result(i).lambda))=obj.result(i).lambda;
                average_total_rsquare=NaN(1, max_length);
                average_total_rsquare(1:length(obj.result(i).average_total_rsquare))=obj.result(i).average_total_rsquare;
                average_event_rsquare=NaN(length(this_master_map), max_length);
                average_event_rsquare(new_idx, 1:size(obj.result(i).admm_residual, 2))=obj.result(i).average_event_rsquare;
                
                %Assign new masterized values back to the result object
                obj.result(i).rerp_estimate=rerp_estimate;
                obj.result(i).admm_residual=admm_residual;
                obj.result(i).lambda=lambda;
                obj.result(i).average_total_rsquare=average_total_rsquare;
                obj.result(i).average_event_rsquare=average_event_rsquare;

                %Adjust xval folds to master scheme
                for k=1:length(obj.result(i).total_xval_folds)
                    this_length = length(obj.result(i).total_xval_folds(k).data_variance);
                    
                    %Create new total data fold with master layout and assign to this fold 
                    total_data_variance = NaN(1, max_length);
                    total_data_variance(1:this_length)= obj.result(i).total_xval_folds(k).data_variance;
                    total_noise_variance = NaN(1, max_length);
                    total_noise_variance(1:this_length)= obj.result(i).total_xval_folds(k).noise_variance;
                    total_num_samples = NaN(1, max_length);
                    total_num_samples(1:this_length)= obj.result(i).total_xval_folds(k).num_samples;
                    obj.result(i).total_xval_folds(k).data_variance=total_data_variance;
                    obj.result(i).total_xval_folds(k).noise_variance=total_noise_variance;
                    obj.result(i).total_xval_folds(k).num_samples=total_num_samples;                    
                    
                    %Create new event fold with master layout and assign to
                    %this fold
                    event_data_variance = NaN(length(this_master_map), max_length);
                    event_data_variance(~nan_idx, 1:this_length)= obj.result(i).event_xval_folds(k).data_variance;
                    event_noise_variance = NaN(length(this_master_map), max_length);
                    event_noise_variance(~nan_idx, 1:this_length)= obj.result(i).event_xval_folds(k).noise_variance;
                    event_num_samples = NaN(length(this_master_map), max_length);
                    event_num_samples(new_idx, 1:this_length)= repmat(obj.result(i).event_xval_folds(k).num_samples,1,this_length);
                    obj.result(i).event_xval_folds(k).data_variance=event_data_variance;
                    obj.result(i).event_xval_folds(k).noise_variance=event_noise_variance;
                    obj.result(i).event_xval_folds(k).num_samples=event_num_samples; 
                end
            end
        end
        
        function plotRerpEventTypes(obj, h)
            %No combined plotting functionality. See
            %RerpResult.plotRerpEventTypes. 
            num_results = length(obj.result);
            
            if nargin == 0
                h=[];
            end
            
            if num_results > 0
                obj.result(1).plotRerpEventTypes(h);
            end
        end
        
        function plotRerpTimeSeries(obj, h)
            %No combined plotting functionality. See
            %RerpResult.plotRerpTimeSeries. 
            num_results = length(obj.result);
            
            if nargin == 0
                h=[];
            end
            
            if num_results > 0
                obj.result(1).plotRerpTimeSeries(h);
            end
        end
        
        function plotRerpTotalRsquared(obj, h)
            %Combines cross validation folds of all RerpResult objects in
            %obj.result. Uses a weighted mean and weighted ttest. Weights
            %are determined by number of samples used to produce each
            %value.
            if nargin == 0
                h=[];
            end
            num_results = length(obj.result);
            %Combined plotting from multiple results
            if num_results > 1
                %Result which will be used to combine all others
                final_result = copy(obj.result(1));
                final_result.average_total_rsquare = zeros(num_results, length(final_result.rerp_plot_spec.ts_idx));
                num_folds = final_result.rerp_profile.settings.num_xvalidation_folds;
                
                %Go through each result and stack the folds, rearranging the
                %order of the time-series according to each results
                %rerp_plot_sec if required.
                for i=1:num_results
                    this_result = obj.result(i);
                    
                    %Rearrange the timeseries if we are sorting by R2
                    if final_result.rerp_plot_spec.sort_by_r2
                        this_average_total_rsquare=this_result.average_total_rsquare(this_result.rerp_plot_spec.ts_idx);
                        
                        for j=1:num_folds
                            this_fold = copy(this_result.total_xval_folds(j));
                            
                            this_fold.noise_variance=this_fold.noise_variance(this_result.rerp_plot_spec.ts_idx);
                            this_fold.data_variance=this_fold.data_variance(this_result.rerp_plot_spec.ts_idx);
                            this_fold.num_samples=this_fold.num_samples(this_result.rerp_plot_spec.ts_idx);
                            
                            final_result.total_xval_folds(num_folds*(i-1)+j) = this_fold;
                            
                        end
                        final_result.average_total_rsquare(i, :) = this_average_total_rsquare;
                    end
                end
                
                final_result.average_total_rsquare=mean(final_result.average_total_rsquare);
                final_result.rerp_plot_spec.ts_idx= 1:length(final_result.average_total_rsquare);
                final_result.rerp_profile.include_comps= 1:length(final_result.average_total_rsquare);
                final_result.rerp_profile.include_chans= 1:length(final_result.average_total_rsquare);
                final_result.rerp_profile.eeglab_dataset_name=sprintf('/%d datasets combined.set', length(obj.result));
                final_result.plotRerpTotalRsquared(h);
                
            elseif num_results==1
                %Just plotting one result
                obj.result.plotRerpTotalRsquared(h);
            else
                %No results are stored in this object
                return;
            end
        end
        
        function plotRerpEventRsquared(obj, h)
            %Combines cross validation folds of all RerpResult objects in
            %obj.result. Uses a weighted mean and weighted ttest. Weights
            %are determined by number of samples used to produce each
            %value.
            import rerp_dependencies.RerpXvalFold
            if nargin == 0
                h=[];
            end
            num_results = length(obj.result);
            
            
            %Result which will be used to combine all others
            final_result = copy(obj.result(1));
            final_result.event_xval_folds=RerpXvalFold;
            
            num_folds = final_result.rerp_profile.settings.num_xvalidation_folds;
            
            %Go through each result
            combined_average_event_rsquare = zeros([num_results, size(final_result.average_event_rsquare)]);
            this_ts_idx = zeros(size(final_result.average_event_rsquare));
            for i=1:num_results
                this_result = obj.result(i);
                
                %Rearrange the timeseries if sorting by R2
                if final_result.rerp_plot_spec.sort_by_r2 || num_results > 1
                    for j=1:size(this_result.average_event_rsquare, 1)
                        %Want NaN at the bottom of the sort list, so we force
                        %using fliplr
                        [r2vals, r2idx] = sort(this_result.average_event_rsquare(j,:));
                        nn=~isnan(r2vals);
                        r2vals(nn)=fliplr(r2vals(nn));
                        r2idx(nn)=fliplr(r2idx(nn));
                        
                        combined_average_event_rsquare(i,j,:)= r2vals;
                        this_ts_idx(j, :)=r2idx;
                        
                        %Stack the folds for combined statistics
                        for k=1:num_folds
                            noise_variance=this_result.event_xval_folds(k).noise_variance(j, this_ts_idx(j,:));
                            data_variance=this_result.event_xval_folds(k).data_variance(j, this_ts_idx(j,:));
                            num_samples=this_result.event_xval_folds(k).num_samples(j, this_ts_idx(j,:));
                            
                            final_result.event_xval_folds(num_folds*(i-1)+k).noise_variance(j,:) = noise_variance;
                            final_result.event_xval_folds(num_folds*(i-1)+k).data_variance(j,:) = data_variance;
                            final_result.event_xval_folds(num_folds*(i-1)+k).num_samples(j,:) = num_samples;
                        end
                    end
                end
            end
            
            %Combined plotting from multiple results
            if num_results > 1
                final_result.average_event_rsquare=squeeze(mean(combined_average_event_rsquare));
                final_result.rerp_plot_spec.ts_idx_event_types= repmat(1:length(final_result.rerp_plot_spec.ts_idx), [size(final_result.average_event_rsquare,1) 1]);
                final_result.rerp_profile.include_comps= 1:size(final_result.average_event_rsquare,2);
                final_result.rerp_profile.include_chans= 1:size(final_result.average_event_rsquare,2);
                final_result.rerp_profile.eeglab_dataset_name=sprintf('/%d datasets combined.set', length(obj.result));
                final_result.plotRerpEventRsquared(h);
                
            elseif num_results==1
                %Just plotting one result
                final_result.rerp_plot_spec.ts_idx_event_types=this_ts_idx(:, 1:length(final_result.rerp_plot_spec.ts_idx));
                final_result.plotRerpEventRsquared(h);
            else
                %No results are stored in this object
                return;
            end
        end
        
        function plotRerpImage(obj, h)
            %No combined plotting functionality. See
            %RerpResult.plotRerpImage. 
            if nargin == 0
                h=[];
            end
            
            obj.result(1).plotRerpImage(h);
        end
        
        function plotGridSearch(obj, h)
            %No combined plotting functionality. See
            %RerpResult.plotGridSearch. 
            if nargin == 0
                h=[];
            end
            
            obj.result(1).plotGridSearch(h);
        end
        
        function plotRersp(obj, h)
            %No combined plotting functionality. See
            %RerpResult.plotRersp. 
            if nargin == 0
                h=[];
            end
            
            obj.result(1).plotRersp(h);
        end
    end
end

