classdef RerpResultStudy
    %Used for combining multiple RerpResults for combined plotting and
    %statistics.
    
    properties
        result
    end
    
    methods
        function obj = RerpResultStudy(result)
            obj.result=result;
        end
        
        function plotRerpEventTypes(obj, event_idx, ts_idx, plotfig, exclude_insignificant, significance_level)
            this_result=obj.result{1};
            this_result.plotRerpEventTypes(event_idx, ts_idx, plotfig, exclude_insignificant, significance_level);
        end
        
        function plotRerpTimeSeries(obj, event_idx, ts_idx, plotfig, exclude_insignificant, significance_level)
            this_result=obj.result{1};
            this_result.plotRerpTimeSeries(event_idx, ts_idx, plotfig, exclude_insignificant, significance_level)
        end
        
        function plotRerpTotalRsquared(obj, ts_idx, significance_level, plotfig)
            this_result=obj.result{1};
            this_result.plotRerpTotalRsquared(ts_idx, significance_level, plotfig)
        end        
        
        function plotRerpEventRsquared(obj, ts_idx, significance_level, event_idx, plotfig)
            this_result=obj.result{1};
            this_result.plotRerpEventRsquared(ts_idx, significance_level, event_idx, plotfig);
        end
        
        function plotRerpImage(obj, locking_idx, sorting_idx, ts_idx, window_size_ms, plotfig)
            this_result=obj.result{1};
            
            eeg_parts=regexp(this_result.rerp_profile.eeglab_dataset_name, '(.*[\\\/])(.*.set)', 'tokens');            

            try 
                EEG=pop_loadset('filename', eeg_parts{1}{2}, 'filepath', eeg_parts{1}{1});
            catch
                EEG=pop_loadset;             
            end
            
            if (~this_result.rerp_profile.settings.type_proc) && isempty(EEG.icaact)
                EEG.icaact=eeg_getica(EEG);
            end
            
            this_result.plotRerpImage(EEG, locking_idx, sorting_idx, ts_idx, window_size_ms, plotfig);
        end
        
        function plotGridSearch(obj, ts_idx, plotfig)
            this_result=obj.result{1};
            this_result.plotGridSearch(ts_idx, plotfig);
        end
        
        function plotRersp(obj, event_idx, ts_idx, plotfig)
            this_result=obj.result{1};
            this_result.plotRersp(event_idx, ts_idx, plotfig);
        end        
    end
    
end

