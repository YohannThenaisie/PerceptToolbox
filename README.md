# PerceptToolbox
MATLAB Toolbox to extract JSON files from Medtronic Percept PC neurostimulator.

## Instructions

The loadJSON script extracts data from the following BrainSense recording modes: Setup, Streaming, Survey, Survey Indefinite Streaming and Timeline.
When running loadJSON, select the JSON files to be extracted.
Set correct4missingSamples as 'true' if LFP data needs to be synchronized to other devices (such as EMG or EEG recordings).

Once extracted, you may load the raw LFP data and use the following functions:
- plotChannels(LFP.data, LFP) plots raw signal for each channel
- plotSpectrogram(LFP.data, LFP) plots spectrogram for each channel
- plotPwelch(LFP.data, LFP) plots the power spectrum density for each channel

In case a streaming has been disrupted (ie. a loading screen appeared on the tablet), the two recordings (before and after) disruption can be concatenated with the concatenateLFP script.

Please cite our article when using our Toolbox:
Towards adaptive deep brain stimulation: clinical and technical notes on a novel commercial device for chronic brain sensing, Thenaisie et al. J Neural Eng. 2021

## Updates
- 24.09.2021 Bug fix in extractLFPTrendlogs
- 27.09.2021 Allow direct selection of JSON files, bug fix in extractLFP
- 07.12.2021 Bug fix in file selection
- 01.02.2022 Bug fix in extractLFPTrendlogs 

## Developped by
Yohann Thenaisie - Lausanne University Hospital
Barth Keulen - Leids Universitair Medisch Centrum
Contact: yohann.thenaisie@chuv.ch
