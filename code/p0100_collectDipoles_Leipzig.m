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



% Set path to Fieldtrip's AAL library.

aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));
anatomicalLabels    = table([1:116]', aal.tissuelabel, 'VariableNames', {'Index' 'Labels'});
subcorticalLabelIdx = [21 22 29 30 37:42 71:78 92:116];
corticalLabelIdx    = setdiff(1:116, subcorticalLabelIdx);

    %{
    % Visually confirm the 'tissue'.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(aal.tissue(:,:,zIdx))
    end
    %}


%%
% Load Leipzig datasets.
allSets = dir(fullfile(projectRoot, 'p0000_preprocess_Leipzig', '*.set'));
dipMatrix = zeros(62*length(allSets), 13); % SubjIdx, icIdx, maxProb, maxIdx, posXyz, momXyz, rv, labelIdx, isCortical
rowCounter = 0;
for setIdx = 1:length(allSets)

    loadName = allSets(setIdx).name;
    loadPath = allSets(setIdx).folder;
    EEG = pop_loadset('filename', loadName, 'filepath', loadPath, 'loadmode', 'info');
    [classProb, classIdx] = max(EEG.etc.ic_classification.ICLabel.classifications, [], 2);

    for icIdx = 1:length(EEG.dipfit.model)

        % Obtain rv.
        currentRv = EEG.dipfit.model(icIdx).rv;

        % Obtain the current IC's dipole coordinate.
        currentPos = EEG.dipfit.model(icIdx).posxyz;
        currentMom = EEG.dipfit.model(icIdx).momxyz;
        if size(currentPos,1) == 2
            [~,maxIdx] = max(sqrt(sum(EEG.dipfit.model(icIdx).momxyz.^2,2)));
            currentPos = EEG.dipfit.model(icIdx).posxyz(maxIdx,:);
            currentMom = EEG.dipfit.model(icIdx).momxyz(maxIdx,:);;
        end

        labelIdx = 0;    % default = outside/unknown

        % Invert the voxel->mm affine and map to continuous voxel coords
        Tinv = inv(aal.transform);           % This 4×4 affine matrix maps voxel indices → MNI millimeter coordinates
        ijk_h = (Tinv * [currentPos 1].').'; % 1×4
        ijk   = ijk_h(1,1:3);                % continuous (1-based)

        % Safer sampling with interpn (nearest neighbor)
        [I,J,K] = ndgrid(1:aal.dim(1), 1:aal.dim(2), 1:aal.dim(3));
        v = interpn(I, J, K, double(aal.tissue), ijk(1), ijk(2), ijk(3), 'nearest', 0);
        labelIdx = uint16(v); % 0 = outside/background

                % % Identify the corresponding anatomical label.
                % aalCoordinates = round([(currentPos(1)-aal.transform(1,4))/aal.transform(1,1) ...
                %                         (currentPos(2)-aal.transform(2,4))/aal.transform(2,2) ...
                %                         (currentPos(3)-aal.transform(3,4))/aal.transform(3,3)]);
                % if  (aalCoordinates(1)>0 & aalCoordinates(1)<=size(aal.tissue,1)) & ...
                %         (aalCoordinates(2)>0 & aalCoordinates(2)<=size(aal.tissue,2)) & ...
                %         (aalCoordinates(3)>0 & aalCoordinates(3)<=size(aal.tissue,3))
                %     labelIdx = double(aal.tissue(aalCoordinates(1), aalCoordinates(2), aalCoordinates(3)));
                % else
                %     labelIdx = 0;
                % end

        % Determine if it is cortical or not.
        if ismember(labelIdx, corticalLabelIdx)
            isCortical = 1;
        else
            isCortical = 0;
        end
    
        % Store the results.
        rowCounter = rowCounter+1;
        dipMatrix(rowCounter,:) = [setIdx, icIdx, classProb(icIdx), classIdx(icIdx), currentPos, currentMom, currentRv, labelIdx, isCortical];
    end
end
columnLabels = {'subjIdx' 'icIdx' 'icLabelProb' 'icLabelClassIdx' 'dipX' 'dipY' 'dipZ' 'momX' 'momY' 'momZ' 'rv' 'aalLabelIdx' 'isCortical'}; % SubjIdx, icIdx, maxProb, maxIdx, posXyz, momXyz, labelIdx, isCortical
save(fullfile(projectRoot, 'p0100_collectDipoles_Leipzig', 'Leipzig_n212'), 'dipMatrix', 'anatomicalLabels', 'columnLabels')


%%
isBrain    = find(dipMatrix(:,4)==1); % SubjIdx, icIdx, maxProb, maxIdx, X, Y, Z, labelIdx, isCortical
isCortical = find(dipMatrix(:,13)==1);

brainRatio    = length(isBrain)/size(dipMatrix,1);  % 51.3%
corticalRatio = length(isCortical)/length(isBrain); % 72.2%