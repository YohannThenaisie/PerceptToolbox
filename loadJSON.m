%LOADJSON loads JSON files, extracts, saves and plots BrainSense, Setup, 
%Survey, Indefinite Streaming and Timeline data in one folder per session
%Yohann Thenaisie 02.09.2020 - Lausanne University Hospital (CHUV)

%Set pathname to the Percept Toolbox
addpath(genpath('C:\Users\BSI\Dropbox (NeuroRestore)\Dystonia\Code\PerceptToolbox'))

%Set pathname to the folder containing the JSON files
[filenames, data_pathname] = uigetfile('*.json', 'MultiSelect', 'on');
cd(data_pathname)

nFiles = size(filenames, 2);
for fileId = 1:nFiles
    
    %Load JSON file
    fname = filenames{fileId};
    data = jsondecode(fileread(fname));
    
    %Create a new folder per JSON file
    params.fname = fname;
    params.SessionDate = regexprep(data.SessionDate, {':', '-'}, {''});
    params.save_pathname = [data_pathname filesep params.SessionDate(1:end-1)];
    mkdir(params.save_pathname)
    params.correct4MissingSamples = true; %set as 'true' if device synchronization is required
    params.ProgrammerVersion = data.ProgrammerVersion;
    
    if isfield(data, 'IndefiniteStreaming') %Survey Indefinite Streaming
        
        params.recordingMode = 'IndefiniteStreaming';
        params.nChannels = 6;
        params.channel_map = [1 2 3 ; 4 5 6];
        
        extractLFP(data, params)
        
    end
    
    if isfield(data, 'BrainSenseTimeDomain') %Streaming
        
        params.nChannels = 2;
        params.channel_map = 1:params.nChannels;
        
        params.recordingMode = 'BrainSenseTimeDomain';
        extractLFP(data, params)
        params.recordingMode = 'BrainSenseLfp';
        extractStimAmp(data, params)
        
    end
    
    if isfield(data, 'SenseChannelTests') %Setup OFF stimulation
        
        params.recordingMode = 'SenseChannelTests';
        params.nChannels = 6;
        params.channel_map = [1 2 3 ; 4 5 6];
        
        extractLFP(data, params)
        
    end
    
    if isfield(data, 'CalibrationTests') %Setup ON stimulation
        
        params.recordingMode = 'CalibrationTests';
        params.nChannels = 2;
        params.channel_map = [1 2];
        
        extractLFP(data, params)
        
    end
    
    if isfield(data, 'LFPMontage') %Survey
        
        %Extract and save LFP Montage PSD
        extractLFPMontage(data, params)
        
        %Extract and save LFP Montage Time Domain
        params.recordingMode = 'LfpMontageTimeDomain';
        params.nChannels = 6;
        params.channel_map = [1 2 3 ; 4 5 6];
        extractLFP(data, params);
                
    end
    
    if ~isempty(data.MostRecentInSessionSignalCheck) %Setup
        
        SignalCheck = data.MostRecentInSessionSignalCheck;
        save([params.save_pathname filesep 'SignalCheck'], 'SignalCheck')

        h = figure; hold on
        channel_names = cell(6, 1);
        for chId = 1:6
            plot(SignalCheck(chId).SignalFrequencies, SignalCheck(chId).SignalPsdValues)
            channel_names{chId} = SignalCheck(chId).Channel(19:end);
        end
        xlabel('Frequency (Hz)')
        ylabel('uVp/rtHz')
        legend(channel_names)
        savefig(h, [params.save_pathname filesep 'SignalCheck'])
        disp('SignalCheck saved')
        
    end
    
    if isfield(data, 'DiagnosticData') && isfield(data.DiagnosticData, 'LFPTrendLogs') %Timeline and Events
        
        params.recordingMode = 'LFPTrendLogs';
        extractTrendLogs(data, params)
        
    end
    
end
