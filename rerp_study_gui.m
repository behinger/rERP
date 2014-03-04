function varargout = rerp_study_gui(varargin)
% RERP_STUDY_GUI MATLAB code for rerp_study_gui.fig
%      RERP_STUDY_GUI, by itself, creates a new RERP_STUDY_GUI or raises the existing
%      singleton*.
%
%      H = RERP_STUDY_GUI returns the handle to a new RERP_STUDY_GUI or the handle to
%      the existing singleton*.
%
%      RERP_STUDY_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RERP_STUDY_GUI.M with the given input arguments.
%
%      RERP_STUDY_GUI('Property','Value',...) creates a new RERP_STUDY_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rerp_study_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rerp_study_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rerp_study_gui

% Last Modified by GUIDE v2.5 03-Mar-2014 19:21:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rerp_study_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @rerp_study_gui_OutputFcn, ...
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


% --- Executes just before rerp_study_gui is made visible.
function rerp_study_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rerp_study_gui (see VARARGIN)

% Choose default command line output for rerp_study_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rerp_study_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = rerp_study_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in dataset_list.
function dataset_list_Callback(hObject, eventdata, handles)
% hObject    handle to dataset_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dataset_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dataset_list


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


% --- Executes on button press in add_profiles.
function add_profiles_Callback(hObject, eventdata, handles)
% hObject    handle to add_profiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in run.
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in add_datasets.
function add_datasets_Callback(hObject, eventdata, handles)
% hObject    handle to add_datasets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
