% Expected caller: FLIR Thermal fileList PathFilter. Candidate paths are
% inspected through the thermal facade; unreadable or non-radiometric files
% are rejected before source-list records are created.
function accepted = matchesRadiometricFiles(paths)
paths = reshape(string(paths), 1, []);
accepted = false(size(paths));
for index = 1:numel(paths)
    inspection = labkit.thermal.inspectFile(paths(index));
    accepted(index) = inspection.isThermal;
end
end
