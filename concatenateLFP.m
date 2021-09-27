%When a streaming is disrupted, it appears as two recordings.
%Concatenate two LFPs recordings and interleave NaNs to account for the
%disruption.
%Yohann Thenaisie 15.02.2021

filename1 = '20210505T100520_BrainSenseTimeDomain';
filename2 = '20210505T101029_BrainSenseTimeDomain';

load(filename1) %load recording 1 (chronologically first)
LFP1 = LFP;

load(filename2) %load recording 2 (chronologically second)
LFP2 = LFP;

%Create a new matrix and contatenate data from both recordings
fullDuration = LFP2.firstTickInSec - LFP1.firstTickInSec + LFP2.time(end); %s
LFP = LFP1;
LFP.time = 1/LFP.Fs:1/LFP.Fs:fullDuration;
LFP.data = NaN(size(LFP.time, 2), LFP.nChannels);
LFP.data(1:size(LFP1.data, 1), :) = LFP1.data;
LFP.data(end-size(LFP2.data, 1)+1:end, :) = LFP2.data;

%Plot - there should be a disruption
plotChannels(LFP.data, LFP);

save([filename1 '_concatenated'], 'LFP')