function final_result = rerp_parfor( EEG, rerp_profile, varargin)
%RERP_PARFOR Parallel process dataset; requires the artifact indexes to be precomputed. Function performs 
%time-frequency decomposition first if indicated in rerp_profile. 

p=inputParser;
addOptional(p,'disable_parfor', 0);
parse(p,varargin{:}); 
disable_parfor=p.Results.disable_parfor;

% Get the appropriate data
if rerp_profile.settings.type_proc
    time_series = rerp_profile.include_chans;
    data=EEG.data(time_series, :)';
    
else
    if isempty(EEG.icaact)
        EEG.icaact = eeg_getica(EEG);
    end
    time_series = rerp_profile.include_comps;
    data=EEG.icaact(time_series, :)';
end

pnts=size(data,1);
nbchan=size(data,2);
nbins=rerp_profile.settings.nbins;

temp=rerp_profile.settings.rerp_result_autosave;
rerp_profile.settings.rerp_result_autosave=0; % We want to consolidate results before saving

tic;
if ~rerp_profile.settings.ersp_enable
    results = cell(1, size(data,2));
    if ~disable_parfor
        parfor i=1:length(time_series)
            this_profile=copy(rerp_profile);
            
            if this_profile.settings.type_proc
                this_profile.include_comps=[];
                this_profile.include_chans=time_series(i);
            else
                this_profile.include_chans=[];
                this_profile.include_comps=time_series(i);
            end
            
            results{i}=rerp(data(:,i), this_profile);
        end
    else
        
        results{1} = rerp(data, rerp_profile);
    end
    
    ersp_flag=0;
    
else
    
    % Time frequency decomposition
    t=((0:rerp_profile.pnts-1)/rerp_profile.sample_rate)';
    ts = rerp_dependencies.timeSeries(double(data), t, repmat({'label'}, 1, size(data,2)), rerp_profile.sample_rate);
   
    wname = 'cmor1-1.5';
    fmin = 1;
    fmax = rerp_profile.sample_rate/2;
    plotFlag = false;
    [coefficients, data, angle, frequency, time] = ts.waveletTimeFrequencyAnalysis(wname, fmin, fmax, nbins, plotFlag);
    
    td = find(t==time(1))-1;
    to = length(t) - find(t==time(end));
    data = permute(data, [1 3 2]);
    data = [zeros(td, nbchan, nbins); data; zeros(to, size(data,2),nbins)];
       
    results = cell(1, size(data,2));
    if ~disable_parfor
        data = reshape(data, [pnts, nbchan*nbins]); % Flatten into 2D matrix (datalength,  nbchan*nbins)
        parfor i=1:size(data,2)
            this_profile=copy(rerp_profile);
            
            if this_profile.settings.type_proc
                this_profile.include_comps=[];
                this_profile.include_chans=time_series(ceil(i/nbins));
            else
                this_profile.include_chans=[];
                this_profile.include_comps=time_series(ceil(i/nbins));
            end
            
            results{i}=rerp(data(:,i), this_profile);
        end
    else
        results{1} = rerp(data, rerp_profile);
    end
    
    ersp_flag=1;
end

rerp_profile.settings.rerp_result_autosave=temp;
final_result = RerpResult.combineRerpResults(results);
final_result.compute_time_seconds=toc;
final_result.date_completed=datestr(now,'yyyy-mm-dd-HH:MM:SS');
final_result.ersp_flag=ersp_flag;

