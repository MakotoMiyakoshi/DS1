% simUDL_mainGUI(): A plugin to simulate a forward model.
%
% Author: Makoto Miyakoshi, SCCN,INC,UCSD
%
% History:  
% 02/15/2022 Makoto. Created.

% Copyright (C) 2022, Makoto Miyakoshi (mmiyakoshi@ucsd.edu) , SCCN,INC,UCSD
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.



function varargout = simUDL_mainGUI(varargin)
% SIMUDL_MAINGUI MATLAB code for simUDL_mainGUI.fig
%      SIMUDL_MAINGUI, by itself, creates a new SIMUDL_MAINGUI or raises the existing
%      singleton*.
%
%      H = SIMUDL_MAINGUI returns the handle to a new SIMUDL_MAINGUI or the handle to
%      the existing singleton*.
%
%      SIMUDL_MAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIMUDL_MAINGUI.M with the given input arguments.
%
%      SIMUDL_MAINGUI('Property','Value',...) creates a new SIMUDL_MAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before simUDL_mainGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to simUDL_mainGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help simUDL_mainGUI

% Last Modified by GUIDE v2.5 14-Feb-2022 16:52:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @simUDL_mainGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @simUDL_mainGUI_OutputFcn, ...
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


% --- Executes just before simUDL_mainGUI is made visible.
function simUDL_mainGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to simUDL_mainGUI (see VARARGIN)

% Choose default command line output for simUDL_mainGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes simUDL_mainGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = simUDL_mainGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function conductivitiesEdit_Callback(hObject, eventdata, handles)
% hObject    handle to conductivitiesEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of conductivitiesEdit as text
%        str2double(get(hObject,'String')) returns contents of conductivitiesEdit as a double

bscrVec = str2num(get(handles.conductivitiesEdit, 'string'));
bscr = bscrVec(1)/bscrVec(3);
set(handles.bscrEdit, 'string', num2str(bscr));



% --- Executes during object creation, after setting all properties.
function conductivitiesEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to conductivitiesEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bscrEdit_Callback(hObject, eventdata, handles)
% hObject    handle to bscrEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bscrEdit as text
%        str2double(get(hObject,'String')) returns contents of bscrEdit as a double


% --- Executes during object creation, after setting all properties.
function bscrEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bscrEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function radiiEdit_Callback(hObject, eventdata, handles)
% hObject    handle to radiiEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radiiEdit as text
%        str2double(get(hObject,'String')) returns contents of radiiEdit as a double


% --- Executes during object creation, after setting all properties.
function radiiEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiiEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function coordinateOfHeadCenterEdit_Callback(hObject, eventdata, handles)
% hObject    handle to coordinateOfHeadCenterEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of coordinateOfHeadCenterEdit as text
%        str2double(get(hObject,'String')) returns contents of coordinateOfHeadCenterEdit as a double


% --- Executes during object creation, after setting all properties.
function coordinateOfHeadCenterEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coordinateOfHeadCenterEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in densityOfScelpElectrodesPopupmenu.
function densityOfScelpElectrodesPopupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to densityOfScelpElectrodesPopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns densityOfScelpElectrodesPopupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from densityOfScelpElectrodesPopupmenu


% --- Executes during object creation, after setting all properties.
function densityOfScelpElectrodesPopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to densityOfScelpElectrodesPopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function radiusOfUdlEdit_Callback(hObject, eventdata, handles)
% hObject    handle to radiusOfUdlEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radiusOfUdlEdit as text
%        str2double(get(hObject,'String')) returns contents of radiusOfUdlEdit as a double


% --- Executes during object creation, after setting all properties.
function radiusOfUdlEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiusOfUdlEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function aveIntDipDistEdit_Callback(hObject, eventdata, handles)
% hObject    handle to aveIntDipDistEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of aveIntDipDistEdit as text
%        str2double(get(hObject,'String')) returns contents of aveIntDipDistEdit as a double


% --- Executes during object creation, after setting all properties.
function aveIntDipDistEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aveIntDipDistEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function udlDepthEdit_Callback(hObject, eventdata, handles)
% hObject    handle to udlDepthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of udlDepthEdit as text
%        str2double(get(hObject,'String')) returns contents of udlDepthEdit as a double


% --- Executes during object creation, after setting all properties.
function udlDepthEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to udlDepthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in GenerateDataPushbutton.
function GenerateDataPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to GenerateDataPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Add a path to Gagarinov's spheretri.
fullpathToThisFile = mfilename('fullpath');
[filepath, name, ext] = fileparts(fullpathToThisFile);
addpath([filepath filesep 'external/spheretriByGagarinov']);
disp('Adding the path to shperetri by Gagarinov successfully.')


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Set forward model parameters. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
headmodel = [];
headmodel.type = 'concentricspheres';
headmodel.unit = 'm';
headmodel.r    = str2num(get(handles.radiiEdit, 'string'));
headmodel.o    = str2num(get(handles.coordinateOfHeadCenterEdit, 'string'));
headmodel.cond = str2num(get(handles.conductivitiesEdit, 'string'));

% Create a file for using custom head model parameters.
vol.r = headmodel.r*1000; % Convert from m to mm for EEGLAB.
vol.c = headmodel.cond;
vol.o = headmodel.o;
standardBesaCustomFullpath = [filepath filesep 'standard_BESA_custom.mat'];
save(standardBesaCustomFullpath, 'vol')
disp(['Saving ''vol'' to ' filepath filesep 'standard_BESA_custom.mat successfully.'])


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare a high-resolution electrode montage. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find path to standard-10-5-cap385.elp.
fullpathToDipfitFile = which('dipfit_erpeeg');
[filepath, name, ext] = fileparts(fullpathToDipfitFile);
fullpathToDipfit = filepath;
fullpathToChanlocs1005 = [filepath filesep 'standard_BESA' filesep 'standard-10-5-cap385.elp'];
chanlocs1005 = readlocs(fullpathToChanlocs1005);

% Change the class of Nz to EEG.
chanlocs1005 = chanlocs1005(3:end); % Ch3 is Nz. Cz is 43.
[chanlocs1005.type] = deal('EEG');  % Use Nz as EEG channel, not FID.
elecLabels = {chanlocs1005.labels}';

% Change the spherical radius to the custom length (90 mm).
[chanlocs1005.sph_radius] = deal(headmodel.r(4)*1000);

% Prepare dummy EEG.
EEG = eeg_emptyset;
EEG.nbchan = length(chanlocs1005);
EEG.trials = 1;
EEG.pnts = 1000;
EEG.srate = 1000;
EEG.xmin = 0.001;
EEG.xmax = 1;
EEG.times = 0.001:0.001:1;
EEG.data = zeros(length(chanlocs1005), 1000);
EEG.chanlocs = chanlocs1005;
EEG = pop_chanedit(EEG, 'convert',{'sph2all'});

switch get(handles.densityOfScelpElectrodesPopupmenu, 'value')
    case 1 % 21 channels (10-20 system).
        elecLabelsUsed = {'Fp1','Fpz','Fp2',...
            'F7','F3','Fz','F4','F8',...
            'T7','C3','Cz','C4','T8',...
            'P7','P3','Pz','P4','P8',...
            'O1','Oz','O2'};
        [~, selectingIdx] = intersect(elecLabels, elecLabelsUsed);
        EEG = pop_select(EEG, 'channel', selectingIdx);
        
    case 2
        % 31 channels.
        elecLabelsUsed = {'Fp1','Fpz','Fp2',...
            'F7','F3','Fz','F4','F8',...
            'FT7','FC3','FCz','FC4','FT8',...
            'T7','C3','Cz','C4','T8',...
            'TP7','CP3','CPz','CP4','TP8',...
            'P7', 'P3','Pz','P4','P8',...
            'O1','Oz','O2'};
        [~, selectingIdx] = intersect(elecLabels, elecLabelsUsed);
        EEG = pop_select(EEG, 'channel', selectingIdx);
        
    case 3
        % 64 channels.
        elecLabelsUsed = {'Fp1','Fpz','Fp2',...
            'AF3','AF4',...
            'F7','F5','F3','F1','Fz','F2','F4','F6','F8',...
            'FT9','FT7','FC5','FC3','FC1','FCz','FC2','FC4','FC6','FT8','FT10',...
            'T7','C5','C3','C1','Cz','C2','C4','C6','T8',...
            'TP9','TP7','CP5','CP3','CP1','CPz','CP2','CP4','CP6','TP8','TP10',...
            'P7','P5','P3','P1','Pz','P2','P4','P6','P8',...
            'PO7','PO5','PO3','POz','PO4','PO6','PO8',...
            'O1','Oz','O2'};
        [~, selectingIdx] = intersect(elecLabels, elecLabelsUsed);
        EEG = pop_select(EEG, 'channel', selectingIdx);
        
    case 4 % 85 channels (10-10 system).
        elecLabelsUsed = {'Nz',...
            'Fp1','Fpz','Fp2',...
            'AF7','AF5','AF3','AF1','AFz','AF2','AF4','AF6','AF8',...
            'F9','F7','F5','F3','F1','Fz','F2','F4','F6','F8','F10',...
            'FT9','FT7','FC5','FC3','FC1','FCz','FC2','FC4','FC6','FT8','FT10',...
            'T9','T7','C5','C3','C1','Cz','C2','C4','C6','T8','T10',...
            'TP9','TP7','CP5','CP3','CP1','CPz','CP2','CP4','CP6','TP8','TP10',...
            'P9','P7','P5','P3','P1','Pz','P2','P4','P6','P8','P10',...
            'PO9','PO7','PO5','PO3','PO1','POz','PO2','PO4','PO6','PO8','PO10',...
            'O1','Oz','O2',...
            'I1','Iz','I2'};
        [~, selectingIdx] = intersect(elecLabels, elecLabelsUsed);
        EEG = pop_select(EEG, 'channel', selectingIdx);
        
    case 5 % 141 channels (10-5 system).
        elecLabelsUsed = {'Nz',...
            'Fp1','Fpz','Fp2',...
            'AFp3','AFp4',...
            'AF7','AF5h','AF3h','AFz','AF4h','AF6h','AF8',...
            'AFF7h','AFF5h','AFF3h','AFF1h','AFF2h','AFF4h','AFF6h','AFF8h',...
            'F9','F7','F5','F3','F1','Fz','F2','F4','F6','F8','F10',...
            'FFT9h','FFT7h','FFC5h','FFC1h','FFC2h','FFC4h','FFC6h','FFT8h','FFT10h',...
            'FT9','FT7','FC5','FC3','FC1','FCz','FC2','FC4','FC6','FT8','FT10',...
            'FTT9h','FTT7h','FCC5h','FCC1h','FCC2h','FCC4h','FCC6h','FTT8h','FTT10h',...
            'T9','T7','C5','C3','C1','Cz','C2','C4','C6','T8','T10',...
            'TTP7h','CCP5h','CCP3h','CCP1h','CCP2h','CCP4h','CCP6h','TTP8h',...
            'TP7','CP5','CP3','CP1','CPz','CP2','CP4','CP6','TP8',...
            'TPP9h','TPP7h','CPP5h','CPP3h','CPP1h','CPP2h','CPP4h','CPP6h','TPP8h','TPP10h',...
            'P9','P7','P5','P3','P1','Pz','P2','P4','P6','P8','P10',...
            'PPO9h','PPO7h','PPO5h','PPO3h','PPO1h','PPO2h','PPO4h','PPO6h','PPO8h','PPO10h',...
            'PO9','PO7','PO5h','PO3h','POz','PO4h','PO6h','PO8','PO10',...
            'POO9h','O1','POO3','Oz','POO4','O2','POO10h',...
            'I1','O1h','Iz','O2h','I2'};
        [~, selectingIdx] = intersect(elecLabels, elecLabelsUsed);
        EEG = pop_select(EEG, 'channel', selectingIdx);
        
    case 6 % 346 channels (use all except occular locations.)
        selectingIdx = 1:length(chanlocs1005)-10;
        EEG = pop_select(EEG, 'channel', selectingIdx);
        
    case 7 % Use spherical surface triangulation by Gagarinov to generate electrode locations.
        [vMat, fMat] = spheretri(2500);
            %{
            figure
            patch('Vertices',vMat,'Faces',fMat,'FaceColor','g','EdgeColor','k');
            axis equal
            %}
        
        % Scale the electrode locations to the model (i.e. 0.092 m from the center of the sphere)
        vMat_scaled = vMat*headmodel.r(4);
        elecPos = vMat_scaled*1000; % In mm.
        
        % Calculate the mean distance: 'Distance to the neighboring electrodes, M = 6.7 mm (SD 0.3)'
        minDistVec = zeros(size(fMat,1),1);
        for faceIdx = 1:size(fMat,1)
            currentFaceIdx = fMat(faceIdx,:);
            currentXyzTriangle = [elecPos(currentFaceIdx(1),:); ...
                elecPos(currentFaceIdx(2),:); ...
                elecPos(currentFaceIdx(3),:)];
            edgeLengths = [sqrt(sum([currentXyzTriangle(1,:)-currentXyzTriangle(2,:)].^2)) ...
                sqrt(sum([currentXyzTriangle(1,:)-currentXyzTriangle(3,:)].^2)) ...
                sqrt(sum([currentXyzTriangle(2,:)-currentXyzTriangle(3,:)].^2))];
            minDistVec(faceIdx,:) = mean(edgeLengths); % Identical anyway.
        end
        sprintf('Average distance to the neighboring electrodes, M = %.1f mm (SD %.1f)', mean(minDistVec), std(minDistVec))  

        % Build a chanloc structure.
        chanlocsSpheretri = [];
        for chanIdx = 1:size(elecPos,1)
            chanlocsSpheretri(chanIdx).type       = 'EEG';
            chanlocsSpheretri(chanIdx).labels     = sprintf('ch%04d', chanIdx);
            chanlocsSpheretri(chanIdx).sph_radius = [];
            chanlocsSpheretri(chanIdx).sph_theta  = [];
            chanlocsSpheretri(chanIdx).sph_phi    = [];
            chanlocsSpheretri(chanIdx).theta      = [];
            chanlocsSpheretri(chanIdx).radius     = [];
            chanlocsSpheretri(chanIdx).X = elecPos(chanIdx,1);
            chanlocsSpheretri(chanIdx).Y = elecPos(chanIdx,2);
            chanlocsSpheretri(chanIdx).Z = elecPos(chanIdx,3);
            chanlocsSpheretri(chanIdx).ref    = '';
            chanlocsSpheretri(chanIdx).urchan = [];
        end
        
        % Use only upper half of the sphere.
        upperHalfSphereElectrodeIdx = find(elecPos(:,3)>=0);
        chanlocsSpheretri = chanlocsSpheretri(upperHalfSphereElectrodeIdx);

        % Store it to EEGLAB.
        EEG.nbchan = length(chanlocsSpheretri);
        EEG.data = zeros(EEG.nbchan, EEG.pnts);
        EEG.chanlocs = chanlocsSpheretri;
        EEG = pop_chanedit(EEG, 'convert',{'cart2all'});
end

% Convert the electrode information to Fieldtrip format.
elec = [];
elec.unit = 'm';
elec.elecpos = [[EEG.chanlocs.X]' [EEG.chanlocs.Y]' [EEG.chanlocs.Z]']/1000; % Convert from mm to m.
for i=1:size(elec.elecpos,1)
    elec.label{i} = sprintf('%03d', i);
end

    %{
    figure
    ft_plot_sens(elec, 'elecsize', 20);
    ft_plot_headmodel(headmodel); % ft_plot_vol() is deplicated.
    ft_plot_axes(headmodel); % this plots 10 cm long axes for x/y/z (red, green, blue) and a 1 cm sphere at [0 0 0]
    view([1 1 1])
    camlight
    rotate3d % zoom in and you will see the electrodes on the top of the sphere
    %}

% Obtain the vertexChanIdx.
[~,vertexChanIdx]  = max(elec.elecpos(:,3));
elec.elecpos(vertexChanIdx,:); % Confirm the output is [0 0 0.090].


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Coregister the electrodes to the CUSTOM head model. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EEG = pop_dipfit_settings(EEG, 'hdmfile',  standardBesaCustomFullpath,...,...
                               'mrifile',  [fullpathToDipfit filesep 'standard_BESA' filesep 'avg152t1.mat'],...
                               'chanfile', [fullpathToDipfit filesep 'standard_BESA' filesep 'standard-10-5-cap385.elp'],...
                               'coordformat','Spherical', 'coord_transform', [0 0 0 0 0 0 0.9444 0.9444 0.9444], 'chansel', 1:EEG.nbchan);


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Generate a spherical radial vectors for a uniform dipole layer (UDL).%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Obtain the UDL depth.
udlDepthFromGrayMatterSurface = 0.002;

% Use spherical surface triangulation by Gagarinov to generate electrode locations.
[vMat, fMat] = spheretri(40000);
    %{
    figure
    patch('Vertices',vMat,'Faces',fMat,'FaceColor','g','EdgeColor','k');
    axis equal
    %}

% Obtain the uniform dipole layer at the fixed depth of 2mm.
udlRadius = headmodel.r(1)-udlDepthFromGrayMatterSurface;
vMat_scaled = vMat*udlRadius;
dipX = vMat_scaled(:,1);
dipY = vMat_scaled(:,2);
dipZ = vMat_scaled(:,3);
dipPos = vMat_scaled';

    %{
    % Calculate the mean distance: 'Distance to the neighboring electrodes, M = 1.5 mm (SD 0.1)'
    minDistVec = zeros(size(fMat,1),1);
    for faceIdx = 1:size(fMat,1)
        currentFaceIdx = fMat(faceIdx,:);
        currentXyzTriangle =   [dipPos(currentFaceIdx(1),:); ...
                                dipPos(currentFaceIdx(2),:); ...
                                dipPos(currentFaceIdx(3),:)];
        edgeLengths =  [sqrt(sum([currentXyzTriangle(1,:)-currentXyzTriangle(2,:)].^2)) ...
                        sqrt(sum([currentXyzTriangle(1,:)-currentXyzTriangle(3,:)].^2)) ...
                        sqrt(sum([currentXyzTriangle(2,:)-currentXyzTriangle(3,:)].^2))];
        minDistVec(faceIdx,:) = mean(edgeLengths); % Identical anyway.
    end
    sprintf('Distance to the neighboring electrodes, M = %.1f mm (SD %.1f)', mean(minDistVec)*1000, std(minDistVec)*1000)
    %}


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Select a subset of dipoles to form a disk-shaped UDL. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convert Cartegian to spherical.
[theta1, phi1] = cart2sph(dipPos(1,:), dipPos(2,:), dipPos(3,:));

% Wikipedia's theta is Matlab's pi/2-PHI, Wikipedia's phi is Matlab's TH.
theta2 = pi/2-phi1;
phi2   = theta1;

% Obtain the coefficient to convert radian to arc length.
arcLength = theta2/(2*pi)*(2*pi)*udlRadius; % m.

% Find dipoles within X m distance on the surface of the dipole sheet sphere.
dispUdlRadius     = str2num(get(handles.radiusOfUdlEdit, 'string'));; % m.
selectedDipoleIdx = find(arcLength<=dispUdlRadius);

% Select dipoles.
udlPos = dipPos(:,selectedDipoleIdx);

% Determine dipole moments for the dipoles in the shell.
udlMom = udlPos/udlRadius;

    %{
    patchAreaInSquareCm   = (dispUdlRadius*(10^2))^2*pi;
    numDipolesPerSquareCm = length(selectedDipoleIdx)/patchAreaInSquareCm; % dipole count per cm^2.

    patchAreaInSquareMm   = (dispUdlRadius*(10^3))^2*pi;
    numDipolesPerSquareMm = length(selectedDipoleIdx)/patchAreaInSquareMm; % dipole count per mm^2.
    %}


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Shifts down the UDL along with z-axis. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
udlPos(3,:) = udlPos(3,:)-[str2num(get(handles.udlDepthEdit, 'string'))-udlDepthFromGrayMatterSurface];


%% Set a dipole and compute leadfield (V/Am)
lfUDL_matrix = zeros(size(elec.elecpos,1), size(udlPos,2));
processingTimeVec = nan(size(udlPos,2),1);
for dipIdx = 1:size(udlPos,2)
    
    tStart = tic;
    
    currentDipPos = udlPos(:,dipIdx)'; % POS is a row vector!
    currentDipMom = udlMom(:,dipIdx);  % DIP is a column vector! (02/07/2022 Makoto)
    
    lf = ft_compute_leadfield(currentDipPos, elec, headmodel)*currentDipMom;
    lfUDL_matrix(:,dipIdx) = lf;
    
    tElapsed = toc(tStart);
    processingTimeVec(dipIdx) = tElapsed;
    disp(sprintf('%d/%d, remaining %.1f min', dipIdx, size(udlPos,2),...
        nanmedian(processingTimeVec)*(size(udlPos,2)-dipIdx)/60))
end

% Dipole moment is 1 nA*m.
leadfieldMatrix = lfUDL_matrix; % uV/(nA*m) so that when multiplied with dipole moment you obtain uV.

% The V/(A*m) SI units can be multiplied with 0.001 to get uV/(nA*m)
lfmScalingFactor = ft_scalingfactor('V/(A*m)', 'uV/(nA*m)');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Store the results. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
EEG.setname = 'UDL simulation';
EEG.comments = sprintf('UDL disc radius, %dm; Depth, %dm', dispUdlRadius, str2num(get(handles.udlDepthEdit, 'string')));
EEG.etc.simUDL.headmodel  = headmodel;
EEG.etc.simUDL.vol        = vol;
EEG.etc.simUDL.dipPosUnit = 'm';
EEG.etc.simUDL.dipMomUnit = 'nA*m'; 
EEG.etc.simUDL.udlRadius = dispUdlRadius;
EEG.etc.simUDL.udlPos    = udlPos;
EEG.etc.simUDL.udlMom    = udlMom;
EEG.etc.simUDL.originalUdlDepth    = udlDepthFromGrayMatterSurface;
EEG.etc.simUDL.userDefinedUdlDepth = str2num(get(handles.udlDepthEdit, 'string'));
EEG.etc.simUDL.leadfieldMatrix  = leadfieldMatrix;
EEG.etc.simUDL.lfmScalingFactor = lfmScalingFactor;
EEG.etc.simUDL.elec = elec;
assignin('base', 'EEG', EEG)

% Refresh the screens.
close
eeglab redraw