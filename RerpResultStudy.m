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

