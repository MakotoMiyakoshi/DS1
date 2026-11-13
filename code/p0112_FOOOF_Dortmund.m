% TRACE migration candidate; original source archived separately; see code/docs/SOURCE_SHA256.txt.
% Not numerically validated. Dataset-specific and version-specific settings remain as authored.
close all
clear
clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(projectRoot, mfilename);
if ~isfolder(outDir), mkdir(outDir); end
fieldtripRoot = getenv('DS1_FIELDTRIP_ROOT');
eeglabRoot = getenv('DS1_ANALYSIS_EEGLAB_ROOT');
assert(isfolder(fieldtripRoot), 'Set DS1_FIELDTRIP_ROOT to the FieldTrip checkout.');
assert(isfolder(eeglabRoot), 'Set DS1_ANALYSIS_EEGLAB_ROOT to the EEGLAB checkout.');
addpath(eeglabRoot);
eeglab('nogui');
addpath(fieldtripRoot);
ft_defaults;
% ANALYSIS INPUTS: upstream stages are only read from lower p-number directories.
% 10/17/2025 Makoto. Used.
% 07/27/2021 Makoto. Created.


addpath(genpath(getenv('DS1_RIBBON_TOOLBOX_ROOT')))

allSets = dir(fullfile(projectRoot, 'p0010_preprocess_Dortmund', '*.set'));
fooofMatrix = zeros(64*length(allSets), 436); % SubjIdx, icIdx, fooof_intercept, fooof_spex, fooof_r2, linearPSD.
icCounter = 0;
for setIdx = 1:length(allSets)

    loadName = allSets(setIdx).name;
    loadPath = allSets(setIdx).folder;
    EEG = pop_loadset('filename', loadName, 'filepath', loadPath);

    % 1. Compute STFT.
    EEG = ribbon_spectrogram(EEG, [2 45]);

    % 2. Find windows that contains 'boundary' (i.e. discontinuity).
    EEG = ribbon_findBoundaryWindows(EEG);

    % 3. Extract the peak-power frequency Ribbon after removing 'boundary' epochs.
    spectrogramFourierCoeffTensor = EEG.etc.ribbon.spectrogramFourierCoeffTensor;
    specFreqs                     = EEG.etc.ribbon.specFreqs;
    boundaryMask                  = EEG.etc.ribbon.boundaryMask;
    [ribbonizedSpectrogramDb, peakPowerFreqRibbon, ribbonPower, ribbonSortingIdx] = ribbon_extractRibbon(spectrogramFourierCoeffTensor, boundaryMask, specFreqs);

    % 4. Extract alpha peak using FOOOF.
    stftWindow = hamming(EEG.srate, 'periodic');
    ribbonizedSpectrogram_linear  = 10.^(ribbonizedSpectrogramDb/10);
    linearPsdMatrix               = squeeze(median(ribbonizedSpectrogram_linear,2)/(sum(stftWindow.^2)*EEG.srate)); % For the normalization, see https://sccn.ucsd.edu/wiki/Makoto's_useful_EEGLAB_code#Comparison_between_spectopo.28.29_and_spectrogram.28.29_.2812.2F30.2F2023_added.29
    fooofStructure                = ribbon_FOOOF(linearPsdMatrix, specFreqs); % Input dimensions are freq, channel.
    EEG.etc.ribbon.fooofStructure = fooofStructure;

    for icIdx = 1:size(EEG.icawinv,2)
        icCounter = icCounter + 1;
        fooofMatrix(icCounter,:) = [setIdx icIdx fooofStructure.channel(icIdx).FOOOF.aperiodic_params ...
                                                   fooofStructure.channel(icIdx).FOOOF.r_squared ...
                                                   linearPsdMatrix(:,icIdx)'];
    end
end
columnLabels = {'SubjIdx', 'icIdx', 'fooof_intercept', 'fooof_spex', 'fooof_r2', 'linearPSD_431'};
psdFreqBins  = fooofStructure.channel(1).FOOOF.fooofFreqs;
save(fullfile(projectRoot, 'p0112_FOOOF_Dortmund', 'FOOOF_Dortmund'), 'fooofMatrix', 'columnLabels', 'psdFreqBins')