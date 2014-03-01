function varargout = rerp_profile_advanced_gui(varargin)
%RERP_PROFILE_ADVANCED_GUI M-file for rerp_profile_advanced_gui.fig
%      RERP_PROFILE_ADVANCED_GUI, by itself, creates a new RERP_PROFILE_ADVANCED_GUI or raises the existing
%      singleton*.
%
%      H = RERP_PROFILE_ADVANCED_GUI returns the handle to a new RERP_PROFILE_ADVANCED_GUI or the handle to
%      the existing singleton*.
%
%      RERP_PROFILE_ADVANCED_GUI('Property','Value',...) creates a new RERP_PROFILE_ADVANCED_GUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to rerp_profile_advanced_gui_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      RERP_PROFILE_ADVANCED_GUI('CALLBACK') and RERP_PROFILE_ADVANCED_GUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in RERP_PROFILE_ADVANCED_GUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rerp_profile_advanced_gui

% Last Modified by GUIDE v2.5 28-Feb-2014 20:01:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rerp_profile_advanced_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @rerp_profile_advanced_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before rerp_profile_advanced_gui is made visible.
function rerp_profile_advanced_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)
p=inputParser;
addOptional(p,'rerp_profile', []);
parse(p, varargin{:});
handles.UserData.rerp_profile = p.Results.rerp_profile; 
handles.Userdata.old_settings=p.Results.rerp_profile.settings;
set(handles.elastic_net_quick_zoom,'Value',handles.UserData.rerp_profile.settings.elasticnet_quick_zoom);

try
    lambdastr=num2str(handles.UserData.rerp_profile.settings.first_phase_lambda(:)'); 
    set(handles.first_phase_lambda, 'String', lambdastr); 
catch
end

try
    set(handles.num_grid_points, 'String', num2str(handles.UserData.rerp_profile.settings.num_grid_points)); 
catch
end

try
    set(handles.num_grid_zoom_levels, 'String', num2str(handles.UserData.rerp_profile.settings.num_grid_zoom_levels)); 
catch
end

try
    set(handles.num_xvalidation_folds, 'String', num2str(handles.UserData.rerp_profile.settings.num_xvalidation_folds)); 
catch
end

% Choose default command line output for rerp_profile_advanced_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rerp_profile_advanced_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = rerp_profile_advanced_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function first_phase_lambda_Callback(hObject, eventdata, handles)
% hObject    handle to first_phase_lambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of first_phase_lambda as text
%        str2double(get(hObject,'String')) returns contents of first_phase_lambda as a double

lambda=str2double (get(hObject, 'String'));
try
    handles.UserData.rerp_profile.settings.first_phase_lambda = lambda(:);
catch
    set(hObject, 'String', num2str(handles.UserData.rerp_profile.settings.first_phase_lambda)); 
end

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function first_phase_lambda_CreateFcn(hObject, eventdata, handles)
% hObject    handle to first_phase_lambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function num_grid_points_Callback(hObject, eventdata, handles)
% hObject    handle to num_grid_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_grid_points as text
%        str2double(get(hObject,'String')) returns contents of num_grid_points as a double
try
    num_grid_points = str2double (get(hObject, 'String'));
    assert(length(num_grid_points)==1); 
    handles.UserData.rerp_profile.settings.num_grid_points = num_grid_points;
catch
    set(hObject, 'String', num2str(handles.UserData.rerp_profile.settings.num_grid_points)); 
end

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function num_grid_points_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_grid_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function num_grid_zoom_levels_Callback(hObject, eventdata, handles)
% hObject    handle to num_grid_zoom_levels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_grid_zoom_levels as text
%        str2double(get(hObject,'String')) returns contents of num_grid_zoom_levels as a double
try
    num_grid_zoom_levels = str2double (get(hObject, 'String'));
    assert(length(num_grid_zoom_levels)==1); 
    handles.UserData.rerp_profile.settings.num_grid_zoom_levels = num_grid_zoom_levels;
catch
    set(hObject, 'String', num2str(handles.UserData.rerp_profile.settings.num_grid_zoom_levels)); 
end
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function num_grid_zoom_levels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_grid_zoom_levels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in elastic_net_quick_zoom.
function elastic_net_quick_zoom_Callback(hObject, eventdata, handles)
% hObject    handle to elastic_net_quick_zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    handles.UserData.rerp_profile.settings.elasticnet_quick_zoom=get(hObject, 'Value'); 
catch 
end
% Update handles structure
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of elastic_net_quick_zoom


% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.output);


% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.UserData.rerp_profile.settings=handles.Userdata.old_settings; 
close(handles.output); 



function num_xvalidation_folds_Callback(hObject, eventdata, handles)
% hObject    handle to num_xvalidation_folds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_xvalidation_folds as text
%        str2double(get(hObject,'String')) returns contents of num_xvalidation_folds as a double
try
    num_xvalidation_folds = str2double (get(hObject, 'String'));
    assert(length(num_xvalidation_folds)==1); 
    handles.UserData.rerp_profile.settings.num_xvalidation_folds = num_xvalidation_folds;
catch
    set(hObject, 'String', num2str(handles.UserData.rerp_profile.settings.num_xvalidation_folds)); 
end

% --- Executes during object creation, after setting all properties.
function num_xvalidation_folds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_xvalidation_folds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
