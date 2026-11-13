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
% 10/27/2025 Makoto. Modified.
% 10/20/2025 Makoto. Created.



% Set path to Fieldtrip's AAL library.

aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));
anatomicalLabels    = table([1:116]', aal.tissuelabel, 'VariableNames', {'Index' 'Labels'});
subcorticalLabelIdx = [21 22 29 30 37:42 71:78 92:116];
corticalLabelIdx    = setdiff(1:116, subcorticalLabelIdx);

voxelSize = 2; % mm isometric.

% Load precomputed modified AAL for dipfit's EEGLAB-default.
%load(fullfile(projectRoot, 'p0220_modifyAAL', 'extrapolatedAalTissue'));
load(fullfile(projectRoot, 'p0220_modifyAAL', 'extrapolatedAalTissue_subcortical.mat'));

    %{
    % Visually confirm the 'tissue'.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(extrapolatedAalTissue_onlySubcortical(:,:,zIdx)'); axis xy
    end
    %}


%%
% Load Leipzig datasets.
load(fullfile(projectRoot, 'p0100_collectDipoles_Leipzig', 'Leipzig_n212'), 'dipMatrix', 'anatomicalLabels', 'columnLabels')
% columnLabels = {'subjIdx' 'icIdx' 'icLabelProb' 'icLabelClassIdx' 'dipX' 'dipY' 'dipZ' 'momX' 'momY' 'momZ' 'rv' 'aalLabelIdx' 'isCortical'}; % SubjIdx, icIdx, maxProb, maxIdx, posXyz, momXyz, labelIdx, isCortical

[~, L] = bwdist(extrapolatedAalTissue_onlySubcortical < 1e-3, 'euclidean');

aalLabel_isSubcortical = zeros(size(dipMatrix,1), 2);
for icIdx = 1:size(dipMatrix,1)

    if mod(icIdx, 1000) == 0
        disp(sprintf('%d/%d...', icIdx, size(dipMatrix,1)))
    end

    % Dipole location in XYZ.
    currentPos = dipMatrix(icIdx, 5:7);
    
    labelIdx = 0;    % default = outside/unknown

    % Invert the voxel->mm affine and map to continuous voxel coords
    Tinv = inv(aal.transform);           % This 4×4 affine matrix maps voxel indices → MNI millimeter coordinates
    ijk_h = (Tinv * [currentPos 1].').'; % 1×4
    ijk   = ijk_h(1,1:3);                % continuous (1-based)

    % Safer sampling with interpn (nearest neighbor)
    [I,J,K] = ndgrid(1:aal.dim(1), 1:aal.dim(2), 1:aal.dim(3));
    v = interpn(I, J, K, extrapolatedAalTissue_onlySubcortical, ijk(1), ijk(2), ijk(3), 'nearest', 0);
    labelIdx = uint16(v); % 0 = outside/background

    % Determine if it is cortical or not.
    if labelIdx == 0
        if (round(ijk(1))>=1 & round(ijk(1))<=91) & (round(ijk(2))>=1 & round(ijk(2))<=109) & (round(ijk(3))>=1 & round(ijk(3))<=91)
            [xn, yn, zn] = ind2sub(size(extrapolatedAalTissue_onlySubcortical), L(round(ijk(1)), round(ijk(2)), round(ijk(3))));
            labelIdx_hat = extrapolatedAalTissue_onlySubcortical(xn, yn, zn);
            dist_hat = sqrt(sum([ijk-[xn, yn, zn]].^2))*voxelSize;
            aalLabel_isSubcortical(icIdx,:) = [labelIdx_hat dist_hat];
        else
            aalLabel_isSubcortical(icIdx,:) = [NaN NaN];
        end
    else
        aalLabel_isSubcortical(icIdx,:) = [labelIdx 0];
    end
end

save(fullfile(projectRoot, 'p0231_modifiedAAL_Leipzig_subcorticalMask', 'modifiedAAL_subcortical_Leipzig'), "aalLabel_isSubcortical", 'dipMatrix')