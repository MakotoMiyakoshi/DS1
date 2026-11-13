%% p1400_figure8AngleDepth.m
% DS1 / Cortex -- Figure 8: paired 2 x 2 angle-depth histograms.
%
% Left  block (A-D): polarity-invariant angle vs local boundary normal
%                     (corresponds to Figure 7B).
% Right block (E-H): polarity-invariant angle vs MNI-origin radial direction
%                     (corresponds to Figure 7C).
%
% The only data dependency is the corrected p1300 output.  This script
% lives directly in projectRoot/code/ and writes exclusively to the
% matching p1400_figure8AngleDepth/ stage output directory.
%
% Definitions:
%   Angle: 0 = radial, 90 = tangential; ICA polarity is disregarded.
%   Depth: -geometry.signedDistance_mm, positive inward / negative outward.
%   Histogram bins: 3 degrees by 1 mm, identical for all eight panels.
%   Smoothing: separable 2-D Gaussian, sigma = 1.5 bins in BOTH axes;
%              for display and peak detection, not for integer bin counts.
%   Color scale: matched for each local/MNI pair, not between depth groups.
%
% MATLAB R2023a-compatible. No toolboxes, helpers, random numbers, user
% input, workspace variables, or other pipeline output directories needed.

clearvars;
close all;
clc;

%% 1. TRACE paths and strict provenance
stageName = mfilename;
assert(strcmp(stageName, 'p1400_figure8AngleDepth'), ...
    'Script must be named p1400_figure8AngleDepth.m.');
codeDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(codeDir);
assert(strcmp(codeDir, fullfile(projectRoot, 'code')), ...
    'Put the script directly under the project code/ directory.');

inputFile = fullfile(projectRoot, 'p1300_estimateDipDepth', 'dipoleGeometry.mat');
outputDir = fullfile(projectRoot, stageName);
assert(isfile(inputFile), 'Corrected p1300 MAT file not found: %s', inputFile);
if ~isfolder(outputDir)
    [ok, message] = mkdir(outputDir);
    assert(ok, 'Cannot create output directory: %s', message);
end

S = load(inputFile, 'geometry', 'classification', 'meshQA');
assert(isfield(S,'geometry') && isfield(S,'classification') && ...
    isfield(S,'meshQA'), 'Incorrect or incomplete p1300 MAT file.');
g = S.geometry;
c = S.classification;
meshQA = S.meshQA;

requiredGeometry = {'signedDistance_mm','nearestDistance_mm', ...
    'angleLocalAxial_deg','angleMNIAxial_deg','globalIdx'};
for k = 1:numel(requiredGeometry)
    assert(isfield(g,requiredGeometry{k}), ...
        'Missing geometry.%s', requiredGeometry{k});
end
requiredClassification = {'surfaceRow','deepCortexRow', ...
    'subCortexRow','selectedIdx'};
for k = 1:numel(requiredClassification)
    assert(isfield(c,requiredClassification{k}), ...
        'Missing classification.%s',requiredClassification{k});
end

localAngle = double(g.angleLocalAxial_deg(:));
mniAngle   = double(g.angleMNIAxial_deg(:));
signedD    = double(g.signedDistance_mm(:));
inwardD    = -signedD;
nearestD   = double(g.nearestDistance_mm(:));
nGeometry  = numel(signedD);

assert(all([numel(localAngle),numel(mniAngle),numel(nearestD), ...
    numel(g.globalIdx),numel(c.selectedIdx)] == nGeometry), ...
    'Incorrect compact geometry array lengths.');
assert(all(isfinite(localAngle)) && all(isfinite(mniAngle)) && ...
    all(isfinite(inwardD)), 'Nonfinite geometry values encountered.');
assert(all(localAngle>=0 & localAngle<=90) && ...
    all(mniAngle>=0 & mniAngle<=90), 'Axial angles must be in [0,90].');
assert(max(abs(abs(signedD)-nearestD))<1e-9, ...
    'Signed and unsigned distances disagree.');
assert(isequal(double(g.globalIdx(:)),double(c.selectedIdx(:))), ...
    'Global IC index alignment differs between geometry and classification.');
assert(meshQA.nInsideDisagreement == 0 && ...
    meshQA.maxBarycentricReconstructionError_mm<1e-9, ...
    'p1300 geometry quality checks failed.');
assert(meshQA.nSelected == nGeometry && meshQA.nClassified == 14578, ...
    'Unexpected p1300 selected/classified counts.');

%% 2. Use compact geometry ROW numbers, never original global IC indices
surfaceRow = double(c.surfaceRow(:));
deepRow = double(c.deepCortexRow(:));
subRow = double(c.subCortexRow(:));
allRow = [surfaceRow;deepRow;subRow];
rows = {surfaceRow,deepRow,subRow,allRow};
expectedN = [2873,7656,4049,14578];
for i = 1:4
    rr = rows{i};
    assert(numel(rr)==expectedN(i), 'Unexpected group count, group %d.',i);
    assert(all(isfinite(rr) & rr==floor(rr) & rr>=1 & rr<=nGeometry), ...
        'Invalid compact geometry row numbers, group %d.',i);
    assert(numel(unique(rr))==numel(rr), ...
        'Duplicate compact geometry rows within group %d.',i);
end
assert(numel(unique(allRow))==numel(allRow), 'IC groups overlap.');
assert(numel(allRow)==14578 && numel(setdiff(1:nGeometry,allRow))==218, ...
    'Qualified/unclassified IC accounting failed.');

% The comparison is between orientation REFERENCES only.
% The depth and row memberships MUST be identical across columns.
anglesByReference = {localAngle,mniAngle};
referenceNames = {'Local boundary normal','MNI-origin radial direction'};
groupNames = {'Surface cortex','Deep cortex','Subcortex', ...
    'All qualified Brain ICs'};
groupShort = {'Surface cortex','Deep cortex','Subcortex','All Brain ICs'};

%% 3. Common bin lattice and explicitly defined Gaussian kernel
angleEdges = 0:3:90;            % 30 bins
inwardDepthEdges = -10:1:65;   % 75 bins, includes exterior observations
angleCenters = (angleEdges(1:end-1)+angleEdges(2:end))/2;
depthCenters = (inwardDepthEdges(1:end-1)+inwardDepthEdges(2:end))/2;
assert(min(inwardD(allRow))>=inwardDepthEdges(1) && ...
    max(inwardD(allRow))<=inwardDepthEdges(end), ...
    'Some ICs would be excluded: widen depth edges AND displayed axes.');
assert(min(inwardD(surfaceRow))>=-10 && max(inwardD(surfaceRow))<=5, ...
    'The magnified Surface cortex axes would clip observations.');

sigmaBins = 1.5;
kernelRadius = ceil(4*sigmaBins);
t = -kernelRadius:kernelRadius;
w = exp(-0.5*(t/sigmaBins).^2);
w = w/sum(w);
gaussianKernel = w(:)*w(:)';  % orientation bins x depth bins

rawCounts = cell(4,2);
smoothedCounts = cell(4,2);
peakAngle_deg = zeros(4,2);
peakDepth_mm = zeros(4,2);
peakSmoothedCount = zeros(4,2);
peakRawCount = zeros(4,2);
peakAngleLower_deg = zeros(4,2);
peakAngleUpper_deg = zeros(4,2);
peakDepthLower_mm = zeros(4,2);
peakDepthUpper_mm = zeros(4,2);
rawMaxCount = zeros(4,2);
rawMaxAngle_deg = zeros(4,2);
rawMaxDepth_mm = zeros(4,2);
medianAngle_deg = zeros(4,2);
medianDepth_mm = zeros(4,2);
minDepth_mm = zeros(4,2);
maxDepth_mm = zeros(4,2);
nExterior = zeros(4,2);

for ref = 1:2
    for i = 1:4
        rr = rows{i};
        A = anglesByReference{ref}(rr);
        D = inwardD(rr);
        assert(all(A>=0 & A<=90) && all(isfinite(A)) && ...
            all(isfinite(D)), 'Invalid plotted values.');
        raw = histcounts2(A,D,angleEdges,inwardDepthEdges);
        smooth = conv2(double(raw),gaussianKernel,'same');
        assert(isequal(size(raw),[30,75]), 'Unexpected histogram dimensions.');
        assert(sum(raw(:))==expectedN(i), ...
            'Histogram did not capture every IC: group %d, ref %d.',i,ref);
        rawCounts{i,ref} = raw;
        smoothedCounts{i,ref} = smooth;
        medianAngle_deg(i,ref) = median(A);
        medianDepth_mm(i,ref) = median(D);
        minDepth_mm(i,ref) = min(D);
        maxDepth_mm(i,ref) = max(D);
        nExterior(i,ref) = nnz(D<0);

        [peakSmoothedCount(i,ref),loc] = max(smooth(:));
        [ai,di] = ind2sub(size(smooth),loc);
        peakAngle_deg(i,ref) = angleCenters(ai);
        peakDepth_mm(i,ref) = depthCenters(di);
        peakRawCount(i,ref) = raw(ai,di);
        peakAngleLower_deg(i,ref) = angleEdges(ai);
        peakAngleUpper_deg(i,ref) = angleEdges(ai+1);
        peakDepthLower_mm(i,ref) = inwardDepthEdges(di);
        peakDepthUpper_mm(i,ref) = inwardDepthEdges(di+1);

        [rawMaxCount(i,ref),locRaw] = max(raw(:));
        [aiRaw,diRaw] = ind2sub(size(raw),locRaw);
        rawMaxAngle_deg(i,ref) = angleCenters(aiRaw);
        rawMaxDepth_mm(i,ref) = depthCenters(diRaw);
    end
end

%% 4. Numerical QA: groups, references, bins and smoothed counts
for ref = 1:2
    assert(isequal(rawCounts{4,ref}, ...
        rawCounts{1,ref}+rawCounts{2,ref}+rawCounts{3,ref}), ...
        'All ICs bin counts differ from the sum of three groups.');
    sumSmooth = smoothedCounts{1,ref}+smoothedCounts{2,ref}+ ...
        smoothedCounts{3,ref};
    assert(max(abs(smoothedCounts{4,ref}(:)-sumSmooth(:)))<1e-9, ...
        'All ICs smoothed counts differ from the group sum.');
end
assert(all(nExterior(:,1)==nExterior(:,2)), ...
    'Exterior IC counts depend on the reference angle, which is impossible.');
assert(all(medianDepth_mm(:,1)==medianDepth_mm(:,2)), ...
    'Depth values differ between angle references.');

% Matched COLOR SCALES for each same-group local/MNI pair.
% The A-D and E-H panels need not share one global range, since Ns differ.
pairedColorMax = zeros(4,1);
for i = 1:4
    m = max([max(smoothedCounts{i,1}(:)),max(smoothedCounts{i,2}(:))]);
    pairedColorMax(i) = 5*ceil(m/5);
    assert(pairedColorMax(i)>0);
end

%% 5. Tables: integer bin counts and reproducible peak statistics
[angleBinIdx,depthBinIdx] = ndgrid(1:numel(angleCenters), ...
    1:numel(depthCenters));
flatAI = angleBinIdx(:);
flatDI = depthBinIdx(:);
nBins = numel(flatAI);
binTables = cell(8,1);
peakRows = cell(8,1);
for ref = 1:2
    for i = 1:4
        panelIndex = i+4*(ref-1);   % A-D local; E-H MNI
        panelLetter = char(double('A')+panelIndex-1);
        binTables{panelIndex} = table( ...
            repmat(string(panelLetter),nBins,1), ...
            repmat(string(groupNames{i}),nBins,1), ...
            repmat(string(referenceNames{ref}),nBins,1), ...
            reshape(angleEdges(flatAI),[],1), ...
            reshape(angleEdges(flatAI+1),[],1), ...
            reshape(angleCenters(flatAI),[],1), ...
            reshape(inwardDepthEdges(flatDI),[],1), ...
            reshape(inwardDepthEdges(flatDI+1),[],1), ...
            reshape(depthCenters(flatDI),[],1), ...
            rawCounts{i,ref}(:),smoothedCounts{i,ref}(:), ...
            'VariableNames',{'panel','group','reference', ...
            'angle_bin_lower_deg','angle_bin_upper_deg','angle_center_deg', ...
            'inward_depth_bin_lower_mm','inward_depth_bin_upper_mm', ...
            'inward_depth_center_mm','raw_count','smoothed_count'});

        peakRows{panelIndex} = table( ...
            string(panelLetter),string(groupNames{i}), ...
            string(referenceNames{ref}),expectedN(i),nExterior(i,ref), ...
            medianAngle_deg(i,ref),medianDepth_mm(i,ref), ...
            minDepth_mm(i,ref),maxDepth_mm(i,ref), ...
            peakAngle_deg(i,ref),peakDepth_mm(i,ref), ...
            peakRawCount(i,ref),peakSmoothedCount(i,ref), ...
            peakAngleLower_deg(i,ref),peakAngleUpper_deg(i,ref), ...
            peakDepthLower_mm(i,ref),peakDepthUpper_mm(i,ref), ...
            rawMaxCount(i,ref),rawMaxAngle_deg(i,ref),rawMaxDepth_mm(i,ref), ...
            pairedColorMax(i), ...
            'VariableNames',{'panel','group','reference','n_ic','n_exterior', ...
            'median_axial_angle_deg','median_inward_depth_mm', ...
            'min_inward_depth_mm','max_inward_depth_mm', ...
            'peak_angle_deg','peak_inward_depth_mm', ...
            'peak_raw_count','peak_smoothed_count', ...
            'peak_angle_lower_deg','peak_angle_upper_deg', ...
            'peak_depth_lower_mm','peak_depth_upper_mm', ...
            'raw_max_count','raw_max_angle_deg','raw_max_depth_mm', ...
            'paired_colorbar_max_count'});
    end
end
binTable = vertcat(binTables{:});
peakTable = vertcat(peakRows{:});
assert(sum(binTable.raw_count)==4*14578, ...
    'Eight panels must each count all their members, twice per reference.');
assert(height(binTable)==8*nBins && height(peakTable)==8);

comparisonTable = table( ...
    string(groupNames(:)), ...
    expectedN(:), ...
    medianAngle_deg(:,1),medianAngle_deg(:,2), ...
    medianAngle_deg(:,2)-medianAngle_deg(:,1), ...
    peakAngle_deg(:,1),peakAngle_deg(:,2), ...
    peakAngle_deg(:,2)-peakAngle_deg(:,1), ...
    peakDepth_mm(:,1),peakDepth_mm(:,2), ...
    'VariableNames',{'group','n_ic', ...
    'median_local_deg','median_mni_deg','median_mni_minus_local_deg', ...
    'peak_local_deg','peak_mni_deg','peak_mni_minus_local_deg', ...
    'peak_local_depth_mm','peak_mni_depth_mm'});

writetable(binTable,fullfile(outputDir,'Figure8_bin_counts.csv'));
writetable(peakTable,fullfile(outputDir,'Figure8_peak_statistics.csv'));
writetable(comparisonTable,fullfile(outputDir,'Figure8_reference_comparison.csv'));

histogramData = struct();
histogramData.inputFile = inputFile;
histogramData.stageName = stageName;
histogramData.groupNames = groupNames;
histogramData.referenceNames = referenceNames;
histogramData.expectedN = expectedN;
histogramData.angleEdges_deg = angleEdges;
histogramData.inwardDepthEdges_mm = inwardDepthEdges;
histogramData.angleCenters_deg = angleCenters;
histogramData.depthCenters_mm = depthCenters;
histogramData.sigmaBins = sigmaBins;
histogramData.gaussianKernel = gaussianKernel;
histogramData.rawCounts = rawCounts;
histogramData.smoothedCounts = smoothedCounts;
histogramData.pairedColorMax = pairedColorMax;
histogramData.peakTable = peakTable;
histogramData.comparisonTable = comparisonTable;
histogramData.meshQA = meshQA;
save(fullfile(outputDir,'Figure8_histogram_data.mat'), ...
    'histogramData','-v7.3');

%% 6. Draw 2 x 4: LEFT 2 x 2 local, RIGHT 2 x 2 MNI
% Physical layout, in normalized figure coordinates.  Titles are kept
% above their axes; paired groups have identical color maps and limits.
fig = figure('Color','white','Units','centimeters', ...
    'Position',[1.5 1.5 42 23], 'Renderer','painters', ...
    'Visible','off');
set(fig,'PaperPositionMode','auto','InvertHardcopy','off');
colX = [0.054,0.298,0.544,0.788];
rowY = [0.577,0.155];  % top row, bottom row
axWidth = 0.158;
axHeight = 0.268;
cbarGap = 0.006;
cbarWidth = 0.009;

colormap(fig,hot(256));
for ref = 1:2
    for i = 1:4
        panelIndex = i+4*(ref-1);
        letter = char(double('A')+panelIndex-1);
        groupCol = mod(i-1,2)+1;
        groupRow = floor((i-1)/2)+1;
        col = groupCol+2*(ref-1);
        xpos = colX(col);
        ypos = rowY(groupRow);
        ax = axes('Parent',fig,'Units','normalized', ...
            'Position',[xpos,ypos,axWidth,axHeight]);

        smooth = smoothedCounts{i,ref};
        vmax = pairedColorMax(i);
        contourf(ax,angleCenters,depthCenters,smooth', ...
            linspace(0,vmax,31),'LineColor','none');
        hold(ax,'on');
        caxis(ax,[0 vmax]);
        plot(ax,[0 90],[0 0],'--','Color',[0.73 0.73 0.73], ...
            'LineWidth',0.85);
        scatter(ax,peakAngle_deg(i,ref),peakDepth_mm(i,ref), ...
            58,[0.22 0.33 0.93],'filled','MarkerEdgeColor','white', ...
            'LineWidth',0.7);
        xlim(ax,[0 90]);
        if i==1
            ylim(ax,[-10 5]);
            yticks(ax,[-10 -5 0 5]);
        else
            ylim(ax,[-10 65]);
            yticks(ax,[-10 0 20 40 60]);
        end
        xticks(ax,[0 30 60 90]);
        set(ax,'FontName','Arial','FontSize',9.0,'Box','on', ...
            'Layer','top','TickDir','out');
        if groupCol==1
            ylabel(ax,'Inward depth (mm)','FontSize',9.5);
        end

        if expectedN(i)>=1000
            nString = sprintf('%d,%03d',floor(expectedN(i)/1000), ...
                mod(expectedN(i),1000));
        else
            nString = sprintf('%d',expectedN(i));
        end
        title(ax,{sprintf('(%s) %s  (n=%s)',letter,groupShort{i},nString), ...
            sprintf('Peak %.1f deg, %.1f mm', ...
                peakAngle_deg(i,ref),peakDepth_mm(i,ref))}, ...
            'FontSize',10.2,'FontWeight','normal');

        cb = colorbar(ax,'eastoutside');
        cb.Units = 'normalized';
        cb.Position = [xpos+axWidth+cbarGap,ypos,cbarWidth,axHeight];
        cb.Ticks = [0,vmax/2,vmax];
        cb.FontName = 'Arial';
        cb.FontSize = 8.2;
        % Colorbar creation can shrink the axes; restore fixed placement.
        ax.Units = 'normalized';
        ax.Position = [xpos,ypos,axWidth,axHeight];
    end
end

annotation(fig,'textbox',[0.054 0.944 0.435 0.034], ...
    'String','LOCAL BOUNDARY NORMAL  (Figure 7B)', ...
    'EdgeColor','none','HorizontalAlignment','center', ...
    'FontName','Arial','FontSize',12,'FontWeight','bold');
annotation(fig,'textbox',[0.544 0.944 0.435 0.034], ...
    'String','MNI-ORIGIN RADIAL DIRECTION  (Figure 7C)', ...
    'EdgeColor','none','HorizontalAlignment','center', ...
    'FontName','Arial','FontSize',12,'FontWeight','bold');
annotation(fig,'textbox',[0.054 0.091 0.435 0.028], ...
    'String','Local axial angle (deg)', ...
    'EdgeColor','none','HorizontalAlignment','center', ...
    'FontName','Arial','FontSize',11);
annotation(fig,'textbox',[0.544 0.091 0.435 0.028], ...
    'String','MNI-origin axial angle (deg)', ...
    'EdgeColor','none','HorizontalAlignment','center', ...
    'FontName','Arial','FontSize',11);
annotation(fig,'textbox',[0.055 0.030 0.91 0.027], ...
    'String',['Color = smoothed IC count / (3 deg x 1 mm bin); ', ...
        'color scales matched within each Local/MNI group pair. ', ...
        'Dashed line = template boundary (0 mm); negative depth = exterior.'], ...
    'EdgeColor','none','HorizontalAlignment','center', ...
    'FontName','Arial','FontSize',8.7);

drawnow;
exportgraphics(fig,fullfile(outputDir,'Figure8_local_vs_MNI.pdf'), ...
    'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,fullfile(outputDir,'Figure8_local_vs_MNI.png'), ...
    'Resolution',600,'BackgroundColor','white');
print(fig,fullfile(outputDir,'Figure8_local_vs_MNI.svg'), ...
    '-dsvg','-painters');
print(fig,fullfile(outputDir,'Figure8_local_vs_MNI.eps'), ...
    '-depsc','-painters');
savefig(fig,fullfile(outputDir,'Figure8_local_vs_MNI.fig'));
close(fig);

%% 7. Plain-text audit, written only by this stage
fid = fopen(fullfile(outputDir,'Figure8_QA.txt'),'wt');
assert(fid>=0,'Cannot create QA report.');
fprintf(fid,'Stage: %s\n',stageName);
fprintf(fid,'Corrected input: %s\n',inputFile);
fprintf(fid,'Geometry rows: %d; qualified rows: %d; unclassified: %d\n', ...
    nGeometry,numel(allRow),nGeometry-numel(allRow));
fprintf(fid,'Reference A-D: geometry.angleLocalAxial_deg\n');
fprintf(fid,'Reference E-H: geometry.angleMNIAxial_deg\n');
fprintf(fid,'Inward depth = -geometry.signedDistance_mm\n');
fprintf(fid,'Bin widths: angle 3 deg; depth 1 mm\n');
fprintf(fid,'Gaussian sigma: %.1f bins; radius: %d bins\n', ...
    sigmaBins,kernelRadius);
fprintf(fid,'Observed inward-depth range (qualified): %.6f .. %.6f mm\n', ...
    min(inwardD(allRow)),max(inwardD(allRow)));
fprintf(fid,'Mesh barycentric error: %.15g mm; ray conflicts: %d\n', ...
    meshQA.maxBarycentricReconstructionError_mm, ...
    meshQA.nInsideDisagreement);
for i = 1:4
    fprintf(fid,'%s: N=%d, exterior=%d, color max=%g\n', ...
        groupNames{i},expectedN(i),nExterior(i,1),pairedColorMax(i));
    for ref = 1:2
        fprintf(fid,'  %s: peak = %.1f deg, %.1f mm (smooth=%g)\n', ...
            referenceNames{ref},peakAngle_deg(i,ref),peakDepth_mm(i,ref), ...
            peakSmoothedCount(i,ref));
    end
end
fprintf(fid,'QA: ALL COUNT / BIN CONSERVATION / RANGE TESTS PASSED.\n');
fclose(fid);

fprintf('p1400 Figure 8 created in %s\n',outputDir);
disp(peakTable(:,{'panel','group','reference','n_ic', ...
    'peak_angle_deg','peak_inward_depth_mm'}));
disp(comparisonTable);
