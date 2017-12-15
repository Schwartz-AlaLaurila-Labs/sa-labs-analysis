classdef TreeBrowserView < appbox.View
    
    events
        SelectedNodes
        AddAnalysisTree
        SelectedPlots
        SelectedPlotFromPanel
        SelectedXAxis
        SelectedYAxis
        PopoutActivePlot
        EnableFeatureIteration
        GoToPreviousFeature
        GoToNextFeature
        AddParameter
        RemoveParameter
        RunScript
        OpenCurator
        ApplyFeatureExtractor
        SendEntityToWorkspace
    end
    
    properties (Access = private)
        browserMenu
        analysisProjectTree
        analysisGroupNode
        availablePlots
        parameterPropertyGrid
        addParameterButton
        removeParameterButton
        tabPanel
        plotCard
        xPlotField
        yPlotField
        popoutPlot
        itereateFeatureCheckBox
        featureIndex
        featureSize
        previousFeature
        nextFeature
    end
    
    methods
        
        function createUi(obj)
            import appbox.*;
            import sa_labs.analysis.ui.views.EntityNodeType;
            
            set(obj.figureHandle, ...
                'Name', 'Tree Browser', ...
                'Position', screenCenter(611, 450));
            % Toolbar menu
            toolbar = uitoolbar('parent', obj.figureHandle);
            uitoolfactory(toolbar, 'Exploration.ZoomIn');
            uitoolfactory(toolbar,'Exploration.ZoomOut');
            obj.browserMenu.root = uimenu(obj.figureHandle, ...
                'Label', 'Menu');
            
            mainLayout = uix.HBoxFlex( ...
                'Parent', obj.figureHandle, ...
                'padding', 11);
            masterControlsLayout = uix.VBox( ...
                'Parent', mainLayout,...
                'padding', 5);
            
            analysisTreeAndPlotControlsLayout = uix.HBox( ...
                'Parent', masterControlsLayout, ...
                'Spacing', 5);
            % Analysis tree layout
            analysisTreeLayout = uix.VBox( ...
                'Parent', analysisTreeAndPlotControlsLayout, ...
                'Spacing', 5);
            obj.analysisProjectTree= uiextras.jTree.Tree( ...
                'Parent', analysisTreeLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'BorderType', 'none', ...
                'SelectionChangeFcn', @(h,d)notify(obj, 'SelectedNodes'), ...
                'SelectionType', 'discontiguous');
            root = obj.analysisProjectTree.Root;
            set(root, 'Value', struct('entity', [], 'type', EntityNodeType.ANALYSIS_PROJECT));
            set(root, 'Name', 'Analysis Project');
            menu = uicontextmenu('Parent', obj.figureHandle);
            uimenu( ...
                'Parent', menu, ...
                'Label', 'Add Analysis Tree..', ...
                'Callback', @(h,d)notify(obj, 'AddAnalysisTree'));
            set(root, 'UIContextMenu', menu);
            % Plot menu layout
            plotControlsLayout = uix.VBox( ...
                'Parent', analysisTreeAndPlotControlsLayout);
            Label( ...
                'Parent', plotControlsLayout, ...
                'String', 'Available Plots:');
            obj.availablePlots = MappedListBox( ...
                'Parent', plotControlsLayout, ...
                'Max', 5, ...
                'Min', 1, ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'SelectedPlots'));
            set(plotControlsLayout, 'Heights', [20 -1]);
            set(analysisTreeAndPlotControlsLayout, 'Widths', [-1.3 -1]);
            % Epoch group parameters CRUD
            parameterLayout = uix.HBox( ...
                'Parent', masterControlsLayout, ...
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
            set(masterControlsLayout, 'Heights', [-5 -2]);
            
            % Signals layout
            signalLayout = uix.VBox( ...
                'Parent', mainLayout, ...
                'Spacing', 5);
            
            obj.tabPanel = uix.TabPanel( ...
                'Parent', signalLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'SelectionChangedFcn', @(h,d)notify(obj, 'SelectedPlotFromPanel'),...
                'Padding', 11,...
                'TabWidth', 100,...
                'BackgroundColor', 'w');
            
            signalDetailControlLayout = uix.HBox( ...
                'Parent', signalLayout, ...
                'Spacing', 5);
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
            obj.popoutPlot = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Open Plot In New Figure', ...
                'Enable', 'on', ...
                'Callback', @(h,d)notify(obj, 'PopoutActivePlot'));
            obj.itereateFeatureCheckBox = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'checkbox', ...
                'String', 'Iterate Features', ...
                'Enable', 'off',...
                'Callback', @(h,d)notify(obj, 'EnableFeatureIteration'));
            Label( ...
                'Parent', signalDetailControlLayout, ...
                'String', 'Showing feature #');
            obj.featureIndex = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'edit', ...
                'String', '1', ...
                'Enable', 'off', ...
                'HorizontalAlignment', 'left');
            obj.featureSize =  Label( ...
                'Parent', signalDetailControlLayout, ...
                'String', ' / none');
            obj.previousFeature = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Previos', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'GoToPreviousFeature'));
            obj.nextFeature = uicontrol( ...
                'Parent', signalDetailControlLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Next', ...
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'GoToNextFeature'));

            set(signalDetailControlLayout, 'Widths', [40 100 40 100 150 100 100 20 50 100 100]);
            set(signalLayout, 'Heights', [-1 30]);
            
            set(mainLayout, 'Widths', [400 -1]);
        end
        
        % Add / remove tree nodes
        
        function n = setAnalysisProjectNode(obj, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.views.EntityNodeType.ANALYSIS_PROJECT;
            set(obj.analysisProjectTree.Root, 'Name', name);
            set(obj.analysisProjectTree.Root, 'Value', value);
            n = obj.analysisProjectTree;
        end

        function project = getAnalysisProject(obj)
            project = obj.getNodeEntity(obj.analysisProjectTree);    
        end

        function n = addAnalysisNode(obj, parent, name)
            value.entity = [];
            value.type = sa_labs.analysis.ui.views.EntityNodeType.ANALYSIS;
            n = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', value);
            menu = uicontextmenu('Parent', obj.figureHandle);
            menu = obj.addEntityContextMenus(menu);
            set(n, 'UIContextMenu', menu);
        end
        
        function n = addCellsNode(obj, parent, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.views.EntityNodeType.CELLS;
            n = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', value);
            menu = uicontextmenu('Parent', obj.figureHandle);
            uimenu( ...
                'Parent', menu, ...
                'Label', 'Open Data curator ..', ...
                'Callback', @(h,d)notify(obj, 'OpenCurator'));
            menu = obj.addEntityContextMenus(menu);
            set(n, 'UIContextMenu', menu);
        end
        
        function n = addEpochGroupNode(obj, parent, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.views.EntityNodeType.EPOCH_GROUP;
            n = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', value);
            menu = uicontextmenu('Parent', obj.figureHandle);
            uimenu( ...
                'Parent', menu, ...
                'Label', 'Apply Feature Extractor..', ...
                'Callback', @(h,d)notify(obj, 'ApplyFeatureExtractor'));
            menu = obj.addEntityContextMenus(menu);
            set(n, 'UIContextMenu', menu);
        end
        
        function n = addFeatureNode(obj, parent, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.views.EntityNodeType.FEATURE;
            n = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', value);
            menu = uicontextmenu('Parent', obj.figureHandle);
            menu = obj.addEntityContextMenus(menu);
            set(n, 'UIContextMenu', menu);
        end
        
        function removeNode(obj, node) %#ok<INUSL>
            node.delete();
        end
        
        function removeChildNodes(obj, parent)
            for node = each(parent.Children)
                obj.removeNode(node);
            end
        end
        
        % user operation for tree nodes
        
        function setSelectedNodes(obj, nodes)
            obj.analysisProjectTree.SelectedNodes = nodes;
        end
        
        function nodes = getSelectedNodes(obj)
            nodes = obj.analysisProjectTree.SelectedNodes;
        end
        
        function e = getNodeEntity(obj, node) %#ok<INUSL>
            v = get(node, 'Value');
            e = v.entity;
        end
        
        function t = getNodeType(obj, node) %#ok<INUSL>
            v = get(node, 'Value');
            t = v.type;
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
        
        function collapseNode(obj, node) %#ok<INUSL>
            node.collapse();
        end
        
        function expandNode(obj, node) %#ok<INUSL>
            node.expand();
        end
        
        % Plot listing methods
        
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
        
        % methods related to parameter property grid
        
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

        function enabledEditParameters(obj, tf)
            style = 'readonly';
            if tf
                style = 'normal';
            end
            set(obj.parameterPropertyGrid, 'EditorStyle', style);
        end
        
        % plot pannel methods
        
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
        
        function plot = getActivePlot(obj)
            plot = [];
            index = get(obj.tabPanel, 'Selection');
            if index == 0
                return;
            end

            plots = get(obj.availablePlots, 'Value');
            titles = get(obj.tabPanel, 'TabTitles');
            selectedTitle = titles{index};
            indices = cellfun(@(plot) any(strfind(plot, selectedTitle)), plots);
            plot = plots{indices};
        end
        
        % plot pannel ui controls
        
        function ax = getAxes(obj, plot)
            plotField = obj.getValidPlotField(plot);
            ax = obj.plotCard.(plotField).axes;
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

        function enableFeatureIteration(obj, tf)
            set(obj.itereateFeatureCheckBox, 'Enable', appbox.onOff(tf));
        end
        
        function tf = canIterateFeature(obj)
            tf = get(obj.itereateFeatureCheckBox, 'Value');
        end
        
        function updateCurrentFeatureIndex(obj, index)
            set(obj.featureIndex, 'String', num2str(index));
        end

        function index = getCurrentFeatureIndex(obj)
            index = get(obj.featureIndex, 'String');
            index = str2double(index);
        end

        function setFeatureSize(obj, n)
            set(obj.featureSize, 'String', ['/' num2str(n)]);
        end
        
        function n = getFeatureSize(obj)
            n = get(obj.featureSize, 'String');
            n = str2double(n(2:end));
        end

        function enablePreviousFeature(obj, tf)
            set(obj.previousFeature, 'Enable', appbox.onOff(tf));
        end
        
        function enableNextFeature(obj, tf)
            set(obj.nextFeature, 'Enable', appbox.onOff(tf));
        end

    end
    
    methods (Access = private)
        
        function menu = addEntityContextMenus(obj, menu)
            uimenu( ...
                'Parent', menu, ...
                'Label', 'Run Script ..', ...
                'Callback', @(h,d)notify(obj, 'RunScript'));
            uimenu( ...
                'Parent', menu, ...
                'Label', 'Send to Workspace', ...
                'Separator', appbox.onOff(~isempty(get(menu, 'Children'))), ...
                'Callback', @(h,d)notify(obj, 'SendEntityToWorkspace'));
        end
        
        function plotField = getValidPlotField(obj, name) %#ok
            plotField = matlab.lang.makeValidName(name);
        end
    end
end