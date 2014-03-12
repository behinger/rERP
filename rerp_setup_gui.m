%GUI select datasets and profile to be processed by pop_rerp_study
%A list of profiles
%   Usage:
%       [eeg_dataset_paths, rerp_profile, exitcode] = rerp_setup_gui;
%           Launch
%
function varargout = rerp_setup_gui(varargin)
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
%
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
addOptional(p,'rerp_profile', [], @(x) isa(x,'RerpProfile'));
addOptional(p,'eeg_dataset_paths', {}, @(x) iscell(x));
parse(p, varargin{:});
handles.UserData.eeg_dataset_paths=p.Results.eeg_dataset_paths(:)';
handles.UserData.profiles=struct([]);
handles.UserData.exitcode=0;

if ~isempty(p.Results.rerp_profile)
    handles.UserData.profiles(1).profile = p.Results.rerp_profile;
    handles.UserData.profiles(1).name = 'passed-in';
end

%Get profiles from disk
path=fullfile(RerpProfile.rerp_path, 'profiles');
profiledir=dir(fullfile(path, '*.rerp_profile'));
numpf=length(handles.UserData.profiles);
for i= 1:length(profiledir);
    pfidx=i+numpf;
    %Don't include default.rerp_profile in list, could be misleading
    if ~strcmp(profiledir(i).name,'default.rerp_profile');
        handles.UserData.profiles(pfidx).profile = RerpProfile.loadRerpProfile('path', fullfile(path, profiledir(i).name));
        handles.UserData.profiles(pfidx).name = profiledir(i).name;
    else
        numpf=numpf-1;
    end
    
end

% %If no paths were passed, load one before continuing
% if isempty(handles.UserData.eeg_dataset_paths)
%     try
%         start_path=evalin('base', 'oldp');
%     catch
%         start_path=[];
%     end
%
%     [FileName,PathName] = uigetfile('*.set', 'Select datasets:', start_path ,'MultiSelect','on');
%
%     if ~iscell(FileName)
%         FileName={FileName};
%     end
%
%     if FileName{1}
%         new_dataset_paths=cellfun(@(x) fullfile(PathName, x), FileName, 'UniformOutput', false);
%         handles.UserData.eeg_dataset_paths=unique([handles.UserData.eeg_dataset_paths(:)' new_dataset_paths(:)']);
%     end
% end

%If we have dataset paths, list them, otherwise, return,
if ~isempty(handles.UserData.eeg_dataset_paths)
    set(handles.dataset_list,'String', handles.UserData.eeg_dataset_paths, 'Value', 1:length(handles.UserData.eeg_dataset_paths));
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
    handles.UserData.current_profile=handles.UserData.profiles(get(hObject,'Value')).profile;
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
this_profile=handles.UserData.profiles(get(handles.profiles_list,'Value')).profile;
old_prof = copy(this_profile);
exitcode = rerp_profile_gui(this_profile);

%Cancelled operation, restore old profile
if ~exitcode
    handles.UserData.profiles(get(handles.profiles_list,'Value')).profile=old_prof;
end

% Update handles structure
guidata(handles.output, handles);

% --- Executes on button press in add_profiles.
function add_profiles_Callback(hObject, eventdata, handles)
% hObject    handle to add_profiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[FileName,PathName] = uigetfile('*.rerp_profile;*.rerp_result', 'Select profiles:',...
    fullfile(RerpProfile.rerp_path,'profiles'),'MultiSelect','on');

FileName=cellstr(FileName);
profile_parts=regexp(FileName,'.*\.rerp_profile');
result_parts=regexp(FileName,'.*\.rerp_result');

new_profiles=struct([]);
if FileName{1}
    for i=1:length(FileName)
        if profile_parts{i}
            new_profiles(i).profile=RerpProfile.loadRerpProfile('path',fullfile(PathName, FileName{i}));
            new_profiles(i).name=FileName{i};
        elseif result_parts{i}
            rerp_result = RerpResult.loadRerpResult('path', fullfile(PathName, FileName{i}));
            new_profiles(i).profile = rerp_result.rerp_profile;
            new_profiles(i).name=FileName{i};
        end
    end
end

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
    end
    
    guidata(handles.output, handles);
    
end

% --- Executes on button press in clear_datasets.
function clear_datasets_Callback(hObject, eventdata, handles)
% hObject    handle to clear_datasets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.UserData.eeg_dataset_paths={};
contents = get(handles.dataset_list,'String');

if ~isempty(contents)
    keep_idx = setdiff(1:length(contents), get(handles.dataset_list,'Value'));
    set(handles.dataset_list, 'String', contents(keep_idx));
    set(handles.dataset_list, 'Value', 1);
else
    set(handles.dataset_list, 'String',{});
end

if ~isempty(handles.UserData.eeg_dataset_paths)
    set(handles.generate_default,'Visible','off');
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
handles.UserData.profiles=struct([]);
set(handles.profiles_list, 'String', {},'Value',1);
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

new_profile.profile=RerpProfile.getDefaultProfile(this_dataset);
new_profile.name=strrep(this_dataset.filename,'.set','.rerp_profile');
new_profile.profile.saveRerpProfile('path', fullfile(RerpProfile.rerp_path, 'profiles', new_profile.name));

handles.UserData.profiles=[handles.UserData.profiles new_profile];
set(handles.profiles_list, 'String', {handles.UserData.profiles(:).name});
profiles_list_Callback(handles.profiles_list, eventdata, handles);
