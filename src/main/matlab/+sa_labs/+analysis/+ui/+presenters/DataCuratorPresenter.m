classdef DataCuratorPresenter < appbox.Presenter

	properties
		viewSelectedCloseFcn
	end 

	properties (Access = protected)
		offlineAnalysisManager
	end

	properties (Access = private)
		log
		settings
		uuidToNode
    end
    
    properties (Constant)
        DATA_CURATOR_PLOTS = 'sa_labs.analysis.data_curator.plots'
        PRE_PROCESSOR_FUNCTIONS = 'sa_labs.analysis.data_curator.pre_processor'
    end
    

	methods 
		function obj = DataCuratorPresenter(offlineAnalysisManager, view)
			import sa_labs.analysis.*;
			if nargin < 2
			    view = ui.views.DataCuratorView();
			end
			obj = obj@appbox.Presenter(view);
			obj.offlineAnalysisManager = offlineAnalysisManager;
			obj.settings = ui.settings.DataCuratorSettings();
			obj.log = logging.getLogger(app.Constants.ANALYSIS_LOGGER);
			obj.uuidToNode = containers.Map();
		end
	end

	methods (Access = protected)
        
        function willGo(obj)
        	obj.populateCellDataFilters();
            obj.populateAvailablePlots();
            obj.populateAvailablePreProcessors();
            obj.populatePreProcessorParameters();
            try
                obj.loadSettings();
            catch x
                obj.log.debug(['Failed to load presenter settings: ' x.message]);
            end
            obj.updateStateOfControls();
        end

        function willStop(obj)
            obj.viewSelectedCloseFcn = [];
            try
                obj.saveSettings();
            catch x
                obj.log.debug(['Failed to save presenter settings: ' x.message]);
            end
        end

        function bind(obj)
            bind@appbox.Presenter(obj);

            v = obj.view;
            obj.addListener(v, 'LoadH5File', @obj.onViewLoadH5File);
            obj.addListener(v, 'ReParse', @obj.onViewReParse);
          	obj.addListener(v, 'SelectedNodes', @obj.onViewSelectedNodes).Recursive = true;
            obj.addListener(v, 'SelectedPreProcessor', @obj.onViewSelectedPreProcessor);
            obj.addListener(v, 'SelectedFilterProperty', @obj.onViewSelectedFilterProperty);
            obj.addListener(v, 'SelectedFilterRow', @obj.onViewSelectedFilterRow);
            obj.addListener(v, 'ExecuteFilter', @obj.onViewExecuteFilter);
        end

        function onViewSelectedClose(obj, ~, ~)
            if ~isempty(obj.viewSelectedCloseFcn)
                obj.viewSelectedCloseFcn();
            end
        end		
	end

	methods (Access = private)
        
        function populateCellDataFilters(obj)
            filters = obj.offlineAnalysisManager.getCellDataFilters();
            obj.view.loadCellDataFilters({filters.name});      
        end
        
        function populateAvailablePlots(obj)
            plots = {meta.package.fromName(obj.DATA_CURATOR_PLOTS).FunctionList.Name};
            functionNames = {};
            for plot = each(plots)
                functionNames{end + 1} = [obj.PRE_PROCESSOR_FUNCTIONS '.'  plot]; %#ok
            end
            obj.view.setAvailablePlots(plots, functionNames);
        end
        
        function populateAvailablePreProcessors(obj)
            preProcessors = {meta.package.fromName(obj.PRE_PROCESSOR_FUNCTIONS).FunctionList.Name};
            functionNames = {};
            for preProcessor = each(preProcessors)
                functionNames{end + 1} = [obj.PRE_PROCESSOR_FUNCTIONS '.' preProcessor]; %#ok
            end
            obj.view.setAvailablePreProcessorFunctions(preProcessors, functionNames);
            
        end
        
        function populatePreProcessorParameters(obj)
            functionNames = obj.view.getSelectedPreProcessorFunction();
            fields = sa_labs.analysis.ui.util.helpdocToFields(functionNames);
            if ~ isempty(fields)
                obj.view.setPreProcessorParameters(fields);
                obj.view.enablePreProcessorPropertyGrid('on');
            end
        end
        
		function onViewLoadH5File(obj, ~, ~)
			obj.populateCellDataEntity();
        end
        
        function onViewSelectedPreProcessor(obj, ~, ~)
            obj.populatePreProcessorParameters();
        end

		function populateCellDataEntity(obj)
			pattern = obj.view.getH5FileLocation();
			cellDataArray = obj.offlineAnalysisManager.getParsedCellData(pattern);
			obj.view.setExperimentNode(pattern, cellDataArray);

            for cellData = each(cellDataArray)
                obj.addCellDataNode(cellData);
            end
            obj.populateFilterDetails(cellDataArray);
            
			obj.view.expandNode(obj.view.getCellFolderNode());
            enabled = numel(cellData) > 0;
            
            obj.view.enableAvailablePlots(enabled);
            obj.view.enableAvailablePreProcessorFunctions(enabled);
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
            suggestedValues = linq(values).select(@(x) num2str(x)).toList();
            type = 'numeric';
            if iscellstr(values)
                type = 'string';
            end
            obj.view.setFilterValueSuggestion(type, suggestedValues);
        end
        
        function onViewExecuteFilter(obj, ~, ~)
            query = linq(obj.getFilteredCellData().epochs);
            filterRows = obj.view.getFilterRows();
            
            for row = each(filterRows)
                query = query.where(row.predicate);
            end
            
            filteredEpochs = query.toArray();
            for epoch = each(filteredEpochs)
                epoch.filtered = true;
            end
            obj.view.enableAddAndDeleteParameters(numel(filteredEpochs) > 0);
        end

		function addCellDataNode(obj, cellData)
			parent = obj.view.getCellFolderNode();
			n = obj.view.addCellDataNode(parent, cellData.recordingLabel, cellData);
            obj.uuidToNode(cellData.uuid) = n;
            
            for epoch = each(cellData.epochs)
            	if ~ epoch.excluded || epoch.filtered
            		obj.addEpochDataNode(epoch);
            	end
            end
		end

		function addEpochDataNode(obj, epoch)
			parent = obj.uuidToNode(epoch.parentCell.uuid);
            epochNumber = num2str(epoch.get('epochNumber'));
			n = obj.view.addEpochDataNode(parent, epochNumber, epoch);
            obj.uuidToNode(epoch.uuid) = n;			
		end
        
        function onViewSelectedNodes(obj, ~, ~)
            % obj.view.stopEditingProperties();
            obj.view.update();
            entitiyMap = obj.getSelectedEntityMap();
            obj.populateDetailsForEntityMap(entitiyMap);
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
end