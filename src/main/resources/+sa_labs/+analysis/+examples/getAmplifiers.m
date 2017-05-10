function [amps, name] = getAmplifiers(epoch)

amps = cellfun(@(k) epoch.get(k), epoch.getParameters('chan[0-9]?$'), 'UniformOutput', false);
active = cellfun(@(k) ~ strcmpi(epoch.get(k), 'Off') ,epoch.getParameters('chan[0-9]Mode'));
amps = amps(active);
name = 'Amplifiers';
end

