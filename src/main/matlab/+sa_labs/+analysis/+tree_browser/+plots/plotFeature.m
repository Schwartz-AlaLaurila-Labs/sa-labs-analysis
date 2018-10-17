function plotFeature(epochGroup, parameter, axes)

% description : plotFeature  helps to visualize how the feature data (yAxis) change over featureDescripion xAxis. Below 'YAML' describes the fields present in the parameter structure.
% xAxis:
%   default : "xAxis"
%   description: see @sa_labs.analysis.entity.FeatureDescription.xAxis
% yAxis:
%   default: "@(epochGroup) epochGroup.getFeatureKey()"
%   description: List of features present in the epochGroup
% ---

import sa_labs.analysis.*;
util.clearAxes(axes);
index = parameter.index;
features = epochGroup.getFeatures(parameter.yAxis);
featureDescripion = features(index).description;
data = features(index).data;

if isEpoch(featureDescripion.id)
    
    response = cell2mat(data);
    key = upper(strcat(featureDescripion.device, '_', 'SPIKETIMES'));
    features = epochGroup.getFeatures(key);
    spikeTimes = [];
    if ~ isempty(features)
        spikeTimes = cell2mat(features(index).data);
    end
    
    if ~ isempty(spikeTimes)
        plots.plotSpikes(spikeTimes, response, featureDescripion, axes);
    else
        plots.plotEpoch(response, featureDescripion, axes);
    end
    return
end

[rows, ~] = size(data);
x = featureDescripion.xAxis;
hold(axes, 'on');

for row = 1 : rows
    if isempty(data{row})
        error([featureDescripion.id ' data is empty']);
    end
    plot(axes, x, data{row});
end
hold(axes, 'off');
xlabel(axes, featureDescripion.xLabel);
ylabel(axes, featureDescripion.yLabel);
title(axes, featureDescripion.description);
end

function tf = isEpoch(id)
tf = strfind(id, sa_labs.analysis.app.Constants.EPOCH_KEY_SUFFIX);
end