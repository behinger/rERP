function [ continuous_var, new_all_tags, continuous_tags ] = make_continuous_var( events )

n=1;
trimmed = strtrim(events.hedTag);
separated =  strtrim(regexp(trimmed, '[;,]', 'split'));
continuous_idx = cellfun(@(x) regexp(x, '[#]', 'match'), separated, 'uniformoutput',0); 

%Go through all tags, identify continuous tags
all_continuous_tags={}; 
for i=1:length(separated)
    this_hed_string = separated{i};
    idx = cellfun(@(x) isempty(x), continuous_idx{i});
    
    this_cont_idx = find(~idx);   
    
    for j=1:length(this_cont_idx)
        this_tag = this_hed_string{this_cont_idx(j)};
        node_seq = regexp(this_tag, '[/]', 'split'); 
        this_cont_tag =strjoin(node_seq(1:(end-2)),'/');
        
        this_hed_string{this_cont_idx(j)} = this_cont_tag;        
        all_continuous_tags{n} = this_cont_tag;
        all_latency(n)=events.latencyInFrame(i);
        all_val(n) = str2double(node_seq{end});  
        all_id(n) = i;
        n=n+1;
    end
    
    new_all_tags{i} = strjoin(this_hed_string,';');
end

[continuous_tags, ~, idx] = unique(all_continuous_tags);
continuous_var=cell(1,length(continuous_tags));

for i=1:length(continuous_tags)
    this_idx=find(idx==i);
    continuous_var{n}.name = continuous_tags{i};
    continuous_var{n}.val = all_val(this_idx);
    continuous_var{n}.ids = all_id(this_idx);
end