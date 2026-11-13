classdef TestCorrectedGeometry < matlab.unittest.TestCase
    % Independent post-run QA of the corrected p1300 output.
    % Run only after all required earlier stages and p1300 have completed.
    methods (Test)
        function testBarycentricReconstruction(testCase)
            projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            geometryFile = fullfile(projectRoot, 'p1300_estimateDipDepth', 'dipoleGeometry.mat');
            meshFile = fullfile(projectRoot, 'p0210_checkDipfitDefaultModel', 'corticalMask.mat');
            testCase.assertTrue(isfile(geometryFile), 'Run p1300 first.');
            testCase.assertTrue(isfile(meshFile), 'Run p0210 first.');
            S = load(geometryFile, 'geometry', 'meshQA', 'classification');
            M = load(meshFile, 'fv');
            G = S.geometry;
            V = double(M.fv.vertices);
            F = double(M.fv.faces);
            tri = F(double(G.nearestTriangle(:)),:);
            u = double(G.uBary(:));
            v = double(G.vBary(:));
            nearest = double(G.nearestPoint_mm);
            dipoles = double(G.dipPos_mm);
            reconstructed = (1-u-v).*V(tri(:,1),:) + ...
                u.*V(tri(:,2),:) + v.*V(tri(:,3),:);
            testCase.verifyGreaterThanOrEqual(min([u; v; 1-u-v]), -1e-10);
            testCase.verifyLessThan(max([u; v; 1-u-v]), 1+1e-10);
            testCase.verifyLessThan(max(vecnorm(reconstructed-nearest,2,2)), 1e-6);
            testCase.verifyLessThan(max(abs(vecnorm(nearest-dipoles,2,2) - ...
                double(G.nearestDistance_mm(:)))), 1e-6);
            testCase.verifyLessThan(S.meshQA.maxBarycentricReconstructionError_mm, 1e-6);
            testCase.verifyEqual(S.meshQA.nInsideDisagreement, 0);
            testCase.verifyEqual(S.meshQA.nonTwoFaceEdges, 0);
        end

        function testAngleDepthAndGroupIndices(testCase)
            projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            geometryFile = fullfile(projectRoot, 'p1300_estimateDipDepth', 'dipoleGeometry.mat');
            testCase.assertTrue(isfile(geometryFile), 'Run p1300 first.');
            S = load(geometryFile, 'geometry', 'meshQA', 'classification');
            G = S.geometry;
            C = S.classification;
            idx = [C.surfaceRow(:); C.deepCortexRow(:); C.subCortexRow(:)];
            testCase.verifyEqual(numel(idx), S.meshQA.nClassified);
            testCase.verifyEqual(numel(unique(idx)), numel(idx));
            testCase.verifyTrue(all(G.angleLocalAxial_deg(:)>=0 & ...
                G.angleLocalAxial_deg(:)<=90));
            testCase.verifyTrue(all(G.angleMNIAxial_deg(:)>=0 & ...
                G.angleMNIAxial_deg(:)<=90));
            testCase.verifyLessThan(max(abs(abs(G.signedDistance_mm(:)) - ...
                G.nearestDistance_mm(:))), 1e-9);
            testCase.verifyEqual(numel(C.selectedIdx), S.meshQA.nSelected);
        end
    end
end
