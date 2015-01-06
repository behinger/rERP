function [ continuous_var, new_all_tags, continuous_tags, separator_tags, separator_tag_children ] = make_continuous_var( events )
separated =  strtrim(regexp(events.hedTag, '[;,]', 'split'));

%Identify continuous tags by the # tag
continuous_idx = cellfun(@(x) regexp(x, '[#]', 'match'), separated, 'uniformoutput', 0); 

%Identify separator variables by the | tag
separator_idx = cellfun(@(x) regexp(x, '[|]', 'match'), separated, 'uniformoutput', 0); 

%Go through all tags, identify continuous, separator tags
all_continuous_tags={}; 
n=1;
m=1;
for i=1:length(separated)
    
    %Find index of specific tag within a hed string which is continuous
    this_hed_string = separated{i};
    cidx = cellfun(@(x) isempty(x), continuous_idx{i});
    sidx = cellfun(@(x) isempty(x), separator_idx{i});
    this_cont_idx = find(~cidx);   
    this_sep_idx = find(~sidx);
    
    %For each continous tag in the hed string, add to a continuous tag
    %structure
    for j=1:length(this_cont_idx)
        
        %Split the continuous tag
        this_tag = this_hed_string{this_cont_idx(j)};
        node_seq = regexp(this_tag, '[/]', 'split');         
        this_cont_tag = strjoin(node_seq(1:(end-2)),'/');
        
        %Reassign the continuous tag without value
        this_hed_string{this_cont_idx(j)} = this_cont_tag; 
        
        %Save all the continuous tags along with latencies and values
        all_continuous_tags{n} = this_cont_tag;
        all_latency(n)=events.latencyInFrame(i);
        all_val(n) = str2double(node_seq{end});  
        all_id(n) = i;
        n=n+1;
    end
        
    for j=1:length(this_sep_idx)

        %Split the sep tag
        this_tag = this_hed_string{this_sep_idx(j)};
        node_seq = regexp(this_tag, '[/]', 'split');         
        this_sep_tag = strjoin(node_seq(1:(end-2)),'/');

        %Save all the sep tags
        all_separator_tags{m} = this_sep_tag;
        all_separator_tag_children{m} = this_tag;
        m=m+1;
    end
    
    new_all_tags{i} = strjoin(this_hed_string,';');
end

 
%Assign the values to each continuous var
[continuous_tags, ~, idx] = unique(all_continuous_tags);
continuous_var=struct([]);
for i=1:length(continuous_tags)
    this_idx=find(idx==i);
    continuous_var(i).name = continuous_tags{i};
    continuous_var(i).val = all_val(this_idx);
    continuous_var(i).ids = all_id(this_idx);
end

%get the seperator tags
separator_tags = sort(unique(all_separator_tags))';
separator_tag_children=sort(unique(all_separator_tag_children))'; 