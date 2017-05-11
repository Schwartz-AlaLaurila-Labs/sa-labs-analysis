tbUseProject('sa-labs-analysis', 'online', true)
%%
projectName = 'Multi-cell-analysis';

project = createAnalysisProject(projectName, 'experiments', '20170324Dc') %#ok
manager = getAnalysisManager();

%%  pre process the data

preProcessors = {@(d) sa_labs.pre_processors.addSpikesToEpoch(d, 'device',{'Amp1','Amp2','Amp3','Amp4'}, 'checkDetection', false)};
manager.preProcess(project.getCellDataArray(), preProcessors,  'enabled', [true]);


%% create a filter for doing analysis

analysisPreset(1).type = 'device-last';
analysisPreset(1).buildTreeBy = {'RstarMean', 'displayName', 'devices'};
analysisPreset(1).devices.splitValue = {'Amp1', 'Amp2', 'Amp3', 'Amp4'};
analysisPreset(1).devices.featureExtractor = {@(a, g) sa_labs.extractors.extractSpikes(a, g)};

analysisPreset(2).type = 'device-first';
analysisPreset(2).buildTreeBy = {'devices', 'RstarMean', 'displayName'};
analysisPreset(2).devices.splitValue = {'Amp1', 'Amp2', 'Amp3', 'Amp4'};
analysisPreset(2).displayName.featureExtractor = {@(a, g) sa_labs.extractors.extractSpikes(a, g)};


%%

buildAnalysis(projectName, analysisPreset);

%%

finder = getFeatureFinder(projectName, 'analysisType', 'device');

% display tree
finder.getStructure.tostring()
displayTree(finder);