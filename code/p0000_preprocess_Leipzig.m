% p0000_preprocess_Leipzig.m
% Reimplementation of archived code_Leipzig/p0100_imported.m, retaining the
% original preprocessing decisions and AMICA command-line options.
% TRACE candidate: no GUI, explicit dependencies, every generated file under
% this script's matching output directory; no manually modified outputs.
% No actual raw-data execution or comparison with original .set files yet.
clear
close all
clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(projectRoot,mfilename);
if ~isfolder(outDir), mkdir(outDir); end
rawRoot = getenv('DS1_LEIPZIG_RAW_DIR');
eeglabRoot = getenv('DS1_LEIPZIG_EEGLAB_ROOT');
fieldtripRoot = getenv('DS1_LEIPZIG_FIELDTRIP_ROOT');
assert(isfolder(rawRoot), 'Set DS1_LEIPZIG_RAW_DIR to the directory containing LEMON sub-* folders.');
assert(isfolder(eeglabRoot), 'Set DS1_LEIPZIG_EEGLAB_ROOT (legacy EEGLAB 2021.1).');
assert(isfolder(fieldtripRoot), 'Set DS1_LEIPZIG_FIELDTRIP_ROOT (legacy FieldTrip snapshot).');
addpath(eeglabRoot);
eeglab('nogui');
addpath(fieldtripRoot);
ft_defaults;
assert(~isempty(which('runamica15')), 'AMICA runamica15 is unavailable.');
assert(~isempty(which('pop_loadbv')), 'BrainVision importer is unavailable.');
assert(~isempty(which('fitTwoDipoles')), 'Missing bilateral fitTwoDipoles.');
assert(~isempty(which('clean_rawdata')), 'Missing legacy clean_rawdata function.');

% Use the installed DIPFIT version, rather than an absolute machine path.
dipfitRoot = fileparts(which('pop_dipfit_settings'));
standardBEM = fullfile(dipfitRoot,'standard_BEM');
elecFile = fullfile(standardBEM,'elec','standard_1005.elc');
assert(isfile(elecFile) && isfile(fullfile(standardBEM,'standard_vol.mat')), ...
    'Legacy DIPFIT standard BEM files were not found.');

allSubj = dir(fullfile(rawRoot,'sub-*'));
allSubj = allSubj([allSubj.isdir]);
assert(~isempty(allSubj),'No LEMON sub-* directories at DS1_LEIPZIG_RAW_DIR.');
[~,sortingOrder] = sort({allSubj.name});
allSubj = allSubj(sortingOrder);
for subjIdx = 1:numel(allSubj)
    rng(100000+subjIdx, 'twister');
    dataName = allSubj(subjIdx).name;
    try
        sourceDir = fullfile(rawRoot,dataName,'RSEEG');
        sourceFile = fullfile(sourceDir,[dataName '.vhdr']);
        assert(isfile(sourceFile), 'Missing BrainVision EEG header %s', sourceFile);
        fprintf('LEMON %d/%d: %s\n',subjIdx,numel(allSubj),dataName);
        EEG = pop_loadbv(sourceDir,[dataName '.vhdr']);
        EEG = pop_resample(EEG,250);
        EEG = pop_firws(EEG,'fcutoff',1.5,'ftype','highpass', ...
            'wtype','hamming','forder',826,'minphase',0);
        EEG = pop_chanedit(EEG,'lookup',elecFile);

        eoIdx = find(contains({EEG.event.type}','S200'));
        ecIdx = find(contains({EEG.event.type}','S210'));
        assert(numel(eoIdx)>1 && numel(ecIdx)>1, 'LEMON S200/S210 blocks are missing.');
        medianDiff = median(diff([EEG.event(eoIdx).latency]/EEG.srate));

        eoStartIdx = [1; find(diff(eoIdx)-1)+1];
        eoEndIdx = [find(diff(eoIdx)-1); numel(eoIdx)];
        eoStart = eoIdx(eoStartIdx);
        eoEnd = eoIdx(eoEndIdx);
        cropEO = [[EEG.event(eoStart).latency]' [EEG.event(eoEnd).latency]'+EEG.srate*medianDiff]/EEG.srate;
        EEG_EO = pop_select(EEG,'time',cropEO);
        EEG_EO = clean_rawdata(EEG_EO,-1,-1,-1,-1,20,0.25,'availableRAM_GB',16);

        ecStartIdx = [1; find(diff(ecIdx)-1)+1];
        ecEndIdx = [find(diff(ecIdx)-1); numel(ecIdx)];
        ecStart = ecIdx(ecStartIdx);
        ecEnd = ecIdx(ecEndIdx);
        cropEC = [[EEG.event(ecStart).latency]' [EEG.event(ecEnd).latency]'+EEG.srate*medianDiff]/EEG.srate;
        EEG_EC = pop_select(EEG,'time',cropEC);
        EEG_EC = clean_rawdata(EEG_EC,-1,-1,-1,-1,20,0.25,'availableRAM_GB',16);

        EEG = pop_mergeset(EEG_EO,EEG_EC,0);
        EEG.etc.EEG_EO_etc = EEG_EO.etc;
        EEG.etc.EEG_EC_etc = EEG_EC.etc;
        EEG.nbchan = EEG.nbchan+1;
        EEG.data(end+1,:) = zeros(1,EEG.pnts);
        EEG.chanlocs(1,EEG.nbchan).labels = 'FCz';
        EEG = pop_reref(EEG,[]);
        EEG = pop_select(EEG,'nochannel',{'VEOG'});
        EEG = pop_chanedit(EEG,'lookup',elecFile);

        dataRank = sum(eig(cov(double(EEG.data'))) > 1E-7);
        amicaDir = fullfile(outDir,dataName);
        if ~isfolder(amicaDir),mkdir(amicaDir);end
        try
            EEG2 = pop_resample(EEG,100);
            runamica15(EEG2.data(:,:), 'num_chans',EEG.nbchan, ...
                'outdir',amicaDir,'pcakeep',dataRank,'num_models',1, ...
                'nodeproc',[3 16],'do_reject',1,'numrej',15, ...
                'rejsig',3,'rejint',1,'max_iter',2000);
            EEG.etc.ds1_amica_sampling_rate = 100;
        catch ME100
            warning('LEMON 100 Hz AMICA failed for %s: %s. Trying legacy 250 Hz fallback.',dataName,ME100.message);
            runamica15(EEG.data(:,:), 'num_chans',EEG.nbchan, ...
                'outdir',amicaDir,'pcakeep',dataRank,'num_models',1, ...
                'nodeproc',[3 16],'do_reject',1,'numrej',15, ...
                'rejsig',3,'rejint',1,'max_iter',2000);
            EEG.etc.ds1_amica_sampling_rate = 250;
        end
        EEG = pop_loadmodout(EEG,amicaDir);
        EEG = iclabel(EEG,'default');
        EEG = pop_dipfit_settings(EEG,'hdmfile',fullfile(standardBEM,'standard_vol.mat'), ...
            'mrifile',fullfile(standardBEM,'standard_mri.mat'), ...
            'chanfile',elecFile, 'coordformat','MNI', ...
            'coord_transform',[0 0 0 0 0 -1.5708 1 1 1], ...
            'chansel',1:EEG.nbchan);
        % Same component set as the loaded AMICA weights; original uses EEG.icaact.
        EEG = pop_multifit(EEG,1:size(EEG.icaweights,1),'threshold',100);
        EEG = fitTwoDipoles(EEG,'LRR',35);
        EEG.etc.ds1_preprocess_origin = 'code_Leipzig/p0100_imported.m';
        pop_saveset(EEG,'filename',[dataName '.set'],'filepath',outDir);
    catch ME
        errFile = fullfile(outDir,['ERROR_' dataName '.txt']);
        fid = fopen(errFile,'w');
        if fid~=-1
            fprintf(fid,'%s\n',getReport(ME,'extended','hyperlinks','off'));
            fclose(fid);
        end
        rethrow(ME);
    end
end
fprintf('LEMON preprocessing completed: %d participants.\n',numel(allSubj));
