function [ continuous_var, tags, ids ] = make_continuous_var( tags, ids )
import rerp_dependencies.*
continuous_var={};

k=1;
n=1;
i=1;
remove=[];

%Go through all tags
while 1
    this_tag = tags{i};
    node_seq = regexp(this_tag, '[/]', 'split');
    
    %Check if this node is a number
    if ~isempty(node_seq)
        if strcmp(node_seq{end}, '#')
            continuous_var{n}.name = strjoin(node_seq(1:(end-1)),'/');
            continuous_var{n}.val=[];
            continuous_var{n}.ids={};
            
            %Remove the # node
            remove(k)=i;
            k=k+1;
            
            %Begin an inner loop at i+1, parsing the values of the current
            %continuous tag (they will be in order). Afterwards, move the
            %outer index i to the end of the continuous tags we just
            %parsed.
            m=1;
            val=[];
            j=i+1;
            while 1
                this_contin_tag = tags{j};
                this_node_seq = regexp(this_contin_tag, '[/]', 'split');
                if length(this_node_seq) > length(node_seq) && strcmp(strjoin(this_node_seq(1:(end-1)),'/'), node_seq)
                    this_original_id = ids{j};
                    
                    val = str2double(this_node_seq{end});
                    val = repmat(val, 1,length(this_original_id));
                    continuous_var{n}.val(m) = val;
                    continuous_var{n}.ids(m) = this_original_id;
                    
                    m=m+1;
                    
                    %Remove all continuous tags from list regardless of
                    %whether the parent is included or not
                    remove(k)=j;
                    k=k+1;
                    
                    if j < length(tags)
                        j=j+1;
                    else
                        i=j;
                        break;
                    end
                    
                else
                    break;
                end   
            end
            
            %Reached the last continuous tag in this series: jump the outer index i to the current position                    
            i=j;
        end
        
        n=n+1;
    end
    
    %Exit when we reach the end of the list
    if i < length(tags)
        i=i+1;
    else
        break;
    end
end

%Remove the designated tags from the list
tags=tags(setdiff(1:length(tags), remove));
ids = ids(setdiff(1:length(tags), remove));

% for i=1:length(continuous_tags)
%     fprintf('parse_hed_tree: creating continuous variable %d/%d\n', i, length(continuous_tags));
%
%     this_continuous_tag = continuous_tags{i};
%     node_seq = regexp(this_continuous_tag, '[/]', 'split');
%
%     if ~isempty(node_seq) && isempty(node_seq{1})
%         node_seq(1)=[];
%     end
%
%     this_continuous_var=[];
%     for j=1:length(tags)
%         this_unique_tag = tags{j};
%         this_node_seq = regexp(this_unique_tag, '[/]', 'split');
%
%         %Child of the continuous tag will have a longer node sequence
%         if length(this_node_seq) > length(node_seq)
%
%             %Check if this tag is a child of the continuous tag, store as
%             %continuous var
%             if ~nnz(~strcmpi(this_node_seq(1:length(node_seq)), node_seq))
%                 tags{j} = ['[   ' this_unique_tag '   ]'];
%                 this_original_id = ids{j};
%                 
%             %Parse the last node as a continuous variable
%                 val = str2double(this_node_seq(end));
%                 val = repmat(val, 1,length(this_original_id));
%
%                 this_continuous_var(k).val = val;
%                 this_continuous_var(k).ids = this_original_id;
%                 k=k+1;
%                 remove(k)=j;
%             end
%         end
%     end
%
%     if ~isempty(this_continuous_var)
%         continuous_var{i}.val = [this_continuous_var(:).val];
%         continuous_var{i}.ids = cell2mat({this_continuous_var(:).ids}')';
%         continuous_var{i}.name = this_continuous_tag;
%     else
%         continuous_var{i}.val = [];
%         continuous_var{i}.ids = [];
%         continuous_var{i}.name = this_continuous_tag;
%     end
% end
end


