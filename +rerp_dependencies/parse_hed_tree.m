%Return hed tags and original hed string ids for tree, excluding
%intermediate nodes which have only one child. Used in
%heirarchical regression. Excludes "exclude_tags" and
%"separator_tags", forming context groups based on separator_tags.
function parse_hed_tree(cp, s)
import rerp_dependencies.*

hed_tree=cp.hed_tree;

tags = hed_tree.uniqueTag;
ids = hed_tree.originalHedStringId;

%Remove exclude_tags
k=1;
remove=[];
extended_sep_tags=[s.separator_tag; cellfun(@(x) [x '/|'], s.separator_tag, 'uniformoutput', false); s.separator_tag_children];
rem_tags=[s.exclude_tag(:); s.exclude_continuous_tag(:); extended_sep_tags(:)];

[tags, idx]=setdiff(tags, rem_tags);
ids = ids(idx);

%Form context groups
if isempty(cp.context_group) && ~isempty(s.separator_tag)
    [cp.context_group, tags, ids] = makeContextGroup(cp, tags, ids, s);
end

if ~isempty(s.separator_tag)
    disp('parse_hed_tree: refreshing context groups');
    [tags, ids] = refreshContextGroup(cp, tags, ids);
end

%Figure out which included tags were affected by each context group
context_affected_tags = RerpTagList.strip_label(RerpTagList.strip_brackets(RerpTagList.get_affected(tags)));
for i=1:length(cp.context_group) 
    included_affected = intersect(cp.context_group(i).affected_tags, context_affected_tags(:));
    cp.context_group(i).included_affected = included_affected;
end

%Remove categorical redundant tags
[tags, ids, marked_tags, marked_ids] = remove_redundant_tags(tags, ids, {}, {},s);

cp.include_tag = {tags{:} marked_tags{:}};
cp.include_ids = {ids{:} marked_ids{:}};

disp('parse_hed_tree: done');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Utility functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Recursively remove any redundant tags in hierarchy
function [short_tags, short_ids, marked_tags, marked_ids] = remove_redundant_tags(tag_list, id_list, marked_tags, marked_ids,s) % XXX BEHINGER added 's' because apparently it is needed in line 77
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
                if ~any(strcmp(strjoin(node_seq(1:(end)),'/'), s.continuous_tag)) % BEHINGER XXX I had to remove the end-1 when i only had continuous regressors
                    marked_tags{end+1} = ['*   ' tag_list{i} '   *'];
                    marked_ids(end+1) = id_list(i);
                    
                    ridx = zeros(size(id_list));
                    ridx(i) = 1;
                    
                    %Remove one duplicate tag
                    id_list = id_list(~ridx);
                    tag_list = tag_list(~ridx);
                    
                    %Go one level deeper in recursion
                    [short_tags, short_ids, marked_tags, marked_ids] = remove_redundant_tags(tag_list, id_list, marked_tags, marked_ids,s); 
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
function [context_group, tags, ids] = makeContextGroup(cp, tags, ids, s)
import rerp_dependencies.*
hed_tree=cp.hed_tree;

separator_tag=s.separator_tag;
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
    [~, children_idx] = intersect(hed_tree.uniqueTag, s.separator_tag_children);
    %Determine which tags are children of separator_tag and mark them as { }
    for j=1:length(s.separator_tag_children)
        this_tag = s.separator_tag_children{j};
        this_node_seq = regexp(this_tag, '[/]', 'split');
        
        %Child of the separator tag will have a longer node sequence
        if length(this_node_seq) > length(node_seq)
            
            %Check if this tag is a child of the separator tag, store as context group
            if ~nnz(~strcmpi(this_node_seq(1:length(node_seq)), node_seq))
                
                %Get the unique ids for events which are hit with an
                %included tag and this separator tag
                this_original_id = hed_tree.originalHedStringId{children_idx(j)};
                [~, include_idx] = intersect(hed_tree.uniqueTag, this_tag);
                included_original_id=hed_tree.originalHedStringId{include_idx};
                
                these_children(m).tag = this_tag;
                these_children(m).ids  = included_original_id;
                these_children(m).hed_tree = hedTree(hed_tree.originalHedStrings(these_children(m).ids));
                
                remove(k) = j;
                k=k+1;
                m=m+1;
            end
        end
    end
    
    % Determine which tags to replicate in the context groups (co-occurring
    % tags)
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

end

function [tags, ids] = refreshContextGroup(cp, tags, ids)
import rerp_dependencies.*
% Mark the tags which are affected by context groups. This will show any
% intersections of context groups by marking along with the
% separator tags.
sub_tags=tags;
if ~isempty(tags)
    for i=1:length(cp.context_group)
        this_group = cp.context_group(i);
        
        if ~isempty(this_group) && ~isempty(intersect(this_group.name, cp.include_separator_tag))
            [stripped_hit_tags, this_idx, ~] = intersect(RerpTagList.strip_affected_brackets(sub_tags), this_group.affected_tags);
            hit_tags = sub_tags(this_idx);
            
            %Find the affected ids which are included for each child
            for j=1:length(this_group.children)
                this_child = this_group.children(j);
                [cp.context_group(i).children(j).included_tag, incld_idx] = intersect(this_child.hed_tree.uniqueTag, stripped_hit_tags);
                
                % Find the original hed string ids associated with the tags which
                % fall under this child (separated according to tag)
                for k=1:length(cp.context_group(i).children(j).included_tag)
                    included_tag_id = this_child.hed_tree.originalHedStringId{incld_idx(k)};
                    cp.context_group(i).children(j).included_ids{k} = sort(this_child.ids(included_tag_id));
                end
            end
            
            %Some of the included tags were affected, mark them
            if ~isempty(hit_tags)
                for j=1:length(hit_tags)
                    hit_tags(j) = { ['{{    ' hit_tags{j} '    (' this_group.name ')    }}']};
                end
                
                %We work in the sub_tags index space, but then have to index back into tags
                tags(this_idx) = hit_tags;
                sub_tags(this_idx) = hit_tags;
            end
        end
    end
end
end
