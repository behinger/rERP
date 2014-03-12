% Copyright (C) 2013 Matthew Burns, Swartz Center for Computational
% Neuroscience. 
%
% User feedback welcome: email rerptoolbox@gmail.com
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

% Last Modified by GUIDE v2.5 01-Mar-2014 11:40:12

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
addOptional(p,'results_dir', []);
parse(p, varargin{:});
results_dir=p.Results.results_dir; 
handles.UserData.results=struct([]);
handles.UserData.rerp_plot_spec=RerpPlotSpec; 

% Get last result and see if it matches the dataset
rerp_path = regexp(strtrim(mfilename('fullpath')),'(.*)[\\\/].*','tokens');
rerp_path=rerp_path{1}{1}; 
handles.UserData.rerp_path=rerp_path;

if isempty(results_dir)
    results_dir = fullfile(rerp_path, 'results'); 
end

these_results = dir(fullfile(results_dir, '*.rerp_result'));
names = {these_results(:).name};

for i=1:length(names)
    this_result = RerpResult.loadRerpResult('path', fullfile(results_dir, names{i}));
    this_result.gridsearch=[]; 
    this_result.rerp_plot_spec = handles.UserData.rerp_plot_spec; 
    handles.UserData.results(end+1).result=this_result;
    handles.UserData.results(end).name=names{i};
    handles.UserData.results(end).path=fullfile(results_dir, names{i}); 
end

try
    set(handles.typeplotlist,'max',1,'value',1);
    set(handles.resultslist,'string',{handles.UserData.results(:).name},'max',1);
    set(handles.channelslist,'max', 1e7);
catch 
end
handles.UserData.sort_idx=0;
handles.UserData.locksort=0;
handles.UserData.rerpimage=0;
handles.UserData.lastplot='';
handles.UserData.plotfig=[];

% Choose default command line output for rerp_result_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

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

new_results={handles.UserData.results(itemnum).result};
if ~verify_results_are_consistent(new_results)
    warning('rerp_profile_gui: some results selected were not compatible'); 
end

handles.UserData.current.result=new_results;
handles.UserData.current.path={handles.UserData.results(itemnum).path};
handles.UserData.current.name={handles.UserData.results(itemnum).name};

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

% % Rsquare options
% if strcmp(thisplot, 'R-Squared by event type')||(strcmp(thisplot, 'R-Squared by HED tag')||strcmp(thisplot, 'R-Squared total'))
%     set(handles.significancelevel, 'Visible','on');
%     set(handles.significancelabel, 'Visible','on');
% else
%     set(handles.significancelevel, 'Visible','off');
%     set(handles.significancelabel, 'Visible','off');
% end

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
        handles.UserData.rerp_plot_spec.delay_idx=get(hObject,'Value');
    else
        handles.UserData.rerp_plot_spec.locking_idx=get(hObject,'Value');
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

start_path=fullfile(handles.UserData.rerp_path, 'results');


[fn,fp] = uigetfile('*.rerp_result','Select rerp results:',start_path,'MultiSelect','on');
if ~iscell(fn)
    fn={fn};
    fp={fp};
end

if fn{1} 
    
    if ~iscell(fn)
        fn={fn};
    end
    
    for i=1:length(fn)
        this_dir = dir(fullfile(fp,'*.rerp_result'));
        thisfn = fullfile(fp, fn{i});
        this_result = RerpResult.loadRerpResult('path', thisfn);
        this_result.rerp_plot_spec=handles.UserData.rerp_plot_spec; 
        this_eegpath=this_result.rerp_profile.eeglab_dataset_name;
        eegfn=regexp(this_eegpath, '(.*[\\\/])(.*.set)','tokens');
        eegdir = dir(eegfn{1}{1});
        
        handles.UserData.results(end+1).result=this_result;
        handles.UserData.results(end).name = fn{i};
        handles.UserData.results(end).path = fullfile(fp{i}, fn{i}); 
        
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

handles.UserData.rerp_plot_spec.ts_idx = handles.UserData.sort_idx(get(handles.channelslist,'Value'));
handles.UserData.rerp_plot_spec.event_idx = get(handles.tagslist,'Value');

%Make sure we have a handle to the plot window
if ~isempty(handles.UserData.plotfig)
    try
        a=get(handles.UserData.plotfig);
    catch
        handles.UserData.plotfig=figure;
    end
else
    handles.UserData.plotfig=figure;
end

set(0,'CurrentFigure', handles.UserData.plotfig);
set(handles.UserData.plotfig,'color', [1 1 1]);
handles.UserData.rerp_plot_spec.significance_level=str2double(get(handles.significancelevel,'String'));
handles.UserData.rerp_plot_spec.exclude_insignificant=get(handles.exclude_insignif, 'value'); 

%Combine multiple results into object for study plotting
rerp_study = RerpResultStudy(handles.UserData.current.result); 

if strcmp(plottype, 'Rerp by event type')||strcmp(plottype,'Rerp by HED tag')
    rerp_study.plotRerpEventTypes(handles.UserData.plotfig);
end

if strcmp(plottype, 'Rerp by component')||strcmp(plottype,'Rerp by channel')
    rerp_study.plotRerpTimeSeries(handles.UserData.plotfig);
end

if strcmp(plottype, 'R-Squared total')
    rerp_study.plotRerpTotalRsquared(handles.UserData.plotfig);
end

if strcmp(plottype, 'R-Squared by event type')||strcmp(plottype, 'R-Squared by HED tag')
    rerp_study.plotRerpEventRsquared(handles.UserData.plotfig);
end

if strcmp(plottype, 'Rerp image')       
    handles.UserData.rerp_plot_spec.window_size_ms = str2double(get(handles.enterwindow,'String'));
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

function [opts, funcs] = get_all_plotting_opts(first_result, study)
opts=[];
if isempty(first_result)
    return;
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
if ~study
    if first_result.ersp_flag
        opts = {'Rersp'};
    else
        opts = {['Rerp ' type], ['Rerp ' typeproc], 'R-Squared total', ['R-Squared ' type], 'Rerp image'};

        if ~isempty(first_result.gridsearch)
            opts = {opts{:} 'Grid search'};
        end
    end
    
%Combine plotting from multiple datasets
else
    if first_result.ersp_flag
        opts = {};
    else
        opts = {'R-Squared total', ['R-Squared ' type]};
    end
end

% Fills in lists based on current result and settings
function handles = set_options(handles)

set(handles.resultslist,'String', {handles.UserData.results(:).name});
try
    result = handles.UserData.current.result;
catch
    return;
end

%We could have selected many results. This assumes that they are all
%compatible.
if isempty(result)
    set(handles.typeplotlist, 'string', '','value',1);
    set(handles.channelslist, 'string', '','value',1);
    return;
else
    first_result=result{1};
end

% Setup result options for plotting. Populate channels/components. Populate event types/tags
opts=get_all_plotting_opts(first_result, length(result)>1);
set(handles.typeplotlist, 'string', opts, 'value', min(length(opts), get(handles.typeplotlist,'Value')));

if first_result.rerp_profile.settings.type_proc
    channels = first_result.rerp_profile.include_chans;
    set(handles.typeproclabel, 'string', 'Channels (R-Squared)');
else
    channels = first_result.rerp_profile.include_comps;
    set(handles.typeproclabel, 'string', 'Components (R-Squared)');
end
time_series_str = num2str(unique(channels'));
assert(length(channels)==size(first_result.rerp_estimate,2), 'pop_plot_rerp_result: problem matching dataset to result');

if first_result.ersp_flag
    nbins=first_result.rerp_profile.settings.nbins;
    rsq = max(reshape(first_result.average_total_rsquare, [nbins, length(first_result.average_total_rsquare)/nbins]));
else
    rsq = first_result.average_total_rsquare;
end

if get(handles.sortbyrsqaurebox, 'Value')
    [~, handles.UserData.sort_idx]=sort(rsq,'descend');
else
    handles.UserData.sort_idx=1:length(time_series_str);
end

rsqstr = num2str(rsq');
ts_str_w_rsq=cell(1,size(rsqstr,1));

for i=1:length(ts_str_w_rsq)
    ts_str_w_rsq{i} = [time_series_str(i,:) '    (' rsqstr(i,:) ')'];
end
cts=get(handles.channelslist,'Value'); 
tsstr=ts_str_w_rsq(handles.UserData.sort_idx);
set(handles.channelslist, 'string', tsstr, 'value', cts(cts<=length(tsstr)));

tags = first_result.get_plotting_params;
ctags = get(handles.tagslist,'value');
set(handles.tagslist, 'string', tags, 'value', ctags(ctags<=length(tags)));

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

% Hint: get(hObject,'Value') returns toggle state of sortbyrsqaurebox
handles = set_options(handles);
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in displayprofilebutton.
function displayprofilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to displayprofilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pop_rerp({}, handles.UserData.current.result{1}.rerp_profile,'view_only',1);


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
    set(handles.tagslist,'Value', handles.UserData.rerp_plot_spec.delay_idx);
    handles.UserData.locksort=1;
else
    set(hObject,'String', 'Locking variable');
    handles.UserData.locksort=0;
    set(handles.tagslist,'Value',handles.UserData.rerp_plot_spec.locking_idx);
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
if length(handles.UserData.current.result)==1
    handles.UserData.current.result{1}.saveRerpResult;
else
    error('rerp_result_gui: can not save multiple results simultaneously');
end
    
% --- Executes on button press in exclude_insignif.
function exclude_insignif_Callback(hObject, eventdata, handles)
% hObject    handle to exclude_insignif (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of exclude_insignif
