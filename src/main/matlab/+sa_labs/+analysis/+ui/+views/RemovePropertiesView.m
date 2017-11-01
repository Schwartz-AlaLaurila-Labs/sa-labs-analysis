classdef RemovePropertiesView < appbox.View

    events
        Remove
        Cancel
    end

    properties (Access = private)
        availableProperties
        removeButton
        cancelButton
    end

    methods

        function createUi(obj)
            import appbox.*;

            set(obj.figureHandle, ...
                'Name', 'Remove Property', ...
                'Position', screenCenter(250, 250), ...
                'Resize', 'off');

            mainLayout = uix.VBox( ...
                'Parent', obj.figureHandle, ...
                'Padding', 11, ...
                'Spacing', 11);
            
            % Add properties list
            Label( ...
                'Parent', mainLayout, ...
                'String', 'Select Properties: ');
            obj.availableProperties = MappedListBox( ...
                'Parent', mainLayout, ...
                'Max', 5, ...
                'Min', 1);
            % Add/Cancel controls.
            controlsLayout = uix.HBox( ...
                'Parent', mainLayout, ...
                'Spacing', 7);
            uix.Empty('Parent', controlsLayout);
            obj.removeButton = uicontrol( ...
                'Parent', controlsLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Remove', ...
                'Interruptible', 'off', ...
                'Callback', @(h,d)notify(obj, 'Remove'));
            obj.cancelButton = uicontrol( ...
                'Parent', controlsLayout, ...
                'Style', 'pushbutton', ...
                'String', 'Cancel', ...
                'Interruptible', 'off', ...
                'Callback', @(h,d)notify(obj, 'Cancel'));
            set(controlsLayout, 'Widths', [-1 75 75]);

            set(mainLayout, 'Heights', [23 -1 23]);

            % Set add button to appear as the default button.
            try %#ok<TRYNC>
                h = handle(obj.figureHandle);
                h.setDefaultButton(obj.addButton);
            end
        end

        function setAvailableProperties(obj, names)
            set(obj.availableProperties, 'String', names);
            set(obj.availableProperties, 'Values', names);
        end

        function requestKeyFocus(obj)
            obj.update();
            uicontrol(obj.availableProperties);
        end

        function v = getSelectedProperties(obj)
            v = get(obj.availableProperties, 'Value');
        end

    end

end