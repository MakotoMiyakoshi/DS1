% p1322_finalizeAngleFigures.m
% Finalized reference-axis sensitivity figure with boundary-corrected KDE.
% This stage supersedes p1320 for manuscript export quality.
%
% Main updates relative to p1320:
%   1) KDE uses bounded support [0, 90] with reflection boundary correction.
%   2) Legend label is renamed from "Local normal" to
%      "Template-boundary normal".
%   3) MATLAB exports PDF/EPS/PNG; separately generate a native SVG
%      whose labels remain live editable text for Illustrator.
%
% Input:
%   p1300_estimateDipDepth/dipoleGeometry.mat
%
% Output directory:
%   p1322_finalizeAngleFigures/
%
% Outputs:
%   Figure008_Angle_local_vs_MNI_v3.{svg,pdf,eps,png}
%   Figure008_Angle_local_vs_MNI_v3_stats.csv
%   Figure008_Angle_local_vs_MNI_v3_density.csv
%
% Run in a fresh MATLAB session.

clear;
close all;
clc;

stageName = mfilename;
codeDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(codeDir);
assert(strcmp(stageName,'p1322_finalizeAngleFigures'), ...
    'Script filename and declared stage name disagree.');
assert(strcmp(codeDir,fullfile(projectRoot,'code')), ...
    'Place the script directly under projectRoot/code/.');

sourceFile = fullfile(projectRoot,'p1300_estimateDipDepth', ...
    'dipoleGeometry.mat');
assert(isfile(sourceFile), 'Missing p1300 input: %s', sourceFile);
assert(exist('ksdensity','file')==2, ...
    'Statistics and Machine Learning Toolbox: ksdensity is required.');
S = load(sourceFile,'geometry','classification','meshQA');
assert(isfield(S,'geometry') && isfield(S,'classification') && ...
       isfield(S,'meshQA'), 'Unexpected p1300 MAT-file structure.');
G = S.geometry;
C = S.classification;
QA = S.meshQA;

assert(QA.nInsideDisagreement==0, ...
    'p1300 reports ray-parity conflicts. Review before visualization.');
assert(QA.maxBarycentricReconstructionError_mm < 1e-6, ...
    'p1300 barycentric reconstruction QA failed.');
assert(QA.nonTwoFaceEdges==0, ...
    'p1300 reported an open or nonmanifold surface mesh.');

idx = {C.surfaceRow(:), C.deepCortexRow(:), C.subCortexRow(:)};
labels = {'Surface cortex','Deep cortex','Subcortex'};
panelTags = {'(A)','(B)','(C)'};
Ntotal = numel(G.angleLocalAxial_deg);
allIdx = vertcat(idx{:});
assert(numel(allIdx)==QA.nClassified && ...
       numel(unique(allIdx))==numel(allIdx) && ...
       all(allIdx>=1 & allIdx<=Ntotal), ...
       'Classification is inconsistent with p1300 geometry.');
assert(numel(G.angleMNIAxial_deg)==Ntotal, ...
       'The two angular vectors have different lengths.');

localAngle = double(G.angleLocalAxial_deg(:));
mniAngle   = double(G.angleMNIAxial_deg(:));
assert(all(isfinite(localAngle(allIdx))) && all(isfinite(mniAngle(allIdx))), ...
       'Nonfinite angles in the classified data.');
assert(all(localAngle(allIdx)>=0 & localAngle(allIdx)<=90) && ...
       all(mniAngle(allIdx)>=0 & mniAngle(allIdx)<=90), ...
       'The comparison must use 0-90 degree axial angles.');

% Fixed plotting specification.
xGrid = linspace(0,90,451)';
% MATLAB ksdensity with reflection can return exactly zero at the *exact*
% support endpoints, although its one-sided interior limit is nonzero.
% Evaluate infinitesimally inside, then label the results at 0 and 90.
% This changes only displayed endpoint evaluation, not bandwidth, data,
% group statistics, or the specified [0,90] support.
queryGrid = xGrid;
queryGrid(1) = 1e-6;
queryGrid(end) = 90 - 1e-6;
localRGB = [0.55 0.73 0.85; ... % surface cortex: blue
            0.55 0.78 0.54; ... % deep cortex: green
            0.71 0.52 0.73];    % subcortex: purple
mniRGB = [0.10 0.10 0.10];

numberICs = zeros(3,1);
meanLocal = zeros(3,1);
meanMNI   = zeros(3,1);
medianLocal = zeros(3,1);
medianMNI   = zeros(3,1);
medianOfPairedDifference = zeros(3,1);
differenceOfMedians = zeros(3,1);
densityLocal = zeros(numel(xGrid),3);
densityMNI   = zeros(numel(xGrid),3);
areaLocal = zeros(3,1);
areaMNI   = zeros(3,1);

for k = 1:3
    q = idx{k};
    yLocal = localAngle(q);
    yMNI   = mniAngle(q);

    numberICs(k) = numel(q);
    meanLocal(k) = mean(yLocal);
    meanMNI(k)   = mean(yMNI);
    medianLocal(k) = median(yLocal);
    medianMNI(k)   = median(yMNI);
    differenceOfMedians(k) = medianLocal(k) - medianMNI(k);
    medianOfPairedDifference(k) = median(yLocal - yMNI);

    % Boundary-aware KDE for bounded angular support.
    densityLocal(:,k) = ksdensity(yLocal, queryGrid, ...
        'Support',[0 90], 'BoundaryCorrection','reflection');
    densityMNI(:,k) = ksdensity(yMNI, queryGrid, ...
        'Support',[0 90], 'BoundaryCorrection','reflection');

    % Guard against MATLAB releases that clamp values even infinitesimally
    % inside the support. With reflection, the endpoint derivative is zero,
    % so the value at the adjacent 0.2-degree sample is a stable fallback.
    if densityLocal(1,k)==0, densityLocal(1,k)=densityLocal(2,k); end
    if densityLocal(end,k)==0, densityLocal(end,k)=densityLocal(end-1,k); end
    if densityMNI(1,k)==0, densityMNI(1,k)=densityMNI(2,k); end
    if densityMNI(end,k)==0, densityMNI(end,k)=densityMNI(end-1,k); end

    areaLocal(k) = trapz(xGrid, densityLocal(:,k));
    areaMNI(k)   = trapz(xGrid, densityMNI(:,k));
end

assert(all(numberICs>0), 'Empty anatomical group.');
assert(sum(numberICs)==QA.nClassified, 'Classified IC count mismatch.');
assert(all(isfinite(densityLocal(:))) && all(isfinite(densityMNI(:))), ...
       'KDE returned a nonfinite value.');
assert(all(abs(areaLocal-1) < 0.02) && all(abs(areaMNI-1) < 0.02), ...
       'Boundary-corrected densities do not integrate to ~1 on [0,90].');

yMax = 0.022;
assert(max([densityLocal(:); densityMNI(:)]) < yMax, ...
       'KDE exceeds the fixed Y limit: revise and document the figure scale.');

outputDir = fullfile(projectRoot, stageName);
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

% ---- Standard MATLAB figure for editable PDF/EPS and raster PNG ----
% Legends are placed in a dedicated band ABOVE the plotting areas.
% This avoids obscuring the deep-cortex peak.
fig = figure('Visible','off', 'Color','w', ...
    'Units','pixels', 'Position',[50 50 1500 490], ...
    'Renderer','painters', 'InvertHardcopy','off');

for k = 1:3
    axLeft = 0.062+(k-1)*0.327;
    ax = axes('Parent',fig, 'Units','normalized', ...
        'Position',[axLeft 0.185 0.253 0.548]);
    hold(ax,'on');
    plot(ax,xGrid,densityLocal(:,k),'-', ...
        'Color',localRGB(k,:),'LineWidth',2.7);
    plot(ax,xGrid,densityMNI(:,k),'--', ...
        'Color',mniRGB,'LineWidth',2.1);

    xlim(ax,[0 90]);
    ylim(ax,[0 yMax]);
    set(ax,'XTick',[0 20 40 60 80 90], ...
        'YTick',[0 0.005 0.010 0.015 0.020], ...
        'FontName','Arial', 'FontSize',10.5, ...
        'LineWidth',0.85,'TickDir','out','TickLength',[0.016 0.016], ...
        'Box','off','XColor',[0.16 0.16 0.16],'YColor',[0.16 0.16 0.16]);
    xlabel(ax,'Axial angle (degrees)','FontName','Arial','FontSize',11.5);
    if k==1
        ylabel(ax,'Estimated probability density', ...
            'FontName','Arial','FontSize',11.5);
    end

    % MATLAB annotations use figure-normalized coordinates.
    annotation(fig,'textbox',[axLeft-0.005 0.912 0.263 0.066], ...
        'String',sprintf('%s %s (N=%d)',panelTags{k},labels{k},numberICs(k)), ...
        'FitBoxToText','off','EdgeColor','none', ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FontName','Arial','FontSize',12.8,'FontWeight','bold', ...
        'Interpreter','none');

    legendYs = [0.854 0.808];
    legendText = {sprintf('Template-boundary normal (median %.1f)',medianLocal(k)), ...
                  sprintf('MNI radial (median %.1f)',medianMNI(k))};
    for m=1:2
        if m==1
            rgb = localRGB(k,:);
            style = '-';
            lineWidth = 2.7;
        else
            rgb = mniRGB;
            style = '--';
            lineWidth = 2.1;
        end
        annotation(fig,'line',[axLeft+0.006 axLeft+0.046], ...
            [legendYs(m) legendYs(m)], ...
            'Color',rgb,'LineStyle',style,'LineWidth',lineWidth);
        annotation(fig,'textbox', ...
            [axLeft+0.049 legendYs(m)-0.021 0.232 0.041], ...
            'String',legendText{m},'FitBoxToText','off', ...
            'EdgeColor','none','Interpreter','none', ...
            'FontName','Arial','FontSize',9.0, ...
            'VerticalAlignment','middle');
    end
end

filePrefix = 'Figure008_Angle_local_vs_MNI_v3';
exportgraphics(fig,fullfile(outputDir,[filePrefix '.pdf']), ...
    'ContentType','vector','BackgroundColor','white');
print(fig,fullfile(outputDir,[filePrefix '.eps']),'-depsc2','-painters');
exportgraphics(fig,fullfile(outputDir,[filePrefix '.png']), ...
    'Resolution',600,'BackgroundColor','white');
close(fig);

% ---- Native SVG with LIVE TEXT (not glyph outlines) ----
% MATLAB's -dsvg export frequently replaces all glyphs with paths.
% Write the plot geometry as standards-compliant SVG: axes, curves, labels,
% title and legends remain distinct editable vector/text objects.
% Coordinates are in user-space pixels; no external renderer or font file
% is required to create the SVG. Illustrator resolves Arial when opening.
svgPath = fullfile(outputDir,[filePrefix '.svg']);
fid = fopen(svgPath,'wt');
assert(fid>=0,'Cannot create native editable SVG: %s',svgPath);
svgW = 1500;
svgH = 490;
svgLeft = [94 584 1074];
svgPlotW = 378;
svgPlotTop = 151;
svgPlotBottom = 399;
svgPlotH = svgPlotBottom-svgPlotTop;
hexLocal = {'#8CBAD9','#8CC78A','#B585BA'};

fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,['<svg xmlns="http://www.w3.org/2000/svg" ' ...
    'width="%d" height="%d" viewBox="0 0 %d %d">\n'], ...
    svgW,svgH,svgW,svgH);
fprintf(fid,'<title>Figure 8: Dipole axial angle and reference direction</title>\n');
fprintf(fid,'<desc>Three cortical-depth groups, with reflected bounded KDE curves.</desc>\n');
fprintf(fid,'<rect x="0" y="0" width="%d" height="%d" fill="white"/>\n', ...
    svgW,svgH);
fprintf(fid,['<g fill="#242424" font-family="Arial,Helvetica,sans-serif" ' ...
    'font-weight="normal">\n']);

for k=1:3
    left = svgLeft(k);
    right = left+svgPlotW;
    fprintf(fid,'<g id="panel_%c">\n',char('A'+k-1));

    fprintf(fid,['<text x="%.2f" y="38" text-anchor="middle" ' ...
        'font-size="21" font-weight="bold">%s %s (N=%d)</text>\n'], ...
        left+svgPlotW/2,panelTags{k},labels{k},numberICs(k));

    fprintf(fid,['<line x1="%g" y1="76" x2="%g" y2="76" ' ...
        'stroke="%s" stroke-width="4"/>\n'], ...
        left+10,left+72,hexLocal{k});
    fprintf(fid,['<text x="%g" y="82" font-size="16">' ...
        'Template-boundary normal (median %.1f)</text>\n'], ...
        left+79,medianLocal(k));
    fprintf(fid,['<line x1="%g" y1="109" x2="%g" y2="109" ' ...
        'stroke="#1A1A1A" stroke-width="3.2" stroke-dasharray="9 7"/>\n'], ...
        left+10,left+72);
    fprintf(fid,['<text x="%g" y="115" font-size="16">' ...
        'MNI radial (median %.1f)</text>\n'], ...
        left+79,medianMNI(k));

    % Axes and ticks
    fprintf(fid,['<path d="M %g %g L %g %g M %g %g L %g %g" ' ...
        'fill="none" stroke="#292929" stroke-width="1.5"/>\n'], ...
        left,svgPlotTop,left,svgPlotBottom, ...
        left,svgPlotBottom,right,svgPlotBottom);
    xt = [0 20 40 60 80 90];
    for t=xt
        x = left + (t/90)*svgPlotW;
        fprintf(fid,['<line x1="%.3f" y1="%g" x2="%.3f" y2="%g" ' ...
            'stroke="#292929" stroke-width="1.2"/>\n'], ...
            x,svgPlotBottom,x,svgPlotBottom+7);
        fprintf(fid,['<text x="%.3f" y="%g" font-size="17" ' ...
            'text-anchor="middle">%d</text>\n'], ...
            x,svgPlotBottom+29,t);
    end
    yt=[0 .005 .010 .015 .020];
    ylabels={'0','0.005','0.01','0.015','0.02'};
    for t=1:numel(yt)
        y = svgPlotBottom - yt(t)/yMax*svgPlotH;
        fprintf(fid,['<line x1="%g" y1="%.3f" x2="%g" y2="%.3f" ' ...
            'stroke="#292929" stroke-width="1.2"/>\n'], ...
            left-7,y,left,y);
        fprintf(fid,['<text x="%g" y="%.3f" font-size="17" ' ...
            'text-anchor="end">%s</text>\n'], ...
            left-15,y+6,ylabels{t});
    end
    fprintf(fid,['<text x="%.3f" y="467" font-size="19" ' ...
        'text-anchor="middle">Axial angle (degrees)</text>\n'], ...
        left+svgPlotW/2);
    if k==1
        fprintf(fid,['<text x="24" y="%.3f" font-size="19" ' ...
            'text-anchor="middle" ' ...
            'transform="rotate(-90 24 %.3f)">' ...
            'Estimated probability density</text>\n'], ...
            (svgPlotTop+svgPlotBottom)/2,(svgPlotTop+svgPlotBottom)/2);
    end

    xp = left + (xGrid/90)*svgPlotW;
    yp1 = svgPlotBottom - (densityLocal(:,k)/yMax)*svgPlotH;
    yp2 = svgPlotBottom - (densityMNI(:,k)/yMax)*svgPlotH;
    points1 = sprintf('%.3f,%.3f ',[xp.'; yp1.']);
    points2 = sprintf('%.3f,%.3f ',[xp.'; yp2.']);
    fprintf(fid,['<polyline id="local_normal_%c" points="%s" ' ...
        'fill="none" stroke="%s" stroke-width="4" ' ...
        'stroke-linejoin="round" stroke-linecap="round"/>\n'], ...
        char('A'+k-1),points1,hexLocal{k});
    fprintf(fid,['<polyline id="mni_radial_%c" points="%s" ' ...
        'fill="none" stroke="#1A1A1A" stroke-width="3.3" ' ...
        'stroke-dasharray="9 7" stroke-linejoin="round"/>\n'], ...
        char('A'+k-1),points2);
    fprintf(fid,'</g>\n');
end
fprintf(fid,'</g>\n</svg>\n');
status=fclose(fid);
assert(status==0,'Could not finalize native editable SVG.');

% Confirm the native SVG really does contain editable live text.
svgText=fileread(svgPath);
assert(contains(svgText,'<text ') && ...
       contains(svgText,'Template-boundary normal'), ...
       'Native SVG text-content QA failed.');

summary = table(string(labels(:)), numberICs, meanLocal, meanMNI, ...
    medianLocal, medianMNI, differenceOfMedians, medianOfPairedDifference, ...
    areaLocal, areaMNI, ...
    'VariableNames', {'Group','N','MeanLocal_deg','MeanMNIRadial_deg', ...
    'MedianLocal_deg','MedianMNIRadial_deg', ...
    'DifferenceOfMedians_deg','MedianPairedDifference_deg', ...
    'IntegratedDensityLocal_0to90','IntegratedDensityMNI_0to90'});
writetable(summary, fullfile(outputDir,[filePrefix '_stats.csv']));

densityTable = table(xGrid, densityLocal(:,1), densityMNI(:,1), ...
    densityLocal(:,2), densityMNI(:,2), densityLocal(:,3), densityMNI(:,3), ...
    'VariableNames', {'Angle_deg','Surface_Local','Surface_MNI', ...
    'Deep_Local','Deep_MNI','Subcortex_Local','Subcortex_MNI'});
writetable(densityTable, fullfile(outputDir,[filePrefix '_density.csv']));

fprintf('\n=== p1322: finalized reference-axis sensitivity figure ===\n');
disp(summary);
fprintf('Shared x range: 0 to 90 deg; shared y range: 0 to %.3f.\n', yMax);
fprintf('Output directory: %s\n', outputDir);
fprintf(['Exported %s in SVG, vector PDF, EPS, and 600 dpi PNG.\n' ...
         'Native SVG contains live text (no glyph outlining).\n'], filePrefix);
