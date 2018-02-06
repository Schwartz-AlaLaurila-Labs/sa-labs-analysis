%% Set the matlab path !
tbUseProject('sa-labs-analysis', 'online', false);

%% Load the curator GUI

ui_test.testCurator();

%% Create the analysis project

clear;
[project, offlineAnalysisManager] = createAnalysisProject('Example-Analysis_01',...
    'experiments', {'101217Dc*Amp2'},...
    'override', true);
% open the project file
open(project.file)
%% Create a simple search tree definition

analysisFilter = struct();
analysisFilter.type = 'LightStepAnalysis';
analysisFilter.buildTreeBy = {'displayName', 'intensity', 'stimTime'};
analysisFilter.displayName.splitValue = {'Light Step'};
analysisFilter.stimTime.featureExtractor = {@(analysis, epochGroup, analysisParameter)...
     sa_labs.analysis.common.extractors.psthExtractor(...
     analysis,...
     epochGroup,...
     analysisParameter)...
    };

% Build the tree based on the tree definition

buildAnalysis('Example-Analysis_01', analysisFilter)

%% Create Finder for searching through tree

finder = getFeatureFinder('Example-Analysis_01');
finder.getStructure().tostring()

%%
% a) To list all the epoch group for protocol Auto Center

epochGroup = finder.find('Receptive Field 1D').toArray();
epochs = epochGroup.getFeatureData('SPIKETIMES')

%%
% b) To get all the epochs corresponds to the above featureGroup

epochs = epochGroup.getFeatureData('AMP1_EPOCH');

% c) To get all the spikes corresponds to the above featureGroup

spikeTimes = epochGroup.getFeatureData('AMP1_SPIKETIMES')


