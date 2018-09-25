classdef DataCuratorView < appbox.View
    
    events
        BrowseLocation
        LoadSelectedCell
        ReParse
        ShowFilteredEpochs
        SelectedNodes
        SelectedDevices
        SelectedPlots
        SelectedPlotFromPanel
        SelectedPreProcessor
        ExecutePreProcessor
        SelectedXAxis
        SelectedYAxis
        DisablePlots
        PopoutActivePlot
        AddDeleteTag
        ClearDeleteTag
        DeleteEntity
        SelectedCell
        SelectedFilter
        DoRefreshFilterTable
        SelectedFilterProperty
        SelectedFilterRow
        AddParameter
        RemoveParameter
        ExecuteFilter
        SaveConfiguredFilter
        AddParametersToFilteredGroup
        RemoveParametersFromFilteredGroup
        ChangedParameterProperties
        SendEntityToWorkspace
    end
    
    properties (Access = private)
        shortCutMenu
        h5FileName
        browseLocationButton
        loadH5FileButton
        reparseButton
        infoText
        showFilteredEpochsCheckBox
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
        xPlotField
        yPlotField
        disablePlotsCheckBox
        tagToDelete
        undoTagToDelete
        deleteTagged
        popoutPlot
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
            % Toolbar menu
            toolbar = uitoolbar('parent', obj.figureHandle);
            uitoolfactory(toolbar, 'Exploration.ZoomIn');
            uitoolfactory(toolbar,'Exploration.ZoomOut');
          
            % ShortCut menu.
            obj.shortCutMenu.root = uimenu(obj.figureHandle, ...
                'Label', 'Shortcuts');
            obj.shortCutMenu.addDeleteEpochsTag = uimenu(obj.shortCutMenu.root, ...
                'Label', 'Add Delete Tag', ...
                'Accelerator', 'D', ...
                'Callback', @(h,d)notify(obj, 'AddDeleteTag'));
            obj.shortCutMenu.undoDeleteEpochsTag = uimenu(obj.shortCutMenu.root, ...
                'Label', 'Undo Delete Tag', ...
                'Accelerator', 'Z', ...
                'Callback', @(h,d)notify(obj, 'ClearDeleteTag'));
            layout = uix.VBox(...
                'Parent', obj.figureHandle,...
                'Spacing', 1);
            
            cellInfoLayout = uix.HBox( ...
                'Parent', layout, ...
                'Padding', 5);
            Label( ...
                'Parent', cellInfoLayout, ...
                'String', 'H5 File Name:');
            obj.h5FileName = uicontrol( ...
                'Parent', cellInfoLayout, ...
                'Style', 'edit', ...
                'HorizontalAlignment', 'left');
            obj.browseLocationButton = uicontrol( ...
                'Parent', cellInfoLayout, ...
                'Style', 'pushbutton', ...
                'String', '...', ...
                'Callback', @(h,d)notify(obj, 'BrowseLocation'));
            uix.Empty('Parent', cellInfoLayout);
            obj.reparseButton = uicontrol( ...
                'Parent', cellInfoLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Re-Parse', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'ReParse'));
           uix.Empty('Parent', cellInfoLayout);
           obj.availableCellsMenu = MappedPopupMenu( ...
               'Parent', cellInfoLayout, ...
               'String', {' '}, ...
               'Enable', 'off', ...
               'HorizontalAlignment', 'left', ...
               'Callback', @(h,d)notify(obj, 'SelectedCell'));
           uix.Empty('Parent', cellInfoLayout);

           obj.loadH5FileButton = uicontrol( ...
                'Parent', cellInfoLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Load', ...
                'Callback', @(h,d)notify(obj, 'LoadSelectedCell'));

            uix.Empty('Parent', cellInfoLayout);
            set(cellInfoLayout, 'Widths', [100 -1 100 10 100 10 150 10 100 -4]);
                       
            mainLayout = uix.HBox( ...
                'Parent', layout, ...
                'padding', 5);
            
            masterLayout = uix.VBox( ...
                'Parent', mainLayout,...
                'padding', 11);
            obj.showFilteredEpochsCheckBox = uicontrol( ...
                'Parent', masterLayout, ...
                'Style', 'checkbox', ...
                'String', 'Show Filtered Epochs', ...
                'Enable', 'off',...
                'Callback', @(h,d)notify(obj, 'ShowFilteredEpochs'));
            obj.entityTree = uiextras.jTree.Tree( ...
                'Parent', masterLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'SelectionChangeFcn', @(h,d)notify(obj, 'SelectedNodes'), ...
                'SelectionType', 'discontiguous');
            set(masterLayout, 'Heights', [30 -1]);
            
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
            signalPreProcessingLayout = uix.VBoxFlex( ...
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
                'SelectionChangedFcn', @(h,d)notify(obj, 'SelectedPlotFromPanel'),...
                'Padding', 11,...
                'TabWidth', 100,... 
                'BackgroundColor', 'w');

            signalDetailControlLayout = uix.HBox( ...
                'Parent', signalDetailLayout, ...
                'Spacing', 5);
            uix.Empty('Parent', signalDetailControlLayout);
            
            Label( ...
                'Parent', signalDetailControlLayout, ...
                'String', 'X axis');
            obj.xPlotField = MappedPopupMenu( ...
               'Parent', signalDetailControlLayout, ...
               'String', {' '}, ...
               'HorizontalAlignment', 'left', ...
               'Enable', 'off', ...
               'Callback', @(h,d)notify(obj, 'SelectedXAxis'));
           Label( ...
               'Parent', signalDetailControlLayout, ...
               'String', 'Y axis');
            obj.yPlotField =  MappedPopupMenu( ...
               'Parent', signalDetailControlLayout, ...
               'String', {' '}, ...
               'HorizontalAlignment', 'left', ...
               'Enable', 'off', ...
               'Callback', @(h,d)notify(obj, 'SelectedYAxis'));
            obj.disablePlotsCheckBox = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'checkbox', ...
                'String', 'Disable Plots', ...
                'Enable', 'on',...
                'Callback', @(h,d)notify(obj, 'DisablePlots'));
            obj.popoutPlot = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Open Plot In New Figure', ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'PopoutActivePlot'));
            Label( ...
                'Parent', signalDetailControlLayout, ...
                'String', ' | ');
            obj.tagToDelete = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Tag To Delete', ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'AddDeleteTag'));
            obj.undoTagToDelete = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Undo Delete Tag', ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'ClearDeleteTag'));
            obj.deleteTagged = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Delete Tagged', ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'DeleteEntity'));
 
            set(signalDetailControlLayout, 'Widths', [20 40 100 40 100 90 160 10 100 100 100]);
            
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
                'Enable', true,...
                'EditorStyle', 'readonly');
            parameterPropertyGridControlLayout = uix.HBox( ...
                'Parent', parameterPropertyLayout, ...
                'Padding', 9);
            obj.addParameterButton = uicontrol( ...
                'Parent', parameterPropertyGridControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Add Parameter', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'AddParameter'));
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
               'String', '  Select Filter:');
           obj.availablefilterMenu = MappedPopupMenu( ...
               'Parent', filterLabelLayout, ...
               'String', {' '}, ...
               'HorizontalAlignment', 'left', ...
               'Enable', 'off', ...
               'Callback', @(h,d)notify(obj, 'SelectedFilter'));
           set(filterLabelLayout, 'Widths', [80 -2]);
           
           obj.filterTable = uiextras.jTable.Table(...
               'Parent', filterLayout,...
               'ColumnEditable', [true true true],...
               'ColumnName', {'Property','Condition', 'Value'},...
               'ColumnFormat', {'popup', 'popup', 'popupcheckbox'},...
               'CellSelectionCallback', @(h, d)notify(obj, 'SelectedFilterRow', sa_labs.analysis.ui.util.UiEventData(d)),...
               'CellEditCallback', @(h, d)notify(obj, 'SelectedFilterProperty', sa_labs.analysis.ui.util.UiEventData(d)),...
               'ColumnPreferredWidth', [40 20 100]);
           obj.filterTable.Data = cell(7, 3);
           
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
               'Enable', 'off', ...
               'Callback', @(h,d)notify(obj, 'AddParametersToFilteredGroup'));
           obj.removeParametersButton = uicontrol( ...
               'Parent', filterControlsLayout, ...
               'Style', 'pushbutton', ...
               'String', 'Remove Parameters', ...
               'Enable', 'off', ...
               'Callback', @(h,d)notify(obj, 'RemoveParametersFromFilteredGroup'));
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
            
            set(layout, 'Heights', [35 -3 -1]);
        end
        
        function name = getH5FileName(obj)
            name = get(obj.h5FileName, 'String');
        end
        
        function setH5FileName(obj, name)
            set(obj.h5FileName, 'String', name);
        end
        
        function enableReParse(obj, tf)
            set(obj.reparseButton, 'Enable', appbox.onOff(tf));
        end
        
        function enableShowFilteredEpochs(obj, tf)
            set(obj.showFilteredEpochsCheckBox, 'Enable', appbox.onOff(tf));
        end
        
        function tf = canShowFilteredEpochs(obj)
            tf = get(obj.showFilteredEpochsCheckBox, 'Value');
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
        
        function addPlotToPanelTab(obj, plots, titles)
            
            for i = 1 : numel(plots)
                plot = plots{i};
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
                    obj.tabPanel.TabTitles{end} = titles{i};
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
                
        function setXAxisValues(obj, values)
            set(obj.xPlotField, 'String', values);
        end
        
        function value = getXAxisValue(obj)
            names = get(obj.xPlotField, 'String');
            index = get(obj.xPlotField, 'Value');
            value = names{index};
        end
        
        function setYAxisValues(obj, values)
            set(obj.yPlotField, 'String', values);
        end
        
        function value = getYAxisValue(obj)
            names = get(obj.yPlotField, 'String');
            index = get(obj.yPlotField, 'Value');
            value = names{index};
        end
        
        function disableXYAxis(obj, tf)
            set(obj.xPlotField, 'Enable', appbox.onOff(~tf));
            set(obj.yPlotField, 'Enable',  appbox.onOff(~tf));
        end

        function disablePlotPannel(obj, tf)
            set(obj.tabPanel, 'Visible', appbox.onOff(~tf)); 
        end
        
        function ax = getAxes(obj, plot)
            plotField = obj.getValidPlotField(plot);
            ax = obj.plotCard.(plotField).axes;
        end
        
        function plot = getActivePlot(obj)
            plots = get(obj.availablePlots, 'Value');
            titles = get(obj.tabPanel, 'TabTitles');
            index = get(obj.tabPanel, 'Selection');
            selectedTitle = titles{index};
            
            indices = cellfun(@(plot) any(strfind(plot, selectedTitle)), plots);
            plot = plots{indices};
        end
        
        function setAvailablePreProcessorFunctions(obj, names, values)
            set(obj.availablePreProcessorFunctions, 'String', names);
            set(obj.availablePreProcessorFunctions, 'Values', values);
        end
        
        function functionNames = getSelectedPreProcessorFunction(obj)
            functionNames = get(obj.availablePreProcessorFunctions, 'Value');
        end

        function tf = hasValidPreProcessorSelected(obj)
            functionNames = get(obj.availablePreProcessorFunctions, 'Value');
            tf =  ~ isempty([functionNames{:}]);
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
                type = prop.Type;
                if isa(type, 'uiextras.jide.PropertyType') && ~ isempty(type.Domain) && type.islogical()
                    value = prop.Type.Domain(value);
                end
                parameters.(prop.Name) = value;
            end
        end
        
        function propertyGrid = getPreProcessorParameterPropertyGrid(obj)
            propertyGrid = get(obj.preProcessorPropertyGrid, 'Properties');
        end
    
        function tf = hasPlotsDisabled(obj)
            tf = get(obj.disablePlotsCheckBox, 'Value');
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
        
        function updateFilterProperties(obj, data)
             rows = size(data, 1);
             for i = 1 : rows
                 obj.filterTable.Data(i, :) = data(i, :);
             end
        end
        
        function cellName = getSelectedCellName(obj)
            cellNames = get(obj.availableCellsMenu, 'String');
            index = obj.availableCellsMenu.getValue;
            cellName = cellNames(index);
        end

        function loadCellDataFilters(obj, filterNames)
            set(obj.availablefilterMenu, 'String', filterNames);
        end
        
        function name = getSelectedFilterName(obj)
            names = get(obj.availablefilterMenu, 'String');
            index = get(obj.availablefilterMenu, 'Value');
            name = names{index};
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
        
        function clearFilterProperties(obj)
             obj.filterTable.Data = cell(7, 3);
        end
        
        function name = getSaveFilterName(obj)
            name = get(obj.filterNameField, 'String');
        end
        
        function setSaveFilterName(obj, name)
            set(obj.filterNameField, 'String', name);
        end
        
        function property = getSelectedFilterProperty(obj, row)
            property = obj.filterTable.Data{row, 1};
        end
        
        function data = getFilterRows(obj)
            data = obj.filterTable.Data;
            rows = size(data, 1);
            filterRows = [];
            
            for i = 1 : rows
                rowData = data(i, :);
                if ~ any(cellfun(@isempty, rowData))
                    filterRows  = [filterRows, i];  %#ok
                end
            end
            data = data(filterRows, :);
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
        
        function removeChildNodes(obj, parent)
            for node = each(parent.Children)
                obj.removeNode(node);
            end
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
        
        function name = getSelectedParameterNameFromPropertyGrid(obj)
            name = obj.parameterPropertyGrid.GetSelectedProperty();
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
                
        function plotField = getValidPlotField(obj, name)
             plotField = matlab.lang.makeValidName(name);
        end
        
        function menu = addEpochDataContextMenus(obj, menu)
            % TODO change source label
        end

    end
end
