function extractTrendLogs(data, params)
% Bart Keulen 4-10-2020
% Modified by Yohann Thenaisie 05.10.2020

% Extract parameters for this recording mode
recordingMode = params.recordingMode;
fname = params.fname;
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

% Store LFP in a structure
LFP.time = DateTime;
LFP.nChannels = nHemisphereLocations;
LFP.channel_names = hemisphereLocationNames;
LFP.xlabel = 'Date Time';
LFP.ylabel = 'LFP band power';

%Store stimAmp in a structure
stimAmp.time = DateTime;
stimAmp.nChannels = nHemisphereLocations;
stimAmp.channel_names = hemisphereLocationNames;
stimAmp.xlabel = 'Date Time';
stimAmp.ylabel = 'Stimulation amplitude [mA]';

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
        if iscell(data_events) %depending on software version
            thisEvent = struct2table(data_events{eventId}, 'AsArray', true);
        else
            thisEvent = struct2table(data_events(eventId), 'AsArray', true);
        end
        events(eventId, 1:5) = thisEvent(:, 1:5); %remove potential 'LfpFrequencySnapshotEvents'
        if ismember('LfpFrequencySnapshotEvents', thisEvent.Properties.VariableNames)
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

%Has the stimulation/recording group been changed?
% GroupHistory = struct2table(data.GroupHistory);
% GroupHistory.SessionDate = cellfun(@(x) datetime(regexprep(x(1:end-1),'T',' ')), GroupHistory.SessionDate);
EventLogs = data.DiagnosticData.EventLogs;
nEventLogs = size(EventLogs, 1);
ActiveGroup = [];
for eventId = 1:nEventLogs
    if isfield(EventLogs{eventId}, 'NewGroupId')
        DateTime = datetime(regexprep(EventLogs{eventId}.DateTime(1:end-1),'T',' '));
        OldGroupId = afterPoint(EventLogs{eventId}.OldGroupId);
        NewGroupId = afterPoint(EventLogs{eventId}.NewGroupId);
        
        %Find the stimulation and sensing settings of this new group
        Groups_PPS = data.Groups.Initial;
        if iscell(Groups_PPS)
            nGroups = size(Groups_PPS, 1);
            GroupParams = table('Size',[nGroups 4], 'VariableTypes',...
                {'string','logical','struct', 'struct'}, 'VariableNames',...
                {'GroupId', 'ActiveGroup', 'ProgramSettings', 'GroupSettings'});
            for groupId = 1:nGroups
                GroupParams(groupId, :) = struct2table(Groups_PPS{groupId});
            end
        else
            if size(Groups_PPS, 1)
                GroupParams = struct2table(Groups_PPS, 'AsArray', true);
            else
                GroupParams = struct2table(Groups_PPS);
            end
        end
        GroupParams.GroupId = cellfun(@(x) afterPoint(x), GroupParams.GroupId, 'UniformOutput', false);
        NewProgramSettings = GroupParams.ProgramSettings(NewGroupId == categorical(GroupParams.GroupId));
        
        %Create output table
        ActiveGroup_temp = cell2table({DateTime, OldGroupId, NewGroupId, NewProgramSettings},...
            'VariableNames',{'DateTime' 'OldGroupId' 'NewGroupId' 'NewProgramSettings'});
        ActiveGroup = [ActiveGroup; ActiveGroup_temp];
        
    end
end

%Define savename
savename = [params.SessionDate '_' recordingMode];

%Plot and save LFP trends
channelsFig = plotLFPTrendLogs(LFPTrendLogs, ActiveGroup);
savefig(channelsFig, [params.save_pathname filesep savename]);

%Save TrendLogs in one file
save([params.save_pathname filesep savename '.mat'], 'LFPTrendLogs', 'ActiveGroup')
disp([savename ' saved'])
    
end