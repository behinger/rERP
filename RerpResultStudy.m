%Used for combining multiple RerpResults for plotting and statistics.
%All methods of this class currently mirror RerpResult. If called for multiple
%results, it will simply plot the first result using RerpResult. In
%future releases, the methods will be able to handle multiple results.
%   Usage:
%       rerp_result_study = RerpResultStudy(rerp_results);
%           Initiate the RerpResultStudy and all results in rerp_results with
%           a default RerpPlotSpec instance
%
%       rerp_result_study = RerpResultStudy(rerp_results, rerp_plot_spec);
%           Initiate the RerpResultStudy and all results in rerp_results with
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
            
            if nargin > 1
                obj.rerp_plot_spec = rerp_plot_spec;
            else
                obj.rerp_plot_spec = RerpPlotSpec;
            end
            
            if nargin == 0
                help RerpResultStudy;
            elseif ~isempty(rerp_results)
                obj.result=rerp_results(:);
            end
            
            %If we wanted to control all rerp_plot_spec objects with one
            %instance, we can pass it in.
            if nargin > 1
                [obj.result(:).rerp_plot_spec] = deal(obj.rerp_plot_spec);
            end
        end
        
        function plotRerpEventTypes(obj, h)
            num_results = length(obj.result);
            
            if nargin == 0
                h=[];
            end
            
            if num_results > 0
                obj.result(1).plotRerpEventTypes(h);
            end
        end
        
        function plotRerpTimeSeries(obj, h)
            num_results = length(obj.result);
            
            if nargin == 0
                h=[];
            end
            
            if num_results > 0
                obj.result(1).plotRerpTimeSeries(h);
            end
        end
        
        function plotRerpTotalRsquared(obj, h)
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
                            this_fold = this_result.total_xval_folds(j);
                            
                            
                            this_fold.noise_variance=this_fold.noise_variance(this_result.rerp_plot_spec.ts_idx);
                            this_fold.data_variance=this_fold.data_variance(this_result.rerp_plot_spec.ts_idx);
                            
                            try
                                this_fold.num_samples=this_fold.num_samples(this_result.rerp_plot_spec.ts_idx);
                            catch
                                this_fold.num_samples=[];
                            end
                            
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
                            this_fold = this_result.total_xval_folds(j);
                            
                            
                            this_fold.noise_variance=this_fold.noise_variance(this_result.rerp_plot_spec.ts_idx);
                            this_fold.data_variance=this_fold.data_variance(this_result.rerp_plot_spec.ts_idx);
                            
                            try
                                this_fold.num_samples=this_fold.num_samples(this_result.rerp_plot_spec.ts_idx);
                            catch
                                this_fold.num_samples=[];
                            end
                            
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
                final_result.plotRerpEventRsquared(h);
                
            elseif num_results==1
                %Just plotting one result
                obj.result.plotRerpEventRsquared(h);
            else
                %No results are stored in this object
                return;
            end
        end
        
        function plotRerpImage(obj, h)
            if nargin == 0
                h=[];
            end
            
            obj.result(1).plotRerpImage(h);
        end
        
        function plotGridSearch(obj, h)
            if nargin == 0
                h=[];
            end
            
            obj.result(1).plotGridSearch(h);
        end
        
        function plotRersp(obj, h)
            if nargin == 0
                h=[];
            end
            
            obj.result(1).plotRersp(h);
        end
    end
end

