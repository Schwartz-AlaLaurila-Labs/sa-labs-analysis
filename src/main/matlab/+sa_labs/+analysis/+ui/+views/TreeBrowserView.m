classdef TreeBrowserView < appbox.View
    
    events
        SelectedNodes
        AddAnalysisTree
        SelectedPlots
        SelectedPlotFromPanel
        SelectedXAxis
        SelectedYAxis
        PopoutActivePlot
        AddParameter
        RemoveParameter
        RunScript
        OpenCurator
        ApplyFeatureExtractor
        SendEntityToWorkspace
    end
    
    properties (Access = private)
        browserMenu
        analysisTree
        analysisGroupNode
        availablePlots
        parameterPropertyGrid
        addParameterButton
        removeParameterButton
        tabPanel
        xPlotField
        yPlotField
        popoutPlot
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
            obj.analysisTree = uiextras.jTree.Tree( ...
                'Parent', analysisTreeLayout, ...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'), ...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'BorderType', 'none', ...
                'SelectionChangeFcn', @(h,d)notify(obj, 'SelectedNodes'), ...
                'SelectionType', 'discontiguous');
            root = obj.analysisTree.Root;
            set(root, 'Value', struct('entity', [], 'type', EntityNodeType.ANALYSIS_RESULTS));
            set(root, 'Name', 'Result');
            analysisGroups = uiextras.jTree.TreeNode( ...
                'Parent', root, ...
                'Name', 'Analysis', ...
                'Value', struct('entity', [], 'type', EntityNodeType.ANALYSIS_GROUPS));
            obj.analysisGroupNode = analysisGroups;
            menu = uicontextmenu('Parent', obj.figureHandle);
            uimenu( ...
                'Parent', menu, ...
                'Label', 'Add Analysis Tree..', ...
                'Callback', @(h,d)notify(obj, 'AddAnalysisTree'));
            set(analysisGroups, 'UIContextMenu', menu);
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
                'Enable', 'off', ...
                'Callback', @(h,d)notify(obj, 'SelectedPlots'));
            set(plotControlsLayout, 'Heights', [20 -1]);
            set(analysisTreeAndPlotControlsLayout, 'Widths', [-1 -1]);
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
            set(signalDetailControlLayout, 'Widths', [40 100 40 100 150]);
            set(signalLayout, 'Heights', [-1 30]);
            
            set(mainLayout, 'Widths', [-2 -5]);
        end
        
        % Add / remove tree nodes
        
        function n = addAnalysisNode(obj, parent, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.EntityNodeType.ANALYSIS;
            n = uiextras.jTree.TreeNode( ...
                'Parent', parent, ...
                'Name', name, ...
                'Value', value);
            menu = uicontextmenu('Parent', obj.figureHandle);
            uimenu( ...
                'Parent', menu, ...
                'Label', 'Run Script ..', ...
                'Callback', @(h,d)notify(obj, 'RunScript'));
            menu = obj.addEntityContextMenus(menu);
            set(n, 'UIContextMenu', menu);
        end
        
        function n = addCellsNode(obj, parent, name, entity)
            value.entity = entity;
            value.type = sa_labs.analysis.ui.EntityNodeType.CELLS;
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
            value.type = sa_labs.analysis.ui.EntityNodeType.EPOCH_GROUP;
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
            value.type = sa_labs.analysis.ui.EntityNodeType.FEATURE;
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
            obj.entityTree.SelectedNodes = nodes;
        end
        
        function nodes = getSelectedNodes(obj)
            nodes = obj.entityTree.SelectedNodes;
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
            plots = get(obj.availablePlots, 'Value');
            titles = get(obj.tabPanel, 'TabTitles');
            index = get(obj.tabPanel, 'Selection');
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
    end
    
    methods (Access = private)
        
        function menu = addEntityContextMenus(obj, menu)
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