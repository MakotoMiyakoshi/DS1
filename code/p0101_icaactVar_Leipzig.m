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
% 10/15/2025 Makoto. Created.



% Load Leipzig datasets.
allSets = dir(fullfile(projectRoot, 'p0000_preprocess_Leipzig', '*.set'));
robustVarStdMatrix = zeros(62*length(allSets), 2); % var, varStd
rowCounter = 0;
for setIdx = 1:length(allSets)

    loadName = allSets(setIdx).name;
    loadPath = allSets(setIdx).folder;
    EEG = pop_loadset('filename', loadName, 'filepath', loadPath);
    EEG.icaact = EEG.icaweights*EEG.icasphere*double(EEG.data);

    for icIdx = 1:length(EEG.dipfit.model)

        % Calculate std.
        currentIcaact = EEG.icaact(icIdx,:);
        binWidth = floor(length(currentIcaact)/100);
        truncatedIcaact = currentIcaact(1:binWidth*100);
        icaact3D = reshape(truncatedIcaact, [binWidth, 100]);
        icaactVar = var(icaact3D);
        robustVar = median(icaactVar);
        robustVarStd = std(icaactVar);

        rowCounter = rowCounter+1;
        robustVarStdMatrix(rowCounter,:) = [robustVar robustVarStd];
    end
end
columnLabels = {'robustVar' 'robustVarStd'};
save(fullfile(projectRoot, 'p0101_icaactVar_Leipzig', 'Leipzig_robustVarStd'), 'robustVarStdMatrix', 'columnLabels')