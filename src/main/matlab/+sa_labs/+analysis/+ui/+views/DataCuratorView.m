classdef DataCuratorView < appbox.View
    
    events
        LoadH5File
        ReParse
        SelectedNodes
        SelectedDevices
        SelectedPlots
        SelectedPreProcessor
        ExecutePreProcessor
        ExcludeCurrentEpoch
        ApplyPreProcessorToAll
        ApplyPreProcessorToThisAndFuture
        UpdatePlots
        SelectedCell
        SelectedFilter
        DoRefreshFilterTable
        SelectedFilterProperty
        SelectedFilterRow
        AddNewParameter
        RemoveParameter
        ExecuteFilter
        SaveConfiguredFilter
        AddParametersToFilteredGroup
        RemoveParametersToFilteredGroup
        ChangedParameterProperties
        SendEntityToWorkspace
        AddDeleteTag
        DeleteEntity
    end
    
    properties (Access = private)
        shortCutMenu
        h5FileName
        loadH5FileButton
        reparseButton
        infoText
        entityTree
        cellFolderNode
        availablePreProcessorFunctions
        preProcessorPropertyGrid
        addParameterButton
        removeParameterButton
        executePreProcessorButton
        excludeCurrentEpochCheckBox
        availableDevices
        availablePlots
        tabPanel
        plotCard
        tagToDelete
        deleteTagged
        updatePlotsCheckBox
        goToEpochField
        parameterPropertyGrid
        availableCellsMenu
        availablefilterMenu
        filterTable
        executeFilterButton
        addParametersButton
        removeParametersButton
        filterNameField
        saveFilter
    end
    
    properties (Constant)
        FILTER_CONDITION_MAP = containers.Map({'numeric', 'string'},...
            {{'', '==', '>', '<', '>=', '<=', '~='}, {'', 'strcmpi', 'strfind', 'strcmp', 'regexp'}});
    end
    
    methods
        
        function createUi(obj)
            import appbox.*;
            import sa_labs.analysis.ui.views.EntityNodeType;
            
            set(obj.figureHandle, ...
                'Name', 'Data Curator', ...
                'Position', screenCenter(800, 520));
            % ShortCut menu.
            obj.shortCutMenu.root = uimenu(obj.figureHandle, ...
                'Label', 'ShortCuts');
            obj.shortCutMenu.tagDeleteEpochs = uimenu(obj.shortCutMenu.root, ...
                'Label', 'Add Delete Tag', ...
                'Accelerator', 'D', ...
                'Callback', @(h,d)notify(obj, 'AddDeleteTag'));
            
            layout = uix.VBoxFlex(...
                'Parent', obj.figureHandle,...
                'Spacing', 1);
            
            cellInfoLayout = uix.HBox( ...
                'Parent', layout, ...
                'Padding', 11);
            Label( ...
                'Parent', cellInfoLayout, ...
                'String', 'H5 File Name:');
            obj.h5FileName = uicontrol( ...
                'Parent', cellInfoLayout, ...
                'Style', 'edit', ...
                'HorizontalAlignment', 'left');
            obj.loadH5FileButton = uicontrol( ...
                'Parent', cellInfoLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Load', ...
                'Callback', @(h,d)notify(obj, 'LoadH5File'));
            uix.Empty('Parent', cellInfoLayout);
            obj.reparseButton = uicontrol( ...
                'Parent', cellInfoLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Re-Parse', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'ReParse'));

            uix.Empty('Parent', cellInfoLayout);
            set(cellInfoLayout, 'Widths', [100 -1 100 10 100 -5]);
                       
            mainLayout = uix.HBoxFlex( ...
                'Parent', layout, ...
                'DividerMarkings', 'off', ...
                'DividerBackgroundColor', [160/255 160/255 160/255], ...
                'padding', 5);
            
            masterLayout = uix.HBox( ...
                'Parent', mainLayout,...
                'padding', 11);
            
            obj.entityTree = uiextras.jTree.Tree( ...
                'Parent', masterLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'SelectionChangeFcn', @(h,d)notify(obj, 'SelectedNodes'), ...
                'SelectionType', 'discontiguous');

            root = obj.entityTree.Root;
            set(root, 'Value', struct('entity', [], 'type', EntityNodeType.EXPERIMENT));
            
            cells = uiextras.jTree.TreeNode( ...
                'Parent', root, ...
                'Name', 'Cells', ...
                'Value', struct('entity', [], 'type', EntityNodeType.CELLS));
            obj.cellFolderNode = cells;

            detailLayout = uix.VBox( ...
                'Parent', mainLayout, ...
                'Padding', 11);
            
            % Epoch card.
            epochLayout = uix.VBox( ...
                'Parent', detailLayout, ...
                'Spacing', 5);
            signalLayout = uix.HBox( ...
                'Parent', epochLayout, ...
                'Padding', 5);
            signalPreProcessingLayout = uix.VBox( ...
                'Parent', signalLayout);
            Label( ...
                'Parent', signalPreProcessingLayout, ...
                'String', 'Available Devices:');
            obj.availableDevices = MappedListBox( ...
                'Parent', signalPreProcessingLayout, ...
                'Max', 5, ...
                'Min', 1, ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'SelectedDevices'));
            Label( ...
                'Parent', signalPreProcessingLayout, ...
                'String', 'Available Plots:');
            obj.availablePlots = MappedListBox( ...
                'Parent', signalPreProcessingLayout, ...
                'Max', 5, ...
                'Min', 1, ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'SelectedPlots'));
            Label( ...
                'Parent', signalPreProcessingLayout, ...
                'String', 'Pre-Processor Functions:');
            obj.availablePreProcessorFunctions = MappedListBox( ...
                'Parent', signalPreProcessingLayout, ...
                'Max', 5, ...
                'Min', 1, ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'SelectedPreProcessor'));
            obj.preProcessorPropertyGrid = uiextras.jide.PropertyGrid(signalPreProcessingLayout, ...
                'Enable', false, ...
                'ShowDescription', true);
            obj.executePreProcessorButton = uicontrol( ...
                'Parent', signalPreProcessingLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Execute', ...
                'Callback', @(h,d)notify(obj, 'ExecutePreProcessor'));
            set(signalPreProcessingLayout, 'Heights', [30 -1 30 -2 30 -3 -2 30]);

            signalDetailLayout = uix.VBox( ...
                'Parent', signalLayout, ...
                'Spacing', 5);
            
            obj.tabPanel = uix.TabPanel( ...
                'Parent', signalDetailLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'Padding', 11,...
                'TabWidth', 100,... 
                'BackgroundColor', 'w');

            signalDetailControlLayout = uix.HBox( ...
                'Parent', signalDetailLayout, ...
                'Spacing', 5);
            uix.Empty('Parent', signalDetailControlLayout);
            obj.tagToDelete = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Tag To Delete', ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'AddDeleteTag'));
            obj.deleteTagged = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Delete Tagged', ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'DeleteEntity'));
            obj.updatePlotsCheckBox = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'checkbox', ...
                'String', 'Update Plots While Pre-Processing', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'UpdatePlots'));
            obj.excludeCurrentEpochCheckBox = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'checkbox', ...
                'String', 'Exclude Current Epoch', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'ExcludeCurrentEpoch'));
            Label( ...
                'Parent', signalDetailControlLayout, ...
                'String', 'Go To Epoch:');
            obj.goToEpochField = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'edit', ...
                'HorizontalAlignment', 'left');
            uix.Empty('Parent', signalDetailControlLayout);
            set(signalDetailControlLayout, 'Widths', [20 100 150 210 150 80 50 -2]);
            
            set(signalDetailLayout, 'Heights', [-1 30]);
            set(signalLayout, 'Widths', [-1.2 -7]);
            set(mainLayout, 'Widths', [-1 -5]);
            
            parameterLayout = uix.HBox( ...
                'Parent', layout, ...
                'Spacing', 5);
            parameterPropertyLayout = uix.VBox( ...
                'Parent', parameterLayout, ...
                'Spacing', 5);
            obj.parameterPropertyGrid = uiextras.jide.PropertyGrid(parameterPropertyLayout, ...
                'Enable', false, ...
                'Callback', @(h,d)notify(obj, 'ChangedParameterProperties'));
            parameterPropertyGridControlLayout = uix.HBox( ...
                'Parent', parameterPropertyLayout, ...
                'Padding', 9);
            obj.addParameterButton = uicontrol( ...
                'Parent', parameterPropertyGridControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Add Parameter', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'AddNewParameter'));
            obj.removeParameterButton = uicontrol( ...
                'Parent', parameterPropertyGridControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Remove Parameter', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'RemoveParameter'));
            set(parameterPropertyLayout, 'Heights', [-1 45]);
          
           filterLayout = uix.VBox( ...
               'Parent', parameterLayout, ...
               'Padding', 5);            
           filterLabelLayout = uix.HBox( ...
               'Parent', filterLayout, ...
               'Padding', 5);
           Label( ...
               'Parent', filterLabelLayout, ...
               'String', 'Select Cell: ');
           obj.availableCellsMenu = MappedPopupMenu( ...
               'Parent', filterLabelLayout, ...
               'String', {' '}, ...
               'Enable', 'off', ...
               'HorizontalAlignment', 'left', ...
               'Callback', @(h,d)notify(obj, 'SelectedCell'));
           Label( ...
               'Parent', filterLabelLayout, ...
               'String', '  Select Filter:');
           obj.availablefilterMenu = MappedPopupMenu( ...
               'Parent', filterLabelLayout, ...
               'String', {' '}, ...
               'HorizontalAlignment', 'left', ...
               'Enable', 'off', ...
               'Callback', @(h,d)notify(obj, 'SelectedFilter'));
           set(filterLabelLayout, 'Widths', [60 -1 80 -2]);
           
           obj.filterTable = uiextras.jTable.Table(...
               'Parent', filterLayout,...
               'ColumnEditable', [true true true],...
               'ColumnName', {'Property','Condition', 'Value'},...
               'ColumnFormat', {'popup', 'popup', 'popupcheckbox'},...
               'CellSelectionCallback', @(h, d)notify(obj, 'SelectedFilterRow', sa_labs.analysis.ui.util.UiEventData(d)),...
               'CellEditCallback', @(h, d)notify(obj, 'SelectedFilterProperty', sa_labs.analysis.ui.util.UiEventData(d)),...
               'ColumnPreferredWidth', [40 20 100]);
           obj.filterTable.Data = cell(10, 3);
           
           filterControlsLayout = uix.HBox( ...
               'Parent', filterLayout, ...
               'Padding', 11);
           obj.executeFilterButton = uicontrol( ...
               'Parent', filterControlsLayout, ...
               'Style', 'pushbutton', ...
               'String', 'Execute', ...
               'Callback', @(h,d)notify(obj, 'ExecuteFilter'));
           obj.addParametersButton = uicontrol( ...
               'Parent', filterControlsLayout, ...
               'Style', 'pushbutton', ...
               'String', 'Add Parameters', ...
               'Callback', @(h,d)notify(obj, 'AddParametersToFilteredGroup'));
           obj.removeParametersButton = uicontrol( ...
               'Parent', filterControlsLayout, ...
               'Style', 'pushbutton', ...
               'String', 'Remove Parameters', ...
               'Callback', @(h,d)notify(obj, 'RemoveParametersToFilteredGroup'));
           Label( ...
               'Parent', filterControlsLayout, ...
               'String', 'Name:');
           obj.filterNameField = uicontrol( ...
               'Parent', filterControlsLayout, ...
               'Style', 'edit', ...
               'HorizontalAlignment', 'left');
           obj.saveFilter = uicontrol( ...
               'Parent', filterControlsLayout, ...
               'Style', 'pushbutton', ...
               'String', 'Save', ...
               'Callback', @(h,d)notify(obj, 'SaveConfiguredFilter'));
           set(filterControlsLayout, 'Widths', [-1 -2 -2 -1 -2 -1]);
           set(filterLayout, 'Heights', [40 -1 50]);
            
            consoleLayout =  uix.VBox( ...
                'Parent', parameterLayout, ...
                'Padding', 5);
            Label( ...
                'Parent', consoleLayout, ...
                'String', 'Results:');
            obj.infoText = TextArea( ...
                'Parent', consoleLayout,...
                'Scrollable', true);
            set(consoleLayout, 'Heights', [30 -1]);
            set(parameterLayout, 'Widths', [-2, -2, -3])
            
            set(layout, 'Heights', [50 -3 -1]);
        end
        
        function path = getH5FileLocation(obj)
            path = get(obj.h5FileName, 'String');
        end
        
        function setAvailableDevices(obj, names, values)
            set(obj.availableDevices, 'String', names);
            set(obj.availableDevices, 'Values', values);
            if isempty(obj.getSelectedDevices) && ~ isempty(values)
                set(obj.availableDevices, 'Value', values{1});
            end
        end
        
        function devices = getSelectedDevices(obj)
             devices = get(obj.availableDevices, 'Value');
        end
        
        function enableSelectDevices(obj, tf)
            set(obj.availableDevices, 'Enable', appbox.onOff(tf));
        end
        
        function setAvailablePlots(obj, names, values)
            set(obj.availablePlots, 'String', names);
            set(obj.availablePlots, 'Values', values);
        end
        
        function plots = getSelectedPlots(obj)
             plots = get(obj.availablePlots, 'Value');
        end
        
        function plots = getUnSelectedPlots(obj)
            allPlots = get(obj.availablePlots, 'Values');
            selectedPlots = obj.getSelectedPlots();
            plots = setdiff(allPlots, selectedPlots);
        end
        
        function addPlotToPanelTab(obj, plots)
            for plot = each(plots)
                plotField = obj.getValidPlotField(plot);
                
                if ~ isfield(obj.plotCard, plotField)
                    newplotCard.panel = uipanel( ...
                        'Parent', obj.tabPanel, ...
                        'BorderType', 'line', ...
                        'HighlightColor', [130/255 135/255 144/255], ...
                        'BackgroundColor', 'w');
                    newplotCard.axes = axes( ...
                        'Parent', newplotCard.panel);
                    set(newplotCard.axes, 'YColor', 'black');
                    obj.plotCard.(plotField) = newplotCard;
                end
            end
        end
        
        function removePlotFromPanelTab(obj, plots)
            for plot = each(plots)
                plotField = obj.getValidPlotField(plot);
                
                if isfield(obj.plotCard, plotField)
                    oldplotCard = obj.plotCard.(plotField);
                    delete(oldplotCard.panel);
                    delete(oldplotCard.axes);
                    obj.plotCard = rmfield(obj.plotCard, plotField);
                end
            end
        end
        
        function setPlotPannelTitles(obj, names)
            obj.tabPanel.TabTitles = names;
        end
        
        function ax = getAxes(obj, plot)
            plotField = obj.getValidPlotField(plot);
            ax = obj.plotCard.(plotField).axes;
        end
        
        function setAvailablePreProcessorFunctions(obj, names, values)
            set(obj.availablePreProcessorFunctions, 'String', names);
            set(obj.availablePreProcessorFunctions, 'Values', values);
        end
        
        function functionNames = getSelectedPreProcessorFunction(obj)
            functionNames = get(obj.availablePreProcessorFunctions, 'Value');
        end
                
        function setPreProcessorParameters(obj, properties)
             set(obj.preProcessorPropertyGrid, 'Properties', properties);
             set(obj.preProcessorPropertyGrid, 'Enable', true);
        end
        
        function parameters = getPreprocessorFunctionParameters(obj, preProcessor)
            properties = get(obj.preProcessorPropertyGrid, 'Properties');
            functionNames = strsplit(preProcessor, '.');
            category = appbox.humanize(functionNames{end});
            parameters = struct();
            
            if isempty(properties)
                return
            end
            filteredProperties = linq(properties).where(@(prop) strcmpi(prop.Category, category)).toArray();
          
            for prop = each(filteredProperties)
                value = prop.Value;
                if isa(prop.Type, 'uiextras.jide.PropertyType') && prop.Type.islogical()
                    value = prop.Type.Domain(value);
                end
                parameters.(prop.Name) = value;
            end
        end
        
        function propertyGrid = getPreProcessorParameterPropertyGrid(obj)
            propertyGrid = get(obj.preProcessorPropertyGrid, 'Properties');
        end

        function setExperimentNode(obj, name, entity)
            value = get(obj.entityTree.Root, 'Value');
            value.entity = entity;
            set(obj.entityTree.Root, ...
                'Name', name, ...
                'Value', value);
        end
        
        function name = getExperimentName(obj)
            name = get(obj.entityTree.Root, 'Name');
        end
        
        function entity = getExperimentData(obj)
            value = get(obj.entityTree.Root, 'Value');
            entity = value.entity;
        end

        function n = addCellDataNode(obj, parent, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.views.EntityNodeType.CELLS;
            n = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', value);
        end

        function node = getCellFolderNode(obj)
            node = obj.cellFolderNode;
        end

        function n = addEpochDataNode(obj, parent, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.views.EntityNodeType.EPOCH;
            n = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', value);
            menu = uicontextmenu('Parent', obj.figureHandle);
            menu = obj.addEpochDataContextMenus(menu);
            set(n, 'UIContextMenu', menu);
        end
        
        function setAvailableCellNames(obj, cellNames)
           obj.availableCellsMenu.setString(cellNames); 
        end
        
        function cellName = getSelectedCellName(obj)
            cellNames = get(obj.availableCellsMenu, 'String');
            index = obj.availableCellsMenu.getValue;
            cellName = cellNames(index);
        end

        function loadCellDataFilters(obj, filterNames)
            set(obj.availablefilterMenu, 'String', filterNames); 
        end
        
        function setFilterProperty(obj, properties)
            obj.filterTable.ColumnFormatData{1} = properties;
            obj.filterTable.ColumnFormatData{2} = {''};
        end
        
        function setFilterValueSuggestion(obj, type, value)
            obj.filterTable.ColumnFormatData{2} = obj.FILTER_CONDITION_MAP(type);
            obj.filterTable.ColumnFormatData{3} = value;
        end
        
        function enableFilters(obj, tf)
            set(obj.availableCellsMenu, 'Enable', appbox.onOff(tf));
            set(obj.availablefilterMenu, 'Enable', appbox.onOff(tf));
        end
        
        function property = getSelectedFilterProperty(obj, row)
            property = obj.filterTable.Data{row, 1};
        end
        
        function filterRows = getFilterRows(obj)
            data = obj.filterTable.Data;
            rows = size(data, 1);
            filterRows = [];
            
            for i = 1 : rows
                rowData = data(i, :);
                if ~ any(cellfun(@isempty, rowData))
                    filterRows(i).predicate = obj.getFilterPredicate(rowData);  %#ok
                end
            end
        end
        
        function enableAvailablePlots(obj, tf)
            set(obj.availablePlots, 'Enable', appbox.onOff(tf));
        end
                
        function enableAvailablePreProcessorFunctions(obj, tf)
            set(obj.availablePreProcessorFunctions, 'Enable', appbox.onOff(tf));
        end
        
        function enablePreProcessorPropertyGrid(obj, tf)
            set(obj.preProcessorPropertyGrid, 'Enable', appbox.onOff(tf));
        end
        
        function n = getNodeName(obj, node) %#ok<INUSL>
            n = get(node, 'Name');
        end
        
        function setNodeName(obj, node, name) %#ok<INUSL>
            set(node, 'Name', name);
        end
        
        function i = getNodeIndex(obj, node) %#ok<INUSL>
            i = find(node.Parent.Children == node, 1);
        end
        
        function setNodeTooltip(obj, node, t) %#ok<INUSL>
            set(node, 'TooltipString', t);
        end
        
        function e = getNodeEntity(obj, node) %#ok<INUSL>
            v = get(node, 'Value');
            e = v.entity;
        end
        
        function t = getNodeType(obj, node) %#ok<INUSL>
            v = get(node, 'Value');
            t = v.type;
        end
        
        function removeNode(obj, node) %#ok<INUSL>
            node.delete();
        end
        
        function collapseNode(obj, node) %#ok<INUSL>
            node.collapse();
        end
        
        function expandNode(obj, node) %#ok<INUSL>
            node.expand();
        end
        
        function nodes = getSelectedNodes(obj)
            nodes = obj.entityTree.SelectedNodes;
        end
        
        function setSelectedNodes(obj, nodes)
            obj.entityTree.SelectedNodes = nodes;
        end
        
        function setParameterPropertyGrid(obj, properties)
             set(obj.parameterPropertyGrid, 'Properties', properties);
        end
        
        function enableAddAndDeleteParameter(obj, tf)
            set(obj.addParameterButton, 'Enable', appbox.onOff(tf));
            set(obj.removeParameterButton, 'Enable', appbox.onOff(tf));
        end
        
        function enableAddAndDeleteParameters(obj, tf)
            set(obj.addParametersButton, 'Enable', appbox.onOff(tf));
            set(obj.removeParametersButton, 'Enable', appbox.onOff(tf));
        end
        
        function setConsoleText(obj, text)
            obj.infoText.String = evalc('disp(text)');
        end
    end
    
    methods (Access = protected)
                
        function predicate = getFilterPredicate(obj, rowData)
            property = rowData{1};
            condition = rowData{2};
            values =  rowData{3};
            
            index = cellfun(@(valueSet) ismember(condition, valueSet), obj.FILTER_CONDITION_MAP.values);
            keys = obj.FILTER_CONDITION_MAP.keys;
            type = keys{index};
            
            if strcmp(type, 'numeric')
                predicateCondition = str2func(strcat('@(data, values) any(data.get(''', property, ''')', condition, 'values)'));
                values = str2double(values);
                
            else
                predicateCondition = str2func(strcat('@(data, values) any(', condition, '(data.get(''', property, '''), values))'));
            end
            predicate = @(data) predicateCondition(data, values);
        end
        
        function plotField = getValidPlotField(obj, name)
             plotField = matlab.lang.makeValidName(name);
        end
        
        function menu = addEpochDataContextMenus(obj, menu)
            % TODO change source label
        end

    end
end
