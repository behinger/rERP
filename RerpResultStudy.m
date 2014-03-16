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
        function obj = RerpResultStudy(result, rerp_plot_spec)
            import rerp_dependencies.RerpPlotSpec
            obj.result=result;
            if ~exist('rerp_plot_spec','var')
                obj.rerp_plot_spec = RerpPlotSpec; 
            else
                obj.rerp_plot_spec = rerp_plot_spec; 
            end
            
            %Make sure all results are synchronized to the same
            %RerpPlotSpec handle
            [obj.result(:).rerp_plot_spec] = deal(obj.rerp_plot_spec); 
        end
        
        function plotRerpEventTypes(obj, h)
            obj.result(1).plotRerpEventTypes(h);
        end
        
        function plotRerpTimeSeries(obj, h)
            obj.result(1).plotRerpTimeSeries(h);
        end
        
        function plotRerpTotalRsquared(obj, h)
            obj.result(1).plotRerpTotalRsquared(h)
        end
        
        function plotRerpEventRsquared(obj, h)
            obj.result(1).plotRerpEventRsquared(h);
        end
        
        function plotRerpImage(obj, h)
            obj.result(1).plotRerpImage(h);
        end
        
        function plotGridSearch(obj, h)
            obj.result(1).plotGridSearch(h);
        end
        
        function plotRersp(obj, h)
            obj.result(1).plotRersp(h);
        end
    end   
end

