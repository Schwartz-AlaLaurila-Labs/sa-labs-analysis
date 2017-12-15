function plotFeature(data, featureDescripion, axes)

% description : plotFeature  helps to visualize how the feature data (yAxis) change over featureDescripion xAxis. Below 'YAML' describes the fields present in the parameter structure.
% xAxis:
%   default : "xAxis"
%   description: see @sa_labs.analysis.entity.FeatureDescription.xAxis
% yAxis:
%   default: "data"
%   description: see @sa_labs.analysis.entity.Feature.data
% ---

import sa_labs.analysis.*;
util.clearAxes(axes);

if isEpoch(featureDescripion.id)
    plots.plotEpoch(cell2mat(data), featureDescripion, axes);
    return
end

[rows, ~] = size(data);
x = featureDescripion.xAxis;
for row = 1 : rows 
	plot(axes, x, data{row});
	hold(axes, 'on');
end
hold(axes, 'off');
xlabel(axes, featureDescripion.xLabel);
ylabel(axes, featureDescripion.yLabel);

end

function tf = isEpoch(id)
tf = strfind(id, sa_labs.analysis.app.Constants.EPOCH_KEY_SUFFIX);
end