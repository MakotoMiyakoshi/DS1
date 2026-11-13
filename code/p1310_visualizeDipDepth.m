% p1310_visualizeDipDepth.m
% Render revised depth and dipole-orientation figures from p1300 geometry.
%
% Design references inspected (NOT runtime inputs): Figure004.ai, Figure007.ai.
% Figure004: updated depth histograms corresponding to panels G-I, plus a
% pooled depth audit. Other Illustrator panels are intentionally unchanged.
% Figure007: layout-matched seven-row axial mosaic, three histograms and
% three probability-density curves, in both signed and axial definitions.
% Diagnostic: local-normal versus MNI-radial axial angles.
%
% Inputs ONLY from earlier p-numbered stage output directories:
%   p1300_estimateDipDepth/dipoleGeometry.mat
%   p0210_checkDipfitDefaultModel/corticalMask.mat (AAL affine/dim)
% No p0300 data, no third-party plotting functions, no GUI, no random inputs.
% Requires MATLAB with Statistics and Machine Learning Toolbox (ksdensity).
% Outputs ONLY in p1310_visualizeDipDepth/.
%
% IMPORTANT: Original Figure 7A averages angles linearly within a voxel.
% This is retained solely for visual comparability with the supplied art.
% The sign-invariant axial version is provided separately. A spatial
% average of angles is NOT the same as acosd(mean(abs(dot)))).

clear;
close all;
clc;

stageName = mfilename;
codeDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(codeDir);
assert(strcmp(stageName,'p1310_visualizeDipDepth'), 'Unexpected script name.');
assert(strcmp(codeDir,fullfile(projectRoot,'code')), ...
    'This script must sit directly in projectRoot/code/.');
outDir = fullfile(projectRoot,stageName);
if ~exist(outDir,'dir')
    mkdir(outDir);
end

% --- Stage dependencies and explicit field validation. ---
S = load(fullfile(projectRoot,'p1300_estimateDipDepth', ...
    'dipoleGeometry.mat'),'geometry','classification','meshQA');
G = S.geometry;
C = S.classification;
assert(S.meshQA.nInsideDisagreement==0, ...
    'p1300 has ray-parity conflicts; review before plotting.');
assert(S.meshQA.maxBarycentricReconstructionError_mm < 1e-6, ...
    'p1300 failed barycentric QA.');
A = load(fullfile(projectRoot,'p0210_checkDipfitDefaultModel', ...
    'corticalMask.mat'),'aal');
assert(isfield(A,'aal') && isfield(A.aal,'transform') && ...
       isfield(A.aal,'dim'), 'AAL transform not saved in p0210 output.');
T = double(A.aal.transform);
dim = double(A.aal.dim(:)');
assert(isequal(size(T),[4 4]) && numel(dim)==3, 'Invalid AAL grid.');
assert(all(dim==[91 109 91]), 'Unexpected AAL grid.');

idx = {C.surfaceRow(:),C.deepCortexRow(:),C.subCortexRow(:)};
groupNames = {'Surface cortex','Deep cortex','Subcortex'};
colors = [0.55 0.73 0.85; 0.55 0.78 0.54; 0.71 0.52 0.73];
fillColors = [0.84 0.90 0.94; 0.84 0.93 0.86; 0.91 0.84 0.91];
n = numel(G.signedDistance_mm);
allRows = vertcat(idx{:});
assert(numel(unique(allRows))==numel(allRows) && ...
    all(allRows>=1) && all(allRows<=n), 'Invalid anatomical groups.');
assert(numel(allRows)==S.meshQA.nClassified, ...
    'Group membership does not match p1300 QA.');

% --- One summary used for plot annotations and audit CSV. ---
N = zeros(3,1);
depthMean = zeros(3,1);
depthSD = zeros(3,1);
depthMedian = zeros(3,1);
signedMean = zeros(3,1);
signedSD = zeros(3,1);
signedMedian = zeros(3,1);
axialMean = zeros(3,1);
axialMedian = zeros(3,1);
mniMedian = zeros(3,1);
for k=1:3
    q=idx{k};
    N(k)=numel(q);
    depthMean(k)=mean(G.signedDistance_mm(q));
    depthSD(k)=std(G.signedDistance_mm(q));
    depthMedian(k)=median(G.signedDistance_mm(q));
    signedMean(k)=mean(G.angleLocalSigned_deg(q));
    signedSD(k)=std(G.angleLocalSigned_deg(q));
    signedMedian(k)=median(G.angleLocalSigned_deg(q));
    axialMean(k)=mean(G.angleLocalAxial_deg(q));
    axialMedian(k)=median(G.angleLocalAxial_deg(q));
    mniMedian(k)=median(G.angleMNIAxial_deg(q));
end
stats = table(groupNames',N,depthMean,depthSD,depthMedian, ...
    signedMean,signedSD,signedMedian,axialMean,axialMedian,mniMedian, ...
    'VariableNames',{'Group','N','DepthMean_mm','DepthSD_mm', ...
    'DepthMedian_mm','SignedAngleMean_deg','SignedAngleSD_deg', ...
    'SignedAngleMedian_deg','AxialAngleMean_deg', ...
    'AxialAngleMedian_deg','MNIAxialMedian_deg'});
writetable(stats,fullfile(outDir,'p1310_summary.csv'));

% =====================================================================
% Figure 004: drop-in revised depth histograms for panels G, H and I.
% Retain the reference's 2-mm bins, -60:12 range, and pale-blue bars.
% =====================================================================
fig = figure('Visible','off','Color','w','Units','pixels', ...
    'Position',[50 50 1200 390],'Renderer','painters');
for k=1:3
    ax=axes('Parent',fig,'Units','normalized', ...
        'Position',[0.075+(k-1)*0.319 0.18 0.274 0.65]);
    histogram(ax,G.signedDistance_mm(idx{k}),-60:2:12, ...
        'FaceColor',[0.76 0.82 0.93],'FaceAlpha',1, ...
        'EdgeColor','k','LineWidth',0.55);
    xlim(ax,[-62 12]);
    ylim(ax,[0 1300]);
    xticks(ax,[-60 -40 -20 0]);
    xlabel(ax,'Depth (mm)','FontSize',11);
    if k==1
        ylabel(ax,'IC Counts','FontSize',11);
    end
    title(ax,sprintf('(%s) %s',char('F'+k),groupNames{k}), ...
        'FontWeight','bold','FontSize',12);
    text(ax,0.055,0.96, ...
        sprintf('M = %+.1f mm (SD %.1f)\nMedian %+.1f mm', ...
        depthMean(k),depthSD(k),depthMedian(k)), ...
        'Units','normalized','VerticalAlignment','top', ...
        'FontSize',9,'FontAngle','italic');
    set(ax,'FontName','Arial','FontSize',10,'LineWidth',0.8,'Box','off', ...
        'TickDir','out');
end
exportgraphics(fig,fullfile(outDir,'Figure004_G-I_depth.pdf'), ...
    'ContentType','vector','BackgroundColor','white');
print(fig,fullfile(outDir,'Figure004_G-I_depth.svg'),'-dsvg','-painters');
exportgraphics(fig,fullfile(outDir,'Figure004_G-I_depth.png'), ...
    'Resolution',600,'BackgroundColor','white');
close(fig);

% Additional audit of the pooled depth distribution; not an Illustrator
% replacement panel, because the original Figure 004 does not show this.
fig = figure('Visible','off','Color','w','Units','pixels', ...
    'Position',[50 50 920 485],'Renderer','painters');
ax=axes('Parent',fig,'Position',[0.12 0.18 0.83 0.72]);
depthAll=G.signedDistance_mm(allRows);
histogram(ax,depthAll,-70:2:20,'FaceColor',[0.73 0.82 0.94], ...
    'EdgeColor',[0.25 0.30 0.38]);
hold(ax,'on');
xline(ax,-5,'--','LineWidth',1.5,'Color',[0.75 0.25 0.24]);
xline(ax,-14,':','LineWidth',1.6,'Color',[0.27 0.37 0.64]);
xlabel(ax,'Signed distance to cortical boundary (mm)');
ylabel(ax,'IC counts (2-mm bins)');
title(ax,sprintf('N = %d    Depth >5 mm: %.2f%%    Depth >14 mm: %.2f%%', ...
    numel(depthAll),100*mean(depthAll< -5),100*mean(depthAll< -14)), ...
    'FontWeight','normal');
set(ax,'FontName','Arial','FontSize',12,'Box','off');
exportgraphics(fig,fullfile(outDir,'Depth_pooled_audit.pdf'), ...
    'ContentType','vector','BackgroundColor','white');
print(fig,fullfile(outDir,'Depth_pooled_audit.svg'),'-dsvg','-painters');
exportgraphics(fig,fullfile(outDir,'Depth_pooled_audit.png'), ...
    'Resolution',600,'BackgroundColor','white');
close(fig);

% =====================================================================
% Figure 007 A-C in the layout of Figure007.ai (US Letter proportions).
% Two versions: original-presentation signed angle, and axial angle.
% The native MNI AAL affine is from p0210 rather than a guessed origin.
% =====================================================================
centerIJK=[(dim(1)+1)/2*ones(dim(3),1), ...
           (dim(2)+1)/2*ones(dim(3),1), ...
           (1:dim(3))',ones(dim(3),1)];
centerMM=(T*centerIJK')';
zMM=centerMM(:,3);
zSlices=find(zMM>=-72-1e-5 & zMM<=98+1e-5);
assert(numel(zSlices)==86 && all(abs(diff(zMM(zSlices))-2)<1e-5), ...
    'Unexpected AAL z coordinate mapping; do not mislabel figure slices.');

pos=G.dipPos_mm(allRows,:);
posHom=[pos ones(size(pos,1),1)];
ijkRound=round((T\posHom')');
ijkRound=ijkRound(:,1:3);
validVoxel=all(isfinite(ijkRound),2) & ...
    all(ijkRound>=1 & ijkRound<=dim,2);
ijkValid=ijkRound(validVoxel,:);
voxId=sub2ind(dim,ijkValid(:,1),ijkValid(:,2),ijkValid(:,3));
countLinear=accumarray(voxId,1,[prod(dim),1],@sum,0);
countVol=reshape(countLinear,dim);

% This reproduces the original makeDipoleAngleVolume smoothing algorithm.
% Gaussian sigma is 2 mm along each world-space voxel direction.
voxelSize=sqrt(sum(T(1:3,1:3).^2,1));
sigmaVox=2./voxelSize;
kernels=cell(1,3);
for axisNo=1:3
    radius=max(1,ceil(3*sigmaVox(axisNo)));
    coord=-radius:radius;
    kern=exp(-0.5*(coord/sigmaVox(axisNo)).^2);
    kernels{axisNo}=kern/sum(kern);
end
smoothCount=convn(countVol,reshape(kernels{1},[],1,1),'same');
smoothCount=convn(smoothCount,reshape(kernels{2},1,[],1),'same');
smoothCount=convn(smoothCount,reshape(kernels{3},1,1,[]),'same');

figureVersions={'Signed','Axial'};
for version=1:2
    if version==1
        values=G.angleLocalSigned_deg(allRows);
        maxAngle=180;
        edges=0:10:180;
        figTitle='(A) Mean dipole angle relative to template-boundary normal';
        figPrefix='Figure007_signed';
    else
        values=G.angleLocalAxial_deg(allRows);
        maxAngle=90;
        edges=0:5:90;
        figTitle='(A) Axial dipole angle relative to template-boundary normal';
        figPrefix='Figure007_axial';
    end
    valueSum=accumarray(voxId,values(validVoxel),[prod(dim),1],@sum,0);
    valueVol=reshape(valueSum,dim);
    smoothValues=convn(valueVol,reshape(kernels{1},[],1,1),'same');
    smoothValues=convn(smoothValues,reshape(kernels{2},1,[],1),'same');
    smoothValues=convn(smoothValues,reshape(kernels{3},1,1,[]),'same');
    meanVol=zeros(dim);
    hit=smoothCount>0;
    meanVol(hit)=smoothValues(hit)./smoothCount(hit);
    clear valueVol smoothValues valueSum;

    fig=figure('Visible','off','Color','w','Units','pixels', ...
        'Position',[50 50 935 1210],'Renderer','painters');
    annotation(fig,'textbox',[0.08 0.967 0.84 0.025], ...
        'String',figTitle,'FontName','Arial','FontSize',14, ...
        'FontWeight','bold','HorizontalAlignment','center', ...
        'VerticalAlignment','middle','LineStyle','none');
    cmap=jet(256);
    rowTops=[58 156 250 344 439 533 628];
    rowHeights=[81 78 80 80 79 83 84];
    for t=1:numel(zSlices)
        k=zSlices(t);
        row=floor((t-1)/13)+1;
        col=mod(t-1,13)+1;
        xx=(19+(col-1)*69.7)/935;
        yy=1-(rowTops(row)+rowHeights(row))/1210;
        ww=65/935;
        hh=rowHeights(row)/1210;
        ax=axes('Parent',fig,'Units','normalized', ...
            'Position',[xx yy ww hh],'Visible','off', ...
            'Color','k');
        valueSlice=meanVol(:,:,k);
        active=smoothCount(:,:,k)>0;
        mapped=1+floor(255*max(0,min(maxAngle,valueSlice))/maxAngle);
        mapped(~active)=1;
        im=reshape(cmap(mapped(:),:),[dim(1),dim(2),3]);
        for rgb=1:3
            plane=im(:,:,rgb);
            plane(~active)=0;
            im(:,:,rgb)=plane;
        end
        image(ax,permute(im,[2 1 3]));
        set(ax,'YDir','normal','XLim',[0.5 dim(1)+0.5], ...
            'YLim',[0.5 dim(2)+0.5]);
        axis(ax,'off');
        title(ax,sprintf('z=%dmm',round(zMM(k))), ...
            'FontName','Arial','FontSize',7.4,'FontWeight','normal', ...
            'Color','k','Units','normalized','Position',[0.5 1.04 0]);
    end
    % Inline color scale in the unused cells of the last mosaic row.
    cax=axes('Parent',fig,'Units','normalized','Position', ...
        [0.618 0.413 0.013 0.067]);
    imagesc(cax,[0 1],[0 maxAngle],linspace(0,maxAngle,256)');
    set(cax,'YDir','normal','XTick',[],'YTick',[], ...
        'Box','off','Visible','off');
    colormap(cax,cmap);
    text(cax,1.8,maxAngle, sprintf('%d',maxAngle), ...
        'FontName','Arial','FontSize',7,'VerticalAlignment','middle');
    text(cax,1.8,maxAngle/2,sprintf('%d',maxAngle/2), ...
        'FontName','Arial','FontSize',7,'VerticalAlignment','middle');
    text(cax,1.8,0,'0','FontName','Arial','FontSize',7, ...
        'VerticalAlignment','middle');
    text(cax,0.5,maxAngle*1.12,'degrees','FontName','Arial','FontSize',7);

    annotation(fig,'textbox',[0.035 0.382 0.675 0.022], ...
        'String','(B) Histogram of brain dipole angles', ...
        'FontName','Arial','FontSize',13,'FontWeight','bold', ...
        'HorizontalAlignment','center','LineStyle','none');
    annotation(fig,'textbox',[0.774 0.382 0.214 0.022], ...
        'String','(C) PDF of brain dipole angles', ...
        'FontName','Arial','FontSize',12,'FontWeight','bold', ...
        'HorizontalAlignment','center','LineStyle','none');
    gridX=[0.064 0.286 0.519];
    gridW=[0.190 0.185 0.191];
    for k=1:3
        vv=values; % compact group order: surface; deep; subcortex.
        starts=[1 1+N(1) 1+N(1)+N(2)];
        q=starts(k):(starts(k)+N(k)-1);
        v=vv(q);
        ax=axes('Parent',fig,'Units','normalized', ...
            'Position',[gridX(k) 0.176 gridW(k) 0.182]);
        histogram(ax,v,edges,'FaceColor',fillColors(k,:), ...
            'FaceAlpha',1,'EdgeColor','k','LineWidth',0.65);
        xlim(ax,[0 maxAngle]);
        if version==1
            ylim(ax,[0 1250]);
            xticks(ax,[0 50 100 150]);
        else
            ylim(ax,[0 max(1250,ceil(N(k)*0.25/100)*100)]);
            xticks(ax,[0 30 60 90]);
        end
        xlabel(ax,'Angle (degree)','FontSize',9);
        if k==1
            ylabel(ax,'Counts','FontSize',9);
        end
        set(ax,'FontName','Arial','FontSize',8.5,'LineWidth',0.8, ...
            'Box','off','TickDir','out');
        title(ax,groupNames{k},'FontName','Arial','FontSize',10, ...
            'FontWeight','bold');
        text(ax,0.23,0.84, ...
            sprintf('M %.1f deg (SD %.1f)\nMedian %.1f deg', ...
                mean(v),std(v),median(v)), ...
            'Units','normalized','FontSize',8.3,'FontAngle','italic', ...
            'VerticalAlignment','top');
    end
    ax=axes('Parent',fig,'Units','normalized', ...
        'Position',[0.784 0.176 0.194 0.182]);
    hold(ax,'on');
    angleGrid=linspace(0,maxAngle,181);
    for k=1:3
        q=idx{k};
        if version==1
            v=G.angleLocalSigned_deg(q);
        else
            v=G.angleLocalAxial_deg(q);
        end
        density=ksdensity(v,angleGrid);
        plot(ax,angleGrid,density,'LineWidth',2.3,'Color',colors(k,:));
    end
    xlabel(ax,'Angle (degree)','FontSize',9);
    ylabel(ax,'Estimated probability density','FontSize',9);
    xlim(ax,[0 maxAngle]);
    set(ax,'FontName','Arial','FontSize',8.5,'LineWidth',0.8, ...
        'Box','off','TickDir','out');
    legend(ax,groupNames,'FontSize',8,'Location','northeast','Box','off');

    % A mosaic consists of raster image objects; labels/axes are vector.
    exportgraphics(fig,fullfile(outDir,[figPrefix '.pdf']), ...
        'ContentType','vector','BackgroundColor','white');
    print(fig,fullfile(outDir,[figPrefix '.svg']),'-dsvg','-painters');
    exportgraphics(fig,fullfile(outDir,[figPrefix '.png']), ...
        'Resolution',600,'BackgroundColor','white');
    close(fig);
end

% =====================================================================
% Additional sensitivity analysis: paired axial angles, same 3 IC groups.
% =====================================================================
fig=figure('Visible','off','Color','w','Units','pixels', ...
    'Position',[50 50 1200 400],'Renderer','painters');
for k=1:3
    ax=axes('Parent',fig,'Units','normalized', ...
        'Position',[0.075+(k-1)*0.32 0.18 0.275 0.65]);
    hold(ax,'on');
    vLocal=G.angleLocalAxial_deg(idx{k});
    vMNI=G.angleMNIAxial_deg(idx{k});
    xx=0:2:90;
    plot(ax,xx,ksdensity(vLocal,xx),'Color',colors(k,:), ...
        'LineWidth',2.6);
    plot(ax,xx,ksdensity(vMNI,xx),'Color',[0.1 0.1 0.1], ...
        'LineStyle','--','LineWidth',2);
    xlim(ax,[0 90]);
    xlabel(ax,'Axial angle (degree)');
    if k==1
        ylabel(ax,'Estimated probability density');
    end
    title(ax,sprintf('%s (N=%d)',groupNames{k},N(k)), ...
        'FontWeight','bold');
    legend(ax,{sprintf('Local (median %.1f)',median(vLocal)), ...
        sprintf('MNI radial (median %.1f)',median(vMNI))}, ...
        'Location','northeast','FontSize',9,'Box','off');
    set(ax,'FontName','Arial','FontSize',10,'Box','off');
end
exportgraphics(fig,fullfile(outDir,'Angle_local_vs_MNI.pdf'), ...
    'ContentType','vector','BackgroundColor','white');
print(fig,fullfile(outDir,'Angle_local_vs_MNI.svg'),'-dsvg','-painters');
exportgraphics(fig,fullfile(outDir,'Angle_local_vs_MNI.png'), ...
    'Resolution',600,'BackgroundColor','white');
close(fig);

fprintf('\n=== p1310 visualization complete ===\n');
disp(stats);
fprintf('Classified N: %d; >5 mm depth: %.2f%%; >14 mm: %.2f%%\n', ...
    numel(depthAll),100*mean(depthAll< -5),100*mean(depthAll< -14));
fprintf('Output directory: %s\n',outDir);
