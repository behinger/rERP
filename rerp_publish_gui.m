%Allows the user to publish individual graphs by right clicking on a graph
function varargout = rerp_publish_gui(varargin)
% RERP_PUBLISH_GUI MATLAB code for rerp_publish_gui.fig
%      RERP_PUBLISH_GUI, by itself, creates a new RERP_PUBLISH_GUI or raises the existing
%      singleton*.
%
%      H = RERP_PUBLISH_GUI returns the handle to a new RERP_PUBLISH_GUI or the handle to
%      the existing singleton*.
%
%      RERP_PUBLISH_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RERP_PUBLISH_GUI.M with the given input arguments.
%
%      RERP_PUBLISH_GUI('Property','Value',...) creates a new RERP_PUBLISH_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rerp_publish_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rerp_publish_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rerp_publish_gui

% Last Modified by GUIDE v2.5 05-Nov-2013 14:15:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rerp_publish_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @rerp_publish_gui_OutputFcn, ...
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


% --- Executes just before rerp_publish_gui is made visible.
function rerp_publish_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rerp_publish_gui (see VARARGIN)
p=inputParser;
addOptional(p,'hFig', []);
parse(p, varargin{:});
hFig = p.Results.hFig;
assert(~isempty(hFig),'rerp_publish_gui: usage error, rerp_publish_gui_OpeningFcn(''hFig'', h)'); 
set(handles.formatselect,'String', {'eps' 'pdf' 'jpg' 'tif' 'bmp' 'fig' 'png'}, 'Value', 1);

% Choose default command line output for rerp_publish_gui
handles.output = hObject;
handles.UserData.hFig=hFig; 
handles.UserData.pubFig=hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rerp_publish_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = rerp_publish_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function imagewidth_Callback(hObject, eventdata, handles)
% hObject    handle to imagewidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of imagewidth as text
%        str2double(get(hObject,'String')) returns contents of imagewidth as a double


% --- Executes during object creation, after setting all properties.
function imagewidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imagewidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function imageheight_Callback(hObject, eventdata, handles)
% hObject    handle to imageheight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of imageheight as text
%        str2double(get(hObject,'String')) returns contents of imageheight as a double


% --- Executes during object creation, after setting all properties.
function imageheight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imageheight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in formatselect.
function formatselect_Callback(hObject, eventdata, handles)
% hObject    handle to formatselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns formatselect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from formatselect


% --- Executes during object creation, after setting all properties.
function formatselect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to formatselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in publish.
function publish_Callback(hObject, eventdata, handles)
% hObject    handle to publish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

width=str2double(get(handles.imagewidth,'String'));
height=str2double(get(handles.imageheight,'String'));
h= handles.UserData.hFig; 

set(h, 'paperposition', [0 0 width height]); 
contents = get(handles.formatselect,'String');
format = contents{get(handles.formatselect,'Value')}; 


[fn, pn] = uiputfile(['.' format], 'Save image as: ','unnamed');

if strcmp(format,'eps')
    format='epsc';
end

if fn
    saveas(h, fullfile(pn,fn), format);
end

close(h);
close(handles.UserData.pubFig); 


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    delete(handles.UserData.hFig); 
catch 
end
try
    delete(hObject);
catch
end
