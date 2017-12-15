function  plotMhtSpikesStatistics(epochData, parameter, axes)

% description : Plot the k means cluster (2 cluster) of spike and non spike amplitude. Below 'YAML' describes the fields present in the parameter structure.
% xAxis:
%   default : Peak Amplitude
%   description: Peak amplitude of spikes 
% yAxis:
%   default: L rebound
%   description: Left rebound of the spike
% zAxis:
%   default: R rebound
%   description: Right rebound of the spike
% devices:
%   default: Amp1
%   description: It is the value selected from the device pannel in curator interface
% ---

devices = parameter.devices;
n = numel(devices);
sa_labs.analysis.util.clearAxes(axes);

if numel(epochData) > 1
    title(axes, 'Cannot display stats for multiple epochs')
    return
end

axesArray = sa_labs.analysis.util.getNewAxesForSublot(axes, n);

for i = 1 : n
    device = devices{i};

    statistics = epochData.getDerivedResponse('spikeStatistics', device);
    if isempty(statistics)
        error('spikeStatistics is an inmemory attribute. Run mhtSpikeDetector again to visualize the statistics')
    end
    peakAmplitudes = statistics.peakAmplitudes;
    
    rebound = statistics.rebound;
    clusterIndex = statistics.clusterIndex;
    spikeClusterIndex = statistics.spikeClusterIndex;
    nonspikeClusterIndex = statistics.nonspikeClusterIndex;
    
    ax = axesArray(i);
    subplot(n, 1, i, ax);
    
    plot3(ax, peakAmplitudes(clusterIndex == spikeClusterIndex),...
        rebound.Left(clusterIndex == spikeClusterIndex),...
        rebound.Right(clusterIndex == spikeClusterIndex), 'ro');
    hold(ax, 'on');
    plot3(ax, peakAmplitudes(clusterIndex == nonspikeClusterIndex),...
        rebound.Left(clusterIndex == nonspikeClusterIndex),...
        rebound.Right(clusterIndex == nonspikeClusterIndex), 'ko');
    hold(ax, 'off');
    title(ax, ['spike factor ' num2str(statistics.sigF) ]);
end
xlabel(ax, 'Peak Amplitude');
ylabel(ax, 'L rebound');
zlabel(ax, 'R rebound');

end