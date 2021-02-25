function extractLFPMontage(data, params)
%Yohann Thenaisie 20.12.2020

%Two data formats co-exist (structure or cell of structures)
nRecordings = size(data.LFPMontage, 1);
if ~iscell(data.LFPMontage)
    S = cell(nRecordings, 1);
    for recId = 1:nRecordings
        S{recId} = data.LFPMontage(recId);
    end
    data.LFPMontage = S;
end

%Extract LFP montage data
LFPMontage.LFPFrequency = data.LFPMontage{1}.LFPFrequency;
LFPMontage.LFPMagnitude = NaN(size(LFPMontage.LFPFrequency, 1), nRecordings);
for recId = 1:nRecordings
    LFPMontage.hemisphere{recId} = afterPoint(data.LFPMontage{recId}.Hemisphere);
    LFPMontage.channel_names{recId} = strrep(afterPoint(data.LFPMontage{recId}.SensingElectrodes), '_', ' ');
    LFPMontage.LFPMagnitude(:, recId) = data.LFPMontage{recId}.LFPMagnitude;
    LFPMontage.ArtifactStatus{recId} = afterPoint(data.LFPMontage{recId}.ArtifactStatus);
end

%define savename
recNames = data.LfpMontageTimeDomain(1).FirstPacketDateTime;
savename = regexprep(char(recNames), {':', '-'}, {''});
savename = [savename(1:end-5) '_LFPMontage'];

%plot LFP Montage
LFPMontage.hemisphere = categorical(LFPMontage.hemisphere);
hemisphereNames = unique(LFPMontage.hemisphere);
nHemispheres = numel(hemisphereNames);
channelsFig = figure;
for hemisphereId = 1:nHemispheres
    subplot(nHemispheres, 1, hemisphereId)
    plot(LFPMontage.LFPFrequency, LFPMontage.LFPMagnitude(:, LFPMontage.hemisphere == hemisphereNames(hemisphereId)));
    xlabel('Frequency (Hz)'); ylabel('Power (uVp/rtHz)');
    legend(LFPMontage.channel_names(LFPMontage.hemisphere == hemisphereNames(hemisphereId)))
    title(hemisphereNames(hemisphereId))
end
savefig(channelsFig, [params.save_pathname filesep savename '_LFPMontage']);

%save data
save([params.save_pathname filesep savename '.mat'], 'LFPMontage')