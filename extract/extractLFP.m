function extractLFP(data, params)
%Yohann Thenaisie 04.09.2020

%Extract parameters for this recording mode
recordingMode = params.recordingMode;
nChannels = params.nChannels;
fname = params.fname;

%Identify the different recordings
nLines = size(data.(recordingMode), 1);
FirstPacketDateTime = cell(nLines, 1);
for lineId = 1:nLines
    FirstPacketDateTime{lineId, 1} = data.(recordingMode)(lineId).FirstPacketDateTime;
end
FirstPacketDateTime = categorical(FirstPacketDateTime);
recNames = unique(FirstPacketDateTime);
nRecs = numel(recNames);

%Extract LFPs in a new structure for each recording
for recId = 1:nRecs
    
    datafield = data.(recordingMode)(FirstPacketDateTime == recNames(recId));
    
    LFP = struct;
    LFP.nChannels = size(datafield, 1);
    if LFP.nChannels ~= nChannels
        warning(['There are ' num2str(LFP.nChannels) ' instead of the expected ' num2str(nChannels) ' channels'])
    end
    LFP.channel_names = cell(1, LFP.nChannels);
    LFP.data = [];
    for chId = 1:LFP.nChannels
        LFP.channel_names{chId} = strrep(datafield(chId).Channel, '_', ' ');
        LFP.data(:, chId) = datafield(chId).TimeDomainData;
    end
    LFP.Fs = datafield(chId).SampleRateInHz;
    
    %Extract size of received packets
    GlobalPacketSizes = str2num(datafield(1).GlobalPacketSizes); %#ok<ST2NM>
    if sum(GlobalPacketSizes) ~= size(LFP.data, 1) && ~strcmpi(recordingMode, 'SenseChannelTests') && ~strcmpi(recordingMode, 'CalibrationTests')
       warning([recordingMode ': data length (' num2str(size(LFP.data, 1)) ' samples) differs from the sum of packet sizes (' num2str(sum(GlobalPacketSizes)) ' samples)'])
    end
    
    %Extract timestamps of received packets
    TicksInMses = str2num(datafield(1).TicksInMses); %#ok<ST2NM>
    if ~isempty(TicksInMses)
        LFP.firstTickInSec = TicksInMses(1)/1000; %first tick time (s)
    end 
    
    if ~isempty(TicksInMses) && params.correct4MissingSamples %TicksInMses is empty for SenseChannelTest
        TicksInS = (TicksInMses - TicksInMses(1))/1000; %convert to seconds and initiate at 0
        
        %If there are more ticks in data packets, ignore extra ticks
        nPackets = numel(GlobalPacketSizes);
        nTicks = numel(TicksInS);
        if  nPackets ~= nTicks
            warning('GlobalPacketSizes and TicksInMses have different lengths')
            
            maxPacketId = max([nPackets, nTicks]);
            nSamples = size(LFP.data, 1);
            
            %Plot
            figure; 
            ax(1) = subplot(2, 1, 1); plot(TicksInS, '.'); xlabel('Data packet ID'); ylabel('TicksInS'); xlim([0 max([nPackets nTicks])])
            ax(2) = subplot(2, 1, 2); plot(cumsum(GlobalPacketSizes), '.'); xlabel('Data packet ID'); ylabel('Cumulated sum of samples received'); xlim([0 max([nPackets nTicks])]);
            hold on; plot([0 maxPacketId], [nSamples, nSamples], '--')
            linkaxes(ax, 'x')
            
            TicksInS = TicksInS(1:nPackets);
                        
        end
        
        %Check if some ticks are missing
        isDataMissing = logical(TicksInS(end) >= sum(GlobalPacketSizes)/LFP.Fs);
        
        if isDataMissing
            LFP = correct4MissingSamples(LFP, TicksInS, GlobalPacketSizes);
        end
                
    end
    
    LFP.time = (1:length(LFP.data))/LFP.Fs; % [s]
    if LFP.nChannels <= 2
        LFP.channel_map = 1:LFP.nChannels;
    else
        LFP.channel_map = params.channel_map;
    end
    LFP.xlabel = 'Time (s)';
    LFP.ylabel = 'LFP (uV)';
    LFP.json = fname;
    LFP.recordingMode = recordingMode;
    
    %save name
    savename = regexprep(char(recNames(recId)), {':', '-'}, {''});
    savename = [savename(1:end-5) '_' recordingMode];
    
    %Plot LFPs and save figure
    channelsFig = plotChannels(LFP.data, LFP);
    savefig(channelsFig, [params.save_pathname filesep savename '_LFP']);
    
    %Plot spectrogram and save figure
    if ~isempty(TicksInMses) && params.correct4MissingSamples && isDataMissing %cannot compute Fourier transform on NaN
        warning('Spectrogram cannot be computed as some samples are missing.')
    else
        spectroFig = plotSpectrogram(LFP.data, LFP);
        savefig(spectroFig, [params.save_pathname filesep savename '_spectrogram']);
    end
      
    %save LFPs
    save([params.save_pathname filesep savename '.mat'], 'LFP')
    disp([savename ' saved'])
    
end