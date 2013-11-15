% Copyright (C) 2013 Matthew Burns, Swartz Center for Computational
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

classdef RerpTagList
%RerpTagList - static functions for parsing hed tag lists in RerpProfile objects created by pop_rerp(). 

    properties (Constant=true)
        %Regular expression string for all tags with brackets 
        regexp_str_all = '^\s*[\[{]+\s*(.*)\s+[\]}]+\s*$';
        
        %Regular expression string for context affected tags with brackets 
        regexp_str_affected = '^\s*[\[{]+\s+(.*)\s+(?:\(.*\))\s+[\]}]+\s*$';
        
        %Regular expression for brackets removed, but not the label
        regexp_str_label = '^(.*)\s+(?:\(.*\))\s*$';
    end
    
    %TAGLIST Collection of static functions for handling list of tags from
    %pop_rerp GUI (brackets mark specific types of variables). 
    methods(Static=true)
        %Strips away layers of brackets recursively
        function tag_list = strip_brackets(tag_list)
            import rerp_dependencies.*
            
            segmented = regexp(tag_list, RerpTagList.regexp_str_all, 'tokens');
            go_deeper=0;
            for i=1:length(segmented)

                this_seg = segmented{i};

                if ~isempty(this_seg)
                    tag_list(i)=this_seg{:};
                    go_deeper=1;
                end
            end
            
            tag_list = RerpTagList.strip_label(tag_list);

            if go_deeper
                tag_list = RerpTagList.strip_brackets(strtrim(tag_list));
            end
        end
        
        %Strips away labels
        function tag_list = strip_label(tag_list)
            import rerp_dependencies.*
            
            segmented = regexp(tag_list, RerpTagList.regexp_str_label, 'tokens');
            go_deeper=0;
            for i=1:length(segmented)

                this_seg = segmented{i};

                if ~isempty(this_seg)
                    tag_list(i)=this_seg{:};
                    go_deeper=1;
                end
            end

            if go_deeper
                tag_list = RerpTagList.strip_brackets(strtrim(tag_list));
            end
        end
        
        %Strips away layers of brackets recursively
        function tag_list = strip_affected_brackets(tag_list)
            import rerp_dependencies.*
            
            segmented = regexp(tag_list, RerpTagList.regexp_str_affected, 'tokens');
            go_deeper=0;
            for i=1:length(segmented)

                this_seg = segmented{i};

                if ~isempty(this_seg)
                    tag_list(i)=this_seg{:};
                    go_deeper=1;
                end
            end

            if go_deeper
                tag_list = RerpTagList.strip_brackets(strtrim(tag_list));
            end
        end
        
         % Return a sublist of tags which are not subtags
        function tag_list = strip_subtags(tag_list)
            import rerp_dependencies.*
                        
            segmented = regexp(tag_list, RerpTagList.regexp_str_all, 'tokens');
            idx = [];
            for i=1:length(segmented)

                this_seg = segmented{i};

                if isempty(this_seg)
                    idx(end+1)=i;
                end
            end

            tag_list=strtrim(tag_list(idx));
        end  
        
        % Return a sublist of tags which are affected by context groups
        function tag_list = get_affected(tag_list)
            import rerp_dependencies.*
            
            segmented = regexp(tag_list, RerpTagList.regexp_str_affected, 'tokens');
            idx = [];
            for i=1:length(segmented)

                this_seg = segmented{i};

                if ~isempty(this_seg)
                    idx(end+1)=i;
                end
            end

            tag_list=strtrim(tag_list(idx));
        end           
            
        %Count the number of parameters based on the list provided by
        %pop_rerp GUI (with brackets and labelling. 
        function [ncontinvars, ncatvars, ncontextvars, ncontextchldrn] = cntVarsParams(rerp_profile)
            import rerp_dependencies.*
            
            tags = rerp_profile.include_tag;
            ncontinvars =length(rerp_profile.continuous_var);
            ncatvars = length(RerpTagList.strip_subtags(tags));
            
            % Compute number of variables and number of children introduced by context groups
            ncontextvars = 0; 
            ncontextchldrn = 0; 
            context_affected_tags = RerpTagList.strip_brackets(RerpTagList.get_affected(tags));
            context_group = rerp_profile.context_group;
            for i=1:length(context_group)
                this_group = context_group{i};
                included_affected = intersect(this_group.affected_tags, context_affected_tags);
                rerp_profile.context_group{i}.included_affected = included_affected;

                nchld = length(this_group.children);
                ncontextchldrn = ncontextchldrn + nchld;
                thisnum = length(included_affected)*nchld;
                ncontextvars = ncontextvars + thisnum;
            end
        end
        
    end
end

