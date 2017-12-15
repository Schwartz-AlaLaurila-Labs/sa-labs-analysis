classdef TreeBrowserPresenter < appbox.Presenter
    
    properties
        analysisManager
        fileRepository
    end
    
    properties (Access = private)
        analysisprojectName
        featureTreeFinder
        log
        settings
        uuidToNode
    end
    
    properties (Constant)
        ANALYSES_PLOTS = 'sa_labs.analysis.tree_browser.plots'
    end
    
    methods
        
        function obj = TreeBrowserPresenter(projectName, analysisManager, fileRepository, view)
            import  sa_labs.analysis.*;
            if nargin < 4
                view = ui.views.TreeBrowserView();
            end
            
            obj = obj@appbox.Presenter(view);
            obj.analysisprojectName = projectName;
            obj.analysisManager = analysisManager;
            obj.log = logging.getLogger(app.Constants.ANALYSIS_LOGGER);
            obj.settings = ui.settings.TreeBrowserSettings();
            obj.fileRepository = fileRepository;
            obj.uuidToNode = containers.Map();
        end
        
    end
    
    methods (Access = protected)
        
        function willGo(obj)
            obj.initalizeAnalysisProject();
            obj.populateAvailablePlots();
            obj.updatePlotPanel();
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load presenter settings: ' x.message]);
            end
            obj.updateStateOfControls();
        end
        
        function willStop(obj)
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save presenter settings: ' x.message]);
            end
        end
        
        function bind(obj)
            bind@appbox.Presenter(obj);
            
            v = obj.view;
            obj.addListener(v, 'SelectedNodes', @obj.onViewSelectedNodes).Recursive = true;
            obj.addListener(v, 'AddAnalysisTree', @obj.onViewAddAnalysisTree);
            obj.addListener(v, 'SelectedPlots', @obj.onViewSelectedPlots);
            obj.addListener(v, 'SelectedPlotFromPanel', @obj.onViewSelectedPlotFromPanel);
            obj.addListener(v, 'SelectedXAxis', @obj.onViewSelectedXAxis);
            obj.addListener(v, 'SelectedYAxis', @obj.onViewSelectedYAxis);
            obj.addListener(v, 'PopoutActivePlot', @obj.onViewSelectedPopOutPlot);  
            obj.addListener(v, 'EnableFeatureIteration', @obj.onViewSelectedEnableFeatureIteration);
            obj.addListener(v, 'GoToPreviousFeature', @obj.onViewSelectedGoToPreviosFeature);          
            obj.addListener(v, 'GoToNextFeature', @obj.onViewSelectedGoToNextFeature);                      
        end
    end
    
    methods (Access = private)
        
        function initalizeAnalysisProject(obj)
            [finder, project] = obj.analysisManager.getFeatureFinder(obj.analysisprojectName);
            obj.featureTreeFinder = finder;
            root = obj.view.setAnalysisProjectNode(project.identifier, project);
            
            
            for analysisType = each(project.getUniqueAnalysisTypes())
                analysisNode = obj.view.addAnalysisNode(root, analysisType);

                for cellName = each(project.getCellNames(analysisType))
                    cellData = project.getCellData(cellName);
                    n = obj.view.addCellsNode(analysisNode, cellName, cellData);
                    groupName = project.getAnalysisResultName(analysisType, cellName);
                    obj.addEpochGroup(groupName, n);
                end
            end
        end

        function addEpochGroup(obj, groupName, parentNode, parentGroupName)
            isNodeCreated = false;
            if nargin < 4
                parentGroupName = [];
                isNodeCreated = true;
            end
            
            finder = obj.featureTreeFinder;
            epochGroup = finder.find(groupName, 'hasParent', parentGroupName).toArray();
            % create node only for epoch groups
            if ~ isNodeCreated
                n = obj.view.addEpochGroupNode(parentNode, epochGroup.name, epochGroup);
            else
                n = parentNode;
            end
            obj.uuidToNode(epochGroup.uuid) = n;
            obj.addFeatures(epochGroup);            
            
            for childEpochGroup = each(finder.getChildEpochGroups(epochGroup))
                obj.addEpochGroup(childEpochGroup.name, n, epochGroup.name);
            end
        end

        function addFeatures(obj, epochGroup)
            parent = obj.uuidToNode(epochGroup.uuid);
            
            for key = each(epochGroup.getFeatureKey())
                obj.view.addFeatureNode(parent, key, epochGroup);
            end
        end

        function populateAvailablePlots(obj)
            plots = {meta.package.fromName(obj.ANALYSES_PLOTS).FunctionList.Name};
            functionNames = {};
            for plot = each(plots)
                functionNames{end + 1} = [obj.ANALYSES_PLOTS '.'  plot]; %#ok
            end
            obj.view.setAvailablePlots(plots, functionNames);
        end

        function updatePlotPanel(obj)
            selectedPlots = obj.view.getSelectedPlots();
            
            if isempty(selectedPlots)
                return;
            end
            unSelectedplots = obj.view.getUnSelectedPlots();
            titles = {};
            for plot = each(selectedPlots)
                parsedName = strsplit(plot, '.');
                titles{end +1} = parsedName{end}; %#ok
            end
            obj.view.addPlotToPanelTab(selectedPlots, titles);
            obj.view.removePlotFromPanelTab(unSelectedplots);
            obj.setPlotXYAxis();
        end

        function setPlotXYAxis(obj)
            v = obj.view;
            nodes = v.getSelectedNodes();
            plot = v.getActivePlot();
            inValid = isempty(nodes) || isempty(plot);

            if  ~ inValid
                [~, parameter] = sa_labs.analysis.ui.util.helpDocToStructure(plot);
                entity = v.getNodeEntity(nodes(1));
                xAxis = getValue(parameter.xAxis);
                yAxis = getValue(parameter.yAxis);
                v.setXAxisValues(xAxis);
                v.setYAxisValues(yAxis);
            end
            v.disableXYAxis(inValid);
             
            function value = getValue(value)
                if sa_labs.analysis.ui.util.isFunctionHandle(value)
                    func = str2func(value);
                    value = func(entity);
                else
                    value = strtrim(strsplit(value, ','));
                end
            end
        end

        function onViewSelectedNodes(obj, ~, ~)
            import sa_labs.analysis.ui.views.EntityNodeType;

            obj.view.enableFeatureIteration(false);
            nodes = obj.view.getSelectedNodes();
            [isSameType, type] = obj.isNodeOfSameType(nodes);    
            
            if ~ isSameType
                return;
            end
            
            switch type
                case EntityNodeType.EPOCH_GROUP
                   obj.updateEpochGroupParameter();
                   obj.setPlotXYAxis();
                case EntityNodeType.ANALYSIS_PROJECT
                   obj.updateProjectParameters();
                case EntityNodeType.CELLS
                    obj.viewCellParameters();
                case EntityNodeType.FEATURE
                    obj.view.enableFeatureIteration(true);
                    obj.updateFeatures();
            end
            obj.plotSelectedNodes();
        end
        
        function updateEpochGroupParameter(obj)
            v = obj.view;
            nodes = v.getSelectedNodes();
            
            if numel(nodes) > 1
                return;
            end
            epochGroup = v.getNodeEntity(nodes(1));
            fields = obj.convertMapToPropertyGridFields(epochGroup.attributes);
            v.setParameterPropertyGrid(fields);
            v.enabledEditParameters(false);
            v.enableAddAndDeleteParameter(true);
        end

        function updateProjectParameters(obj)
            v = obj.view;
            nodes = v.getSelectedNodes();
            analysisProject = v.getNodeEntity(nodes(1));
            fields = uiextras.jide.PropertyGridField.GenerateFromClass(analysisProject);
            v.setParameterPropertyGrid(fields);
            v.enabledEditParameters(false);
            v.enableAddAndDeleteParameter(false);
        end

        function viewCellParameters(obj)
            v = obj.view;
            nodes = v.getSelectedNodes();
            cellData = v.getNodeEntity(nodes(1));
            fields = obj.convertMapToPropertyGridFields(cellData.attributes);
            v.setParameterPropertyGrid(fields);
            v.enabledEditParameters(false);
            v.enableAddAndDeleteParameter(false);
        end

        function updateFeatures(obj)
            v = obj.view;
            nodes = v.getSelectedNodes();
            epochGroup = v.getNodeEntity(nodes(1));
            key = v.getNodeName(nodes(1));
            feature = epochGroup.getFeatures(key);

            if numel(nodes) > 1 || (~ v.canIterateFeature() && numel(feature) > 1)
                return;
            end
            index = v.getCurrentFeatureIndex();
            fields = obj.convertMapToPropertyGridFields(feature(index).description.toMap());
            v.setParameterPropertyGrid(fields);
            v.enabledEditParameters(false);
            v.enableAddAndDeleteParameter(false);
            
            obj.updateFeatureIterationControls();
        end

        function onViewAddAnalysisTree(obj, ~, ~)
            analysisFolder = obj.fileRepository.analysisFolder;
            files = obj.view.showGetFile('Select Analysis Trees', '*.mat', analysisFolder);
            warning('Not implemented !');
        end


        function onViewSelectedPlots(obj, ~, ~)
            obj.updatePlotPanel();
            obj.plotSelectedNodes();
        end

        function plotSelectedNodes(obj, axes)
            v = obj.view;
            nodes = v.getSelectedNodes();
            [isSameType, type] = obj.isNodeOfSameType(nodes);    
            plot = v.getActivePlot();

            if ~ isSameType || isempty(plot) || isempty(nodes) 
                return;
            end

            if nargin < 2
                axes = v.getAxes(plot);
            end

            if type.isEpochGroup()
                obj.plotEpochGroups(axes);
            elseif type.isFeature()
                obj.plotFeature(axes);
            end
        end

        function plotEpochGroups(obj, axes)
            v = obj.view;
            nodes = v.getSelectedNodes();
            plot = v.getActivePlot();

            parameter = struct();
            parameter.xAxis = v.getXAxisValue();
            parameter.yAxis = v.getYAxisValue();
            functionDelegate = str2func(strcat('@(epochGroups, parameter, axes) ', plot, '(epochGroups, parameter, axes)'));
            
            try
                epochGroups =  linq(nodes).select(@(n) v.getNodeEntity(n)).toArray();
                functionDelegate(epochGroups, parameter, axes);
            catch exception
                disp(exception.getReport);
                v.showError(exception.message);
            end
        end

        function plotFeature(obj, axes)
            v = obj.view;
            plot = v.getActivePlot();
            nodes = v.getSelectedNodes();

            if ~ any(strfind(plot, 'Feature')) || numel(nodes) > 1
                return
            end
            epochGroup = v.getNodeEntity(nodes);
            key = v.getNodeName(nodes);
            data = epochGroup.getFeatureData(key);
            features = epochGroup.getFeatures(key);
            
            if ~ v.canIterateFeature() && numel(features) > 1
                return;
            end
            description = [features.description];
            currentIndex = v.getCurrentFeatureIndex();

            functionDelegate = str2func(strcat('@(data, featureDescripion, axes) ', plot, '(data, featureDescripion, axes)'));
            try
                functionDelegate(data(currentIndex), description(currentIndex), axes);
            catch exception
                disp(exception.getReport);
                v.showError(exception.message);
            end
        end

        function enableFeatureIteration(obj, tf)
            v = obj.view;
            v.enablePreviousFeature(tf);
            v.enableNextFeature(tf);
            if tf 
                v.updateCurrentFeatureIndex(1); % start with first index
            end
        end

        function onViewSelectedPlotFromPanel(obj, ~, ~)
            obj.plotSelectedNodes();
        end

        function onViewSelectedXAxis(obj, ~, ~)
            obj.plotSelectedNodes();
        end
        
        function onViewSelectedYAxis(obj, ~, ~)
            obj.plotSelectedNodes();
        end
        
        function onViewSelectedPopOutPlot(obj, ~, ~)
            f = figure();
            ax = axes('Parent', f);
            obj.plotSelectedNodes(ax);
        end

        function onViewSelectedEnableFeatureIteration(obj, ~, ~)
            obj.updateFeatureIterationControls();
            obj.plotSelectedNodes();
        end
        
        function updateFeatureIterationControls(obj)
            v = obj.view;
            nodes = v.getSelectedNodes();
            index = v.getCurrentFeatureIndex();
            enabled = v.canIterateFeature() && numel(nodes) == 1;
            epochGroup = v.getNodeEntity(nodes(1));
            key = v.getNodeName(nodes(1));
            features = epochGroup.getFeatures(key);
            n = numel(features);
            v.setFeatureSize(n);

            obj.enableFeatureIteration(enabled && n ~=1);
            v.updateCurrentFeatureIndex(index);
        end

        function onViewSelectedGoToPreviosFeature(obj, ~, ~)
            v = obj.view;
            index = v.getCurrentFeatureIndex() - 1;
            if index < 1
                v.enablePreviousFeature(false);
                v.enableNextFeature(true);
                return
            end
            v.updateCurrentFeatureIndex(index);
            obj.plotSelectedNodes();
        end

        function onViewSelectedGoToNextFeature(obj, ~, ~)
            v = obj.view;
            index = v.getCurrentFeatureIndex() + 1;
            if index > v.getFeatureSize()
                 v.enableNextFeature(false);
                  v.enablePreviousFeature(true);
                return
            end
            v.updateCurrentFeatureIndex(index);
            obj.plotSelectedNodes();
        end
        
        function updateStateOfControls(obj)
        end
        
        function loadSettings(obj)
            if ~isempty(obj.settings.viewPosition)
                obj.view.position = obj.settings.viewPosition;
            end
        end
        
        function saveSettings(obj)
            obj.settings.viewPosition = obj.view.position;
            obj.settings.save();
        end        
    end

    methods (Access = private)
        
        function fields = convertMapToPropertyGridFields(~, map)
            values = map.values;
            invalidIndex = cellfun(@(v) iscell(v) && ~ iscellstr(v), values);
            keySet = map.keys;
            map = remove(map, keySet(invalidIndex));
            fields = uiextras.jide.PropertyGridField.GenerateFromMap(map);
        end

        function [tf, type] = isNodeOfSameType(obj, nodes)
            types = linq(nodes).select(@(node) obj.view.getNodeType(node)).toArray();
            tf = numel(unique(cellstr(types))) == 1;
            type = types(1);
        end
    end
end