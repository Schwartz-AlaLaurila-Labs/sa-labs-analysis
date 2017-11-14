classdef DataCuratorPresenter < appbox.Presenter
    
    properties (Access = protected)
        offlineAnalysisManager
        fileRepository
    end
    
    properties (Access = private)
        log
        settings
        uuidToNode
        filterMap
    end
    
    properties (Constant)
        DATA_CURATOR_PLOTS = 'sa_labs.analysis.data_curator.plots'
        PRE_PROCESSOR_FUNCTIONS = 'sa_labs.analysis.data_curator.pre_processor'
    end
    
    
    methods
        function obj = DataCuratorPresenter(offlineAnalysisManager, fileRepository, view)
            import sa_labs.analysis.*;
            if nargin < 3
                view = ui.views.DataCuratorView();
            end
            obj = obj@appbox.Presenter(view);
            obj.offlineAnalysisManager = offlineAnalysisManager;
            obj.fileRepository = fileRepository;
            obj.settings = ui.settings.DataCuratorSettings();
            obj.log = logging.getLogger(app.Constants.ANALYSIS_LOGGER);
            obj.uuidToNode = containers.Map();
        end
    end
    
    methods (Access = protected)
        
        function willGo(obj)
            obj.populateAvailablePlots();
            obj.populateAvailablePreProcessors();
            obj.populatePreProcessorParameters();
            obj.populateCellDataFilters();
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
            obj.addListener(v, 'BrowseLocation', @obj.onViewSelectedBrowseLocation);
            obj.addListener(v, 'LoadH5File', @obj.onViewLoadH5File);
            obj.addListener(v, 'ReParse', @obj.onViewReParse);
            obj.addListener(v, 'ShowFilteredEpochs', @obj.onViewShowFilteredEpochs);
            obj.addListener(v, 'SelectedNodes', @obj.onViewSelectedNodes).Recursive = true;
            obj.addListener(v, 'SelectedDevices', @obj.onViewSelectedDevices);
            obj.addListener(v, 'SelectedPlots', @obj.onViewSelectedPlots);
            obj.addListener(v, 'SelectedPlotFromPanel', @obj.onViewSelectedPlotFromPanel);
            obj.addListener(v, 'SelectedPreProcessor', @obj.onViewSelectedPreProcessor);
            obj.addListener(v, 'ExecutePreProcessor', @obj.onViewExecutePreProcessor);
            obj.addListener(v, 'SelectedXAxis', @obj.onViewSelectedXAxis);
            obj.addListener(v, 'SelectedYAxis', @obj.onViewSelectedYAxis);
            obj.addListener(v, 'DisablePlots', @obj.onViewDisabledPlots);
            obj.addListener(v, 'AddDeleteTag', @obj.onViewAddDeleteTag);
            obj.addListener(v, 'ClearDeleteTag', @obj.onViewClearDeleteTag);
            obj.addListener(v, 'DeleteEntity', @obj.onViewSelectedDeleteEntity);
            obj.addListener(v, 'PopoutActivePlot', @obj.onViewSelectedPopOutPlot);
            obj.addListener(v, 'AddParameter', @obj.onViewSelectedAddParamter);
            obj.addListener(v, 'RemoveParameter', @obj.onViewSelectedRemoveParamter);
            obj.addListener(v, 'SelectedCell', @obj.onViewSelectedCell);
            obj.addListener(v, 'SelectedFilter', @obj.onViewSelectedFilter);
            obj.addListener(v, 'SelectedFilterProperty', @obj.onViewSelectedFilterProperty);
            obj.addListener(v, 'SelectedFilterRow', @obj.onViewSelectedFilterRow);
            obj.addListener(v, 'ExecuteFilter', @obj.onViewExecuteFilter);
            obj.addListener(v, 'SaveConfiguredFilter', @obj.onViewSaveFilter);
            obj.addListener(v, 'AddParametersToFilteredGroup', @obj.onViewFilteredAddParamters);
            obj.addListener(v, 'RemoveParametersFromFilteredGroup', @obj.onViewSelectedRemoveParameters);
        end
    end
    
    methods (Access = private)
        
        function populateAvailablePlots(obj)
            plots = {meta.package.fromName(obj.DATA_CURATOR_PLOTS).FunctionList.Name};
            functionNames = {};
            for plot = each(plots)
                functionNames{end + 1} = [obj.DATA_CURATOR_PLOTS '.'  plot]; %#ok
            end
            obj.view.setAvailablePlots(plots, functionNames);
            obj.view.disablePlotPannel(true);
            obj.view.disableXYAxis(true);
        end
        
        function populateAvailablePreProcessors(obj)
            packages = {meta.package.fromName(obj.PRE_PROCESSOR_FUNCTIONS).PackageList.Name};
            functionNames = {''};
            preProcessors= {'none'};
            for package = each(packages)
                names = {meta.package.fromName(package).FunctionList.Name};
                for name = each(names)
                    functionNames{end + 1} = [package '.' name]; %#ok
                end
                preProcessors = [preProcessors names{:}]; %#ok
            end
            obj.view.setAvailablePreProcessorFunctions(preProcessors, functionNames);
            
        end
        
        function populateCellDataFilters(obj)
            obj.filterMap = obj.offlineAnalysisManager.getCellDataFilters();
            if ~ isempty(obj.filterMap)
                obj.view.loadCellDataFilters([{'None'}, obj.filterMap.keys]);
            end
        end

        function onViewSelectedBrowseLocation(obj, ~, ~)
            rawDataFolder = obj.fileRepository.rawDataFolder;
            file = obj.view.showGetFile('Select H5File', '*.h5', rawDataFolder);
            
            if isempty(file)
                return;
            end
            if ~ any(strfind(file, rawDataFolder))
                obj.view.showError('Don''t change the rawdata folder!')
                return;
            end
            [~, name, ~] = fileparts(file);
            
            if strcmp(name, obj.view.getExperimentName())
                return
            end
            obj.view.setH5FileName(name);
            obj.intializeCurator();
        end
        
        function onViewLoadH5File(obj, ~, ~)
            pattern = obj.view.getH5FileName();
            if isempty(pattern) || strcmp(pattern, obj.view.getExperimentName())
                return
            end
            obj.intializeCurator();
        end
        
        function intializeCurator(obj)
            pattern = obj.view.getH5FileName();
            p = obj.view.showBusy('Loading h5 file..');
            d = onCleanup(@()delete(p));
            
            obj.closeExisting();
            cellDataArray = obj.offlineAnalysisManager.getParsedCellData(pattern);
            
            obj.updatePlotPanel();
            obj.view.setExperimentNode(pattern, cellDataArray);
            obj.populateEntityTree(cellDataArray);
            obj.populateFilterDetails(cellDataArray);
        end
        
        function closeExisting(obj)
            node = obj.view.getCellFolderNode();
            obj.view.removeChildNodes(node);
        end
        
        function onViewReParse(obj, ~, ~)
            pattern = obj.view.getH5FileName();
            result = obj.view.showMessage( ...
                'Are you sure you want to override the existing cell data?', 'Reparse h5', ...
                'button1', 'Cancel', ...
                'button2', 'Yes', ...
                'width', 300);
            if ~strcmp(result, 'Yes')
                return;
            end
            p = obj.view.showBusy('Parsing h5 file..');
            d = onCleanup(@()delete(p));
            
            obj.offlineAnalysisManager.parseSymphonyFiles(pattern);
            obj.intializeCurator();
        end
        
        function populateEntityTree(obj, cellDataArray)
           
            for cellData = each(cellDataArray)
                obj.addCellDataNode(cellData);
            end
            obj.view.expandNode(obj.view.getCellFolderNode());
            enabled = numel(cellData) > 0;
            obj.view.enableAvailablePlots(enabled);
            obj.view.enableReParse(enabled)
            obj.view.enableAvailablePreProcessorFunctions(enabled);
            obj.view.disablePlotPannel(~ enabled);
        end
        
        function addCellDataNode(obj, cellData)
            parent = obj.view.getCellFolderNode();
            n = obj.view.addCellDataNode(parent, cellData.recordingLabel, cellData);
            obj.uuidToNode(cellData.uuid) = n;
            
            for epoch = each(cellData.epochs)
                obj.addEpochDataNode(epoch);
            end
        end
        
        function addEpochDataNode(obj, epoch)
            parent = obj.uuidToNode(epoch.parentCell.uuid);
            epochIndex = num2str(epoch.get('epochNum'));
            [h, m, s] = hms(epoch.get('epochTime'));
            h5EpochNumber = epoch.get('h5EpochNumber');
            
            name = strcat('(', epochIndex, ')');
            if ~ isempty(h5EpochNumber)
                strcat(name, '-(h5epochNumber=', num2str(h5EpochNumber) ,')');
            end
            name = strcat(name, '-', num2str(h), ':', num2str(m), ':', num2str(s));
            n = obj.view.addEpochDataNode(parent, name, epoch);
            obj.uuidToNode(epoch.uuid) = n;
        end
        
        function onViewShowFilteredEpochs(obj, ~, ~)
            tf = obj.view.canShowFilteredEpochs();
            obj.showFilteredEpochs(tf);
        end
        
        function showFilteredEpochs(obj, status)
            if ~ status
                 obj.showAllEpochs();
                 return
            end
            
            cellData = obj.getFilteredCellData();
            unFilteredEpochs = linq(cellData.epochs).where(@(epoch) isempty(epoch.filtered) || ~ epoch.filtered).toArray();
            
            if numel(unFilteredEpochs) == numel(cellData.epochs)
                obj.view.showError(['No epochs are filtered for cell ' cellData.recordingLabel]);
                return;
            end
            
            for epoch = each(unFilteredEpochs)
                if isKey(obj.uuidToNode, epoch.uuid)
                    node = obj.uuidToNode(epoch.uuid);
                    obj.view.removeNode(node);
                    remove(obj.uuidToNode, epoch.uuid);
                end
            end
        end
        
        function showAllEpochs(obj)
            cellData = obj.getFilteredCellData();
            updateNode = false;
            for epoch = each(cellData.epochs)
                unFiltered = isempty(epoch.filtered) || ~ epoch.filtered;
                if unFiltered && ~ isKey(obj.uuidToNode, epoch.uuid)
                    updateNode = true;
                    break;
                end
            end
            
            if ~ updateNode
                return;
            end
            p = obj.view.showBusy('Undo Filtering..');
            d = onCleanup(@()delete(p));
            node = obj.uuidToNode(cellData.uuid);
            obj.view.removeNode(node);
            obj.addCellDataNode(cellData);
            node = obj.uuidToNode(cellData.uuid);
            obj.view.expandNode(node);
        end
        
        function onViewSelectedDevices(obj, ~, ~)
            entitiyMap = obj.getSelectedEntityMap();
            obj.preProcessEntityMap(entitiyMap);
            obj.plotEntityMap(entitiyMap);
            obj.populateDetailsForEntityMap(entitiyMap);
        end
        
        function onViewSelectedPlots(obj, ~, ~)
            obj.updatePlotPanel();
            entitiyMap = obj.getSelectedEntityMap();
            obj.plotEntityMap(entitiyMap);
        end
        
        function setPlotXYAxis(obj)
            
            epochData = obj.getSelectedEpoch();
            inValid = isempty(epochData);
            
            if  ~ inValid
                plot = obj.view.getActivePlot();
                [~, parameter] = sa_labs.analysis.ui.util.helpDocToStructure(plot);
                xAxis = getValue(parameter.xAxis);
                yAxis = getValue(parameter.yAxis);
                obj.view.setXAxisValues(xAxis);
                obj.view.setYAxisValues(yAxis);
            end
            obj.view.disableXYAxis(inValid);
             
            function value = getValue(value)
                if sa_labs.analysis.ui.util.isFunctionHandle(value)
                    func = str2func(value);
                    value = func(epochData(1));
                else
                    value = strtrim(strsplit(value, ','));
                end
            end
        end
        
        function updatePlotPanel(obj)
            selectedPlots = obj.view.getSelectedPlots();
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
        
        function onViewSelectedXAxis(obj, ~, ~)
            entitiyMap = obj.getSelectedEntityMap();
            obj.plotEntityMap(entitiyMap);
        end
        
        function onViewSelectedYAxis(obj, ~, ~)
            entitiyMap = obj.getSelectedEntityMap();
            obj.plotEntityMap(entitiyMap);
        end
        
        function onViewSelectedPopOutPlot(obj, ~, ~)
            f = figure();
            ax = axes('Parent', f);
            entityMap = obj.getSelectedEntityMap();
            obj.plotEntityMap(entityMap, ax);
        end
        
        function onViewSelectedPlotFromPanel(obj, ~, ~)
            entityMap = obj.getSelectedEntityMap();
            obj.setPlotXYAxis();
            obj.plotEntityMap(entityMap);
        end
        
        function onViewSelectedPreProcessor(obj, ~, ~)
            entities = obj.getSelectedEpoch();
            if ~ isempty(entities) && numel(entities) == 1
                obj.updatePreProcessorParameters(entities);
            else
                obj.populatePreProcessorParameters();
            end
        end
        
        function populatePreProcessorParameters(obj)
            
            functionNames = obj.view.getSelectedPreProcessorFunction();
            fields = sa_labs.analysis.ui.util.helpdocToFields(functionNames);
            if ~ isempty(fields)
                obj.view.setPreProcessorParameters(fields);
                obj.view.enablePreProcessorPropertyGrid('on');
            end
        end
        
        function onViewExecutePreProcessor(obj, ~, ~)
            entitiyMap = obj.getSelectedEntityMap();
            obj.processSelectedEntity(entitiyMap);
        end
        
        function onViewDisabledPlots(obj, ~, ~)
            disabled = obj.view.hasPlotsDisabled();
            obj.view.disableXYAxis(disabled);
            obj.view.disablePlotPannel(disabled);
            if ~ disabled
                entitiyMap = obj.getSelectedEntityMap();
                obj.plotEntityMap(entitiyMap);
            end
        end
        
        function onViewSelectedAddParamter(obj, ~, ~)
            entityMap = obj.getSelectedEntityMap();
            values = entityMap.values;
            entities = [values{:}];
            
            if obj.addParameters(entities)
                obj.populateDetailsForEntityMap(entityMap);
                obj.populateFilterProperties();
            end
        end
        
        function onViewSelectedRemoveParamter(obj, ~, ~)
            entityMap = obj.getSelectedEntityMap();
            key = obj.view.getSelectedParameterNameFromPropertyGrid();
            values = entityMap.values;
            entity = [values{:}];
            
            if ~ isKey(entity.attributes, key)
                obj.view.showError('Select valid parameter from property grid');
                return
            end
            remove(entity.attributes, key);
            obj.populateDetailsForEntityMap(entityMap);
            obj.offlineAnalysisManager.saveCellData(entity);
            obj.populateFilterProperties();
       end
        
        function onViewSelectedCell(obj, ~, ~)
            obj.populateFilterProperties();
        end
        
        function onViewSelectedFilter(obj, ~, ~)
            name = obj.view.getSelectedFilterName();
            if strcmpi(name, 'None')
                obj.view.clearFilterProperties();
                obj.view.setSaveFilterName('');
                return;
            end
            filterTable = obj.filterMap(name);
            obj.view.clearFilterProperties();
            obj.view.enableAddAndDeleteParameters(false);
            obj.view.updateFilterProperties(filterTable);
            obj.view.setSaveFilterName(name);
        end
        
        function onViewSaveFilter(obj, ~, ~)
            name = obj.view.getSaveFilterName();
            if isempty(name)
                obj.view.showError('Filter name cannot be empty');
                return;
            end
            filterData = obj.view.getFilterRows();
            obj.offlineAnalysisManager.saveCellDataFilter(name, filterData);
            obj.populateCellDataFilters();
        end
        
        function onViewClearFilterProperties(obj, ~, ~)
            obj.view.clearFilterProperties();
            obj.view.enableAddAndDeleteParameters(false);
        end
        
        function populateFilterDetails(obj, cellDataArray)
            if isempty(cellDataArray)
                return
            end
            cellNames = {cellDataArray.recordingLabel};
            obj.view.setAvailableCellNames(cellNames);
            obj.populateFilterProperties();
        end
        
        function populateFilterProperties(obj)
            cellData = obj.getFilteredCellData();
            properties = cellData.getEpochKeysetUnion();
            obj.view.setFilterProperty(properties);
            obj.view.enableFilters(numel(cellData) == 1);
            obj.view.update();
        end
          
        function cellData = getFilteredCellData(obj)
            cellName = obj.view.getSelectedCellName();
            cellDataArray = obj.view.getExperimentData();
            cellData = linq(cellDataArray).where(@(data) strcmp(data.recordingLabel, cellName)).first();
        end
        
        function onViewSelectedFilterProperty(obj, ~, uiEventData)
            indices = uiEventData.data.Indices;
            row = indices(1);
            property = obj.view.getSelectedFilterProperty(row);
            obj.populateFilterValueSuggestion(property);
        end
        
        function onViewSelectedFilterRow(obj, ~, uiEventData)
            row = uiEventData.data.Indices;
            property = obj.view.getSelectedFilterProperty(row);
            obj.populateFilterValueSuggestion(property);
        end
        
        function populateFilterValueSuggestion(obj, property)
            if isempty(property)
                return
            end
            values = obj.getFilteredCellData().getEpochValues(property);
            suggestedValues = {''};
            if ~ isempty(values)
                suggestedValues = linq(values).select(@(x) cellstr(num2str(x))).distinct().toList();
            end
            
            type = 'numeric';
            if iscellstr(values)
                type = 'string';
            end
            obj.view.setFilterValueSuggestion(type, suggestedValues);
        end
        
        function onViewExecuteFilter(obj, ~, ~)
            import sa_labs.analysis.entity.*;
            
            filterData = obj.view.getFilterRows();
            cellData = obj.getFilteredCellData();
            epochs = cellData.epochs;

            arrayfun(@(e) setFiltered(e, false), epochs)
            obj.view.setConsoleText('processing !');
            query = linq(1 : numel(epochs));
            
            rows = size(filterData, 1);
            for row = 1 : rows
                predicate = obj.getFilterPredicate(filterData(row, :));
                query = query.where(@(index) predicate(epochs(index)));
            end
            filteredIndices = query.toArray();
            
            if numel(filteredIndices) ~= numel(epochs)
                arrayfun(@(e) setFiltered(e, true), epochs(filteredIndices))
            end
                
            enabled = numel(filteredIndices) > 0;
            obj.view.enableAddAndDeleteParameters(enabled);
            obj.view.enableShowFilteredEpochs(enabled);
            result = 'No matching records found !';
            
            if enabled
                [p, v] = cellData.getUniqueParamValues(filteredIndices);
                result = KeyValueEntity(containers.Map(p, v));
            end
            obj.view.setConsoleText(result);
            tf = obj.view.canShowFilteredEpochs() && numel(filteredIndices) ~= numel(epochs);
            obj.showFilteredEpochs(tf);
            
            function setFiltered(epoch, tf)
                epoch.filtered = tf;
            end
        end
        
        function predicate = getFilterPredicate(obj, rowData)
            property = rowData{1};
            condition = rowData{2};
            values =  rowData{3};
            
            index = cellfun(@(valueSet) ismember(condition, valueSet), obj.view.FILTER_CONDITION_MAP.values);
            keys = obj.view.FILTER_CONDITION_MAP.keys;
            type = keys{index};
            
            if strcmp(type, 'numeric')
                predicateCondition = str2func(strcat('@(data, values) any(data.get(''', property, ''')', condition, 'values)'));
                values = str2double(values);
                
            else
                predicateCondition = str2func(strcat('@(data, values) any(', condition, '(data.get(''', property, '''), values))'));
            end
            predicate = @(data) predicateCondition(data, values);
        end
        
        function onViewFilteredAddParamters(obj, ~, ~)
            cellData = obj.getFilteredCellData();
            entities = linq(cellData.epochs).where(@ (e) e.filtered).toArray();
            obj.addParameters(entities);
            
            entityMap = obj.getSelectedEntityMap();
            obj.populateDetailsForEntityMap(entityMap);
            obj.populateFilterProperties();
        end
        
        function tf = addParameters(obj, entities)
            presenter = sa_labs.analysis.ui.presenters.AddPropertyPresenter(entities);
            presenter.goWaitStop();
            tf = ~isempty(presenter.result);
            if tf
                obj.offlineAnalysisManager.saveCellData(entities);
            end
        end
        
        function onViewSelectedRemoveParameters(obj, ~, ~)
            cellData = obj.getFilteredCellData();
            entities = linq(cellData.epochs).where(@ (e) e.filtered).toArray();
            presenter = sa_labs.analysis.ui.presenters.RemovePropertiesPresenter(entities);
            presenter.goWaitStop();
            
            obj.offlineAnalysisManager.saveCellData(entities);
            
            entityMap = obj.getSelectedEntityMap();
            obj.populateDetailsForEntityMap(entityMap);
            obj.populateFilterProperties();
        end
        
        function onViewSelectedNodes(obj, ~, ~)
            tic
            obj.view.update();
            entitiyMap = obj.getSelectedEntityMap();
            obj.populateDevicesForCell(entitiyMap);
            obj.processSelectedEntity(entitiyMap);
            elapsedTime = toc;
            obj.log.info(['selected node processing time: ' num2str(elapsedTime)]);
        end
        
        function processSelectedEntity(obj, entitiyMap)
            
            try
                if obj.view.hasValidPreProcessorSelected()
                    obj.preProcessEntityMap(entitiyMap);
                end
            catch exception
                disp(exception.getReport);
                obj.view.showError(exception.message);
            end
            
            if ~ obj.view.hasPlotsDisabled()
                obj.setPlotXYAxis();
                obj.plotEntityMap(entitiyMap);
            end
            obj.populateDetailsForEntityMap(entitiyMap);
        end
        
        function populateDevicesForCell(obj, entitiyMap)
            cellDataArray = obj.getSelectedCell(entitiyMap);
            
            if isempty(cellDataArray)
                return
            end
            devices = linq(cellDataArray).selectMany(@(d) d.getEpochValues('devices')).distinct().toList();
            obj.view.setAvailableDevices(devices, devices);
            obj.view.enableSelectDevices(numel(devices) > 0);
        end
        
        function entitiyMap = getSelectedEntityMap(obj)
            import sa_labs.analysis.*;
            nodes = obj.view.getSelectedNodes();
            entitiyMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for node = each(nodes)
                entity = obj.view.getNodeEntity(node);
                type = obj.view.getNodeType(node);
                if ~ isempty(entity)
                    entitiyMap = util.collections.addToMap(entitiyMap, char(type), entity);
                end
            end
        end
        
        function populateDetailsForEntityMap(obj, entitiyMap)
            values = entitiyMap.values;
            entities = [values{:}];
            isValidEntity = ~ isempty(entities) && numel(entities) == 1;
            
            if isValidEntity
                fields = uiextras.jide.PropertyGridField.GenerateFromMap(entities(1).attributes);
            else
                fields = uiextras.jide.PropertyGridField.empty(0, 1);
            end
            obj.view.setParameterPropertyGrid(fields);
            obj.view.enableAddAndDeleteParameter(isValidEntity);
        end
        
        function preProcessEntityMap(obj, entitiyMap)
            import sa_labs.analysis.ui.views.EntityNodeType;

            cellEntities = obj.getSelectedCell(entitiyMap);
            epochEntities = obj.getSelectedEpoch(entitiyMap);
            needsBusyPresenter =  numel(cellEntities) + numel(epochEntities) > 5;
            
            if needsBusyPresenter
                p = obj.view.showBusy('Pre processing..');
                d = onCleanup(@()delete(p));
            end
            
            if ~ isempty(cellEntities)
                preProcesorHandles = obj.getPreProcessorHandle(char(EntityNodeType.CELLS));
                obj.offlineAnalysisManager.preProcessCellData(cellEntities, preProcesorHandles);
            end
            
            if ~ isempty(epochEntities)
                obj.updatePreProcessorParameters(epochEntities);
                preProcesorHandles = obj.getPreProcessorHandle(char(EntityNodeType.EPOCH));
                obj.offlineAnalysisManager.preProcessEpochData(epochEntities, preProcesorHandles);
            end
        end

        function preProcesorHandles = getPreProcessorHandle(obj, type)

            preProcesors = obj.view.getSelectedPreProcessorFunction();
            preProcesors = linq(preProcesors).where(@(p) any(strfind(lower(p), lower(type)))).toList();
            preProcesorHandles = cell(1, numel(preProcesors));
            
            for i = 1 : numel(preProcesors)
                preProcessor = preProcesors{i};
                parameters = obj.view.getPreprocessorFunctionParameters(preProcessor);
                functionDelegate = getDelegate(preProcessor);
                preProcesorHandles{i} = @(data) functionDelegate(data, parameters);
            end
            
            function f = getDelegate(preProcessor)
                f = str2func(strcat('@(data, parameters) ', preProcessor, '(data, parameters)'));
                obj.log.info(['Executing ' func2str(f)])
            end
        end
        
        function updatePreProcessorParameters(obj, entity)
           
            if isempty(entity) || numel(entity) > 1
               return
            end

            import uiextras.jide.*;
            import sa_labs.analysis.ui.util.*;
            
            functionNames = obj.view.getSelectedPreProcessorFunction();
            fields = obj.view.getPreProcessorParameterPropertyGrid();
            devices = obj.view.getSelectedDevices();
            
            defaultFields = helpdocToFields(functionNames);
            
            for i = 1 : numel(defaultFields)
                
                defaultField = defaultFields(i);
                oldField = fields.FindByName(defaultField.Name);
                
                if isFunctionHandle(defaultField.Value)
                    func = str2func(defaultField.Value);
                    values = func(entity, devices);
                    trueIndex = true(size(values));
                    
                    newField = PropertyGridField(defaultField.Name, trueIndex,...
                        'Type', PropertyType('logical', 'row', values));
                    newField.Category = defaultField.Category;
                    newField.DisplayName = defaultField.DisplayName;
                    defaultFields(i) = newField;
                    
                elseif ~ isempty(oldField)
                    defaultFields(i).Value = oldField.Value;
                end
            end
            obj.view.setPreProcessorParameters(defaultFields);
        end
        
        function plotEntityMap(obj, entitiyMap, axes)
            
            entities = obj.getSelectedEpoch(entitiyMap);
            if isempty(entities)
                return
            end
            plot = obj.view.getActivePlot();
            devices = obj.view.getSelectedDevices();

            if isempty(devices)
                obj.view.showMessage('Device is empty. Click on cell level to select the amplifier');
                return;
            end
            
            if nargin < 3
                axes = obj.view.getAxes(plot);
            end            
            parameter = struct();
            parameter.devices = devices;
            parameter.xAxis = obj.view.getXAxisValue();
            parameter.yAxis = obj.view.getYAxisValue();
            functionDelegate = str2func(strcat('@(data, parameter, axes) ', plot, '(data, parameter, axes)'));
            
            try
                functionDelegate(entities, parameter, axes);
            catch exception
                disp(exception.getReport);
                obj.view.showError(exception.message);
            end
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
        
        function entities = getSelectedEpoch(obj, entitiyMap)
            import sa_labs.analysis.ui.views.EntityNodeType;
            
            if nargin < 2
                entitiyMap = obj.getSelectedEntityMap();
            end
            entities = [];
            key = char(EntityNodeType.EPOCH);
            if ~ isKey(entitiyMap, key)
                return
            end
            entities = entitiyMap(key);
            if isempty(entities)
                return
            end
        end
        
        function entities = getSelectedCell(obj, entitiyMap)
            import sa_labs.analysis.ui.views.EntityNodeType;
            
            if nargin < 2
                entitiyMap = obj.getSelectedEntityMap();
            end
            entities = [];
            key = char(EntityNodeType.CELLS);
            
            if isKey(entitiyMap, key)
                entities = entitiyMap(key);
            end
        end
        
        function onViewAddDeleteTag(obj, ~, ~)
            epochs = obj.getSelectedEpoch();
            for epoch = each(epochs)
                if ~ epoch.excluded
                    epoch.excluded = true;
                    node = obj.uuidToNode(epoch.uuid);
                    name = obj.view.getNodeName(node);
                    obj.view.setNodeName(node, strcat('To delete-', name));
                end
            end
        end
        
        function onViewClearDeleteTag(obj, ~, ~)
            epochs = obj.getSelectedEpoch();
            for epoch = each(epochs)
                if epoch.excluded
                    epoch.excluded = false;
                end
                node = obj.uuidToNode(epoch.uuid);
                name = obj.view.getNodeName(node);
                obj.view.setNodeName(node, strrep(name, 'To delete-', ''));
            end
        end
        
        function onViewSelectedDeleteEntity(obj, ~, ~)
            obj.deleteSelectedEntity();
        end
        
        function deleteSelectedEntity(obj)
            node = obj.view.getCellFolderNode();
            cellDatas = obj.view.getExperimentData();
            
            result = obj.view.showMessage( ...
                'Are you sure you want to delete Tagged Epochs ?', 'Delete Entity', ...
                'button1', 'Cancel', ...
                'button2', 'Delete', ...
                'width', 300);
            if ~strcmp(result, 'Delete')
                return;
            end
            p = obj.view.showBusy('Deleting epochs..');
            d = onCleanup(@()delete(p));
                
            obj.view.collapseNode(node);
            updatedCellDatas = obj.offlineAnalysisManager.deleteEpochFromCells(cellDatas);
            
            for updateCellData = each(updatedCellDatas)
                node = obj.uuidToNode(updateCellData.uuid);
                obj.view.removeNode(node);
            end
            obj.populateEntityTree(updatedCellDatas);
        end
    end
end