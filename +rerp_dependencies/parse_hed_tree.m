%Return hed tags and original hed string ids for tree, excluding
%intermediate nodes which have only one child. Used in
%heirarchical regression. Excludes "exclude_tags" and
%"separator_tags", forming context groups based on separator_tags.
function [tags, ids, context_group] = parse_hed_tree(hed_tree, s)
import rerp_dependencies.*

tags = hed_tree.uniqueTag;
ids = hed_tree.originalHedStringId;

disp('parse_hed_tree: removing exclude/separator tags');
%Remove exclude_tags
k=1;
remove=[]; 
for i = 1:length(tags)
    this_tag = tags{i};  
            
    for j=1:length(s.exclude_tag)
        if strcmpi(this_tag, s.exclude_tag{j})
            remove(k) = i;
            k=k+1;
        end
    end
    
    for j=1:length(s.exclude_continuous_tag)
        if strcmpi(this_tag, s.exclude_continuous_tag{j})
            remove(k) = i;
            k=k+1;
        end
    end
    
    for j=1:length(s.separator_tag)
        if strcmpi(this_tag, s.separator_tag{j})
            remove(k) = i;
            k=k+1;
        end
    end
end

%Remove excluded, continuous and separator tags from the list
idx = setdiff(1:length(ids), unique(remove));
ids = ids(idx);
tags = tags(idx);

%Form context groups
[context_group, tags, ids] = makeContextGroup(hed_tree, tags, ids, s);

%Remove categorical redundant tags
disp('parse_hed_tree: removing redundant tags');
[tags, ids, marked_tags, marked_ids] = remove_redundant_tags(tags, ids, {}, {});
 
tags = {tags{:} marked_tags{:}};
ids = {ids{:} marked_ids{:}};
disp('parse_hed_tree: done');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Utility functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Recursively remove any redundant tags in hierarchy
function [short_tags, short_ids, marked_tags, marked_ids] = remove_redundant_tags(tag_list, id_list, marked_tags, marked_ids)
import rerp_dependencies.*

len_ids=length(id_list);

short_tags = tag_list;
short_ids = id_list;

for i=1:len_ids
    this_id = id_list(i);
    
    for j = (i+1):len_ids
        %Tags with identical ids are duplicate
        if isequal(id_list{j}, this_id{:})

            node_seq = regexp(RerpTagList.strip_brackets(tag_list(i)), '[/]', 'split');
            
            if ~isempty(node_seq)
                node_seq=node_seq{1}; 
                
                %Don't remove continuous tags with same latencies: magnitude
                %can be different even if latency is the same
                if ~any(strcmp(strjoin(node_seq(1:(end-1)),'/'), s.continuous_tag))
                    marked_tags{end+1} = ['*   ' tag_list{i} '   *'];
                    marked_ids(end+1) = id_list(i);
                    
                    ridx = zeros(size(id_list));
                    ridx(i) = 1;
                    
                    %Remove one duplicate tag
                    id_list = id_list(~ridx);
                    tag_list = tag_list(~ridx);
                    
                    %Go one level deeper in recursion
                    [short_tags, short_ids, marked_tags, marked_ids] = remove_redundant_tags(tag_list, id_list, marked_tags, marked_ids);
                    return;
                end
            end
        end
    end
end
end

%Create context groups structure: all variables which are concurrently
%tagged with separator tags will be collected into separate hierarchy
%and saved as a hedTree in the context_group struct.
function [context_group, tags, ids] = makeContextGroup(hed_tree, tags, ids, s)
import rerp_dependencies.*

separator_tag=setdiff(s.separator_tag, s.exclude_separator_tag);
context_group=struct([]) ;

remove=[];
k=1;
rem_tags = {};
for i=1:length(separator_tag)
    fprintf('parse_hed_tree: creating context group %d/%d\n', i, length(separator_tag));
    this_separator_tag = separator_tag{i};
    node_seq = regexp(this_separator_tag, '[/]', 'split');
    
    these_children = [];
    m=1;
    %Determine which tags are children of separator_tag and mark them as { }
    for j=1:length(tags)
        this_tag = tags{j};
        this_node_seq = regexp(this_tag, '[/]', 'split');
        
        %Child of the separator tag will have a longer node sequence
        if length(this_node_seq) > length(node_seq)
            
            %Check if this tag is a child of the separator tag, store as context group
            if ~nnz(~strcmpi(this_node_seq(1:length(node_seq)), node_seq))
                tags{j} = ['{   ' this_tag '   }'];
                
                this_original_id = ids{j};
                these_children(m).tag = this_tag;
                these_children(m).ids = this_original_id;
                these_children(m).hed_tree = hedTree(hed_tree.originalHedStrings(these_children(m).ids));

                remove(k) = j;
                k=k+1;
                m=m+1;
            end
        end
    end
    
    % Determine which tags to replicate in the context groups (co-occurring
    % tags) and mark them as {{ }}
    if ~isempty(these_children)
        hedtag_set={};
        
        for n = 1:length(these_children)
            hedtag_set = union(hedtag_set, these_children(n).hed_tree.uniqueTag);
        end
        
        context_group(i).affected_tags=sort(hedtag_set);
        context_group(i).children=these_children;
        context_group(i).name=this_separator_tag;
    end
end

% Mark the tags which are affected by context groups. This will show any
% intersections of context groups by marking along with the
% separator tags.
[~, rem_idx,~] = intersect(tags, rem_tags);
sub_tags_idx = setdiff(1:length(tags), rem_idx);
sub_tags = tags(sub_tags_idx);

for i=1:length(context_group)
    this_group = context_group(i);
    
    if ~isempty(this_group)
        [stripped_hit_tags, this_idx, ~] = intersect(RerpTagList.strip_affected_brackets(sub_tags), this_group.affected_tags);
        hit_tags = sub_tags(this_idx);

        %Find the affected ids which are included for each child
        for j=1:length(this_group.children)
            this_child = this_group.children(j);
            [context_group(i).children(j).included_tag, incld_idx] = intersect(this_child.hed_tree.uniqueTag, stripped_hit_tags);
            
            % Find the original hed string ids associated with the tags which
            % fall under this child (separated according to tag)
            for k=1:length(context_group(i).children(j).included_tag)
                included_tag_id = this_child.hed_tree.originalHedStringId{incld_idx(k)};
                context_group(i).children(j).included_ids{k} = sort(this_child.ids(included_tag_id));
            end
        end
        
        %Some of the included tags were affected, mark them
        if ~isempty(hit_tags)
            for j=1:length(hit_tags)
                hit_tags(j) = { ['{{    ' hit_tags{j} '    (' this_group.name ')    }}']};
            end
            
            %We work in the sub_tags index space, but then have to index back into tags
            tags(sub_tags_idx(this_idx)) = hit_tags;
            sub_tags(this_idx) = hit_tags;
        end
    end
end

end
