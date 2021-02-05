function extractTrendLogs(data, params)
% Bart Keulen 4-10-2020
% Modified by Yohann Thenaisie 05.10.2020

% Extract parameters for this recording mode
recordingMode = params.recordingMode;
fname = params.fname;

%Find the group that was active
nGroups = size(data.Groups.Initial, 1);
for groupId = 1:nGroups
    if data.Groups.Initial(groupId).ActiveGroup == 1
        activeGroup = groupId;
        if isfield(data.Groups.Initial(groupId).ProgramSettings, 'SensingChannel') %not in old versions
            SensingChannel = data.Groups.Initial(groupId).ProgramSettings.SensingChannel;
            nChannels = size(SensingChannel, 1);
        else
            nChannels = 2;
        end
        RateInHertz = data.Groups.Initial(groupId).ProgramSettings.RateInHertz; %stimulation frequency
    end
end

%Extract stimulation and recording parameters
channel_names = cell(nChannels, 1);
FrequencyInHertz = NaN(nChannels, 1);
PulseWidthInMicroSecond = NaN(nChannels, 1);
for channelId = 1:nChannels
    if isfield(data.Groups.Initial(activeGroup).ProgramSettings, 'SensingChannel')
        channel_names{channelId} = SensingChannel(channelId).SensingSetup.ChannelSignalResult.Channel;
        FrequencyInHertz(channelId) = SensingChannel(channelId).SensingSetup.FrequencyInHertz;
        PulseWidthInMicroSecond(channelId) = SensingChannel(channelId).PulseWidthInMicroSecond;
    else
        hemisphereLocationNames = {'LeftHemisphere', 'RightHemisphere'};
        nHemisphereLocations = numel(hemisphereLocationNames);
        for hemisphereId = 1:nHemisphereLocations
            channel_names{channelId} = hemisphereLocationNames{hemisphereId};
            Programs = data.Groups.Initial(activeGroup).ProgramSettings.(hemisphereLocationNames{hemisphereId}).Programs;
            FrequencyInHertz(channelId) = Programs.PulseWidthInMicroSecond;
            PulseWidthInMicroSecond(channelId) = Programs.PulseWidthInMicroSecond;
        end
    end
end

LFP.data = [];
stimAmp.data = [];

% Extract recordings left and right
hemisphereLocationNames = fieldnames(data.DiagnosticData.LFPTrendLogs);
nHemisphereLocations = numel(hemisphereLocationNames);

for hemisphereId = 1:nHemisphereLocations
    
    data_hemisphere = data.DiagnosticData.LFPTrendLogs.(hemisphereLocationNames{hemisphereId});
    
    recFields = fieldnames(data_hemisphere);
    nRecs = numel(recFields);
    allDays = table;
    
    %Concatenate data accross days
    for recId = 1:nRecs
        
        datafield = struct2table(data_hemisphere.(recFields{recId}));
        allDays = [allDays; datafield]; %#ok<*AGROW>
        
    end
    
    allDays = sortrows(allDays, 1);
    
    LFP.data = [LFP.data allDays.LFP];
    stimAmp.data = [stimAmp.data allDays.AmplitudeInMilliAmps];
    
end

%Extract LFP, stimulation amplitude and date-time information
% DateTime = cellfun(@(x) datetime(regexprep(x(1:end-1),'T',' ')), allDays.DateTime);
nTimepoints = size(allDays, 1);
for recId = 1:nTimepoints
    DateTime(recId) = datetime(regexprep(allDays.DateTime{recId}(1:end-1),'T',' '));
end

% Store LFP in a ctructure
LFP.time = DateTime;
LFP.nChannels = nChannels;
LFP.channel_names = channel_names;
LFP.xlabel = 'Date Time';
LFP.ylabel = 'LFP band power';
LFP.FrequencyInHertz = FrequencyInHertz;

%Store stimAmp in a structure
stimAmp.time = DateTime;
stimAmp.nChannels = nChannels;
stimAmp.channel_names = channel_names;
stimAmp.xlabel = 'Date Time';
stimAmp.ylabel = 'Stimulation amplitude [mA]';
stimAmp.PulseWidthInMicroSecond = PulseWidthInMicroSecond;
stimAmp.stimulationFrequency = RateInHertz;

%Store all information in one structure
LFPTrendLogs.LFP = LFP;
LFPTrendLogs.stimAmp = stimAmp;
LFPTrendLogs.json = fname;
LFPTrendLogs.recordingMode = recordingMode;

%If patient has marked events, extract them
if isfield(data.DiagnosticData, 'LfpFrequencySnapshotEvents')
    data_events = data.DiagnosticData.LfpFrequencySnapshotEvents;
    nEvents = size(data_events, 1);
    events = table('Size',[nEvents 6],'VariableTypes',...
        {'cell', 'double', 'cell', 'logical', 'logical', 'cell'},...
        'VariableNames',{'DateTime','EventID','EventName','LFP','Cycling', 'LfpFrequencySnapshotEvents'});
    for eventId = 1:nEvents
        thisEvent = struct2table(data_events(eventId), 'AsArray', true);
        events(eventId, 1:5) = thisEvent(:, 1:5); %remove potential 'LfpFrequencySnapshotEvents'
        %         if isfield(data_events{eventId}, 'LfpFrequencySnapshotEvents')
        if isfield(data_events(eventId), 'LfpFrequencySnapshotEvents')
            for hemisphereId = 1:nHemisphereLocations
                PSD.FFTBinData(:, hemisphereId) = thisEvent.LfpFrequencySnapshotEvents.(hemisphereLocationNames{hemisphereId}).FFTBinData;
                PSD.channel_names{hemisphereId} = [hemisphereLocationNames{hemisphereId}(23:end), ' ' thisEvent.LfpFrequencySnapshotEvents.(hemisphereLocationNames{hemisphereId}).SenseID(27:end)];
            end
            PSD.Frequency = thisEvent.LfpFrequencySnapshotEvents.(hemisphereLocationNames{hemisphereId}).Frequency;
            PSD.nChannels = nHemisphereLocations;
            events.LfpFrequencySnapshotEvents{eventId} = PSD;
        end
    end
    events.DateTime = cellfun(@(x) datetime(regexprep(x(1:end-1),'T',' ')), events.DateTime);
    LFPTrendLogs.events = events;
end

%Define savename
savename = [params.SessionDate '_' recordingMode];

%Plot and save LFP trends
channelsFig = plotLFPTrendLogs(LFPTrendLogs);
savefig(channelsFig, [params.save_pathname filesep savename]);

%Save TrendLogs in one file
save([params.save_pathname filesep savename '.mat'], 'LFPTrendLogs')
disp([savename ' saved'])
    
end