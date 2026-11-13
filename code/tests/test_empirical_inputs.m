function tests = test_empirical_inputs
% Structural sanity checks for preprocessing outputs. Requires raw data
% separately downloaded and preprocessing stages actually run.
tests = functiontests(localfunctions);
end

function testPreprocessedDatasetShapes(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
leipzig = dir(fullfile(root,'p0000_preprocess_Leipzig','*.set'));
dortmund = dir(fullfile(root,'p0010_preprocess_Dortmund','*.set'));
verifyGreaterThan(testCase,numel(leipzig),0,'No LEMON .set files.');
verifyGreaterThan(testCase,numel(dortmund),0,'No Dortmund .set files.');
verifyEmpty(testCase,dir(fullfile(root,'p0000_preprocess_Leipzig','ERROR_*.txt')));
verifyEmpty(testCase,dir(fullfile(root,'p0010_preprocess_Dortmund','ERROR_*.txt')));
end
