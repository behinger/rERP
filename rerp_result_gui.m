%Launch GUI for plotting results of pop_rerp (RerpResult object)
%   Usage:
%       rerp_result_gui;
%           Launch results gui and load all results from the default folder
%
%       rerp_result_gui('results_dir', '/data/resultsfolder');
%           Launch results gui and load all results from '/data/resultsfolder'
%
%       rerp_result_gui('results', results);
%           Launch results gui and list all results
%
%   Parameters:
%       results_dir:
%           directory where desired .rerp_result files are saved
%       results:
%           Vector of RerpResult objects
%
%   See also:
%       RerpResult, RerpResultStudy, RerpProfile
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

% Last Modified by GUIDE v2.5 26-Apr-2014 04:35:08

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

%TODO verify that the list of results are compatible
function consistent = verify_results_are_consistent(results)
consistent=1;

% --- Executes just before rerp_result_gui is made visible.
function rerp_result_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rerp_result_gui (see VARARGIN)
import rerp_dependencies.RerpPlotSpec

p=inputParser;
addOptional(p,'results_dir', fullfile(RerpProfile.rerp_path, 'results'));
addOptional(p,'results', [], @(x) isa(x, 'RerpResult'));
parse(p, varargin{:});

handles.UserData.results=[];

if isempty(p.Results.results)
    handles.UserData.results = RerpResult.loadRerpResult('path', p.Results.results_dir);
else
    handles.UserData.results=p.Results.results;
end

set(handles.channelslist,'max', 1e7);
set(handles.typeplotlist,'max',1,'value',1);

try
    set(handles.resultslist,'string',{handles.UserData.results(:).name},'max',1e6, 'value', 1);
catch
    set(handles.resultslist,'string',{},'max',1e6, 'value', 1);
end

handles.UserData.locksort=0;
handles.UserData.rerpimage=0;
handles.UserData.lastplot='';
handles.UserData.plotfig=[];

% Choose default command line output for rerp_result_gui
handles.output = hObject;
resultslist_Callback(handles.resultslist,[], handles);
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
if ~isempty(itemnum)
    list_str = cellstr(get(hObject,'String'));
    if ~isempty(list_str)
        new_results=handles.UserData.results(itemnum);
        
        if ~verify_results_are_consistent(new_results)
            warning('rerp_profile_gui: some results selected were not compatible');
        end
        
        handles.UserData.current.result=new_results;
    end
    
    handles = set_options(handles);
end

if ~isempty(handles.UserData.results(:))
    setSortIdx(handles.UserData.results(:));
    channelslist_Callback(handles.channelslist, [], handles);
end

%Load current dataset bounds for rERP image plot
if ~isempty(handles.UserData.current.result)
    cat_bound = handles.UserData.current.result(1).rerp_profile.settings.category_epoch_boundaries;
    con_bound = handles.UserData.current.result(1).rerp_profile.settings.continuous_epoch_boundaries;
    minwin=min([cat_bound con_bound]);
    maxwin=max([cat_bound con_bound]);
    set(handles.enterwindow,'string', num2str([minwin maxwin]));
end
%trigger_all_callbacks(eventdata, handles); 
guidata(handles.output, handles);

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
    set(handles.tagslist,'Value',1,'Max',1);
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
for i=1:length(handles.UserData.results)
    this_ts_list_idx=get(handles.channelslist,'Value');
    this_result=handles.UserData.results(i);
    
    %Only plot number of time series that is available for all currently selected results
    extend_length = max(this_ts_list_idx)-length(this_result.rerp_plot_spec.sort_idx);
    
    dataset_name = regexp(this_result.rerp_profile.eeglab_dataset_name, '.*[\\\/](.*)\.set', 'tokens');
    
    if ~isempty(dataset_name)
        dataset_name=dataset_name{1}{1};
    else
        dataset_name='';
    end
    
    if(this_result.rerp_profile.settings.type_proc)
        type='channels';
    else
        type='components';
    end
    
    if extend_length > 0
        error('rerp_result_gui: dataset %s only has %d %s; select fewer %s for group plotting',...
            dataset_name, length(this_result.rerp_plot_spec.sort_idx), type, type);
    end
    
    this_result.rerp_plot_spec.ts_idx = this_result.rerp_plot_spec.sort_idx(this_ts_list_idx);
end

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
for i=1:length(handles.UserData.results)
    handles.UserData.results(i).rerp_plot_spec.event_idx = get(hObject, 'Value');
    
    if handles.UserData.rerpimage
        if handles.UserData.locksort
            handles.UserData.results(i).rerp_plot_spec.delay_idx=get(hObject,'Value');
        else
            handles.UserData.results(i).rerp_plot_spec.locking_idx=get(hObject,'Value');
        end
    end
end

%Make sure if multiple results are selected they all have the same event
%types
if length(handles.UserData.current.result > 1)
    contents = cellstr(get(hObject,'String'));
    selected = contents(get(hObject,'Value'));
    
    tags_list = cell(1,length(handles.UserData.current.result));
    missing_tags = cell(1,length(handles.UserData.current.result));
    num_elem = zeros(1,length(handles.UserData.current.result));
    for i=1:length(handles.UserData.current.result)
        this_result = handles.UserData.current.result(i);
        tags_list{i}=handles.UserData.current.result(i).get_plotting_params;
        
        %Error if any selected tags are missing from this dataset
        missing_tags{i}=setdiff(selected, tags_list{i});
        if ~isempty(missing_tags{i})
            if ~isempty(this_result.rerp_profile.eeglab_dataset_name)
                dataset_name = regexp(this_result.rerp_profile.eeglab_dataset_name, '.*[\\\/](.*)\.set','tokens');
            else
                dataset_name = {{num2string(i)}};
            end
            
            if this_result.rerp_profile.settings.hed_enable
                type = 'HED tags';
            else
                type = 'event types';
            end
            
            mess = '\nrerp_result_gui: dataset %s is missing the following %s - deselect either the dataset or the %s:';
            for j=1:length(missing_tags{i})
                mess = [mess '\n        ' type(1:end-1) ' ' missing_tags{i}{j}];
            end
            
            error(mess, dataset_name{1}{1}, type, type);
        end
        
        num_elem(i)=length(tags_list);
    end
    
    %Make sure event type indexes match up, might be different if datasets have
    %slightly different tags.
    for i=1:length(tags_list)
        this_tags_list=tags_list{i};
        new_event_idx = zeros(1,length(selected));
        for j=1:length(selected)
            new_event_idx(j) = find(strcmp(selected{j}, this_tags_list),1);
        end
        handles.UserData.current.result(i).rerp_plot_spec.event_idx=new_event_idx;
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
new_results = RerpResult.loadRerpResult;
handles.UserData.results = [handles.UserData.results new_results];
handles = set_options(handles);
res_strings = get(handles.resultslist, 'String');
set(handles.resultslist,'Value',(length(res_strings)-length(new_results)+1):length(res_strings));

% Update handles structure, other lists
resultslist_Callback(handles.resultslist, [], handles);

% --- Executes on button press in clearfigure.
function clearfigure_Callback(hObject, eventdata, handles)
% hObject    handle to clearfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.UserData.plotfig)
    try
        close(handles.UserData.plotfig);
        handles.UserData.plotfig=figure;
        guidata(hObject, handles);
    catch
    end
end

% --- Executes on button press in plot.
function plot_Callback(hObject, eventdata, handles)
% hObject    handle to plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents=cellstr(get(handles.typeplotlist,'String'));
plottype = contents{get(handles.typeplotlist,'Value')};

%Make sure we have a handle to the plot window
if ~isempty(handles.UserData.plotfig)
    if get(handles.overplot,'Value')
        try
            a=get(handles.UserData.plotfig);
        catch
            handles.UserData.plotfig=figure;
        end
    else
        try
            close(handles.UserData.plotfig);
        catch
        end
        handles.UserData.plotfig=figure;
    end
else
    handles.UserData.plotfig=figure;
end

set(0,'CurrentFigure', handles.UserData.plotfig);
set(handles.UserData.plotfig,'color', [1 1 1]);

%Combine multiple results into object: for study plotting or single dataset
%plotting
rerp_study = RerpResultStudy(handles.UserData.current.result);

if strcmp(plottype, 'Rerp by event type')||strcmp(plottype,'Rerp by HED tag')
    rerp_study.plotRerpEventTypes(handles.UserData.plotfig);
end

if strcmp(plottype, 'Rerp by component')||strcmp(plottype,'Rerp by channel')
    rerp_study.plotRerpTimeSeries(handles.UserData.plotfig);
end

if strcmp(plottype, 'R2 total')
    rerp_study.plotRerpTotalRsquared(handles.UserData.plotfig);
end

if strcmp(plottype, 'R2 by event type')||strcmp(plottype, 'R2 by HED tag')
    rerp_study.plotRerpEventRsquared(handles.UserData.plotfig);
end

if strcmp(plottype, 'Rerp image')
    rerp_study.plotRerpImage(handles.UserData.plotfig);
end

if strcmp(plottype, 'Grid search')
    rerp_study.plotGridSearch(handles.UserData.plotfig);
end

if strcmp(plottype, 'Rersp')
    rerp_study.plotRersp(handles.UserData.plotfig);
end

handles.UserData.lastplot = plottype;

% Update handles structure
guidata(hObject, handles);

function opts = get_all_plotting_opts(handles)
opts=[];

if isempty(handles.UserData.current.result)
    return;
else
    first_result=handles.UserData.current.result(1);
end

if first_result.rerp_profile.settings.type_proc;
    typeproc = 'by channel';
else
    typeproc = 'by component';
end

if first_result.rerp_profile.settings.hed_enable
    type= 'by HED tag';
else
    type= 'by event type';
end

%Just one dataset is being plotted
if length(handles.UserData.current.result)==1
    if first_result.ersp_flag
        opts = {'Rersp'};
    else
        opts = {['Rerp ' type], ['Rerp ' typeproc], 'R2 total', ['R2 ' type], 'Rerp image'};
        
        if ~isempty(first_result.gridsearch)
            opts = {opts{:} 'Grid search'};
        end
    end
    
    %Combine plotting from multiple datasets
else
    if first_result.ersp_flag
        opts = {};
    else
        opts = {'R2 total', ['R2 ' type]};
    end
end

% Fills in lists based on current result and settings
function handles = set_options(handles)

if ~isempty(handles.UserData.results)
    set(handles.resultslist,'String', {handles.UserData.results(:).name});
end

try
    result = handles.UserData.current.result;
catch
    return;
end

%We could have selected many results. This assumes that they are all
%compatible.
if isempty(result)
    set(handles.typeplotlist, 'string', {}, 'value',1);
    set(handles.channelslist, 'string', {}, 'value',1);
    return;
else
    first_result=result(1);
end

% Setup result options for plotting. Populate channels/components. Populate event types/tags
opts=get_all_plotting_opts(handles);
if ~isempty(opts) && nnz(get(handles.typeplotlist,'Value'))==0
    val=1;
else
    val=min(length(opts), get(handles.typeplotlist,'Value'));
end
set(handles.typeplotlist, 'string', opts, 'value',val);

if first_result.rerp_profile.settings.type_proc
    set(handles.typeproclabel, 'string', 'Channels (R2)');
else
    set(handles.typeproclabel, 'string', 'Components (R2)');
end

if first_result.rerp_profile.settings.type_proc
    channels = first_result.rerp_profile.include_chans;
else
    channels = first_result.rerp_profile.include_comps;
end

rsq=first_result.setSortIdx;

time_series_str = num2str(unique(channels'));
assert(length(channels)==size(first_result.rerp_estimate,2), 'rerp_result_gui: problem matching dataset to result');
rsqstr = num2str(rsq');
ts_str_w_rsq=cell(1,size(rsqstr,1));

for i=1:length(ts_str_w_rsq)
    ts_str_w_rsq{i} = [time_series_str(i,:) '    (' rsqstr(i,:) ')'];
end
cts=get(handles.channelslist,'Value');

%Indexes into the first result channels or comps for the list
if first_result.rerp_plot_spec.sort_by_r2
    tsstr=ts_str_w_rsq(first_result.rerp_plot_spec.sort_idx);
else
    tsstr=ts_str_w_rsq(1:length(ts_str_w_rsq));
end
set(handles.channelslist, 'string', tsstr, 'value', cts(cts<=length(tsstr)));

%Set tags to the intersection of tag sets across datasets
tags=first_result.get_plotting_params;
for i=2:length(result)
    tags=intersect(tags, result(i).get_plotting_params);
end

ctags = get(handles.tagslist,'value');
contents=cellstr(get(handles.tagslist,'string'));
old_tags = contents(ctags); 

new_val=[]; 
for i=1:length(tags)
    if any(strcmp(tags{i}, old_tags)) 
        new_val = [new_val i];
    end
end

if isempty(new_val)
    new_val = ctags(ctags<=length(tags));
end

set(handles.tagslist, 'string', tags, 'value', new_val);

if first_result.rerp_profile.settings.hed_enable
    set(handles.tagslabel, 'string', 'HED tags');
else
    set(handles.tagslabel, 'string', 'Event types');
end

% --- Executes on button press in sortbyrsqaurebox.
function sortbyrsqaurebox_Callback(hObject, eventdata, handles)
% hObject    handle to sortbyrsqaurebox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.UserData.results(:).rerp_plot_spec.sort_by_r2=get(hObject,'Value');

% Hint: get(hObject,'Value') returns toggle state of sortbyrsqaurebox
resultslist_Callback(handles.resultslist, [], handles)


% --- Executes on button press in displayprofilebutton.
function displayprofilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to displayprofilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
rerp_profile_gui(handles.UserData.current.result(1).rerp_profile)


function significancelevel_Callback(hObject, eventdata, handles)
% hObject    handle to significancelevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of significancelevel as text
%        str2double(get(hObject,'String')) returns contents of significancelevel as a double
try
    newlevel = str2double(get(handles.significancelevel,'String'));
    if isnumeric(newlevel)&&length(newlevel)==1&&newlevel>=0&&newlevel<=1
        for i=1:length(handles.UserData.results)
            handles.UserData.results(i).rerp_plot_spec.significance_level=newlevel;
        end
    else
        error('rerp_result_gui');
    end
catch
    set(hObject,'string', num2str(handles.UserData.rerp_plot_spec.significance_level));
    disp('rerp_result_gui: p-value threshold must be between 0 - 1');
end



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
if  handles.UserData.locksort==0
    set(hObject,'String', 'Sorting variable');
    if ~isempty(handles.UserData.current.result)
           set(handles.tagslist,'Value', handles.UserData.current.result(1).rerp_plot_spec.delay_idx);
    end
    handles.UserData.locksort=1;
else
    set(hObject,'String', 'Locking variable');
    if ~isempty(handles.UserData.current.result) 
        set(handles.tagslist,'Value',handles.UserData.current.result(1).rerp_plot_spec.locking_idx);
    end
    handles.UserData.locksort=0;
end

% Update handles structure
guidata(hObject, handles);


function enterwindow_Callback(hObject, eventdata, handles)
% hObject    handle to enterwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of enterwindow as text
%        str2double(get(hObject,'String')) returns contents of enterwindow as a double
if ~isempty(handles.UserData.results)
    for i=1:length(handles.UserData.results)
        bound = str2num(get(handles.enterwindow,'String'));
        assert(length(bound)==2,'rerp_result_gui: rerp image boundary must have two numeric entries'); 
        handles.UserData.results(i).rerp_plot_spec.rerp_image_boundary = bound;
    end
end

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
if length(handles.UserData.current.result)==1
    handles.UserData.current.result.saveRerpResult;
else
    error('rerp_result_gui: can not save multiple results simultaneously');
end

% --- Executes on button press in exclude_insignif.
function exclude_insignif_Callback(hObject, eventdata, handles)
% hObject    handle to exclude_insignif (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of exclude_insignif
if ~isempty(handles.UserData.results)
    for i=1:length(handles.UserData.results)
        handles.UserData.results(i).rerp_plot_spec.exclude_insignificant=get(hObject,'Value');
    end
end

% --- Executes on button press in constant_scale.
function constant_scale_Callback(hObject, eventdata, handles)
% hObject    handle to constant_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of constant_scale
if ~isempty(handles.UserData.results)
    for i=1:length(handles.UserData.results)
        handles.UserData.results(i).rerp_plot_spec.constant_scale=get(hObject,'Value');
    end
end

% --- Executes on button press in overplot.
function overplot_Callback(hObject, eventdata, handles)
% hObject    handle to overplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of overplot
if ~isempty(handles.UserData.results)
    for i=1:length(handles.UserData.results)
        handles.UserData.results(i).rerp_plot_spec.over_plot=get(hObject,'Value');
    end
end

function trigger_all_callbacks(eventdata, handles)
    typeplotlist_Callback(handles.typeplotlist, eventdata, handles)
    channelslist_Callback(handles.channelslist, eventdata, handles)
    tagslist_Callback(handles.tagslist, eventdata, handles)
    sortbyrsqaurebox_Callback(handles.sortbyrsqaurebox, eventdata, handles)
    significancelevel_Callback(handles.significancelevel, eventdata, handles)
    enterwindow_Callback(handles.enterwindow_Callback, eventdata, handles)
    exclude_insignif_Callback(handles.exclude_insignif, eventdata, handles)
    constant_scale_Callback(handles.constant_scale, eventdata, handles)
    overplot_Callback(handles.overplot, eventdata, handles)
