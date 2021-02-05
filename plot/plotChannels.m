function channelsFig = plotChannels(data, channelParams)
%channelsFig = plotChannels(LFP.data, LFP)
%Plots data from each channel of LFP data in a subplot
%S is a structure with fields:
%.data, .time, .nChannels, .channel_names, .channel_map, .ylabel
%Yohann Thenaisie 26.10.2018

channelsFig = figure();

ax = gobjects(channelParams.nChannels, 1);
[nColumns, nRows] = size(channelParams.channel_map);
for chId = 1:channelParams.nChannels
    channel_pos = find(channelParams.channel_map == chId);
    ax(chId) = subplot(nRows, nColumns, channel_pos);
    hold on
    plot(channelParams.time, data(:, chId))
    title(channelParams.channel_names{chId})
    xlim([channelParams.time(1) channelParams.time(end)])
    grid on
    minY = min(data(:, chId));
    maxY = max(data(:, chId));
    if minY ~= maxY
        ylim([minY maxY])
    end
end
subplot(nRows, nColumns, channelParams.nChannels-nColumns+1)
xlabel('Time (s)')
ylabel(channelParams.ylabel)
linkaxes(ax, 'x')