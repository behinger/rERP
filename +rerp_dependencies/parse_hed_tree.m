%Return hed tags and original hed string ids for tree, excluding
%intermediate nodes which have only one child. Used in
%heirarchical regression. Excludes "exclude_tags" and
%"seperator_tags", forming context groups based on seperator_tags.
function [tags, ids, context_group, continuous_var] = parse_hed_tree(hed_tree, exclude_tags, seperator_tags, continuous_tags)
import rerp_dependencies.*

tags = hed_tree.uniqueTag;
ids = hed_tree.originalHedStringId;
disp('parse_hed_tree: removing exclude/seperator/continuous tags'); 

%Remove exclude_tags, seperator_tags and continuous_tags
k=1;
remove=[];
for i = 1:length(tags)
    this_tag = tags{i};
    
    for j=1:length(exclude_tags)
        if strcmpi(this_tag, exclude_tags{j})
            remove(k) = i;
            k=k+1;
        end
    end
    
    for j=1:length(seperator_tags)
        if strcmpi(this_tag, seperator_tags{j})
            remove(k) = i;
            k=k+1;
        end
    end
    
    for j=1:length(continuous_tags)
        if strcmpi(this_tag, continuous_tags{j})
            remove(k) = i;
            k=k+1;
        end
    end
end

%Remove excluded, continuous and seperator tags from the list
idx = setdiff(1:length(ids), remove);
ids = ids(idx);
tags = tags(idx);

%Extract continuous variables
[continuous_var, tags, ids] = makeContinuousVar(tags, ids, continuous_tags);

%Form context groups
[context_group, tags, ids] = makeContextGroup(hed_tree, tags, ids, seperator_tags);

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
        if isequal(id_list(j),this_id)
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

%Create context groups structure: all variables which are concurrently
%tagged with seperator_tags will be collected into seperate hierarchy
%and saved as a hedTree in the context_group struct.
function [context_group, tags, ids, marked_tags, marked_ids] = makeContextGroup(hed_tree, tags, ids, seperator_tag)
import rerp_dependencies.*

context_group=cell(size(seperator_tag));
remove=[];
k=1;
rem_tags = {}; 
for i=1:length(seperator_tag)
    fprintf('parse_hed_tree: creating context group %d/%d\n', i,length(seperator_tag)); 
    this_seperator_tag = seperator_tag{i};
    node_seq = regexp(this_seperator_tag, '[/]', 'split');
    
    these_children = struct;
    m=1;
    %Determine which tags are children of seperator_tag and mark them as { }
    for j=1:length(tags)
        this_unique_tag = tags{j};
        this_node_seq = regexp(this_unique_tag, '[/]', 'split');
        
        %Child of the seperator tag will have a longer node sequence
        if length(this_node_seq) > length(node_seq)
            
            %Check if this tag is a child of the seperator tag, store as context group
            if ~nnz(~strcmpi(this_node_seq(1:length(node_seq)), node_seq))
                tags{j} = ['{   ' this_unique_tag '   }'];
                
                this_original_id = ids{j};
                these_children(m).tag = this_unique_tag;
                these_children(m).ids = this_original_id;   
                these_children(m).hed_tree = hedTree(hed_tree.originalHedStrings(these_children(m).ids));

                remove(k) = j;
                k=k+1;
                m=m+1;
            end
        end
    end
    
    %We don't want the context groups to affect each other's children
    %(keeps them seperated). 
    rem_tags = {rem_tags{:} tags{remove}}; 
    
    % Determine which tags to replicate in the context groups (co-occurring
    % tags) and mark them as {{ }}
    if ~isempty(these_children)
        hedtag_set={};

        for n = 1:length(these_children)
           hedtag_set = {hedtag_set{:} these_children(n).hed_tree.uniqueTag{:}};  
        end 
        
        sub_hed_tree = hedTree(hedtag_set); 
        context_group{i}.affected_tags=sub_hed_tree.uniqueTag;
        context_group{i}.children=these_children;
        context_group{i}.name=this_seperator_tag;     
    end
end

% Mark the tags which are affected by context groups. This will show any
% intersections of context groups by marking along with the
% seperator tags.
[~, rem_idx,~] = intersect(tags, rem_tags); 
sub_tags_idx = setdiff(1:length(tags), rem_idx);
sub_tags = tags(sub_tags_idx); 

for i=1:length(context_group)
    this_group = context_group{i}; 
    [stripped_hit_tags, this_idx, ~] = intersect(RerpTagList.strip_affected_brackets(sub_tags), this_group.affected_tags);
    hit_tags = sub_tags(this_idx); 
    
    %Find the affected ids which are included for each child
    for j=1:length(this_group.children)
        this_child = this_group.children(j);
        [context_group{i}.children(j).included_tag, incld_idx] = intersect(this_child.hed_tree.uniqueTag, stripped_hit_tags);
        
        % Find the original hed string ids associated with the tags which
        % fall under this child (seperated according to tag)
        for k=1:length(context_group{i}.children(j).included_tag)
            included_tag_id = this_child.hed_tree.originalHedStringId{incld_idx(k)};
            context_group{i}.children(j).included_ids{k} = sort(this_child.ids(included_tag_id)); 
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

function [continuous_var, tags, ids] = makeContinuousVar(tags, ids, continuous_tags)
import rerp_dependencies.*
continuous_var=cell(size(continuous_tags));

k=1;
remove=[];
for i=1:length(continuous_tags)
    fprintf('parse_hed_tree: creating continuous variable %d/%d\n', i,length(continuous_tags)); 
    
    this_continuous_tag = continuous_tags{i};
    node_seq = regexp(this_continuous_tag, '[/]', 'split');
    
    if ~isempty(node_seq) && isempty(node_seq{1})
        node_seq(1)=[];
    end
    
    this_continuous_var=struct;
    for j=1:length(tags)
        this_unique_tag = tags{j};
        this_node_seq = regexp(this_unique_tag, '[/]', 'split');
        
        %Child of the continuous tag will have a longer node sequence
        if length(this_node_seq) > length(node_seq)
            
            %Check if this tag is a child of the seperator tag, store as context group
            if ~nnz(~strcmpi(this_node_seq(1:length(node_seq)), node_seq))
                tags{j} = ['[   ' this_unique_tag '   ]'];
                this_original_id = ids{j};
                %Parse the last node as a continuous variable
                val = str2double(this_node_seq(end));
                val = repmat(val, 1,length(this_original_id));
                
                this_continuous_var(k).val = val;
                this_continuous_var(k).ids = this_original_id;
                k=k+1;
                remove(k)=j;
            end
        end
    end
    
    if ~isempty(this_continuous_var)
        continuous_var{i}.val = [this_continuous_var(:).val];
        continuous_var{i}.ids = cell2mat({this_continuous_var(:).ids}')';
        continuous_var{i}.name = this_continuous_tag;
    else
        continuous_var{i}.val = [];
        continuous_var{i}.ids = [];
        continuous_var{i}.name = this_continuous_tag;
    end
end
end
