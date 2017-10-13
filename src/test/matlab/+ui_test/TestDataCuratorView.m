%% set all the java path
ui_test.addJavaJars({'UIExtrasComboBox.jar', 'UIExtrasTable.jar', 'UIExtrasTable2.jar', 'UIExtrasTree.jar', 'UIExtrasPropertyGrid.jar'});

%%
dataCuratorview.close();
dataCuratorview = sa_labs.ui.DataCuratorView();
dataCuratorview.show();
%%
dataCuratorview.close();