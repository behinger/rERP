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

function [predictor, data_pad, indexes] = predictor_gen( rerp_profile )
%PREDICTOR_GEN generate a sparse matrix predictor for ERP regression

import rerp_dependencies.*

p = rerp_profile;
s = p.settings;

cat_t0 = p.sample_rate*s.category_epoch_boundaries(1);
con_t0 = p.sample_rate*s.continuous_epoch_boundaries(1);

%Calculate start and length of epoch (two types of variables, continuous and categorical)
category_epoch_length = s.category_epoch_boundaries(2) - s.category_epoch_boundaries(1);
continuous_epoch_length = s.continuous_epoch_boundaries(2) - s.continuous_epoch_boundaries(1);

%Number of samples per epoch
category_ns = ceil(continuous_epoch_length*p.sample_rate);
continuous_ns = ceil(category_epoch_length*p.sample_rate);
            
indexes = cell(0,0);

if s.hed_enable
    [ncontinvars, ncatvars, ncontextvars] = RerpTagList.cntVarsParams(p);
    parameter_cnt = ncontinvars*continuous_ns + (ncatvars + ncontextvars)*category_ns;
    predictor_pad = max(continuous_ns, category_ns);
    predictor_shift = min(min(cat_t0, con_t0), 0);
    
    [ii, jj, value] = deal(cell(1, ncontinvars + ncatvars + ncontextvars));
    cell_idx = 1;
    
    cat_tags = RerpTagList.strip_subtags(p.include_tag);
    [~, idx] = intersect(p.hed_tree.uniqueTag, cat_tags);
    cat_ids = p.hed_tree.originalHedStringId(idx);
    
    contin_var = p.continuous_var;
    context_grp = p.context_group;
     
    
    %Enter categorical variables
    for j=1:length(cat_ids)
        this_cat_id =  cat_ids{j};
        j_start_idx = (cell_idx-1)*category_ns + 1;
        j_end_idx = j_start_idx + category_ns - 1;
        m=0;
        
        j_vec=repmat(j_start_idx:j_end_idx,1,length(this_cat_id));
        i_vec=zeros(1,length(this_cat_id)*category_ns);
        indexes{end+1}=j_start_idx:j_end_idx;
        value_vec = ones(1, length(i_vec));
        
        for i=1:length(this_cat_id)
            %The id represents the latency of the event that generated the
            %tag
            this_latency = p.these_events.latencyInFrame(this_cat_id(i));
            i_start_idx = m*category_ns+1;
            i_end_idx = i_start_idx + category_ns -1;
            
            i_vec(i_start_idx:i_end_idx) = (this_latency):(this_latency+category_ns-1);   
            m=m+1;
        end
        
        ii{cell_idx}= i_vec+cat_t0;
        jj{cell_idx}= j_vec;
        value{cell_idx}= value_vec;
        cell_idx = cell_idx +1;
    end
    
    %Enter continuous variables
    for j=1:length(contin_var)
        this_contin_id =  contin_var{j}.ids;
        this_contin_val = contin_var{j}.val;
        
        j_start_idx = (cell_idx-1)*continuous_ns + 1;
        j_end_idx = j_start_idx + continuous_ns - 1;
        m=0;
        
        j_vec=repmat(j_start_idx:j_end_idx,1,length(this_contin_id));
        i_vec=zeros(1,length(this_contin_id)*continuous_ns);
        indexes{end+1}=j_start_idx:j_end_idx;
        value_vec = zeros(1, length(i_vec));
        
        for i=1:length(this_contin_id)
            %The id represents the latency of the event that generated the
            %tag
            this_latency = p.these_events.latencyInFrame(this_contin_id(i));
            i_start_idx = m*continuous_ns+1;
            i_end_idx = i_start_idx + continuous_ns -1;
            
            i_vec(i_start_idx:i_end_idx) = (this_latency):(this_latency+continuous_ns-1);
            value_vec(i_start_idx:i_end_idx) = ones(1, continuous_ns)*this_contin_val(i);
            m=m+1;
        end
        
        ii{cell_idx} = i_vec+con_t0;
        jj{cell_idx} = j_vec;
        value{cell_idx} = value_vec;
        cell_idx = cell_idx +1;
    end
    
    %Enter context group variables
    for j=1:length(context_grp)
        this_group =  context_grp{j};
        for k=1:length(this_group.children)
            this_child = this_group.children(k);
            for x=1:length(this_child.included_ids)
                this_included_id = this_child.included_ids{x};
                
                j_start_idx = (cell_idx-1)*category_ns + 1;
                j_end_idx = j_start_idx + category_ns - 1;

                j_vec=repmat(j_start_idx:j_end_idx,1,length(this_included_id));
                i_vec=zeros(1,length(this_included_id)*category_ns);
                indexes{end+1}=j_start_idx:j_end_idx;
                value_vec = ones(1, length(i_vec));
                m=0;
                
                for i=1:length(this_included_id)
                    %The id represents the latency of the event that generated the
                    %tag
                    this_latency = p.these_events.latencyInFrame(this_included_id(i));
                    i_start_idx = m*category_ns+1;
                    i_end_idx = i_start_idx + category_ns -1;

                    i_vec(i_start_idx:i_end_idx) = (this_latency):(this_latency+category_ns-1);
                    m=m+1;
                end
            
                ii{cell_idx} = i_vec+cat_t0;
                jj{cell_idx} = j_vec;
                value{cell_idx} = value_vec;
                cell_idx = cell_idx +1;
            end
        end
    end
    
else
    
    % Predictor formed on event types
    ns = category_ns;
    numvars = length(p.include_event_types);
    [~, include_idx] = intersect(p.event_types, p.include_event_types);
    num_event_types = p.num_event_types(sort(include_idx)); 
    parameter_cnt = ns*numvars;
    
    predictor_shift = min(cat_t0, 0); 
    predictor_pad = ns;
    
    [ii, jj, value] = deal(cell(1,numvars));
    for j=1:numvars
        
        j_start_idx = (j-1)*ns + 1;
        j_end_idx = j_start_idx + ns - 1;
        m=0;
        
        this_type = p.include_event_types(j);
        j_vec=repmat(j_start_idx:j_end_idx, 1, num_event_types(j));
        i_vec=zeros(1,num_event_types(j)*ns);
        indexes{end+1}=j_start_idx:j_end_idx;
        value_vec = ones(1, num_event_types(j)*ns);
        
        for i=1:length(p.these_events.label)
            this_event = p.these_events.label(i);
            if strcmp(this_event, this_type)
                i_start_idx = m*ns+1;
                i_end_idx = i_start_idx + ns -1;
                this_latency = p.these_events.latencyInFrame(i);
                i_vec(i_start_idx:i_end_idx) = (this_latency):(this_latency+ns-1);
                m=m+1;
            end
        end
        
        ii{j}= i_vec+cat_t0;
        jj{j}= j_vec;
        value{j}=value_vec;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate predictor matrix from lists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

m=cell2mat(ii);
n=cell2mat(jj);
v=cell2mat(value);

%Shift the matrix
m = m-predictor_shift; 

%Return the bounds of the data
data_pad(1) = -predictor_shift;
data_pad(2) = predictor_pad;

try
    predictor=sparse(m, n, v, p.pnts + predictor_pad-predictor_shift, parameter_cnt);
    
catch  e
    fprintf('Max m index = %d, max n index = %d\n',max(m), max(n));
    fprintf('Dimension = %d x %d\n', p.pnts+predictor_pad, parameter_cnt);
    rethrow(e)
end

end
