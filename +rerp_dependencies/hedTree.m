% Copyright (C) 2013 Nima Bigdely-Shamlo and Matthew Burns, Swartz Center for Computational
% Neuroscience.
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

classdef hedTree < matlab.mixin.Copyable
    % this class represents an input cell array containing HED strings (each HED string is composed
    % of several HED tags) as a jungle (multiple node trees). Each tree shows the hierarchical
    % structure of HEd tags. Number of occurance and indices of the original HED strings that match
    % each tag are calculated and plaved in class properties.
    
    properties
        uniqueTag               % a cell array with unique HED tags in the input HED string cell array (derived from all input HED strings)
        uniqueTagCount          % a numrival array containing the number of occurances of each unique tag across all input HED string cell array.
        
        hedVersion=[];           % version of HED specification used to create this hedTree
        originalHedStringId=[];     % a cell array where each cell contains indices in the input HED string cell array where each uniqueTag
        originalHedStrings=[];      % a cell array of hed strings that were used to form this hedTree
        adjacencyMatrix             % Adjacency matrix (could be sparse) defined as follows:
        %   element i,j = 1 if node_i is connected with node_j,
        %   therwise the entry is 0. With i,j = 1: number of nodes.
    end;
    
    methods
        %hedManager is optional second argument: issues an error if the hed
        %specification is violated. 
        function obj = hedTree(hedStrings, hedmanager)
            import rerp_dependencies.*
            
            if nargin > 1
                assert(isa(hedmanager,'hedManager'));
                hm=hedmanager;
            else
                hm={};
            end
            
            obj.originalHedStrings=hedStrings;
            
            %Setting these to zero indicates we are not using hedManager
            %class.
            requireChild=0;
            nodeSequence=0;
            
            %Verify the hed tags are in compliance with a given hed specification, extract requireChild
            %information
            if ~isempty(hm)
                nodeSequence = cell(size(obj.originalHedStrings));
                requireChild = cell(size(obj.originalHedStrings));
                
                for i=1:length(obj.originalHedStrings)
                    [val, nodeSequence{i}, requireChild{i}] = hm.isValidHedString(obj.originalHedStrings{i});
                    if val~=1
                        error('hedTree: "%s" not located in hed specification', obj.originalHedStrings{i});
                    end
                end
                
                obj.hedVersion=hm.hedVersion;
            end
            
            [obj.uniqueTag, obj.uniqueTagCount, obj.originalHedStringId] = hedTree.hed_tag_count(obj.originalHedStrings, nodeSequence, requireChild);
            obj = makeAdjacencyMatrix(obj);
        end;
        
        function obj = makeAdjacencyMatrix(obj)
            import rerp_dependencies.*
            
            isParentyMatrix = false(length(obj.uniqueTag)+1, length(obj.uniqueTag)+1);
            
            for i=1:length(obj.uniqueTag)
                
                isParentyMatrix(i+1,2:end) = strncmpi(obj.uniqueTag{i}, obj.uniqueTag, length(obj.uniqueTag{i}));
            end;
            
            
            % find top-level nodes to be connected to the 'root' node, they are recognized as having no parents
            isParentyMatrix = logical(isParentyMatrix - diag(diag(isParentyMatrix)));
            isTopLevel = ~any(isParentyMatrix);
            
            obj.adjacencyMatrix = isParentyMatrix;
            
            obj.adjacencyMatrix(1,isTopLevel) = true;
            obj.adjacencyMatrix(1,1) = false; % the root node is not considered a child of itself.
            obj.adjacencyMatrix = obj.adjacencyMatrix | obj.adjacencyMatrix';
            
        end;
        
        function plot(obj, varargin)
            import rerp_dependencies.*
            
            uniqueTagLabel = cell(length(obj.uniqueTag),1);
            for i=1:length(obj.uniqueTag)
                locationOfSlash = find(obj.uniqueTag{i} == '/', 1, 'last');
                
                if isempty(locationOfSlash)
                    uniqueTagLabel{i} = obj.uniqueTag{i};
                else
                    uniqueTagLabel{i} = obj.uniqueTag{i}(locationOfSlash+1:end);
                end;
                
                uniqueTagLabel{i}(1) = upper(uniqueTagLabel{i}(1));
                
                uniqueTagLabel{i} = [uniqueTagLabel{i} ' (' num2str(obj.uniqueTagCount(i)) ')'];
            end;
            
            jtreeGraph(obj.adjacencyMatrix, uniqueTagLabel, 'Hed Tag');
        end;
    end
    
    methods (Static = true)
        function [uniqueTag, uniqueTagCount, originalHedStringId] = hed_tag_count(hedStringArray, nodeSequence, requireChild)
            import rerp_dependencies.*
            
            % separate HED string in the array into indivudal tags and removing the ones with ".
            
            %rc designates whether the requireChild feature is being used.
            %This will lump any tag with attribute requireChild="true" with
            %its child. If the name of the child tag is # (to designate a number), it will be
            %lumped with its value, the next proceeding tag.
            if ~iscell(requireChild)
                rc = boolean(0);
            else
                rc = boolean(1);
            end
            
            trimmed = strtrim(hedStringArray);
            hasDoublequote = ~cellfun(@isempty, strfind(hedStringArray, '"'));
            separated =  strtrim(regexp(trimmed, '[;,]', 'split'));
            
            allTags = cell(length(hedStringArray) * 3,1);
            allTagId = zeros(length(hedStringArray) * 3,1);
            counter = 1;
            
            %If we are specifying the requireChild parameter, make sure we
            %have the required number of sequences (one per hedtag)
            if rc
                msg = 'hed_tag_count: did not specify nodeSequence and requireChild args correctly';
                assert((length(nodeSequence)==length(separated))&&(length(nodeSequence)==length(requireChild)), msg);
                allreqChild = cell(length(hedStringArray) * 3,1);
                allNodeSeq = cell(length(hedStringArray) * 3,1);
            end
            
            for i=1:length(separated)
                if rc
                    this_seq = nodeSequence{i};
                    this_req_child = requireChild{i};
                end
                
                this_hed_string = separated{i};
                
                % This class does not recognize the "Time-Locked Event tag,
                % but it may be present in this_hed_string.
                for j=1:length(this_hed_string)
                    if rc
                        if strcmpi(this_seq{j}{1}, 'Time-Locked Event')
                            this_seq{j} = this_seq{j}(2:end);
                            this_req_child{j} = this_req_child{j}(2:end);
                        end
                    end
                    
                    this_hed_string{j} = regexprep(this_hed_string{j}, 'Time-Locked Event/', '', 'ignorecase');
                    this_hed_string{j} = regexprep(this_hed_string{j}, 'Time-Locked Event', '', 'ignorecase');
                end
                   
                if ~hasDoublequote(i)
                    allTags(counter:(counter+length(this_hed_string) -1)) = this_hed_string;
                    allTagId(counter:(counter + length(this_hed_string) - 1)) = i;
                    
                    %If our node sequence from hedManager matched up
                    if rc
                        msg = 'hed_tag_count: this_seq did not match up with the hed string provided';
                        assert(length(this_seq)==length(this_hed_string), msg);
                        allreqChild(counter:(counter + length(this_hed_string) - 1)) = this_req_child;
                        allNodeSeq(counter:(counter + length(this_hed_string) - 1)) = this_seq;
                    end;
                    
                    counter = counter  + length(this_hed_string);
                end;
            end;
            
            if counter < (length(allTags)+1)
                allTags(counter:end) = [];
                allTagId(counter:end) = [];
            end
            
            % remove numbers, for some reason some tags are just numbers
            isaNumber =  ~isnan(str2double(allTags));
            allTags(isaNumber) = [];
            allTagId(isaNumber) = [];
            
            
            %% unroll the tags so the hierarchy is turned into multiple nodes. For example /Stimulus/Visual/Red becomes three tags: /Stimulus/, Stimulus/Visual and /Stimulus/Visual/Red. This lets us count the higher hierarchy levels.
            
            combinedTag = cell(length(allTags) * 5, 1);
            combinedId = zeros(length(allTags) * 5, 1);
            counter = 1;
                   
            for i = 1:length(allTags)             
                this_nodeSequence = regexp(allTags{i}, '[/]', 'split');
                
                if rc
                    this_reqChild = allreqChild{i};
                end
                
                % remove / from start and end
                this_nodeSequence(cellfun(@isempty, this_nodeSequence)) = [];
                
                newTags = {};
                j=0;
                k=1;
                while j < length(this_nodeSequence)
                    j=j+1;
                    
                    if rc
                        %Check if node requires child
                        if this_reqChild(j)==1
                            %Check if child is a number, if soo, keep as part
                            %of this tag.
                            if strcmp(this_nodeSequence(j+1),'#')
                                j=j+1;
                            end
                            continue;
                        end
                    end
                    
                    newTags{k} = strjoin(this_nodeSequence(1:j),'/');
                    k=k+1;
                end;
                
                combinedTag(counter:(counter + length(newTags) - 1)) = newTags;
                
                newTagsId = ones(length(newTags),1) * i;
                %combinedId = cat(1, combinedId, newTagsId);
                combinedId(counter:(counter + length(newTags) - 1)) = newTagsId;
                
                counter = counter + length(newTags);
            end;
            
            if counter < (length(combinedTag)+1)
                combinedTag(counter:end) = [];
                combinedId(counter:end) = [];
            end
            
            %% find unique tags and count them. Use sorting to speed this up.
            
            [sortedCombinedTag ord]= sort(combinedTag);
            sortedCombinedId = combinedId(ord);
            
            [uniqueTag firstIndexUnique]= unique(sortedCombinedTag, 'first');
            [uniqueTag lastIndexUnique]= unique(sortedCombinedTag, 'last');
            
            uniqueTagCount = lastIndexUnique-firstIndexUnique+1;
            
            uniqueTagId = cell(length(lastIndexUnique),1);
            originalHedStringId = cell(length(lastIndexUnique),1);
            for i=1:length(lastIndexUnique)

                
                uniqueTagId{i} = unique(sortedCombinedId(firstIndexUnique(i):lastIndexUnique(i))); % these are IDs of allTags.
                originalHedStringId{i} = allTagId(uniqueTagId{i}); % these are IDs of input HED string.
            end;
 
        end;
    end;  
end


