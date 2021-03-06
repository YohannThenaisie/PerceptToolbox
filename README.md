# PerceptToolbox
MATLAB Toolbox to extract JSON files from Medtronic Percept PC neurostimulator.

The loadJSON script extracts data from the following BrainSense recording modes: Setup, Streaming, Survey, Survey Indefinite Streaming and Timeline.
Before running loadJSON, edit path to the present code and path to the folder containing the JSON files.
Set correct4missingSamples as 'true' if LFP data needs to be synchronized to other devices (such as EMG or EEG recordings).

Once extracted, you may load the raw LFP data and use the following functions:
plotChannels(LFP.data, LFP) plots raw signal for each channel
plotSpectrogram(LFP.data, LFP) plots spectrogram for each channel
plotPwelch(LFP.data, LFP) plots the power spectrum density for each channel

In case a streaming has been disrupted (ie. a loading screen appeared on the tablet), the two recordings (before and after)
disruption can be concatenated with the concatenateLFP script.

Developped by
Yohann Thenaisie - Lausanne University Hospital
Barth Keulen - Leids Universitair Medisch Centrum
Contact: yohann.thenaisie@chuv.ch
