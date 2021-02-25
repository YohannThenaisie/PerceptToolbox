function spectroFig = plotSpectrogram(data, channelParams, varargin)
%Computes and plot standard spectrogram for each channnel
%'channelParams' is a structure with '.nChannels' and '.channel_map' and
%'.channel_names' fields
%Yohann Thenaisie 05.11.2018
normalizePower = 0;

%Default spectrogram parameters
ax = gobjects(channelParams.nChannels, 1);
window = round(0.5*channelParams.Fs); %0.5 second
noverlap = round(window/2);
fmin = 1; %Hz
fmax = 125; %Hz

spectroFig = figure();
[nColumns, nRows] = size(channelParams.channel_map);
for chId = 1:channelParams.nChannels
    electrode_pos = find(channelParams.channel_map == chId);
    ax(chId) = subplot(nRows, nColumns, electrode_pos);
    hold on
    [~, f, t, p] = spectrogram(data(:, chId), window, noverlap, fmin:0.5:fmax, channelParams.Fs, 'yaxis');
    
    if normalizePower == 1
        power2plot = 10*log10(p./mean(p, 2));
    else
        power2plot = 10*log10(p);
    end
    
    imagesc(t, f, power2plot)
    ax_temp = gca;
    ax_temp.YDir = 'normal';
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    xlim([channelParams.time(1) channelParams.time(end)])
    ylim([fmin fmax])
    c = colorbar;
    c.Label.String = 'Power/Frequency (dB/Hz)';
    cmax = max(quantile(power2plot, 0.9));
    cmin = min(quantile(power2plot, 0.1));
    caxis([cmin cmax])
    title(channelParams.channel_names(chId))
    
        
end

linkaxes(ax, 'xy')