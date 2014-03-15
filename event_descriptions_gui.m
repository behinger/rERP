%Edit descriptons of event types in a GUI 
%   Usage:
%       event_descriptions = event_descriptions_gui('event_types', event_types);
%       event_descriptions = event_descriptions_gui('event_types', event_types, 'event_descriptions', event_descriptions);
%
%   Parameters:
%       event_types:
%           Cell array of event type strings
%       
%       event_descriptions:
%           Cell array of descriptions
function varargout = event_descriptions_gui(varargin)
% EVENT_DESCRIPTIONS_GUI MATLAB code for event_descriptions_gui.fig
%      EVENT_DESCRIPTIONS_GUI, by itself, creates a new EVENT_DESCRIPTIONS_GUI or raises the existing
%      singleton*.
%
%      H = EVENT_DESCRIPTIONS_GUI returns the handle to a new EVENT_DESCRIPTIONS_GUI or the handle to
%      the existing singleton*.
%
%      EVENT_DESCRIPTIONS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EVENT_DESCRIPTIONS_GUI.M with the given input arguments.
%
%      EVENT_DESCRIPTIONS_GUI('Property','Value',...) creates a new EVENT_DESCRIPTIONS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before event_descriptions_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to event_descriptions_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help event_descriptions_gui

% Last Modified by GUIDE v2.5 13-Mar-2014 23:20:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @event_descriptions_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @event_descriptions_gui_OutputFcn, ...
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


% --- Executes just before event_descriptions_gui is made visible.
function event_descriptions_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to event_descriptions_gui (see VARARGIN)
p=inputParser;
addOptional(p,'event_types', {}, @(x) iscell(x));
addOptional(p,'event_descriptions', {}, @(x) iscell(x));
parse(p, varargin{:});
handles.UserData.exitcode=0;
set(handles.table,...
    'Data', p.Results.event_descriptions(:),...
    'ColumnName','Brief Description',... 
    'RowName',p.Results.event_types,...
    'columnwidth', {210},...
    'columnformat', {'char'},...
    'columneditable', true,...
    'BackgroundColor', [.67 .77 1; .7 .7 .7]); 
                
% Choose default command line output for event_descriptions_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes event_descriptions_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = event_descriptions_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles)
    varargout{1} = get(handles.table, 'Data')';
    varargout{2} = handles.UserData.exitcode;
    close(handles.output); 
else
    varargout{1} = {};
    varargout{2} = 0;
end


% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.UserData.exitcode=1; 
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1); 


% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1); 
