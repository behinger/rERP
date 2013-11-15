% Collection of methods for analysis and visualization of neurophysiological time series data.
%
% Usage:
%         Fs = 512;           % Sampling rate
%         T = 1/Fs;           % Sample time
%         L = 10000;          % Length of signal
%         t = (0:L-1)*T;      % Time vector
%         t = t(:);           % time must be a vector column  
%
%         % Sum of a 10 Hz sinusoid and a 60 Hz sinusoid
%         x = sin(2*pi*10*t) + 0.7*sin(2*pi*60*t); 
%         data = x + 2*randn(size(t));     % Sinusoids plus noise
%
%         % Constructing the time series object
%         obj = timeSeries(data,t,{'Channel x'},Fs);
%
%         % Plot
%         plot(obj);
%
%         % Spectrum
%         method = 'welch';
%         channels = 1;
%         plotFlag = true;
%         [psdData,frequency] = spectrum(obj, method, channels, plotFlag);
%
%         % Time Frequency Decomposition
%         wname = 'cmor1-1.5'; 
%         fmin = 2;
%         fmax = 100;
%         numFreq = 64;
%         plotFlag = true; 
%         [coefficients,powerDB,angle,frequency,time] = waveletTimeFrequencyAnalysis(obj,wname,fmin,fmax,numFreq,plotFlag);
%
% License:
%     This file is covered by the BSD license.
%
% Copyright (c) 2013, Alejandro Ojeda, Syntrogi, Inc.
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without modification,
% are permitted provided that the following conditions are met:
% 
%   Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
%   Redistributions in binary form must reproduce the above copyright notice, this
%   list of conditions and the following disclaimer in the documentation and/or
%   other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


classdef timeSeries
    properties
        data
        time
        label
        samplingRate
        numberOfChannels
    end
    methods
        function obj = timeSeries(data,time,label,samplingRate)
            if size(data,1) && ~iscellstr(label), error('label must be a cell array of strings.');end
            if size(data,1) ~= length(time) || size(data,2) ~= length(label), error('Dimensions must agree.');end
            obj.data = data;
            obj.time = time;
            obj.label = label;
            obj.samplingRate = samplingRate;
            obj.numberOfChannels = size(data,2);
        end
        function h = plot(obj)
            mu = median(obj.data);
            sigma = median(std(obj.data));
            ytick = fliplr(1:length(obj.label))*sigma;
            x = obj.data - ones(length(obj.time),1)*mu;
            x = x + ones(length(obj.time),1)*ytick;
            h = figure;
            plot(obj.time,x);
            [~,loc] = sort(ytick);
            set(gca,'yTick',ytick(loc),'yticklabel',obj.label(loc));
            grid on;
            xlabel('Time (sec)');
        end
        function h = plotRaw(obj)
            h = figure;
            plot(obj.time,obj.data);
            grid on;
            xlabel('Time (sec)');
        end
        function obj = filtfilt(obj,b,a)
            obj.data = filtfilt(b,a,obj.data);
        end
        function [b, hFigure] = firDesign(obj,order,varargin)
            if nargin < 2, error('Not enough input arguments.');end
            N    = round(order/2)*2; % Filter order
            flag = 'scale';          % Sampling Flag
            win  = hann(N+1);        % Create a Hann window
            filterType = lower(varargin{1});
            if length(varargin) > 2, plotFreqz = varargin{3}; else plotFreqz = false;end
            switch filterType
                case 'lowpass'
                    if length(varargin{2}) ~= 1, error('The second argument must be a number with the cutoff frequency.');end
                    Fpass = varargin{2};     % Passband Frequency
                    b     = fir1(N, Fpass/(obj.samplingRate/2), 'low', win, flag); % Calculate the coefficients using the FIR1 function.
                    
                case 'highpass'
                    if length(varargin{2}) ~= 1, error('The second argument must be a number with the cutoff frequency.');end
                    Fpass = varargin{2};    % Passband Frequency
                    b     = fir1(N, Fpass/(obj.samplingRate/2), 'high', win, flag);
                    
                case 'bandpass'
                    if length(varargin{2}) ~= 2, error('The second argument must be a vector with the cutoff frequencies (e.g., [Fc1 Fc2])');end
                    Fpass1 = varargin{2}(1);  % First Passband Frequency
                    Fpass2 = varargin{2}(2);  % Second Passband Frequency
                    b      = fir1(N, [Fpass1 Fpass2]/(obj.samplingRate/2), 'bandpass', win, flag);
                    
                case 'bandstop'
                    if length(varargin{2}) ~= 2, error('Bandstop filter needs two cutoff frequencies (e.g., [Fstop1 Fstop2])');end
                    Fstop1 = varargin{2}(1);  % First Stopband Frequency
                    Fstop2 = varargin{2}(2);  % Second Stopband Frequency
                    b      = fir1(N, [Fstop1 Fstop2]/(obj.samplingRate/2), 'stop', win, flag);
                    
                otherwise, error('Invalid type of filter. Try one of these: ''lowpass'', ''highpass'', ''bandpass'', or ''bandstop''.');
            end
            hFigure = [];
            if plotFreqz
                hFigure = figure('MenuBar','none','Toolbar','figure','userData',1);
                freqz(b,1,[],obj.samplingRate);
            end
        end
        function [psdData,frequency] = spectrum(obj,varargin)
            if length(varargin) < 1, method = 'welch';else method = varargin{1};end
            if length(varargin) < 2, channels = 1:obj.numberOfChannels;else channels = varargin{2};end
            if length(varargin) < 3, plotFlag = false;else plotFlag = varargin{3};end
            
            channels(channels<1 | channels > obj.numberOfChannels) = [];
            Hs = eval(['spectrum.' method ';']);
            switch method
                case 'welch',       Hs.SegmentLength = obj.samplingRate*2;
                case 'mtm',         Hs.TimeBW = 3.5;
                case 'yulear',      Hs.Order = 128;
                case 'periodogram', Hs.WindowName = 'Hamming';
            end
            Nch = length(channels);
            fmin = 1;
            fmax = obj.samplingRate/2-mod(obj.samplingRate/2,10);
            disp('Computing PSD...');
            psdObj = Hs.psd(obj.data(:,channels(1)),'Fs',obj.samplingRate,'NFFT',2048);
            [~,loc1] = min(abs(psdObj.frequencies-fmin));
            [~,loc2] = min(abs(psdObj.frequencies-fmax));
            frequency = psdObj.frequencies(loc1:loc2);
            psdData = psdObj.Data(loc1:loc2);
            psdData = [psdData zeros(length(psdData),Nch-1)];
            for it=2:Nch
                psdObj = Hs.psd(obj.data(:,channels(it)),'Fs',obj.samplingRate,'NFFT',2048);
                psdData(:,it) = psdObj.Data(loc1:loc2);
            end
            if plotFlag
                figure;
                h = plot(frequency,10*log10(psdData),'ButtonDownFcn','get(gco,''userData'')','LineSmoothing','on');
                tmpLabels = obj.label(channels(:));
                set(h(:),{'userData'},flipud(tmpLabels(:)));
                ylabel('Power/frequency (dB/Hz)')
                xlabel('Frequency (Hz)')
                title([Hs.estimationMethod ' Power Spectral Density Estimate']);
                grid on;
            end
        end
        function [coefficients,powerDB,angle,frequency,time] = waveletTimeFrequencyAnalysis(obj,wname,fmin,fmax,numFreq,plotFlag,numberOfBoundarySamples)
            import rerp_dependencies.*
            
            T = diff(obj.time([1 2]));
            if nargin < 2, wname = 'cmor1-1.5';end
            if nargin < 3, fmin = 2;end
            if nargin < 4, fmax = 1/T/2;end
            if nargin < 5, numFreq = 64;end
            if nargin < 6, plotFlag = true;end
            if nargin < 7, numberOfBoundarySamples = 0;end
                        
            data      = obj.data; %#ok
            dim       = size(obj.data);
            data      = reshape(data,[size(data,1) prod(dim(2:end))]);%#ok
            scales    = freq2scales(fmin, fmax, numFreq, wname, T);
            frequency = scal2frq(scales,wname,T);
            frequency = fliplr(frequency);
            
            if ~numberOfBoundarySamples
                toCut = round(0.05*length(obj.time));
            else
                toCut = numberOfBoundarySamples;
            end
            time = obj.time(toCut:end-toCut-1);
            
            %-- computing wavelet coefficients
            coefficients = zeros([length(scales) dim(1) prod(dim(2:end))]);
            hwait = waitbar(0,'Computing cwt...','Color',[0.93 0.96 1]);
            prodDim = prod(dim(2:end));
            for it=1:prodDim
               coefficients(:,:,it) = cwt(data(:,it),scales,wname);%#ok
               waitbar(it/prodDim,hwait);
            end
            close(hwait);
            
            % fliping frequency dimension
            coefficients = permute(coefficients,[2 1 3]);
            coefficients = reshape(coefficients,[dim(1) length(scales) dim(2:end)]);
            coefficients = flipdim(coefficients,2);
                           
            % computing the power
            coefficients = coefficients(toCut:end-toCut-1,:,:,:);
            powerDB      = 10*log10(abs(coefficients).^2+eps);
            
            % computing the angle
            angle = atan2(imag(coefficients),real(coefficients)+eps);
                        
            if plotFlag
                G = fspecial('gaussian',[4 4],2);
                powerDB_s = powerDB;
                angle_s = angle;
                for it=1:length(obj.label)
                    powerDB_s(:,:,it) = imfilter(powerDB(:,:,it),G,'same');
                    angle_s(:,:,it)   = imfilter(angle(:,:,it), G,'same');
                                        
                    timeSeries.imageLogData(time,frequency,powerDB(:,:,it), ['Power (dB): ' obj.label{it}]);
                    timeSeries.imageLogData(time,frequency,angle(:,:,it),   ['Angle: '      obj.label{it}]);
                end
            end
        end
    end
    methods(Static)
        function imageLogData(time,frequency,data,strTitle)
            if nargin < 4, strTitle = '';end
            figure('Color',[0.93 0.96 1]);
            imagesc(time,log10(frequency),data');
            hAxes = gca;
            tick = get(hAxes,'Ytick');
            fval = 10.^tick;
            Nf = length(tick);
            yLabel = cell(Nf,1);
            fval(fval >= 10) = round(fval(fval >= 10));
            for it=1:Nf, yLabel{it} = num2str(fval(it),3);end
            set(hAxes,'YDir','normal','Ytick',tick,'YTickLabel',yLabel);
            xlabel('Time (sec)');
            ylabel('Frequency (Hz)');
            title(strTitle)
            colorbar;
        end
    end
end