% p1341_finalizeFigure007.m
% Figure 7, combined presentation of axial-angle tomography and the
% two reference-axis definitions.
%
% Panel A: spatial Gaussian-weighted MEAN AXIAL ANGLE relative to the
%          local template brain-compartment boundary normal.
% Panel B: bounded KDE of local-normal axial angles, three IC groups.
% Panel C: bounded KDE of MNI-origin radial axial angles, same groups.
%
% In all panels an axial angle is polarity-invariant (0 to 90 degrees).
% The spatial average in panel A is an average of scalar axial ANGLES,
% not the orientation of an averaged dipole vector.
%
% Inputs:   p1300_estimateDipDepth/dipoleGeometry.mat
%           p0210_checkDipfitDefaultModel/corticalMask.mat
% Outputs:  p1341_finalizeFigure007/ ONLY
%
% No reads of p1330 or p132x. No changes to any prior-stage outputs.
% Generated SVG has live/editable text, vector KDE curves and axes, and
% a single embedded raster mosaic of the 86 colored axial slices.
% MATLAB R2023a; Statistics and Machine Learning Toolbox for ksdensity.

clear;
close all;
clc;

stageName = mfilename;
codeDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(codeDir);
assert(strcmp(stageName,'p1341_finalizeFigure007'), ...
    'The script name must be p1341_finalizeFigure007.m.');
assert(strcmp(codeDir,fullfile(projectRoot,'code')), ...
    'Place the pipeline script directly under projectRoot/code/.');
assert(exist('ksdensity','file')==2, ...
    'Statistics and Machine Learning Toolbox (ksdensity) is required.');

geometryFile = fullfile(projectRoot,'p1300_estimateDipDepth', ...
    'dipoleGeometry.mat');
atlasFile = fullfile(projectRoot,'p0210_checkDipfitDefaultModel', ...
    'corticalMask.mat');
assert(isfile(geometryFile) && isfile(atlasFile), ...
    'Required lower-numbered stage outputs are missing.');

S=load(geometryFile,'geometry','classification','meshQA');
A=load(atlasFile,'aal');
assert(isfield(S,'geometry') && isfield(S,'classification') && ...
    isfield(S,'meshQA') && isfield(A,'aal'), ...
    'Unexpected input MAT-file structure.');
G=S.geometry;
C=S.classification;
QA=S.meshQA;
assert(QA.nInsideDisagreement==0 && QA.nonTwoFaceEdges==0 && ...
    QA.maxBarycentricReconstructionError_mm < 1e-6, ...
    'p1300 geometric quality assurance failed.');

idx={C.surfaceRow(:),C.deepCortexRow(:),C.subCortexRow(:)};
groupLabels={'Surface cortex','Deep cortex','Subcortex'};
colors=[0.55 0.73 0.85; 0.55 0.78 0.54; 0.71 0.52 0.73];
allRows=vertcat(idx{:});
nAll=numel(G.angleLocalAxial_deg);
assert(numel(allRows)==QA.nClassified && ...
    numel(unique(allRows))==numel(allRows) && ...
    all(allRows>=1 & allRows<=nAll), ...
    'Classified IC rows are not consistent with p1300.');
assert(numel(G.angleMNIAxial_deg)==nAll && ...
    size(G.dipPos_mm,1)==nAll, ...
    'Dipole positions and angle data have inconsistent dimensions.');

localAngle=double(G.angleLocalAxial_deg(:));
mniAngle=double(G.angleMNIAxial_deg(:));
assert(all(isfinite(localAngle(allRows))) && ...
    all(isfinite(mniAngle(allRows))) && ...
    all(localAngle(allRows)>=0 & localAngle(allRows)<=90) && ...
    all(mniAngle(allRows)>=0 & mniAngle(allRows)<=90), ...
    'Both angle definitions must be finite and lie in [0,90].');

% --- Group statistics and identical, boundary-corrected KDE settings. ---
angleGrid=linspace(0,90,451)';
queryGrid=angleGrid;
queryGrid(1)=1e-6;
queryGrid(end)=90-1e-6;
nGroups=3;
N=zeros(nGroups,1);
meanLocal=zeros(nGroups,1);
meanMNI=zeros(nGroups,1);
medianLocal=zeros(nGroups,1);
medianMNI=zeros(nGroups,1);
medianPaired=zeros(nGroups,1);
densityLocal=zeros(numel(angleGrid),nGroups);
densityMNI=zeros(numel(angleGrid),nGroups);
areaLocal=zeros(nGroups,1);
areaMNI=zeros(nGroups,1);

for k=1:nGroups
    q=idx{k};
    N(k)=numel(q);
    meanLocal(k)=mean(localAngle(q));
    meanMNI(k)=mean(mniAngle(q));
    medianLocal(k)=median(localAngle(q));
    medianMNI(k)=median(mniAngle(q));
    medianPaired(k)=median(localAngle(q)-mniAngle(q));
    densityLocal(:,k)=ksdensity(localAngle(q),queryGrid, ...
        'Support',[0 90],'BoundaryCorrection','reflection');
    densityMNI(:,k)=ksdensity(mniAngle(q),queryGrid, ...
        'Support',[0 90],'BoundaryCorrection','reflection');

    % On some MATLAB versions, support endpoints are returned as zero.
    % Replace with the adjacent interior value to avoid a false vertical
    % line; the reflected KDE bandwidth and interior are unchanged.
    if densityLocal(1,k)==0, densityLocal(1,k)=densityLocal(2,k); end
    if densityLocal(end,k)==0, densityLocal(end,k)=densityLocal(end-1,k); end
    if densityMNI(1,k)==0, densityMNI(1,k)=densityMNI(2,k); end
    if densityMNI(end,k)==0, densityMNI(end,k)=densityMNI(end-1,k); end

    areaLocal(k)=trapz(angleGrid,densityLocal(:,k));
    areaMNI(k)=trapz(angleGrid,densityMNI(:,k));
end
assert(sum(N)==QA.nClassified && all(N>0), ...
    'Figure 7 group counts do not match p1300.');
assert(all(isfinite(densityLocal(:))) && all(isfinite(densityMNI(:))), ...
    'Nonfinite density estimates.');
assert(all(abs(areaLocal-1)<0.02) && all(abs(areaMNI-1)<0.02), ...
    'A probability density does not integrate to approximately unity.');
yMax=0.022;
assert(max([densityLocal(:);densityMNI(:)])<yMax, ...
    'A density exceeds the common Y-axis range.');

% --- Figure 7A: repeat p1330 spatial analysis from original source data. ---
assert(isfield(A.aal,'transform') && isfield(A.aal,'dim'), ...
    'AAL affine/dim fields are missing.');
T=double(A.aal.transform);
dim=double(A.aal.dim(:)');
assert(isequal(size(T),[4 4]) && isequal(dim,[91 109 91]), ...
    'Unexpected AAL grid for Figure 7A.');
assert(all(isfinite(T(:))) && abs(det(T(1:3,1:3)))>eps, ...
    'Invalid AAL affine matrix.');

sampleIJK=[(dim(1)+1)/2*ones(dim(3),1), ...
    (dim(2)+1)/2*ones(dim(3),1), (1:dim(3))',ones(dim(3),1)];
mm=(T*sampleIJK')';
zMM=mm(:,3);
zSlices=find(zMM>=-72-1e-5 & zMM<=98+1e-5);
assert(numel(zSlices)==86 && ...
    all(abs(diff(zMM(zSlices))-2)<1e-5), ...
    'The 86 axial slices do not match -72 to 98 mm at 2-mm steps.');

p=double(G.dipPos_mm(allRows,:));
ijk=(T\[p ones(numel(allRows),1)]')';
ijk=round(ijk(:,1:3));
validVoxel=all(isfinite(ijk),2) & ...
    all(ijk>=1 & ijk<=dim,2);
loc=ijk(validVoxel,:);
linearID=sub2ind(dim,loc(:,1),loc(:,2),loc(:,3));
countVol=reshape(accumarray(linearID,1,[prod(dim),1],@sum,0),dim);
angleVol=reshape(accumarray(linearID,localAngle(allRows(validVoxel)), ...
    [prod(dim),1],@sum,0),dim);

voxelMM=sqrt(sum(T(1:3,1:3).^2,1));
sigmaMM=2;
sigmaVoxel=sigmaMM./voxelMM;
assert(all(isfinite(sigmaVoxel) & sigmaVoxel>0), ...
    'Invalid conversion from mm to voxel units.');
kernels=cell(1,3);
for d=1:3
    h=max(1,ceil(3*sigmaVoxel(d)));
    offsets=-h:h;
    weights=exp(-0.5*(offsets./sigmaVoxel(d)).^2);
    kernels{d}=weights./sum(weights);
end

countSmooth=convn(countVol,reshape(kernels{1},[],1,1),'same');
countSmooth=convn(countSmooth,reshape(kernels{2},1,[],1),'same');
countSmooth=convn(countSmooth,reshape(kernels{3},1,1,[]),'same');
angleSmooth=convn(angleVol,reshape(kernels{1},[],1,1),'same');
angleSmooth=convn(angleSmooth,reshape(kernels{2},1,[],1),'same');
angleSmooth=convn(angleSmooth,reshape(kernels{3},1,1,[]),'same');
meanAngleVol=nan(dim);
occupied=countSmooth>0;
meanAngleVol(occupied)=angleSmooth(occupied)./countSmooth(occupied);
assert(all(isfinite(meanAngleVol(occupied))) && ...
    all(meanAngleVol(occupied)>=-1e-7 & ...
        meanAngleVol(occupied)<=90+1e-7), ...
    'Spatially smoothed axial angles are invalid.');

% --- Raster mosaic for A, but retain all other marks as editable vector. ---
svgW=1224;
svgH=1500;
montageH=970;
montageRGB=uint8(255*ones(montageH,svgW,3));
jetColors=jet(256);
tileW=86;
tileH=104;
xFirst=18;
yFirst=72;
xPitch=93;
yPitch=128;
nColumns=13;

for j=1:numel(zSlices)
    slice=meanAngleVol(:,:,zSlices(j));
    usable=isfinite(slice);
    cmapID=1+floor(255*min(90,max(0,slice))/90);
    cmapID(~usable)=1;
    sliceRGB=reshape(jetColors(cmapID(:),:),[dim(1),dim(2),3]);
    for channel=1:3
        plane=sliceRGB(:,:,channel);
        plane(~usable)=0;
        sliceRGB(:,:,channel)=plane;
    end
    sliceRGB=flipud(permute(sliceRGB,[2 1 3]));
    rowIDs=round(linspace(1,size(sliceRGB,1),tileH));
    colIDs=round(linspace(1,size(sliceRGB,2),tileW));
    tile=uint8(round(255*sliceRGB(rowIDs,colIDs,:)));
    row=floor((j-1)/nColumns);
    col=mod(j-1,nColumns);
    px=xFirst+col*xPitch;
    py=yFirst+row*yPitch;
    montageRGB(py+(1:tileH),px+(1:tileW),:)=tile;
end

% --- Shared layout of the two equally scaled PDFs in panels B and C. ---
plotLeft=[185 765];
plotW=275;
plotTop=1115;
plotBottom=1390;
plotH=275; % square plot boxes for panels B and C
panelTitleX=plotLeft+plotW/2;
panelTitles={'(B) Local boundary reference', ...
             '(C) MNI-origin reference'};
% Short panel titles are intentional. The exact geometric definitions are
% explained in the caption; pictograms may be added later as separate artwork.
localHex={'#8CBAD9','#8CC78A','#B585BA'};
lineRGB=round(255*colors);
ticksX=[0 30 60 90];
ticksY=[0 0.005 0.010 0.015 0.020];
legendY=[1038 1066 1094];
colorbarX=xFirst+8*xPitch+2;
colorbarY=yFirst+6*yPitch+8;
colorbarW=14;
colorbarH=90;

% Do not create output directory until all data checks have passed.
outputDir=fullfile(projectRoot,stageName);
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
prefix='Figure007_AxialAngle_Local_vs_MNI_v2';
mosaicPath=fullfile(outputDir,'Figure007_A_mosaic.png');
imwrite(montageRGB,mosaicPath,'png');

% Base64-encode the stage-owned PNG using only MATLAB operators.
fid=fopen(mosaicPath,'rb');
assert(fid>=0,'Could not reopen mosaic PNG.');
bytes=fread(fid,Inf,'*uint8');
assert(fclose(fid)==0,'Could not close mosaic PNG input.');
npad=mod(3-mod(numel(bytes),3),3);
padded=uint32([bytes;zeros(npad,1,'uint8')]);
trip=reshape(padded,3,[]);
c1=bitshift(trip(1,:),-2);
c2=bitor(bitshift(bitand(trip(1,:),3),4),bitshift(trip(2,:),-4));
c3=bitor(bitshift(bitand(trip(2,:),15),2),bitshift(trip(3,:),-6));
c4=bitand(trip(3,:),63);
code=double([c1;c2;c3;c4])+1;
alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
b64=alphabet(code(:));
if npad>0
    b64(end-npad+1:end)='=';
end

% --- Native self-contained SVG: editable text, editable curves & axes. ---
svgFile=fullfile(outputDir,[prefix '.svg']);
fid=fopen(svgFile,'wt');
assert(fid>=0,'Cannot create native SVG output.');
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>\n');
fprintf(fid,['<svg xmlns="http://www.w3.org/2000/svg" ' ...
    'width="%d" height="%d" viewBox="0 0 %d %d">\n'], ...
    svgW,svgH,svgW,svgH);
fprintf(fid,'<title>Figure 7: Axial angles, local boundary and MNI radial</title>\n');
fprintf(fid,['<desc>Panel A: Gaussian-weighted scalar mean of axial angles. ' ...
    'Panels B and C: groupwise boundary-corrected kernel densities.</desc>\n']);
fprintf(fid,'<rect x="0" y="0" width="%d" height="%d" fill="white"/>\n', ...
    svgW,svgH);
fprintf(fid,['<image id="panel_A_mosaic" x="0" y="0" width="%d" ' ...
    'height="%d" href="data:image/png;base64,%s"/>\n'], ...
    svgW,montageH,b64);
fprintf(fid,['<g id="editable_labels" font-family="Arial,Helvetica,sans-serif" ' ...
    'fill="#222222">\n']);
fprintf(fid,['<text x="%d" y="40" text-anchor="middle" ' ...
    'font-weight="bold" font-size="22">' ...
    '(A) Mean axial dipole angle relative to template-boundary normal</text>\n'], ...
    svgW/2);

for j=1:numel(zSlices)
    row=floor((j-1)/nColumns);
    col=mod(j-1,nColumns);
    xLabel=xFirst+col*xPitch+tileW/2;
    yLabel=yFirst+row*yPitch-7;
    fprintf(fid,['<text x="%.2f" y="%.2f" font-size="11.5" ' ...
        'text-anchor="middle">z=%d mm</text>\n'], ...
        xLabel,yLabel,round(zMM(zSlices(j))));
end

% Colorbar with clearly separated label and 0,45,90-degree ticks.
for ci=1:256
    yy=colorbarY+(256-ci)*(colorbarH/256);
    rgb=round(255*jetColors(ci,:));
    fprintf(fid,['<rect x="%.3f" y="%.3f" width="%.3f" ' ...
        'height="%.4f" fill="#%02X%02X%02X"/>\n'], ...
        colorbarX,yy,colorbarW,colorbarH/256+0.02, ...
        rgb(1),rgb(2),rgb(3));
end
fprintf(fid,'<text x="%.1f" y="%.1f" font-size="11">degrees</text>\n', ...
    colorbarX+23,colorbarY-11);
for angleTick=[0 45 90]
    yy=colorbarY+(90-angleTick)/90*colorbarH;
    fprintf(fid,['<line x1="%.1f" x2="%.1f" y1="%.2f" ' ...
        'y2="%.2f" stroke="#222" stroke-width="0.9"/>\n'], ...
        colorbarX+colorbarW,colorbarX+colorbarW+4,yy,yy);
    fprintf(fid,'<text x="%.1f" y="%.1f" font-size="11">%d</text>\n', ...
        colorbarX+23,yy+4,angleTick);
end

for panel=1:2
    px=plotLeft(panel);
    fprintf(fid,['<g id="panel_%c">\n<text x="%.2f" y="995" ' ...
        'font-size="22" text-anchor="middle" font-weight="bold">%s</text>\n'], ...
        char('A'+panel),panelTitleX(panel),panelTitles{panel});

    % One legend, three series, directly above each plot.
    for k=1:nGroups
        rgb=lineRGB(k,:);
        if panel==1
            med=medianLocal(k);
        else
            med=medianMNI(k);
        end
        fprintf(fid,['<line x1="%.2f" x2="%.2f" y1="%.2f" ' ...
            'y2="%.2f" stroke="#%02X%02X%02X" stroke-width="3.5"/>\n'], ...
            px+18,px+70,legendY(k),legendY(k), ...
            rgb(1),rgb(2),rgb(3));
        fprintf(fid,['<text x="%.2f" y="%.2f" font-size="15">' ...
            '%s (median %.1f&#176;)</text>\n'], ...
            px+79,legendY(k)+5,groupLabels{k},med);
    end

    fprintf(fid,['<path d="M %.2f %.2f L %.2f %.2f L %.2f %.2f" ' ...
        'stroke="#262626" fill="none" stroke-width="1.5"/>\n'], ...
        px,plotTop,px,plotBottom,px+plotW,plotBottom);
    for tick=ticksX
        xx=px+plotW*(tick/90);
        fprintf(fid,['<line x1="%.2f" x2="%.2f" y1="%d" y2="%d" ' ...
            'stroke="#262626" stroke-width="1"/>\n'], ...
            xx,xx,plotBottom,plotBottom+7);
        fprintf(fid,['<text x="%.2f" y="%.2f" text-anchor="middle" ' ...
            'font-size="16">%d</text>\n'],xx,plotBottom+30,tick);
    end
    for tick=ticksY
        yy=plotBottom-plotH*(tick/yMax);
        fprintf(fid,['<line x1="%.2f" x2="%.2f" y1="%.2f" y2="%.2f" ' ...
            'stroke="#262626" stroke-width="1"/>\n'], ...
            px-7,px,yy,yy);
        fprintf(fid,['<text x="%.2f" y="%.2f" text-anchor="end" ' ...
            'font-size="15">%.3g</text>\n'],px-12,yy+5,tick);
    end
    fprintf(fid,['<text x="%.2f" y="1460" text-anchor="middle" ' ...
        'font-size="18">Axial angle (degrees)</text>\n'], ...
        px+plotW/2);
    fprintf(fid,['<text x="%.2f" y="%.2f" text-anchor="middle" ' ...
        'transform="rotate(-90 %.2f %.2f)" font-size="17">' ...
        'Estimated probability density</text>\n'], ...
        px-72,(plotTop+plotBottom)/2,px-72,(plotTop+plotBottom)/2);

    for k=1:nGroups
        if panel==1
            values=densityLocal(:,k);
        else
            values=densityMNI(:,k);
        end
        xx=px+plotW*angleGrid/90;
        yy=plotBottom-plotH*values/yMax;
        points=sprintf('%.2f,%.2f ',[xx.';yy.']);
        rgb=lineRGB(k,:);
        fprintf(fid,['<polyline id="panel_%c_curve_%d" points="%s" ' ...
            'fill="none" stroke="#%02X%02X%02X" stroke-width="3.5" ' ...
            'stroke-linejoin="round" stroke-linecap="round"/>\n'], ...
            char('A'+panel),k,points,rgb(1),rgb(2),rgb(3));
    end
    fprintf(fid,'</g>\n');
end
fprintf(fid,'</g>\n</svg>\n');
assert(fclose(fid)==0,'Could not finish native SVG.');
svgText=fileread(svgFile);
assert(contains(svgText,'<text ') && ...
    contains(svgText,'data:image/png;base64,') && ...
    contains(svgText,'panel_B_curve_1') && ...
    contains(svgText,'panel_C_curve_3'), ...
    'Output SVG failed structural checks.');

% --- MATLAB figure for vector PDF/EPS and 600-dpi PNG. ---
% Draw in the same 1224 x 1500 absolute coordinate system as the SVG.
% SVG remains the preferred Illustrator master (editable Arial text).
fig=figure('Visible','off','Color','w','Units','pixels', ...
    'Position',[40 40 svgW svgH], ...
    'Renderer','painters','InvertHardcopy','off');
ax=axes('Parent',fig,'Units','normalized','Position',[0 0 1 1]);
hold(ax,'on');
image(ax,'XData',[0 svgW],'YData',[0 montageH],'CData',montageRGB);
set(ax,'YDir','reverse','XLim',[0 svgW],'YLim',[0 svgH]);
axis(ax,'manual');
axis(ax,'off');

text(ax,svgW/2,40, ...
    '(A) Mean axial dipole angle relative to template-boundary normal', ...
    'HorizontalAlignment','center','FontName','Arial', ...
    'FontSize',17,'FontWeight','bold','Color',[0.13 0.13 0.13]);
for j=1:numel(zSlices)
    row=floor((j-1)/nColumns);
    col=mod(j-1,nColumns);
    text(ax,xFirst+col*xPitch+tileW/2, ...
        yFirst+row*yPitch-7, ...
        sprintf('z=%d mm',round(zMM(zSlices(j)))), ...
        'HorizontalAlignment','center','FontName','Arial', ...
        'FontSize',8.2,'Color',[0.13 0.13 0.13]);
end
for ci=1:256
    yy=colorbarY+(256-ci)*(colorbarH/256);
    rectangle(ax,'Position',[colorbarX yy colorbarW colorbarH/256+0.02], ...
        'FaceColor',jetColors(ci,:), ...
        'EdgeColor','none');
end
text(ax,colorbarX+23,colorbarY-11,'degrees','FontName','Arial', ...
    'FontSize',8,'Color',[0.13 0.13 0.13]);
for angleTick=[0 45 90]
    yy=colorbarY+(90-angleTick)/90*colorbarH;
    plot(ax,[colorbarX+colorbarW colorbarX+colorbarW+4],[yy yy], ...
        'Color',[0.13 0.13 0.13],'LineWidth',0.7);
    text(ax,colorbarX+23,yy+4,sprintf('%d',angleTick), ...
        'FontName','Arial','FontSize',8,'Color',[0.13 0.13 0.13]);
end

for panel=1:2
    px=plotLeft(panel);
    text(ax,panelTitleX(panel),995,panelTitles{panel}, ...
        'HorizontalAlignment','center','FontName','Arial', ...
        'FontSize',16,'FontWeight','bold','Color',[0.13 0.13 0.13]);
    for k=1:nGroups
        if panel==1
            med=medianLocal(k);
        else
            med=medianMNI(k);
        end
        plot(ax,[px+18 px+70],[legendY(k) legendY(k)], ...
            'Color',colors(k,:),'LineWidth',2.8);
        text(ax,px+79,legendY(k)+5, ...
            sprintf('%s (median %.1f deg)',groupLabels{k},med), ...
            'FontName','Arial','FontSize',10.5, ...
            'Color',[0.13 0.13 0.13]);
    end
    plot(ax,[px px px+plotW], ...
        [plotTop plotBottom plotBottom], ...
        'Color',[0.15 0.15 0.15],'LineWidth',1.0);
    for tick=ticksX
        xx=px+plotW*tick/90;
        plot(ax,[xx xx],[plotBottom plotBottom+7], ...
            'Color',[0.15 0.15 0.15],'LineWidth',0.75);
        text(ax,xx,plotBottom+30,sprintf('%d',tick), ...
            'HorizontalAlignment','center','FontName','Arial', ...
            'FontSize',11,'Color',[0.13 0.13 0.13]);
    end
    for tick=ticksY
        yy=plotBottom-plotH*tick/yMax;
        plot(ax,[px-7 px],[yy yy], ...
            'Color',[0.15 0.15 0.15],'LineWidth',0.75);
        text(ax,px-12,yy+5,sprintf('%.3g',tick), ...
            'HorizontalAlignment','right','FontName','Arial', ...
            'FontSize',10,'Color',[0.13 0.13 0.13]);
    end
    text(ax,px+plotW/2,1460,'Axial angle (degrees)', ...
        'HorizontalAlignment','center','FontName','Arial', ...
        'FontSize',12,'Color',[0.13 0.13 0.13]);
    text(ax,px-72,(plotTop+plotBottom)/2, ...
        'Estimated probability density', ...
        'HorizontalAlignment','center','Rotation',90, ...
        'FontName','Arial','FontSize',11.5, ...
        'Color',[0.13 0.13 0.13]);
    for k=1:nGroups
        if panel==1
            values=densityLocal(:,k);
        else
            values=densityMNI(:,k);
        end
        xx=px+plotW*angleGrid/90;
        yy=plotBottom-plotH*values/yMax;
        plot(ax,xx,yy,'Color',colors(k,:),'LineWidth',2.6);
    end
end

exportgraphics(fig,fullfile(outputDir,[prefix '.pdf']), ...
    'ContentType','vector','BackgroundColor','white');
print(fig,fullfile(outputDir,[prefix '.eps']),'-depsc2','-painters');
exportgraphics(fig,fullfile(outputDir,[prefix '.png']), ...
    'Resolution',600,'BackgroundColor','white');
close(fig);

% --- Machine-readable results and reproducibility audit. ---
summaryTable=table(string(groupLabels(:)),N, ...
    meanLocal,meanMNI,medianLocal,medianMNI, ...
    medianLocal-medianMNI,medianPaired,areaLocal,areaMNI, ...
    'VariableNames',{'Group','N','MeanLocal_deg','MeanMNI_deg', ...
    'MedianLocal_deg','MedianMNI_deg', ...
    'DifferenceOfMedians_deg','MedianPairedDifference_deg', ...
    'KDEIntegralLocal','KDEIntegralMNI'});
writetable(summaryTable,fullfile(outputDir,[prefix '_stats.csv']));

densityTable=table(angleGrid,densityLocal(:,1),densityLocal(:,2), ...
    densityLocal(:,3),densityMNI(:,1),densityMNI(:,2),densityMNI(:,3), ...
    'VariableNames',{'Angle_deg','Local_Surface','Local_Deep', ...
    'Local_Subcortex','MNI_Surface','MNI_Deep','MNI_Subcortex'});
writetable(densityTable,fullfile(outputDir,[prefix '_density.csv']));

spatialQA=struct;
spatialQA.nClassified=QA.nClassified;
spatialQA.nVoxelInsideGrid=nnz(validVoxel);
spatialQA.nVoxelOutsideGrid=nnz(~validVoxel);
spatialQA.sigma_mm=sigmaMM;
spatialQA.sigma_voxel=sigmaVoxel;
spatialQA.sliceZ_mm=zMM(zSlices);
spatialQA.measure='Gaussian-weighted mean scalar axial angle, local boundary normal';
spatialQA.kdeSupport_deg=[0 90];
spatialQA.kdeBoundaryCorrection='reflection';
save(fullfile(outputDir,[prefix '_volume.mat']), ...
    'meanAngleVol','countVol','countSmooth','dim','T','spatialQA','-v7.3');

fprintf('\n=== p1341: Combined Figure 7 A-C ===\n');
disp(summaryTable);
fprintf('Classified ICs: %d, voxelized: %d, out of grid: %d.\n', ...
    numel(allRows),nnz(validVoxel),nnz(~validVoxel));
fprintf('Slices: %d; smoothing sigma: %.1f mm.\n',numel(zSlices),sigmaMM);
fprintf('KDE integrals, local: %s; MNI: %s.\n', ...
    mat2str(areaLocal',5),mat2str(areaMNI',5));
fprintf('Common B/C x axis: [0 90], y axis: [0 %.3f].\n',yMax);
fprintf('Saved files to: %s\n',outputDir);
