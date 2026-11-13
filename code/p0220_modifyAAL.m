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
% 10/20/2025 Makoto. Created.



% Load AAL just to get the SAME affine as p0200

aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));
aalTissue = aal.tissue;

% Why don't you leave cerebellum dipoles so that they'll be treated as exceptions later?
% % Remove the cerebellum.
% subcorticalLabelIdx = 92:116; % Removing cerebellum only.
% for nonEegSourceIdx = 1:length(subcorticalLabelIdx)
%     currentNonEegSourceTissue = subcorticalLabelIdx(nonEegSourceIdx);
%     aalTissue(aalTissue==currentNonEegSourceTissue) = 0;
% end
    %{
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(squeeze(aalTissue(:,:,zIdx))', [1 116]); axis xy 
    end
    %}

% Load precomputed EEGLAB-default head model.
load(fullfile(projectRoot, 'p0210_checkDipfitDefaultModel', 'corticalMask.mat'))
modifiedAalTissue = double(corticalMask);
modifiedAalTissue(modifiedAalTissue==1) = 999;
clear corticalMask
    %{
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(squeeze(modifiedAalTissue(:,:,zIdx))'); axis xy 
    end
    %}

[~, L] = bwdist(aalTissue > 0, 'euclidean');
aalTissueVec = aalTissue(:);

% Copy and expand AAL.
extrapolatedAalTissue = zeros(size(aalTissue));
for zIdx = 1:91

    currentAAL    = aalTissue(:,:,zIdx);
    currentDipfit = modifiedAalTissue(:,:,zIdx);
    currentL      = L(:,:,zIdx);

    synthesizedMask = currentDipfit;
    synthesizedMask(currentAAL>0) = currentAAL(currentAAL>0);

    innerMask = imfill(logical(currentAAL), 'holes');
    synthesizedMask(innerMask) = currentAAL(innerMask);

    overflowingMask = synthesizedMask==999;

    extrapolatedMask = aalTissueVec(currentL);

    fillingInMask = zeros(size(extrapolatedMask));
    fillingInMask(overflowingMask) = extrapolatedMask(overflowingMask);

    modifiedAAL = currentAAL;
    modifiedAAL(overflowingMask) = extrapolatedMask(overflowingMask);

    extrapolatedAalTissue(:,:,zIdx) = modifiedAAL;

    % figure
    % tiledlayout(2,3,"TileSpacing","none")
    % nexttile
    % imagesc(currentAAL'); axis xy;
    % title('Original AAL')
    % 
    % nexttile
    % imagesc(currentDipfit'); axis xy
    % title('Dipfit mask')
    % 
    % nexttile
    % imagesc(synthesizedMask'); axis xy
    % title('Dipfit > AAL (yellow)')
    % 
    % nexttile
    % imagesc(overflowingMask'); axis xy
    % title('Overflowing')
    % 
    % nexttile
    % imagesc(extrapolatedMask'); axis xy
    % title('Extrapolated')
    % 
    % nexttile
    % imagesc(fillingInMask'); axis xy
    % title('Filling-in')
    % 
    % 
    % figure
    % tiledlayout(1,2,"TileSpacing","none")
    % nexttile
    % imagesc(currentAAL'); axis xy;
    % title('Original AAL')
    % 
    % nexttile
    % imagesc(modifiedAAL'); axis xy;
    % title('Modified AAL')
end

% Replace any tissue below z<13 with cerebellum.
cerebellumMask = extrapolatedAalTissue(:,:,1:13);
cerebellumMask(cerebellumMask>0 & cerebellumMask<92) = 104;
extrapolatedAalTissue(:,:,1:13) = cerebellumMask;

% Save.
save(fullfile(projectRoot, 'p0220_modifyAAL', 'extrapolatedAalTissue'), 'extrapolatedAalTissue')


%% Compare before and after the expansion.
aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));
aalTissue = aal.tissue;
% Reuse extrapolatedAalTissue computed above (no self-load).

figure
tiledlayout(7,13,"TileSpacing","none","Padding","tight")
for zIdx = 1:aal.dim(3)
    nexttile
    imagesc(squeeze(aalTissue(:,:,zIdx))', [1 116]); axis xy 
end

figure
tiledlayout(7,13,"TileSpacing","none","Padding","tight")
for zIdx = 1:aal.dim(3)
    nexttile
    imagesc(squeeze(extrapolatedAalTissue(:,:,zIdx))', [1 116]); axis xy
end

figure('position', [100 100 1200 900])
tiledlayout(7,13,"TileSpacing","none","Padding","tight")
for zIdx = 1:aal.dim(3)
    nexttile
    imagesc(abs(logical(extrapolatedAalTissue(:,:,zIdx))-logical(aalTissue(:,:,zIdx)))');
    axis xy
    box off
    set(gca, 'xtick', [], 'ytick', [])
end
exportgraphics(gcf, fullfile(projectRoot, 'p0220_modifyAAL', 'aafDiff.pdf'),  'Resolution', 300, 'ContentType', 'vector')
exportgraphics(gcf, fullfile(projectRoot, 'p0220_modifyAAL', 'aafDiff.jpeg'), 'Resolution', 200, 'ContentType', 'image')


%% Generate a corticalOnly mask.
aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));
aalTissue = aal.tissue;
% Reuse extrapolatedAalTissue computed above (no self-load).

anatomicalLabels    = table([1:116]', aal.tissuelabel, 'VariableNames', {'Index' 'Labels'});
subcorticalLabelIdx = [21 22 29 30 37:42 71:78 92:116];
corticalLabelIdx    = setdiff(1:116, subcorticalLabelIdx);
    %{
    anatomicalLabels.Labels(subcorticalLabelIdx)
    %}

% Remove non-cortical parts.
extrapolatedAalTissue_onlyCortical = extrapolatedAalTissue;
for subcorticalIdxIdx = 1:length(subcorticalLabelIdx)
    extrapolatedAalTissue_onlyCortical(extrapolatedAalTissue_onlyCortical==subcorticalLabelIdx(subcorticalIdxIdx)) = 0;
end
    %{
    % Visually confirm the 'tissue'.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(extrapolatedAalTissue_onlyCortical(:,:,zIdx)'); axis xy
    end
    %}

% Save.
save(fullfile(projectRoot, 'p0220_modifyAAL', 'extrapolatedAalTissue_cortical'), 'extrapolatedAalTissue_onlyCortical')


%% Generate a subcortical mask.
aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));
aalTissue = aal.tissue;
% Reuse extrapolatedAalTissue computed above (no self-load).

anatomicalLabels    = table([1:116]', aal.tissuelabel, 'VariableNames', {'Index' 'Labels'});
subcorticalLabelIdx = [21 22 29 30 37:42 71:78 92:116];
corticalLabelIdx    = setdiff(1:116, subcorticalLabelIdx);
    %{
    anatomicalLabels.Labels(subcorticalLabelIdx)
    %}

% Remove non-cortical parts.
extrapolatedAalTissue_onlySubcortical = extrapolatedAalTissue;
for corticalIdxIdx = 1:length(corticalLabelIdx)
    extrapolatedAalTissue_onlySubcortical(extrapolatedAalTissue_onlySubcortical==corticalLabelIdx(corticalIdxIdx)) = 0;
end
    %{
    % Visually confirm the 'tissue'.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(extrapolatedAalTissue_onlySubcortical(:,:,zIdx)'); axis xy
    end
    %}

% Save.
save(fullfile(projectRoot, 'p0220_modifyAAL', 'extrapolatedAalTissue_subcortical'), 'extrapolatedAalTissue_onlySubcortical')