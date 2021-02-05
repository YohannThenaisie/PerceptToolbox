%Yohann Thenaisie 02.09.2020

addpath(genpath('F:\Percept_Project\Code\percept-toolbox'))
data_pathname = 'F:\Percept_Project\Data\Rest_IndefiniteStreaming\RestFiles\PW01';
cd(data_pathname)

filenames = ls('*.json');
nFiles = size(filenames, 1);

for fileId = 1:nFiles
    
    %Load JSON file
    fname = filenames(fileId, :);
    data = jsondecode(fileread(fname));
    
    %Create a new folder per JSON file
    params.fname = fname;
    params.SessionDate = regexprep(data.SessionDate, {':', '-'}, {''});
    params.save_pathname = [data_pathname filesep params.SessionDate(1:end-1)];
    mkdir(params.save_pathname)
    params.correct4MissingSamples = true;
    params.ProgrammerVersion = data.ProgrammerVersion;
    
    if isfield(data, 'IndefiniteStreaming')
        
        params.recordingMode = 'IndefiniteStreaming';
        params.nChannels = 6;
        params.channel_map = [1 2 3 ; 4 5 6];
        
        extractLFP(data, params)
        
    end
    
    if isfield(data, 'BrainSenseTimeDomain')
        
        params.nChannels = 2;
        params.channel_map = 1:params.nChannels;
        
        params.recordingMode = 'BrainSenseTimeDomain';
        extractLFP(data, params)
        params.recordingMode = 'BrainSenseLfp';
        extractStimAmp(data, params)
        
    end
    
    if isfield(data, 'SenseChannelTests')
        
        params.recordingMode = 'SenseChannelTests';
        params.nChannels = 6;
        params.channel_map = [1 2 3 ; 4 5 6];
        
        extractLFP(data, params)
        
    end
    
    if isfield(data, 'LFPMontage')
        
        %Extract and save LFP Montage PSD
        extractLFPMontage(data, params)
        
        %Extract and save LFP Montage Time Domain
        params.recordingMode = 'LfpMontageTimeDomain';
        params.nChannels = 6;
        params.channel_map = [1 2 3 ; 4 5 6];
        extractLFP(data, params);
                
    end
    
    if ~isempty(data.MostRecentInSessionSignalCheck)
        SignalCheck = data.MostRecentInSessionSignalCheck;
        figure; hold on
        for chId = 1:6
            plot(SignalCheck(chId).SignalFrequencies, SignalCheck(chId).SignalPsdValues)
            channel_names{chId} = SignalCheck(chId).Channel(19:end);
        end
        xlabel('Frequency (Hz)')
        ylabel('uVp/rtHz')
        legend(channel_names)
        save([params.save_pathname filesep 'SignalCheck'], 'SignalCheck')
        disp('SignalCheck saved')
    end
    
    if isfield(data, 'DiagnosticData') && isfield(data.DiagnosticData, 'LFPTrendLogs')
        
        params.recordingMode = 'LFPTrendLogs';
        params.patientID = '';
        extractTrendLogs(data, params)
        
    end
    
end