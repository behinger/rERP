%RERPPLOTSPEC Contains properties used to specify plotting conditions
classdef RerpPlotSpec < handle
    properties     
        ts_idx=1 %Index of channels/components to plot (not necessarily the actual channel or IC number
        event_idx=1 %Index of event type or tag to plot
        exclude_insignificant=0 %Skip plotting statistically insignificant
        significance_level=.05 %p-value threshold for determining significance
        locking_idx=1 %For plotRerpImage, specifies the locking variable for epochs
        delay_idx=1 %For plotRerpImage, sorts based on delay from locking variable to delay variable
        window_size_ms=3000 %For plotRerpImage, length of plotting window (epoch length)
    end
    
    methods
        function setPlotTimeSeries(obj, time_series_nums)
        end
        
        function setPlotEventTypes(obj, event_types)
        end
    end
end

