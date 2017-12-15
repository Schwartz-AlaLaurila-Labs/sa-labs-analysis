function diaryPlot(epochData, parameter, axes)

% description : Diary plot helps to visualize how the protocol properties (yAxis) change over epochNumber (or) epochTime (xAxis). Below 'YAML' describes the fields present in the parameter structure.
% xAxis:
%   default : epochNum, epochStartTime
%   description: Protocol properties can be visualized for above deafault properties
% yAxis:
%   default: "@(epochData) setdiff(epochData.parentCell.getEpochKeysetUnion(), {'epochNum', 'epochStartTime'})"
%   description: List of protocol properties excluding epochNum and epochTime
% ---

import sa_labs.analysis.*;
util.clearAxes(axes);
cellData = epochData.parentCell;

xvals = cellData.getEpochValues(parameter.xAxis);
displayVals = cellData.getEpochValues(parameter.yAxis);

if isnumeric(displayVals)
    hold(axes, 'on');
    stem(axes, xvals, displayVals, 'bo');
    set(axes, 'YtickMode', 'auto', 'YtickLabelMode', 'auto');
    set(axes, 'Ylim', [min(displayVals) - .1 * range(displayVals) - .1, max(displayVals) + .1 * range(displayVals) + .1]);
else
    % remove nans
    for i = 1:length(displayVals)
        if isempty(displayVals{i})
            displayVals{i} = '-unset-';
        end
        displayVals{i} = num2str(displayVals{i});
    end
    
    uniqueVals = unique(displayVals);
    valInd = zeros(1,length(displayVals));
    for i=1:length(uniqueVals)
        valInd(strcmp(displayVals, uniqueVals{i})) = i;
    end
    hold(axes, 'on');
    
    stem(axes, xvals, valInd, 'bo');
    set(axes, 'Ytick', unique(valInd), 'YtickLabel', uniqueVals);
    set(axes, 'Ylim', [0 max(valInd)+1]);
end

ylabel(axes, parameter.yAxis);
xlabel(axes, parameter.xAxis)
hold(axes, 'off');
end