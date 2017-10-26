%% set all the java path
ui_test.addJavaJars({'UIExtrasComboBox.jar', 'UIExtrasTable.jar', 'UIExtrasTable2.jar', 'UIExtrasTree.jar', 'UIExtrasPropertyGrid.jar'});

%%
cellData = sa_labs.analysis.entity.CellData();
cellData.attributes = containers.Map({'recordingLabel'}, {'c1'});

epochs(1) = sa_labs.analysis.entity.EpochData();
epochs(1).attributes = containers.Map({'epochNumber', 'rstar', 'protocol'}, {1, 0.02, 'LightStep'});
epochs(1).parentCell = cellData;
epochs(2) = sa_labs.analysis.entity.EpochData();
epochs(2).attributes = containers.Map({'epochNumber', 'rstar', 'protocol'}, {2, 0.01, 'MovingBar'});
epochs(2).parentCell = cellData;
cellData.epochs = epochs;

filter1 = struct();
filter1.name = 'filter one';
filter2 = struct();
filter2.name = 'filter two';
filter3 = struct();
filter3.name = 'filter three';

offlineAnalysisManager = Mock();
offlineAnalysisManager.when.getParsedCellData(AnyArgs()).thenReturn(cellData);
offlineAnalysisManager.when.getCellDataFilters(AnyArgs()).thenReturn([filter1, filter2, filter3]);

if exist('p', 'var')
    p.stop();
    
end
p = sa_labs.analysis.ui.presenters.DataCuratorPresenter(offlineAnalysisManager);
p.go();

%%
