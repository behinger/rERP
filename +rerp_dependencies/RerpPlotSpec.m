%Contains properties used to specify plotting conditions.
%   Usage:
%       rerp_result.rerp_plot_spec.significance_level=.01;
%           Set each of the properties directly
%
%   Parameters:
%       rerp_result:
%           RerpResult object we will plot
%       rerp_plot_spec:
%           RerpPlotSpec object
%
%   See also:
%       rerp_result_gui, RerpResult, RerpResultStudy
classdef RerpPlotSpec < matlab.mixin.Copyable
    properties
        sort_idx=1;
        ts_idx=1 %Index of channels/components to plot (not necessarily the actual channel or IC number
        event_idx=1 %Index of event type or tag to plot
        
        exclude_insignificant=0 %Skip plotting statistically insignificant
        significance_level=.05 %p-value threshold for determining significance
        locking_idx=1 %For plotRerpImage, specifies the locking variable for epochs
        delay_idx=1 %For plotRerpImage, sorts based on delay from locking variable to delay variable
        window_size_ms=3000 %For plotRerpImage, length of plotting window (epoch length)
        constant_scale=0; %Force the y-axis to be the same across all plots
        sort_by_r2=1; %Plot in order of decreasing R2
        over_plot=0; %Plot multiple times on the same axes
    end        
end
