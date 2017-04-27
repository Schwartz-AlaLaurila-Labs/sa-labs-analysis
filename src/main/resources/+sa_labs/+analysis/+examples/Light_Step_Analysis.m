%%
tbUseProject('sa-labs-analysis');

clear;
import sa_labs.analaysis.*

PROJECT_ID = 'Example-LightStep-Analysis';
experimentDate = '20170407'; 

createAnalysisProject('20170407', PROJECT_ID); 

%%

manager = getAnalysisManager();
project = manager.initializeProject(PROJECT_ID);

preProcessors = {@(d) addSpikesToEpoch(d)};
cellfun(@(data) manager.preProcess(data, preProcessors), project.getCellDataList());

%%