function [Pxx, F] = plotPwelch(data, params, varargin)
% function pwelchFig = plotPwelch(data, LFP, 'log')
%'log' converts PSD to dB
%Plot Pwelch (PSD along frequencies) for each channel
%Yohann Thenaisie 25.20.2018

%Compute pWelch with 0.01Hz frequency resolution
window = round(1*params.Fs); %default
noverlap = round(window*0.6); %default
freqResolution = 1; %Hz
fmin = 1; %Hz
fmax = params.Fs/2; %Hz


[Pxx, F] = pwelch(data, window, noverlap, fmin:freqResolution:fmax, params.Fs);

%log scale PSD and confidence interval
if nargin > 2 && strcmpi(varargin{1}, 'log')
    Pxx = 10*log10(Pxx);
    params.ylabel = 'PSD (dB/Hz)';
else
    params.ylabel = 'PSD (uV^2/Hz)';
end

% figure;
ax = gobjects(params.nChannels, 1);
[nColumns, nRows] = size(params.channel_map);
for chId = 1:params.nChannels
    channel_pos = find(params.channel_map == chId);
    ax(chId) = subplot(nRows, nColumns, channel_pos);
    hold on
    plot(F, Pxx(:, chId), 'LineWidth', 1)
    ylabel(params.ylabel)
    xlabel('Frequency (Hz)')
    title(params.channel_names(chId))
end
linkaxes(ax, 'x')
xlim([fmin fmax])

end
