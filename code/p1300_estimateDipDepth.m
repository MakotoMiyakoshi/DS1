% p1300_estimateDipDepth.m
% Recompute cortical-surface geometry from upstream data, independently of
% p0300 and of calc_dipoleMetrics.m.  No GUI, random sampling, or toolbox
% plugin is needed.  This script alone owns p1300_estimateDipDepth/.
%
% Scientific definitions:
%   closest point: global Euclidean minimum over ALL cortical mesh triangles
%   signed depth: negative inside, positive outside (3-axis ray parity)
%   local angle: dipole moment versus outward vertex-interpolated normal
%   axial angle: acosd(abs(dot(unit moment, unit reference direction)))
%
% The 3 anatomical groups reproduce p0300's rules, but use NEW distances.
% The calculation does not read the defective p0300 metrics.

clear;
close all;
clc;

scriptPath = mfilename('fullpath');
codeDir = fileparts(scriptPath);
projectRoot = fileparts(codeDir);
stageName = mfilename;
assert(strcmp(stageName, 'p1300_estimateDipDepth'), 'Unexpected stage name.');
assert(strcmp(codeDir, fullfile(projectRoot, 'code')), ...
    'Place this script directly in the project code/ directory.');
outputDir = fullfile(projectRoot, stageName);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% ---- Exact upstream dependencies.  No dependency on p0300. ----
L = load(fullfile(projectRoot, 'p0100_collectDipoles_Leipzig', 'Leipzig_n212.mat'), 'dipMatrix');
D = load(fullfile(projectRoot, 'p0110_collectDipoles_Dortmund', 'Dortmund_n608.mat'), 'dipMatrix');
dipParamMatrix = [L.dipMatrix; D.dipMatrix];
clear L D;

L = load(fullfile(projectRoot, 'p0101_icaactVar_Leipzig', 'Leipzig_robustVarStd.mat'), 'robustVarStdMatrix');
D = load(fullfile(projectRoot, 'p0111_icaactVar_Dortmund', 'Dortmund_robustVarStd.mat'), 'robustVarStdMatrix');
varStdMatrix = [L.robustVarStdMatrix; D.robustVarStdMatrix];
clear L D;

L = load(fullfile(projectRoot, 'p0103_FOOOFagain_Leipzig', 'FOOOF_Leipzig.mat'), 'fooofMatrix');
D = load(fullfile(projectRoot, 'p0113_FOOOFagain_Dortmund', 'FOOOF_Dortmund.mat'), 'fooofMatrix');
fooofMatrix = [L.fooofMatrix; D.fooofMatrix];
clear L D;

L = load(fullfile(projectRoot, 'p0221_modifiedAAL_Leipzig', 'modifiedAAL_Leipzig.mat'), 'aalLabel_isCortical');
D = load(fullfile(projectRoot, 'p0222_modifiedAAL_Dortmund', 'modifiedAAL_Dortmund.mat'), 'aalLabel_isCortical');
aalMatrix = [L.aalLabel_isCortical; D.aalLabel_isCortical];
clear L D;

L = load(fullfile(projectRoot, 'p0231_modifiedAAL_Leipzig_subcorticalMask', 'modifiedAAL_subcortical_Leipzig.mat'), 'aalLabel_isSubcortical');
D = load(fullfile(projectRoot, 'p0232_modifiedAAL_Dortmund_subcorticalMask', 'modifiedAAL_subcortical_Dortmund.mat'), 'aalLabel_isSubcortical');
aalMatrixSubcortical = [L.aalLabel_isSubcortical; D.aalLabel_isSubcortical];
clear L D;

Z = load(fullfile(projectRoot, 'p0210_checkDipfitDefaultModel', 'corticalMask.mat'), 'fv');
V = double(Z.fv.vertices);
F = double(Z.fv.faces);
clear Z;

nAll = size(dipParamMatrix,1);
assert(size(varStdMatrix,1)==nAll && size(fooofMatrix,1)==nAll && ...
       size(aalMatrix,1)==nAll && size(aalMatrixSubcortical,1)==nAll, ...
       'Upstream matrices disagree in row count / IC ordering.');
assert(size(V,2)==3 && size(F,2)==3 && ...
       all(isfinite(V(:))) && all(F(:)>=1) && all(F(:)<=size(V,1)), ...
       'Invalid cortical mesh.');

% ---- Same IC selection as p0300; independent of geometry. ----
brainIdx = find(dipParamMatrix(:,4)==1 & dipParamMatrix(:,11)<0.15);
brainStd = varStdMatrix(brainIdx,1);
withinStd = brainStd > prctile(brainStd,0.1) & ...
            brainStd < prctile(brainStd,99.9);
idxAfterStd = brainIdx(withinStd);
selectedIdx = idxAfterStd(fooofMatrix(idxAfterStd,4)>0.4);
nSelected = numel(selectedIdx);
assert(nSelected>0, 'No qualified Brain ICs.');

P = double(dipParamMatrix(selectedIdx,5:7));
Dmom = double(dipParamMatrix(selectedIdx,8:10));
assert(all(isfinite(P(:))) && all(isfinite(Dmom(:))), 'Non-finite dipole position/moment.');
momNorm = vecnorm(Dmom,2,2);
assert(all(momNorm>0), 'One or more dipole moments have zero length.');
Dhat = Dmom./momNorm;

% ---- Cortical mesh topology and normals. ----
E = sort([F(:,[1,2]); F(:,[2,3]); F(:,[3,1])], 2);
[~,~,eix] = unique(E,'rows');
edgeMultiplicity = accumarray(eix,1);
assert(all(edgeMultiplicity==2), 'Cortical mesh has open or nonmanifold edges.');
clear E eix;

A = V(F(:,1),:);
B = V(F(:,2),:);
C = V(F(:,3),:);
AB = B-A;
AC = C-A;
BC = C-B;
faceAreaDouble = vecnorm(cross(AB,AC,2),2,2);
assert(all(faceAreaDouble>1e-12), 'Degenerate triangle(s) in mesh.');

TR = triangulation(F,V);
vertexN = vertexNormal(TR);
faceN = faceNormal(TR);
meshCenter = mean(V,1);
faceCenter = (A+B+C)/3;
outwardBefore = mean(sum((faceCenter-meshCenter).*faceN,2)>0);
if outwardBefore<0.5
    vertexN = -vertexN;
    faceN = -faceN;
end
outwardAfter = mean(sum((faceCenter-meshCenter).*faceN,2)>0);

% Bounding boxes: a lower bound for distance to every triangle.
lo = min(min(A,B),C);
hi = max(max(A,B),C);

% ---- Global nearest point to all triangles, exact in arithmetic. ----
% The nearest-vertex distance is a valid upper bound.  A triangle whose
% axis-aligned bounding box is farther away cannot contain the minimum.
nearestPoint = nan(nSelected,3);
nearestDist = nan(nSelected,1);
nearestTri = zeros(nSelected,1);
uNearest = nan(nSelected,1);
vNearest = nan(nSelected,1);

fprintf('p1300: global nearest-point search for %d ICs / %d faces.\n', ...
    nSelected, size(F,1));
tic;
for k=1:nSelected
    p = P(k,:);
    upperBoundSq = min(sum((V-p).^2,2));
    boxDelta = max(max(lo-p,p-hi),0);
    cand = find(sum(boxDelta.^2,2)<=upperBoundSq+1e-9);
    assert(~isempty(cand), 'No candidate triangles.');
    a = A(cand,:);
    b = B(cand,:);
    c = C(cand,:);
    x = b-a;
    y = c-a;
    z = c-b;
    ap = p-a;
    bp = p-b;
    xx = sum(x.^2,2);
    xy = sum(x.*y,2);
    yy = sum(y.^2,2);
    xp = sum(x.*ap,2);
    yp = sum(y.*ap,2);
    det2 = xx.*yy-xy.^2;
    assert(all(det2>0), 'Degenerate candidate triangle(s).');
    u = (yy.*xp-xy.*yp)./det2;
    v = (xx.*yp-xy.*xp)./det2;
    q = a+u.*x+v.*y;
    dFace = sum((q-p).^2,2);
    dFace(~(u>=0 & v>=0 & u+v<=1))=Inf;

    tAB = max(0,min(1,xp./xx));
    tAC = max(0,min(1,yp./yy));
    tBC = max(0,min(1,sum(bp.*z,2)./sum(z.^2,2)));
    dAB = sum((a+tAB.*x-p).^2,2);
    dAC = sum((a+tAC.*y-p).^2,2);
    dBC = sum((b+tBC.*z-p).^2,2);
    distancesSq = [dFace dAB dAC dBC];
    [bestSq,flat] = min(distancesSq(:));
    [row,region] = ind2sub(size(distancesSq),flat);
    assert(isfinite(bestSq), 'No finite nearest point.');

    if region==1
        uu=u(row); vv=v(row);
    elseif region==2
        uu=tAB(row); vv=0;
    elseif region==3
        uu=0; vv=tAC(row);
    else
        uu=1-tBC(row); vv=tBC(row); % Correct BC barycentrics.
    end

    nearestTri(k) = cand(row);
    uNearest(k) = uu;
    vNearest(k) = vv;
    nearestDist(k) = sqrt(bestSq);
    nearestPoint(k,:) = (1-uu-vv)*a(row,:) + uu*b(row,:) + vv*c(row,:);

    if mod(k,2000)==0 || k==nSelected
        fprintf('  %d / %d (%.1f s)\n',k,nSelected,toc);
    end
end

% Independent geometry invariant: barycentrics must reconstitute point.
tri = F(nearestTri,:);
recoveredP = (1-uNearest-vNearest).*V(tri(:,1),:) + ...
             uNearest.*V(tri(:,2),:) + ...
             vNearest.*V(tri(:,3),:);
recoveryError = vecnorm(recoveredP-nearestPoint,2,2);
assert(all(recoveryError<1e-6), 'Barycentric reconstruction failed.');
assert(all(abs(vecnorm(nearestPoint-P,2,2)-nearestDist)<1e-6), ...
       'Reported nearest distances do not match nearest points.');

% ---- Independent inside/outside classification. ----
% Ray parity against the ENTIRE closed mesh (not p0300 is_inside).
% For each of +X, +Y and +Z, the ray/triangle intersection is found
% in the two-dimensional projection perpendicular to the ray.
% Deterministic 1e-7-mm transverse jitter avoids exact edge hits.
% Three directions also expose numerically ambiguous classifications.
insideByAxis = false(nSelected,3);
fprintf('p1300: independent three-axis ray parity.\n');
tic;
for axisIndex=1:3
    proj = [mod(axisIndex,3)+1 mod(axisIndex+1,3)+1];
    a2=A(:,proj);
    b2=B(:,proj);
    c2=C(:,proj);
    bndLo=min(min(a2,b2),c2);
    bndHi=max(max(a2,b2),c2);
    edge1=b2-a2;
    edge2=c2-a2;
    denominator=edge1(:,1).*edge2(:,2)-edge1(:,2).*edge2(:,1);
    nondegenerate=abs(denominator)>1e-12;
    for k=1:nSelected
        p=P(k,:);
        pp=p(proj)+[1e-7,2e-7];
        faceCand=find(nondegenerate & ...
            bndLo(:,1)<=pp(1) & bndHi(:,1)>=pp(1) & ...
            bndLo(:,2)<=pp(2) & bndHi(:,2)>=pp(2));
        if isempty(faceCand)
            insideByAxis(k,axisIndex)=false;
            continue;
        end
        ep=pp-a2(faceCand,:);
        e1=edge1(faceCand,:);
        e2=edge2(faceCand,:);
        den=denominator(faceCand);
        ub=(ep(:,1).*e2(:,2)-ep(:,2).*e2(:,1))./den;
        vb=(e1(:,1).*ep(:,2)-e1(:,2).*ep(:,1))./den;
        wb=1-ub-vb;
        interior=ub>1e-12 & vb>1e-12 & wb>1e-12;
        if ~any(interior)
            continue;
        end
        candHit=faceCand(interior);
        ua=ub(interior); va=vb(interior); wa=wb(interior);
        hitCoord=wa.*A(candHit,axisIndex)+ ...
                 ua.*B(candHit,axisIndex)+ ...
                 va.*C(candHit,axisIndex);
        nForward=nnz(hitCoord>p(axisIndex)+1e-8);
        insideByAxis(k,axisIndex)=mod(nForward,2)==1;
    end
    fprintf('  Axis %d done (%.1f s).\n',axisIndex,toc);
end
axisAgreement=all(insideByAxis==insideByAxis(:,1),2);
isInside=sum(insideByAxis,2)>=2;
nConflicts=nnz(~axisAgreement);
if nConflicts>0
    warning('%d/%d ICs disagree across ray directions; review before publication.', ...
        nConflicts,nSelected);
end
signedDist=nearestDist.*(1-2*double(isInside));

% ---- Dipole axis, reference normals, and angular definitions. ----
Nloc=(1-uNearest-vNearest).*vertexN(tri(:,1),:) + ...
     uNearest.*vertexN(tri(:,2),:) + ...
     vNearest.*vertexN(tri(:,3),:);
nlocNorm=vecnorm(Nloc,2,2);
assert(all(nlocNorm>0), 'Interpolated vertex normal has zero length.');
Nloc=Nloc./nlocNorm;
localDot=max(-1,min(1,sum(Dhat.*Nloc,2)));
angleLocalSigned=acosd(localDot);           % 0..180 deg, polarity sensitive
angleLocalAxial=acosd(abs(localDot));       % 0..90 deg, polarity invariant
rNorm=vecnorm(P,2,2);
assert(all(rNorm>0), 'Dipole located exactly at MNI origin.');
Rhat=P./rNorm;                               % MNI [0 0 0] -> dipole
angleMNIAxial=acosd(max(-1,min(1,abs(sum(Dhat.*Rhat,2)))));
angleNormalMNI=acosd(max(-1,min(1,abs(sum(Nloc.*Rhat,2)))));

% ---- Reproduce original p0300 classification, using NEW signed distances. ----
allSignedDist=nan(nAll,1);
allSignedDist(selectedIdx)=signedDist;
validAAL=~isnan(aalMatrix(:,1));
goodCortexIdx=intersect(selectedIdx,find(validAAL & aalMatrix(:,2)==0));
goodNoncortexIdx=intersect(selectedIdx,find(validAAL & aalMatrix(:,2)>0));
mislabeledCortexIdx=goodNoncortexIdx(abs(allSignedDist(goodNoncortexIdx))<10);
combinedCortexIdx=sort([goodCortexIdx; mislabeledCortexIdx]);
noncortexDeepIdx=goodNoncortexIdx(allSignedDist(goodNoncortexIdx)<-10);
surfaceIdx=combinedCortexIdx(allSignedDist(combinedCortexIdx)>-5);
deepCortexIdx=setdiff(combinedCortexIdx,surfaceIdx);
blockedIdx=unique([find(aalMatrixSubcortical(:,2)==0); ...
                   find(dipParamMatrix(:,7)<=-48)]);

classification.surfaceIdx=setdiff(surfaceIdx,blockedIdx);
classification.deepCortexIdx=setdiff(deepCortexIdx,blockedIdx);
classification.subCortexIdx=sort([noncortexDeepIdx; ...
    intersect(surfaceIdx,blockedIdx); intersect(deepCortexIdx,blockedIdx)]);
classification.selectedIdx=selectedIdx;

% Save rows corresponding to group membership within the compact geometry.
[yes1,groupRow1]=ismember(classification.surfaceIdx,selectedIdx);
[yes2,groupRow2]=ismember(classification.deepCortexIdx,selectedIdx);
[yes3,groupRow3]=ismember(classification.subCortexIdx,selectedIdx);
assert(all(yes1) && all(yes2) && all(yes3),'Classification index mismatch.');
classification.surfaceRow=groupRow1;
classification.deepCortexRow=groupRow2;
classification.subCortexRow=groupRow3;
classification.unclassifiedIdx=setdiff(selectedIdx, ...
    [classification.surfaceIdx; classification.deepCortexIdx; classification.subCortexIdx]);
assert(numel(unique([classification.surfaceIdx; classification.deepCortexIdx; ...
    classification.subCortexIdx])) == ...
    numel(classification.surfaceIdx)+numel(classification.deepCortexIdx)+ ...
    numel(classification.subCortexIdx), 'A dipole belongs to multiple groups.');

% ---- Persist numeric results for p1310+ scripts. ----
geometry.globalIdx=selectedIdx;
geometry.dipPos_mm=P;
geometry.dipMom=Dmom;
geometry.nearestPoint_mm=nearestPoint;
geometry.nearestDistance_mm=nearestDist;
geometry.nearestTriangle=nearestTri;
geometry.uBary=uNearest;
geometry.vBary=vNearest;
geometry.normalOutward=Nloc;
geometry.insideByAxis=insideByAxis;
geometry.insideAxisAgreement=axisAgreement;
geometry.isInside=isInside;
geometry.signedDistance_mm=signedDist;
geometry.angleLocalSigned_deg=angleLocalSigned;
geometry.angleLocalAxial_deg=angleLocalAxial;
geometry.angleMNIAxial_deg=angleMNIAxial;
geometry.angleNormalMNIAxial_deg=angleNormalMNI;

meshQA.nVertices=size(V,1);
meshQA.nTriangles=size(F,1);
meshQA.nonTwoFaceEdges=nnz(edgeMultiplicity~=2);
meshQA.outwardFaceFractionBefore=outwardBefore;
meshQA.outwardFaceFractionAfter=outwardAfter;
meshQA.maxBarycentricReconstructionError_mm=max(recoveryError);
meshQA.nInsideDisagreement=nConflicts;
meshQA.nSelected=nSelected;
meshQA.nClassified=numel(classification.surfaceIdx)+ ...
    numel(classification.deepCortexIdx)+numel(classification.subCortexIdx);

rowGroups={groupRow1,groupRow2,groupRow3};
nameGroups={'Surface';'Deep cortex';'Subcortex'};
counts=zeros(3,1);
medianDepth=zeros(3,1);
medianAngleSigned=zeros(3,1);
medianAngleAxial=zeros(3,1);
medianAngleMNI=zeros(3,1);
parityDisagreements=zeros(3,1);
for k=1:3
    q=rowGroups{k};
    counts(k)=numel(q);
    medianDepth(k)=median(signedDist(q));
    medianAngleSigned(k)=median(angleLocalSigned(q));
    medianAngleAxial(k)=median(angleLocalAxial(q));
    medianAngleMNI(k)=median(angleMNIAxial(q));
    parityDisagreements(k)=nnz(~axisAgreement(q));
end
summaryTable=table(nameGroups,counts,medianDepth,medianAngleSigned, ...
    medianAngleAxial,medianAngleMNI,parityDisagreements, ...
    'VariableNames',{'Group','N','MedianSignedDepth_mm', ...
    'MedianSignedAngle_deg','MedianAxialAngle_deg','MedianMNIAxial_deg', ...
    'RayParityConflicts'});

save(fullfile(outputDir,'dipoleGeometry.mat'), ...
    'geometry','classification','meshQA','summaryTable','-v7.3');
writetable(summaryTable,fullfile(outputDir,'angleDepthSummary.csv'));

fprintf('\n=== p1300 output ===\n');
fprintf('Selected=%d, classified=%d, unclassified=%d\n', ...
    nSelected,meshQA.nClassified,numel(classification.unclassifiedIdx));
fprintf('Three-axis parity conflicts=%d\n',nConflicts);
fprintf('Maximum barycentric reconstruction error=%.3g mm\n',max(recoveryError));
disp(summaryTable);
fprintf('Saved under: %s\n',outputDir);
