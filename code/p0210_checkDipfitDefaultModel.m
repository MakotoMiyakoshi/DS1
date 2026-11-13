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
% 10/20/2025 Makoto. Created. Conclusion: It is better to use EEGLAB's head model.



% Load dummy EEG data.
EEG = pop_loadset('filename','sub-002.set','filepath',fullfile(projectRoot, 'p0010_preprocess_Dortmund'), 'loadmode', 'info');

% Extract dipfit's default head model for EEGLAB.
load(EEG.dipfit.hdmfile); % This loads 'vol' used in EEGLAB.
V = double(vol.bnd(3).pnt); % Using EEGLAB's cortical mask.
F = double(vol.bnd(3).tri);

% Load AAL just to get the SAME affine as p0200

aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));
T = aal.transform;                      % same affine as p0200 (vox -> mm)


%% Build the AAL voxel grid (same size & axis order as p0200)
gsize = [91 109 91];                    % X,Y,Z
[X,Y,Z] = ndgrid(1:gsize(1), 1:gsize(2), 1:gsize(3));
vox = [X(:) Y(:) Z(:) ones(numel(X),1)];
xyz_mm = (T * vox.').';                 % voxel centers -> mm
P = xyz_mm(:,1:3);                      % [Nvox x 3]


%% Inside test: voxel center vs cortical surface
% Preferred: inpolyhedron (File Exchange, very fast & robust)
% If you have it:
addpath(getenv('DS1_INPOLYHEDRON_ROOT'))
try
    inside = inpolyhedron(F, V, P);     % logical [Nvox x 1]
catch
    % Fallback: simple ray-parity along +X (slower, but self-contained).
    % Counts intersections of a +X ray from each voxel with all triangles
    % and classifies inside if #hits is odd.
    warning('inpolyhedron not found; using a slower ray-parity fallback.');
    inside = pointInMesh_rayParity(P, V, F);  % defined below
end

% Reshape to 3-D logical mask in AAL grid
corticalMask = false(gsize);
corticalMask(:) = inside;


%% Remove the weired scalp-shaped mask issue.
corticalMask = ~corticalMask;
    %{
    figure
    tiledlayout(7,13,"TileSpacing","none","Padding","tight")
    for zIdx = 1:aal.dim(3)
        nexttile
        imagesc(squeeze(corticalMask(:,:,zIdx))'); axis xy 
    end
    %}

% Remove the head-shape mask.
noBrainIdx = [1:5 82:91];
outsideCortexMask = median(corticalMask(:,:,noBrainIdx),3);
corticalMask_extracted = false(size(corticalMask));
for zIdx = 1:91
    currentSlice = corticalMask(:,:,zIdx);

    if ismember(zIdx, noBrainIdx)
        currentSlice = false(size(currentSlice));
    else
        currentSlice(outsideCortexMask) = 0;

        [L,NUM] = bwlabel(currentSlice);

        % Remove small fractions.
        numPixelVec = zeros(NUM,1);
        for clusterIdx = 1:NUM
            currentNumPixels = sum(sum(L==clusterIdx));
            numPixelVec(clusterIdx) = currentNumPixels;
        end
        [~,maxIdx] = max(numPixelVec);
        BW1 = L==maxIdx;

        % Fill in holes.
        se = strel('sphere', 2); % try radius 1 or 2
        BW2 = imclose(BW1, se);  % dilate→erode (connects gaps)
        BW3 = imfill(BW2, 'holes');
        corticalMask_extracted(:,:,zIdx) = BW3;
    end
end

figure('position', [1 1 2498 1209])
tiledlayout(7,13,"TileSpacing","none","Padding","tight")
for zIdx = 1:aal.dim(3)
    nexttile
    imagesc(squeeze(corticalMask_extracted(:,:,zIdx))'); axis xy
end


%% Compare the results.

% Using precomputed EEGLAB-default head model.
load(fullfile(projectRoot, 'p0200_extractCorticalSurface', 'corticalMask.mat'))
corticalMask_AAL = corticalMask;
clear corticalMask;
figure('position', [1 1 2498 1209])
tiledlayout(7,13,"TileSpacing","none","Padding","tight")
for zIdx = 1:aal.dim(3)
    nexttile
    imagesc(squeeze(corticalMask_AAL(:,:,zIdx))'); axis xy
end


%% Plot the difference
diffMask = corticalMask_extracted-corticalMask_AAL;

figure('position', [1 1 1800 1200])
tiledlayout(7,13,"TileSpacing","compact","Padding","tight")
for zIdx = 1:aal.dim(3)
    nexttile
    imagesc(squeeze(diffMask(:,:,zIdx))', [-1 1]);
    colormap jet
    axis xy
    set(gca, 'xtick', [], 'ytick', [])
    title(sprintf('z=%dmm', -74+2*zIdx))
end
%title('Red, Dipfit>AAL; Blue, AAL>Dipfit')
exportgraphics(gcf, fullfile(projectRoot, 'p0210_checkDipfitDefaultModel', 'diffMasks.pdf'),  'Resolution', 300, 'ContentType', 'vector')
exportgraphics(gcf, fullfile(projectRoot, 'p0210_checkDipfitDefaultModel', 'diffMasks.jpeg'), 'Resolution', 200, 'ContentType', 'image')


%% Re-define high-resolution FV from dipfit's head model.

aal = ft_read_atlas(fullfile(fieldtripRoot,'template','atlas','aal','ROI_MNI_V4.nii'));

[X,Y,Z] = ndgrid(1:size(corticalMask_extracted,1), 1:size(corticalMask_extracted,2), 1:size(corticalMask_extracted,3));
vox = [X(:) Y(:) Z(:) ones(numel(X),1)];
xyz_mm = (aal.transform * vox.').';
Xmm = reshape(xyz_mm(:,1), size(corticalMask_extracted));
Ymm = reshape(xyz_mm(:,2), size(corticalMask_extracted));
Zmm = reshape(xyz_mm(:,3), size(corticalMask_extracted));
fv = isosurface(Xmm, Ymm, Zmm, double(corticalMask_extracted), 0.5);

    %{
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Check XYZ ranges of the mesh. %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    V = fv.vertices;
    fprintf('Mesh X-range: [%.1f .. %.1f] mm\n', min(V(:,1)), max(V(:,1)));
    fprintf('Mesh Y-range: [%.1f .. %.1f] mm\n', min(V(:,2)), max(V(:,2)));
    fprintf('Mesh Z-range: [%.1f .. %.1f] mm\n', min(V(:,3)), max(V(:,3)));
    %}

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

% Save the output.
corticalMask = corticalMask_extracted;
save(fullfile(projectRoot, 'p0210_checkDipfitDefaultModel', 'corticalMask'), 'corticalMask', 'fv', 'aal')
disp('Done.')