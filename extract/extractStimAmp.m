function extractStimAmp(data, params)
%Yohann Thenaisie 24.09.2020

%Extract parameters for this recording mode
recordingMode = params.recordingMode;

%Identify the different recordings
nLines = size(data.(recordingMode), 1);
FirstPacketDateTime = cell(nLines, 1);
for lineId = 1:nLines
    FirstPacketDateTime{lineId, 1} = data.(recordingMode)(lineId).FirstPacketDateTime;
end
FirstPacketDateTime = categorical(FirstPacketDateTime);
recNames = unique(FirstPacketDateTime);
nRecs = numel(recNames);

for recId = 1:nRecs
    
    commaIdx = regexp(data.(recordingMode)(recId).Channel, ',');
    nChannels = numel(commaIdx)+1;
    
    %Convert structure to arrays
    nSamples = size(data.(recordingMode)(recId).LfpData, 1);
    TicksInMs = NaN(nSamples, 1);
    mA = NaN(nSamples, nChannels);
    for sampleId = 1:nSamples
        TicksInMs(sampleId) = data.(recordingMode)(recId).LfpData(sampleId).TicksInMs;
        mA(sampleId, 1) = data.(recordingMode)(recId).LfpData(sampleId).Left.mA;
        mA(sampleId, 2) = data.(recordingMode)(recId).LfpData(sampleId).Right.mA;
    end
    
    %Make time start at 0 and convert to seconds
    TicksInS = (TicksInMs - TicksInMs(1))/1000;
    
    Fs = data.(recordingMode)(recId).SampleRateInHz;
    
    %Store LFP band power and stimulation amplitude in one structure
    stimAmp.data = mA;
    stimAmp.time = TicksInS;
    stimAmp.Fs = Fs;
    stimAmp.ylabel = 'Stimulation amplitude (mA)';
    stimAmp.channel_names = {'Left', 'Right'};
    stimAmp.firstTickInSec = TicksInMs(1)/1000; %first tick time (s)
    stimAmp.json = params.fname;
    
    %save name
    savename = regexprep(char(recNames(recId)), {':', '-'}, {''});
    savename = [savename(1:end-5) '_' recordingMode '_stimAmp'];
    
    %Plot stimulation amplitude
    stimAmpFig = figure; plot(stimAmp.time, stimAmp.data, 'Linewidth', 2'); xlabel('Time (s)'); ylabel(stimAmp.ylabel); legend(stimAmp.channel_names); xlim([stimAmp.time(1) stimAmp.time(end)]); grid on
    savefig(stimAmpFig, [params.save_pathname filesep savename]);
    
    %save
    save([params.save_pathname filesep savename], 'stimAmp')
    disp([savename ' saved'])
    
end