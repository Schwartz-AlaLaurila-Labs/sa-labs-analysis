%% Set the matlab path !
tbUseProject('sa-labs-analysis', 'online', false); 

%% Load the curator GUI

ui_test.testCurator();

%% Create the analysis project

clear;
[project, offlineAnalysisManager] = createAnalysisProject('Example-Analysis-deubug', 'experiments', {'101217Dc'}, 'override', false);
% open the project file
open(project.file)
%% Create a simple search tree definition

analysisPreset = struct();
analysisPreset.type = 'listByProtocol';
analysisPreset.buildTreeBy = {'displayName', 'intensity; probeAxis', 'devices'};
analysisPreset.devices.splitValue = {'Amp1', 'Amp2'};

% Build the tree based on the tree definition

buildAnalysis('Example-Analysis-deubug', analysisPreset)

%% Create Finder for searching through tree

finder = getFeatureFinder('Example-Analysis-deubug');
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


