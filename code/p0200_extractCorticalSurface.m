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



% Set path to Fieldtrip's AAL library.

aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));

% aal.transform
% 
% ans =
% 
%     -2     0     0    92
%      0     2     0  -128
%      0     0     2   -74
%      0     0     0     1

anatomicalLabels    = table([1:116]', aal.tissuelabel, 'VariableNames', {'Index' 'Labels'});
%subcorticalLabelIdx = [21 22 29 30 37:42 71:78 92:116];
subcorticalLabelIdx = 92:116; % Removing cerebellum only.
%subcorticalLabelIdx = []; % Using everything.
corticalLabelIdx    = setdiff(1:116, subcorticalLabelIdx);

    %{
    % Visually confirm the 'tissue'.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(aal.tissue(:,:,zIdx)'); axis xy
    end
    %}

% Remove non-EEG sources from the 'tissue'.
eegSourceTissue_orig = aal.tissue;
for nonEegSourceIdx = 1:length(subcorticalLabelIdx)
    currentNonEegSourceTissue = subcorticalLabelIdx(nonEegSourceIdx);
    eegSourceTissue_orig(eegSourceTissue_orig==currentNonEegSourceTissue) = 0;
end

    %{
    % Visually confirm the eegSourceTissue.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(eegSourceTissue_orig(:,:,zIdx)'); axis xy
    end
    %}


%% Partially mirror LR to make the closed path around the circumference.
eegSourceTissue = logical(eegSourceTissue_orig);

% Manually correct the surface to make a closed path.
zIdx = 24;
currentImage  = eegSourceTissue(:,:,zIdx);
invertedImage = currentImage(end:-1:1,:);
overlaidImage = currentImage;
overlaidImage(1:46,1:35) = invertedImage(1:46,1:35);
eegSourceTissue(:,:,zIdx) = overlaidImage;

zIdx = 25;
currentImage  = eegSourceTissue(:,:,zIdx);
invertedImage = currentImage(end:-1:1,:);
overlaidImage = currentImage;
overlaidImage(1:46,1:35) = invertedImage(1:46,1:35);
eegSourceTissue(:,:,zIdx) = overlaidImage;

zIdx = 26;
currentImage  = eegSourceTissue(:,:,zIdx);
invertedImage = currentImage(end:-1:1,:);
overlaidImage = currentImage;
overlaidImage(1:46,1:34) = invertedImage(1:46,1:34);
eegSourceTissue(:,:,zIdx) = overlaidImage;

zIdx = 27;
currentImage  = eegSourceTissue(:,:,zIdx);
invertedImage = currentImage(end:-1:1,:);
overlaidImage = currentImage;
overlaidImage(1:46,1:31) = invertedImage(1:46,1:31);
eegSourceTissue(:,:,zIdx) = overlaidImage;

zIdx = 28;
currentImage  = eegSourceTissue(:,:,zIdx);
invertedImage = currentImage(end:-1:1,:);
overlaidImage = currentImage;
overlaidImage(1:46,1:31) = invertedImage(1:46,1:31);
eegSourceTissue(:,:,zIdx) = overlaidImage;

    %{
    % Visually confirm the 'tissue'.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(eegSourceTissue(:,:,zIdx)'); axis xy
    end
    %}


%% Connect LR to make the closed path around the circumference.
zIdx = 24;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge([23 24], 36) = 1;
currentEdge([45:47], 26) = 1;
currentEdge(17,36) = 1;
eegSourceTissue(:,:,zIdx) = currentEdge;

zIdx = 25;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge(45:47, 26) = 1; % Connecting the hemispheres at the posterior end.
eegSourceTissue(:,:,zIdx) = currentEdge;

zIdx = 26;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge(21,34) = 1; % Connecting the hemispheres at the posterior end.
currentEdge(46, 24) = 1; % Connecting the hemispheres at the posterior end.
eegSourceTissue(:,:,zIdx) = currentEdge;

zIdx = 27;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge(46,22) = 1; % Connecting the hemispheres at the posterior end.
eegSourceTissue(:,:,zIdx) = currentEdge;

zIdx = 28;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge(46,22) = 1; % Connecting the hemispheres at the posterior end.
eegSourceTissue(:,:,zIdx) = currentEdge;

zIdx = 29;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge(39:46, 18) = 1; % Connecting the hemispheres at the posterior end.
eegSourceTissue(:,:,zIdx) = currentEdge;

zIdx = 30;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge(39:46, 16) = 1; % Connecting the hemispheres at the posterior end.
eegSourceTissue(:,:,zIdx) = currentEdge;

zIdx = 31;
currentEdge  = eegSourceTissue(:,:,zIdx);
currentEdge(44, 20) = 1; % Connecting the hemispheres at the posterior end.
eegSourceTissue(:,:,zIdx) = currentEdge;

% Fill in the model.
corticalMask = false(size(eegSourceTissue));
for zIdx = 1:91
    corticalMask(:,:,zIdx) = imfill(eegSourceTissue(:,:,zIdx), 'holes');
end

    %{
    % Visually confirm the 'tissue'.
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(corticalMask(:,:,zIdx))
    end
    %}


%% Convert the cortical mask into a mesh.
[X,Y,Z] = ndgrid(1:size(corticalMask,1), 1:size(corticalMask,2), 1:size(corticalMask,3));
vox = [X(:) Y(:) Z(:) ones(numel(X),1)];
xyz_mm = (aal.transform * vox.').';
Xmm = reshape(xyz_mm(:,1), size(corticalMask));
Ymm = reshape(xyz_mm(:,2), size(corticalMask));
Zmm = reshape(xyz_mm(:,3), size(corticalMask));
fv = isosurface(Xmm, Ymm, Zmm, double(corticalMask), 0.5);

figure; hold on;
trisurf(fv.faces, fv.vertices(:,1), fv.vertices(:,2), fv.vertices(:,3), ...
        'FaceColor',[0.8 0.7 1], 'EdgeColor','none', 'FaceAlpha',0.5);
axis equal; view(3); camlight; lighting gouraud;
title('Mesh generated from AAL mask (in mm space)');
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');

% Check water-tightness.
F = fv.faces;
E = sort([F(:,[1,2]); F(:,[2,3]); F(:,[3,1])], 2);
[ue,~,ic] = unique(E,'rows');
bad = sum(accumarray(ic,1) ~= 2);
fprintf('Non-watertight edges: %d (0 is watertight)\n', bad);

% Print the axial slices.
figure('position', [1 1 2498 1209])
tiledlayout(7,13,"TileSpacing","none","Padding","tight")
for zIdx = 1:aal.dim(3)
    nexttile
    imagesc(corticalMask(:,:,zIdx)', [0 1]); axis xy
end
print(fullfile(projectRoot, 'p0200_extractCorticalSurface', 'corticalMask'), '-djpeg95', '-r200')

% Save the output.
save(fullfile(projectRoot, 'p0200_extractCorticalSurface', 'corticalMask'), 'corticalMask', 'fv', 'aal')
disp('Done.')