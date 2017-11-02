%% Set the matlab path !
tbUseProject('sa-labs-analysis', 'online', false); 

%% Load the curator GUI

ui_test.testCurator();

%% Create the analysis project

clear;
[project, offlineAnalysisManager] = createAnalysisProject('Example-Analysis', 'experiments', '101217D', 'override', true);
% open the project file
open(project.file)
%% Create a simple search tree definition

analysisPreset = struct();
analysisPreset.type = 'listByProtocol';
analysisPreset.buildTreeBy = {'displayName', 'stimTime', 'devices'};

% Build the tree based on the tree definition

buildAnalysis('Example-Analysis', analysisPreset)

%% Create Finder for searching through tree

finder = getFeatureFinder('Example-Analysis', 'cellData', '2017-10-02c2');
finder.getStructure().tostring()

%%
% a) To list all the epoch group for protocol Auto Center

epochGroup = finder.find('displayName==Auto Center').toArray();
epochs = epochGroup.getFeatureData('EPOCH');

%%
% b) To get all the epochs corresponds to the above featureGroup

epochs = epochGroup.getFeatureData('AMP1_EPOCH');

% c) To get all the spikes corresponds to the above featureGroup

spikeTimes = epochGroup.getFeatureData('AMP1_SPIKES');


