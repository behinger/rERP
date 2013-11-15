% Class that defines the behavior and functionality of MoBI events
%
% Copyright (C) 2013 Nima Bigdely Shamlo, Alejandro Ojeda, Matthew Burns, SCCN, INC, UCSD
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

classdef event 
    properties
        boundaryLatencyInFrame = []; 
        latencyInFrame = []; %  1 x N vector containing latencies for N events
        label = {};  %  1 x N vector containing labels (strings describing event types) for N events.
        uniqueLabel = {}; %  1 x M vector of labels associated with unique event idNumbers.
        hedTag = {}; %  1 x N vector containing semicolon separated hed tags (strings describing each individual event) for N events.
  end
    properties (Hidden = true)
        value = [];
    end
    methods
        %%
        function obj = event(eventChannel,label)
            if nargin < 1, eventChannel = 0;end
            if isstruct(eventChannel) || isa(eventChannel,'event')
                obj.latencyInFrame = eventChannel.latencyInFrame;
                obj.label = eventChannel.label;
                obj.uniqueLabel = unique(obj.label);
                if isfield(eventChannel,'value')
                    obj.value = eventChannel.value;
                end
            else 
                obj.latencyInFrame = find(eventChannel);
                N = length(obj.latencyInFrame);
                if nargin < 2
                    obj.label = mat2cell(num2str(eventChannel(obj.latencyInFrame)),ones(N,1));
                else
                    obj.label = label;
                end
                indBoundary = isnan(eventChannel);
                [~,ind] = ismember(obj.latencyInFrame,find(indBoundary));
                ind = find(ind);
                obj.label(ind) = {'boundary'}; %#ok
                obj.uniqueLabel = unique(obj.label);
            end
        end
        %%
        function obj = addEventFromChannel(obj,eventChannel,offset,label)
            
            if nargin < 3, offset = 0;end
            eventChannel = eventChannel(:);
            tmp = find(eventChannel);
            N = length(tmp);
            obj.latencyInFrame(end+1:end+N) = offset+tmp;
            if nargin < 4, 
                if isempty(obj.label)
                    obj.label = cell(N,1);
                    for it=1:N, obj.label{it} = strtrim(num2str(eventChannel(tmp(it))));end
                else
                    for it=1:N, obj.label{end+1} = strtrim(num2str(eventChannel(tmp(it))));end
                end
            else
                obj.label(end+1:end+N) = label;
            end
            indBoundary = isnan(eventChannel);
            [~,ind] = ismember(obj.latencyInFrame,offset+find(indBoundary));
            ind = find(ind);
            obj.label(ind) = {'boundary'}; %#ok
            obj.uniqueLabel = unique(obj.label);
        end
        %%
        function obj = addEvent(obj,latencyInFrame,label,varargin)
            if nargin < 3, error('prog:input','Not enough input arguments.');end
            N = length(latencyInFrame);
            obj.latencyInFrame(end+1:end+N) = latencyInFrame;
            if iscell(label)
                obj.label(end+1:end+N) = label;
            else
                obj.label(end+1:end+N) = {label};
            end
%             if length(obj.latencyInFrame) > length(unique(obj.latencyInFrame))
%                 tmp = num2cell(obj.latencyInFrame',[length(obj.latencyInFrame)]);
%                 for it=1:length(tmp)
%                     tmp{it} = [num2str(tmp{it}) obj.label{it}];
%                 end
%                 [~,loc] = unique(tmp,'first');
%                 loc = sort(loc);
%                 obj.latencyInFrame = obj.latencyInFrame(loc);
%                 obj.label = obj.label(loc);
%             end
            obj.uniqueLabel = unique(obj.label);
            if nargin > 3
                name = varargin(1:2:end); 
                val = varargin(2:2:end);%#ok
                if isempty(obj.value)
                    for it=1:length(name)
                        eval(['obj.value(1).' name{it} '= val{it}(:);']);
                    end
                    obj.value(1).label = label; 
                else
                    ind = ismember({obj.value.label},label);
                    if ~any(ind)
                        n = length(obj.value);
                        for it=1:length(name)
                            eval(['obj.value(n+1).' name{it} '= val{it}(:);']);
                        end
                        obj.value(n+1).label = label;
                    else
                        ind = find(ind);
                        ind = ind(1);%#ok
                        for it=1:length(name)
                            eval(['obj.value(ind).' name{it} '(end+1:end+N)= val{it}(:);']);
                        end
                    end
                end
            end
        end
        %%
        function eventChannel = event2vector(obj,timeStamp,timeSpan)
            if nargin < 3, timeSpan = [1 length(timeStamp)];end
            eventChannel = zeros(size(timeStamp));
            
            idNumber = str2double(obj.label);
            eventChannel(obj.latencyInFrame) = idNumber;
            
            [~,indBoundary] = ismember(obj.label,'boundary');
            indBoundary = find(indBoundary);
            eventChannel(obj.latencyInFrame(indBoundary)) = NaN;%#ok
            eventChannel = eventChannel(timeSpan(1):timeSpan(2));
        end
        %%
        function obj = eeglab2event(obj,EEG)
            obj.latencyInFrame = nan(1, length(EEG.event));
            obj.label = cell(1, length(EEG.event));
            obj.hedTag = cell(1, length(EEG.event));
            
            counter = 1;
            for eventNumber = 1:length(EEG.event)
                % eventType must contain strings
                if ischar(EEG.event(eventNumber).type)
                    if ~strcmpi(EEG.event(eventNumber).type, 'boundary')
                        obj.label{counter} = EEG.event(eventNumber).type;
                    else
                        obj.boundaryLatencyInFrame(end+1) = EEG.event(eventNumber).latency;
                        continue;
                    end;
                else
                    eventType = EEG.event(eventNumber).type;
                    if ischar(eventType)
                        obj.label{counter} = eventType;
                    else
                        obj.label{counter} = num2str(EEG.event(eventNumber).type);
                    end
                end;
                obj.latencyInFrame(counter) = EEG.event(eventNumber).latency;
                
                % Extract hed tags from EEG structure, if any
                try
                    obj.hedTag{counter} = EEG.event(eventNumber).hedTag;
                catch 
                    obj.hedTag{counter} = 'time-locked event';
                end
                
                counter = counter + 1;
            end;
            obj.label(counter:end) = [];
            obj.latencyInFrame(counter:end) = [];
            obj.hedTag(counter:end) = [];
            
            % get uniqe event labels
            obj.uniqueLabel = unique(obj.label);
        end
        %%
        function EEG = event2eeglab(obj,EEG) 
            N = length(obj.label);
            if N
                if N == 1
                    latencies = {obj.latencyInFrame};
                elseif N == 2
                    latencies = {obj.latencyInFrame(1),obj.latencyInFrame(2)};
                else
                    latencies = num2cell(obj.latencyInFrame,[N 1]);
                end
                EEG = eeg_addnewevents(EEG, latencies, obj.label);
            end
        end
        %%
        function metadata = saveobj(obj)
            metadata.latencyInFrame = obj.latencyInFrame;
            metadata.label          = obj.label;
            metadata.uniqueLabel    = obj.uniqueLabel;
            metadata.value          = obj.value;
            metadata.hedTag         = obj.hedTag; 
        end
        %%
        function numberOfOccurancesForEachEvent = getNumberOfOccurancesForEachEvent(obj)            
            N = length(obj.uniqueLabel);
            numberOfOccurancesForEachEvent = zeros(1,N);
            for it=1:N
                numberOfOccurancesForEachEvent(it) = sum(ismember(obj.label,obj.uniqueLabel{it}));
            end            
        end
        %%
        function plotNumberOfOccurancesForEachEvent(obj)
            numberOfOccurancesForEachEvent = getNumberOfOccurancesForEachEvent(obj);
            figure;
            barh(numberOfOccurancesForEachEvent);
            set(gca,'ytick', 2:length(obj.uniqueLabel),  'ytickLabel', obj.uniqueLabel(2:end))
            ylabel('Events');
            xlabel('Number of occurences');
        end
        %%
        function [eventLatencyInFrame, eventLabel] = getLatencyForEventLabel(obj, eventLabel)
            if isnumeric(eventLabel)
                eventLabel = num2str(eventLabel);
            end
            [~,loc] = ismember(obj.label,eventLabel); 
            eventLatencyInFrame = obj.latencyInFrame(logical(loc));
        end
        %%
        function obj = renameLabels(obj,label,newLabel)
           loc = find(ismember(obj.label,label)); 
           if isempty(loc), return;end
           for it=1:length(loc)
               obj.label{loc(it)} = newLabel;
           end
           obj.uniqueLabel = unique(obj.label);
        end
        %%
        function obj = deleteEvent(obj,index)
            if length(nonzeros(index)) <= length(obj.latencyInFrame) && ~isempty(nonzeros(index))
                obj.latencyInFrame(index) = [];
                obj.label(index) = [];
                obj.uniqueLabel = unique(obj.label);
            end
        end
        %%
        function obj = deleteAllEventsWithThisLabel(obj,label)
            if iscell(label)
                for it=1:length(label)
                    index = ismember(obj.label,label{it});
                    obj = obj.deleteEvent(index);
                end
            else
                index = ismember(obj.label,label);
                obj = obj.deleteEvent(index);
            end
            if ~isempty(obj.value)
                ind = ismember({obj.value.label},label);
                obj.value(ind) = [];
            end
        end
        
    end
    methods(Hidden=true)
        function eventId = getIdForEventLabel(obj, eventLabel)
            eventId = find(strcmp(obj.uniqueLabel, eventLabel));            
        end
        %%
        function obj = interpEvent(obj,x,xi)
            yi = zeros(size(obj.latencyInFrame));
            if ~isempty(obj.latencyInFrame)
                for it=1:length(obj.latencyInFrame)
                    [~,loc] = min(sqrt((x(obj.latencyInFrame(it))-xi).^2));
                    yi(it) = loc;
                end
                obj.latencyInFrame = yi;
            end
        end
    end
    
    methods(Static=true)
        %%
        function obj = loadobj(a)
            import rerp_dependencies.*
            obj=event;
            obj.latencyInFrame=a.latencyInFrame;
            obj.label = a.label; 
            obj.uniqueLabel = a.uniqueLabel; 
            obj.value = a.value; 
            obj.hedTag = a.hedTag; 
        end
    end
end