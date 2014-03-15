%GUI select datasets and profile to be processed by pop_rerp_study
%A list of profiles
%   Usage:
%       [eeg_dataset_paths, rerp_profiles, exitcode] = rerp_setup_gui;
%           Launch
%
function varargout = rerp_setup_gui(varargin)
% RERP_SETUP_GUI MATLAB code for rerp_setup_gui.fig
%      RERP_SETUP_GUI, by itself, creates a new RERP_SETUP_GUI or raises the existing
%      singleton*.
%
%      H = RERP_SETUP_GUI returns the handle to a new RERP_SETUP_GUI or the handle to
%      the existing singleton*.
%
%      RERP_SETUP_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RERP_SETUP_GUI.M with the given input arguments.
%
%      RERP_SETUP_GUI('Property','Value',...) creates a new RERP_SETUP_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rerp_setup_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rerp_setup_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rerp_setup_gui

% Last Modified by GUIDE v2.5 10-Mar-2014 13:47:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @rerp_setup_gui_OpeningFcn, ...
    'gui_OutputFcn',  @rerp_setup_gui_OutputFcn, ...
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


% --- Executes just before rerp_setup_gui is made visible.
function rerp_setup_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rerp_setup_gui (see VARARGIN)

p=inputParser;
addOptional(p,'rerp_profiles', {}, @(x) iscell(x));
addOptional(p,'eeg_dataset_paths', {}, @(x) iscell(x));
parse(p, varargin{:});
handles.UserData.eeg_dataset_paths=p.Results.eeg_dataset_paths(:)';
handles.UserData.profiles=struct([]);
handles.UserData.exitcode=0;

%If profiles were passed in
for i=1:length(p.Results.rerp_profiles)
        handles.UserData.profiles(i) = p.Results.rerp_profile;
        handles.UserData.profiles(i).name = ['profile ' num2str(i)];
end

%Get profiles from disk
path=fullfile(RerpProfile.rerp_path, 'profiles');
if isdir(path)
    handles.UserData.profiles=RerpProfile.loadRerpProfile('path', path); 
    isdefault=strcmp({handles.UserData.profiles(:).name}, 'default.rerp_profile'); 
    %Skip default profile
    handles.UserData.profiles=handles.UserData.profiles(~isdefault); 
end

%If we have dataset paths, list them, otherwise, return,
if ~isempty(handles.UserData.eeg_dataset_paths)
    set(handles.dataset_list,'String', handles.UserData.eeg_dataset_paths, 'Value', 1:length(handles.UserData.eeg_dataset_paths));
    handles.UserData.current_path=handles.UserData.eeg_dataset_paths;
end

if ~isempty(handles.UserData.profiles)
    set(handles.profiles_list, 'String', {handles.UserData.profiles(:).name}, 'Value', 1);
end

% Choose default command line output for rerp_setup_gui
handles.output = hObject;
handles.UserData.exitcode=0;

% Update handles structure
profiles_list_Callback(handles.profiles_list, eventdata, handles);
handles = guidata(hObject);
dataset_list_Callback(handles.dataset_list, eventdata, handles);

% UIWAIT makes rerp_setup_gui wait for user response (see UIRESUME)
uiwait(handles.output);


% --- Outputs from this function are returned to the command line.
function varargout = rerp_setup_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles)
    varargout{1}=handles.UserData.current_path;
    varargout{2}=handles.UserData.current_profile;
    varargout{3}=handles.UserData.exitcode;
    close(handles.output);
else
    varargout{1}=[];
    varargout{2}=[];
    varargout{3}=0;
end
drawnow;


% --- Executes on selection change in dataset_list.
function dataset_list_Callback(hObject, eventdata, handles)
% hObject    handle to dataset_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dataset_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dataset_list
contents = cellstr(get(hObject,'String'));
handles.UserData.current_path=contents(get(hObject,'Value'))';
% Update handles structure
guidata(handles.output, handles);


% --- Executes during object creation, after setting all properties.
function dataset_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataset_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in profiles_list.
function profiles_list_Callback(hObject, eventdata, handles)
% hObject    handle to profiles_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns profiles_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from profiles_list
if ~isempty(handles.UserData.profiles)
    handles.UserData.current_profile=handles.UserData.profiles(get(hObject,'Value'));
end

% Update handles structure
guidata(handles.output, handles);


% --- Executes during object creation, after setting all properties.
function profiles_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to profiles_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in edit_profile.
function edit_profile_Callback(hObject, eventdata, handles)
% hObject    handle to edit_profile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(handles.profiles_list,'Value');
if ~isempty(val)
    if length(val) > 1
        warning('rerp_setup_gui: can only edit one profile at a time');
    end
    this_profile=handles.UserData.profiles(val(1));
    set(handles.profiles_list,'Value', val(1))
    old_prof = copy(this_profile);
    exitcode = rerp_profile_gui(this_profile);
end
%Cancelled operation, restore old profile
if ~exitcode
    handles.UserData.profiles(val(1))=old_prof;
end

% Update handles structure
guidata(handles.output, handles);

% --- Executes on button press in add_profiles.
function add_profiles_Callback(hObject, eventdata, handles)
% hObject    handle to add_profiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Load profile GUI
new_profiles = RerpProfile.loadRerpProfile;

handles.UserData.profiles = [handles.UserData.profiles new_profiles];
set(handles.profiles_list, 'String', {handles.UserData.profiles(:).name});
profiles_list_Callback(handles.profiles_list, eventdata, handles);

% Update handles structure
guidata(handles.output, handles);

% --- Executes on button press in run.
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.UserData.exitcode=1;
% Update handles structure
guidata(handles.output, handles);
uiresume(handles.output);


% --- Executes on button press in add_datasets.
function add_datasets_Callback(hObject, eventdata, handles)
% hObject    handle to add_datasets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.UserData.eeg_dataset_paths)
    start_path = handles.UserData.eeg_dataset_paths{1};
    start_path = regexp(start_path, '(.*)[\\\/].*\.set','tokens');
    start_path = start_path{1}{1};
else
    start_path = [];
end

[FileName,PathName] = uigetfile('*.set', 'Select datasets:',start_path,'MultiSelect','on');

if ~iscell(FileName)
    FileName={FileName};
end

if FileName{1}
    new_dataset_paths=cellfun(@(x) fullfile(PathName, x), FileName, 'UniformOutput', false);
    handles.UserData.eeg_dataset_paths=unique([handles.UserData.eeg_dataset_paths(:)' new_dataset_paths(:)']);
    
    if ~isempty(handles.UserData.eeg_dataset_paths)
        set(handles.dataset_list,'String', handles.UserData.eeg_dataset_paths, 'Value', 1:length(handles.UserData.eeg_dataset_paths));
        handles.UserData.current_path=handles.UserData.eeg_dataset_paths;
    end
    
    guidata(handles.output, handles);
    
end

% --- Executes on button press in clear_datasets.
function clear_datasets_Callback(hObject, eventdata, handles)
% hObject    handle to clear_datasets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = get(handles.dataset_list, 'String');

if ~isempty(contents)
    keep_idx = setdiff(1:length(contents), get(handles.dataset_list,'Value'));
    set(handles.dataset_list, 'String', contents(keep_idx));
    set(handles.dataset_list, 'Value', keep_idx);
else
    set(handles.dataset_list, 'String',{});
end

dataset_list_Callback(handles.dataset_list, eventdata, handles);


% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.output);


% --- Executes on button press in clear_profiles.
function clear_profiles_Callback(hObject, eventdata, handles)
% hObject    handle to clear_profiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = get(handles.profiles_list, 'String');

if ~isempty(contents)
    keep_idx = setdiff(1:length(contents), get(handles.profiles_list,'Value'));
    set(handles.profiles_list, 'String', contents(keep_idx));
    set(handles.profiles_list, 'Value', keep_idx);
else
    set(handles.profiles_list, 'String',{}, 'value',1);
end
profiles_list_Callback(handles.profiles_list, eventdata, handles);

% --- Executes on button press in make_profile.
function make_profile_Callback(hObject, eventdata, handles)
% hObject    handle to make_profile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents=cellstr(get(handles.dataset_list, 'String'));
paths=contents(get(handles.dataset_list, 'Value'));
pathparts=regexp(paths{1},'(.*)[\\\/](.*\.set)','tokens');
if ~isempty(paths)
    this_dataset=pop_loadset('filename',pathparts{1}{2},'filepath',pathparts{1}{1}, 'loadmode', 'info');
else
    return;
end

new_profile=RerpProfile.getDefaultProfile(this_dataset);
new_profile.name=strrep(this_dataset.filename,'.set','.rerp_profile');
new_profile.saveRerpProfile('path', fullfile(RerpProfile.rerp_path, 'profiles', new_profile.name));

handles.UserData.profiles=[handles.UserData.profiles new_profile];
set(handles.profiles_list, 'String', {handles.UserData.profiles(:).name});
profiles_list_Callback(handles.profiles_list, eventdata, handles);
