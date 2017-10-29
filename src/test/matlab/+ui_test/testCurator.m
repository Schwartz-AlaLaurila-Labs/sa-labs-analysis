function testCurator()
ui_test.addJavaJars({'UIExtrasComboBox.jar', 'UIExtrasTable.jar', 'UIExtrasTable2.jar', 'UIExtrasTree.jar', 'UIExtrasPropertyGrid.jar'});
manager = getAnalysisManager();
p = sa_labs.analysis.ui.presenters.DataCuratorPresenter(manager);
p.go();
end

