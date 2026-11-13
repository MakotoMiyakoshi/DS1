function tests = test_simulation_results
% Run via runtests(fullfile(projectRoot,'code','tests')) after p0400.
tests = functiontests(localfunctions);
end

function testOriginalReference(testCase)
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
observedFile = fullfile(projectRoot,'p0400_simulateUDL','results_all.csv');
referenceFile = fullfile(projectRoot,'code','tests','reference_results_all_original.csv');
verifyTrue(testCase,isfile(observedFile),'Run p0400_simulateUDL first.');
observed = readtable(observedFile);
reference = readtable(referenceFile);
verifyEqual(testCase,height(observed),27);
verifyEqual(testCase,observed.BSCR,reference.BSCR);
verifyEqual(testCase,observed.Radius_mm,reference.Radius_mm);
verifyEqual(testCase,isnan(observed.Depth_Bias_mm),isnan(reference.Depth_Bias_mm));
verifyEqual(testCase,isnan(observed.Residual_Variance),isnan(reference.Residual_Variance));
valid = isfinite(reference.Depth_Bias_mm);
% Tight numerical tolerances intentionally expose any simulation drift.
verifyEqual(testCase,observed.Depth_Bias_mm(valid),reference.Depth_Bias_mm(valid), ...
    'AbsTol',1e-6);
verifyEqual(testCase,observed.Residual_Variance(valid),reference.Residual_Variance(valid), ...
    'AbsTol',1e-8);
end
