% Copyright (C) 2013 Matthew Burns, Swartz Center for Computational
% Neuroscience. 
%
% User feedback welcome: email mburns ( at ) sccn.ucsd.edu
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

function varargout = rerp_result_gui(varargin)
% RERP_RESULT_GUI MATLAB gui for displaying and plotting RerpResult objects
%      RERP_RESULT_GUI, by itself, creates a new RERP_RESULT_GUI or raises the existing
%      singleton*.
%
%      H = RERP_RESULT_GUI returns the handle to a new RERP_RESULT_GUI or the handle to
%      the existing singleton*.
%
%      RERP_RESULT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RERP_RESULT_GUI.M with the given input arguments.
%
%      RERP_RESULT_GUI('Property','Value',...) creates a new RERP_RESULT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rerp_result_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rerp_result_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rerp_result_gui

% Last Modified by GUIDE v2.5 05-Nov-2013 17:26:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @rerp_result_gui_OpeningFcn, ...
    'gui_OutputFcn',  @rerp_result_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before rerp_result_gui is made visible.
function rerp_result_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rerp_result_gui (see VARARGIN)
p=inputParser;
addOptional(p,'EEG', []);
parse(p, varargin{:});

% Get last result and see if it matches the dataset
rerp_path = regexp(strtrim(mfilename('fullpath')),'(.*)[\\\/].*','tokens');
handles.UserData.rerp_path=rerp_path{1}{1};
try
    last_result = RerpResult.loadRerpResult('path', fullfile(rerp_path{1}{1}, 'results', 'last.rerp_result'));
    last_dsname = regexp(last_result.rerp_profile.eeglab_dataset_name,'.*[\\\/](.*.set)','tokens');
    handles.UserData.results{1}=last_result;
    handles.UserData.result_names{1}='last';
    
    if ~isempty(p.Results.EEG)
        dsname = p.Results.EEG.filename;
        if strcmp(dsname, last_dsname)
            handles.UserData.datasets{1}=fullfile(p.Results.EEG.filename,p.Results.EEG.filepath);
        else
            handles.UserData.datasets{1}=last_result.rerp_profile.eeglab_dataset_name;
        end
        
    else
        handles.UserData.datasets{1}=last_result.rerp_profile.eeglab_dataset_name;
    end
    
catch
    
    handles.UserData.results{1}=[];
    handles.UserData.result_names{1}='';
    handles.UserData.datasets{1}=[];
end
handles.UserData.plotfig=[];
handles.UserData.current_result=handles.UserData.results{1};
handles.UserData.current_dataset=handles.UserData.datasets{1};

% Get the matching results from the EEG directory, if any
if ~isempty(p.Results.EEG)
    handles.UserData.eegpath = p.Results.EEG.filepath;
    eeg_dir=dir(fullfile(p.Results.EEG.filepath,'*.rerp_result'));
    names = eeg_dir(:).name;
    
    if ~iscell(names)
        names={names};
    end
    
    for i=1:length(names)
        this_name=names{i};
        try
            this_result = RerpResult.loadRerpResult('path',this_name);
            result_dataset = regexp(this_result.rerp_profile.eeglab_dataset_name, '.*[\\\/](.*.set)','tokens');
            
            if strcmp(result_dataset{1}{1}, p.Results.EEG.filename) && ~strcmp(this_name, 'last.rerp_result')
                handles.UserData.results{end+1}=this_result;
                handles.UserData.datasets{end+1}= fullfile(p.Results.EEG.filename,p.Results.EEG.filepath);
                handles.UserData.result_names{end+1}=this_name;
            end
            
        catch
        end
    end
else
    % Get result from the results folder
    handles.UserData.eegpath = [];
end
resultsdir = dir(fullfile(rerp_path{1}{1}, 'results'));
names = {resultsdir(:).name};

for i=1:length(names)
    this_name=names{i};
    try
        this_result = RerpResult.loadRerpResult('path',fullfile(rerp_path{1}{1}, 'results', this_name));
        
        if ~strcmp(this_name, 'last.rerp_result')
            handles.UserData.results{end+1}=this_result;
            handles.UserData.datasets{end+1}= this_result.rerp_profile.eeglab_dataset_name;
            handles.UserData.result_names{end+1}=this_name;
        end
        
    catch
    end
end


set(handles.typeplotlist,'max',1);
set(handles.resultslist,'string',handles.UserData.result_names,'max',1);
set(handles.channelslist,'max', 1e7);

handles.UserData.locking_idx=1;
handles.UserData.sorting_idx=1;
handles.UserData.locksort=0;
handles.UserData.rerpimage=0;
handles.UserData.lastplot='';

handles = set_options(handles);

% Populate channels or ICs and event types or tags

% Choose default command line output for rerp_result_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rerp_result_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = rerp_result_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.UserData.plotfig);
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in resultslist.
function resultslist_Callback(hObject, eventdata, handles)
% hObject    handle to resultslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns resultslist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from resultslist
itemnum = get(hObject,'Value');
handles.UserData.current_result=handles.UserData.results{itemnum};
handles.UserData.current_dataset=handles.UserData.datasets{itemnum};
handles.UserData.current_name=handles.UserData.result_names{itemnum};
handles = set_options(handles);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function resultslist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resultslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in typeplotlist.
function typeplotlist_Callback(hObject, eventdata, handles)
% hObject    handle to typeplotlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns typeplotlist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from typeplotlist
contents=cellstr(get(hObject,'String'));
thisplot=contents{get(hObject,'Value')};

% Rerpimage options 
if strcmp(thisplot,'Rerp image')
    set(handles.lockingindexbutton, 'Visible','on');
    set(handles.tagslist,'Max',1);
    set(handles.enterwindow,'Visible','on');
    set(handles.windowlabel,'Visible','on');
    handles.UserData.rerpimage=1;
else
    set(handles.lockingindexbutton, 'Visible','off');
    set(handles.enterwindow,'Visible','off');
    set(handles.windowlabel,'Visible','off');
    set(handles.tagslist,'Max',1e7);
    handles.UserData.rerpimage=0;
end

% Rsquare options
if strcmp(thisplot, 'R-Squared by event type')||(strcmp(thisplot, 'R-Squared by HED tag')||strcmp(thisplot, 'R-Squared total'))
    set(handles.significancelevel, 'Visible','on');
    set(handles.significancelabel, 'Visible','on');
else
    set(handles.significancelevel, 'Visible','off');
    set(handles.significancelabel, 'Visible','off');
end

tagslist_Callback(handles.tagslist, eventdata, handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function typeplotlist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to typeplotlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in channelslist.
function channelslist_Callback(hObject, eventdata, handles)
% hObject    handle to channelslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channelslist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channelslist


% --- Executes during object creation, after setting all properties.
function channelslist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in tagslist.
function tagslist_Callback(hObject, eventdata, handles)
% hObject    handle to tagslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagslist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagslist
if handles.UserData.rerpimage
    if handles.UserData.locksort
        handles.UserData.sorting_idx=get(hObject,'Value');
    else
        handles.UserData.locking_idx=get(hObject,'Value');
    end
end

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagslist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in loadresultsbutton.
function loadresultsbutton_Callback(hObject, eventdata, handles)
% hObject    handle to loadresultsbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if isempty(handles.UserData.eegpath)
    start_path=fullfile(handles.UserData.rerp_path, 'results');
else
    start_path=handles.UserData.eegpath;
end

[fn,fp] = uigetfile('rerp_result','Select rerp results:',start_path,'MultiSelect','on');

if ~iscell(fn)
    fn={fn};
end

if fn
    for i=1:length(fn)
        this_dir = dir(fp);
        thisfn = fullfile(fp,fn{i});
        this_result = RerpResult.loadRerpResult('path',thisfn);
        this_eegpath=this_result.rerp_profile.eeglab_dataset_name;
        eegfn=regexp(this_eegpath, '(.*[\\\/])(.*.set)','tokens');
        eegdir = dir(eegfn{1}{1});
        handles.UserData.results{end+1}=this_result;
        handles.UserData.result_names{end+1}= fn{i};
        
        if ~isempty(eegdir)
            [~, idx]=intersect({eegdir(:).name}, eegfn{1}{2});
        else
            idx=0;
        end
        
        % Check to make sure the .set file is where it should be
        if any(idx)
            handles.UserData.datasets{end+1}= this_eegpath;
            % If not, check the directory we are looking in
        elseif any(intersect({this_dir(:).name}, eegfn{1}{2}))
            handles.UserData.datasets{end+1}= fullfile(fp, eegfn{1}{2});
            % Could not locate the corresponding .set file
        else
            handles.UserData.datasets{end+1}= [];
        end
        
        handles = set_options(handles);
        
        % Update handles structure
        guidata(hObject, handles);
    end
end

% --- Executes on button press in clearfigure.
function clearfigure_Callback(hObject, eventdata, handles)
% hObject    handle to clearfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.UserData.plotfig)
    try
        get(handles.UserData.plotfig);
        clf(handles.UserData.plotfig);
    catch
    end
else
end

% --- Executes on button press in plot.
function plot_Callback(hObject, eventdata, handles)
% hObject    handle to plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents=cellstr(get(handles.typeplotlist,'String'));
plottype = contents{get(handles.typeplotlist,'Value')};

ts_idx = handles.UserData.sort_idx(get(handles.channelslist,'Value'));
event_idx = get(handles.tagslist,'Value');


if ~isempty(handles.UserData.plotfig)
    try
        get(handles.UserData.plotfig);
        if ~strcmp(handles.UserData.lastplot, plottype)
            clf(handles.UserData.plotfig);
        end
        
    catch
        handles.UserData.plotfig=figure;
    end
else
    handles.UserData.plotfig=figure;
end

set(0,'CurrentFigure', handles.UserData.plotfig)

if strcmp(plottype, 'Rerp by event type')||strcmp(plottype,'Rerp by HED tag');
    handles.UserData.current_result.plotRerpEventTypes(event_idx, ts_idx, handles.UserData.plotfig)
end

if strcmp(plottype, 'Rerp by component')||strcmp(plottype,'Rerp by channel')
    handles.UserData.current_result.plotRerpTimeSeries(event_idx, ts_idx, handles.UserData.plotfig)
end

if strcmp(plottype, 'R-Squared total')
    significance_level=str2double(get(handles.significancelevel,'String'));
    handles.UserData.current_result.plotRerpTotalRsquared(ts_idx, significance_level, handles.UserData.plotfig)
end

if strcmp(plottype, 'R-Squared by event type')||strcmp(plottype, 'R-Squared by HED tag')
    significance_level=str2double(get(handles.significancelevel,'String'));
    handles.UserData.current_result.plotRerpEventRsquared(ts_idx, significance_level, event_idx, handles.UserData.plotfig)
end

if strcmp(plottype, 'Rerp image')
    
    if isempty(handles.UserData.current_dataset)
        nm = handles.UserData.current_dataset.rerp_profile.eeglab_dataset_name;
        [fn, fp] = uigetfile('*.set', 'Locate the EEGLAB .set file for this result:', nm);
        handles.UserData.current_dataset=fullfile(fn, fp);
        handles.UserData.current_result.rerp_profile.eeglab_dataset_name=fullfile(fn, fp);
    end
    
    EEG=pop_loadset(handles.UserData.current_dataset);
    if ~handles.UserData.current_result.rerp_profile.settings.type_proc && isempty(EEG.icaact)
        EEG.icaact=eeg_getica(EEG);
    end
    
    window_size_ms = str2double(get(handles.enterwindow,'String'));
    handles.UserData.current_result.plotRerpImage(EEG, handles.UserData.locking_idx, handles.UserData.sorting_idx, ts_idx, window_size_ms, handles.UserData.plotfig)
end

if strcmp(plottype, 'Grid search')
    handles.UserData.current_result.plotGridSearch(obj, ts_idx, handles.UserData.plotfig)
end

if strcmp(plottype, 'Rersp')
    handles.UserData.current_result.plotRersp(event_idx, ts_idx, handles.UserData.plotfig)
end

handles.UserData.lastplot = plottype;

% Update handles structure
guidata(hObject, handles);

function [opts, funcs] = get_all_plotting_opts(result)
opts=[];
if isempty(result)
    return;
end

if result.rerp_profile.settings.type_proc;
    typeproc = 'by channel';
else
    typeproc = 'by component';
end

if result.rerp_profile.settings.hed_enable
    type= 'by HED tag';
else
    type= 'by event type';
end

if result.ersp_flag
    opts = {'Rersp'};
    funcs = {@result.plotRersp};
else
    opts = {['Rerp ' type], ['Rerp ' typeproc], 'R-Squared total', ['R-Squared ' type], 'Rerp image'};
    
    if isempty(result.gridsearch)
        
    else
        opts = {opts{:} 'Grid search'};
    end
end

% Fills in lists based on current result and settings
function handles = set_options(handles)

set(handles.resultslist,'string',handles.UserData.result_names);
result = handles.UserData.current_result;

if isempty(result)
    set(handles.typeplotlist, 'string', '');
    set(handles.channelslist, 'string', '');
    return;
end

% Setup result options for plotting. Populate channels/components. Populate event types/tags
set(handles.typeplotlist, 'string', get_all_plotting_opts(result),'max',1);

if result.rerp_profile.settings.type_proc
    channels = result.rerp_profile.include_chans;
else
    channels = result.rerp_profile.include_comps;
end

assert(length(channels)==size(result.rerp_estimate,2), 'pop_plot_rerp_result: problem matching dataset to result');

if result.rerp_profile.settings.type_proc
    set(handles.typeproclabel, 'string', 'Channels (R-Squared)');
    time_series_str = num2str(unique(result.rerp_profile.include_chans'));
else
    set(handles.typeproclabel, 'string', 'Components (R-Squared)');
    time_series_str = num2str(unique(result.rerp_profile.include_comps'));
end

if result.ersp_flag
    nbins=result.rerp_profile.settings.nbins;
    rsq = max(reshape(result.average_total_rsquare, [nbins, length(result.average_total_rsquare)/nbins]));
else
    rsq = result.average_total_rsquare;
end

if get(handles.sortbyrsqaurebox, 'Value')
    [~, handles.UserData.sort_idx]=sort(rsq,'descend');
else
    handles.UserData.sort_idx=1:length(time_series_str);
end

rsqstr = num2str(rsq');
ts_str_w_rsq=cell(1,length(rsqstr));

for i=1:length(time_series_str)
    ts_str_w_rsq{i} = [time_series_str(i,:) '    (' rsqstr(i,:) ')'];
end

set(handles.channelslist, 'string', ts_str_w_rsq(handles.UserData.sort_idx));
tags = result.get_plotting_params;
set(handles.tagslist, 'string', tags)

if result.rerp_profile.settings.hed_enable
    set(handles.tagslabel, 'string', 'HED tags');
else
    set(handles.tagslabel, 'string', 'Event types');
end

% --- Executes on button press in sortbyrsqaurebox.
function sortbyrsqaurebox_Callback(hObject, eventdata, handles)
% hObject    handle to sortbyrsqaurebox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of sortbyrsqaurebox
handles = set_options(handles);
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in displayprofilebutton.
function displayprofilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to displayprofilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pop_rerp({}, handles.UserData.current_result.rerp_profile,'view_only',1);



function significancelevel_Callback(hObject, eventdata, handles)
% hObject    handle to significancelevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of significancelevel as text
%        str2double(get(hObject,'String')) returns contents of significancelevel as a double


% --- Executes during object creation, after setting all properties.
function significancelevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to significancelevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in lockingindexbutton.
function lockingindexbutton_Callback(hObject, eventdata, handles)
% hObject    handle to lockingindexbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp( get(hObject,'String'), 'Locking variable')
    set(hObject,'String', 'Sorting variable');
    set(handles.tagslist,'Value',handles.UserData.sorting_idx);
    handles.UserData.locksort=1;
else
    set(hObject,'String', 'Locking variable');
    handles.UserData.locksort=0;
    set(handles.tagslist,'Value',handles.UserData.locking_idx);
    
end

% Update handles structure
guidata(hObject, handles);


function enterwindow_Callback(hObject, eventdata, handles)
% hObject    handle to enterwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of enterwindow as text
%        str2double(get(hObject,'String')) returns contents of enterwindow as a double


% --- Executes during object creation, after setting all properties.
function enterwindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to enterwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    close(handles.UserData.plotfig);
catch
end

% --- Executes on button press in saveresultas.
function saveresultas_Callback(hObject, eventdata, handles)
% hObject    handle to saveresultas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.UserData.current_result.saveRerpResult;
