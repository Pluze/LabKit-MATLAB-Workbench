% Expected caller: FLIR Thermal workbench presentation and direct tests.
% Source identity and image geometry own the thermal canvas. Display range also
% owns the paired temperature-scale Y domain; palette, gamma, and readings do not.
function revision = viewportRevision(sourceId, item, range)
imageSize = [0 0];
if ~isempty(item)
    values = flir_thermal.thermalPreview.presentationData.valueMatrix(item);
    if ~isempty(values)
        imageSize = [size(values, 1), size(values, 2)];
    end
end
revision = string(jsonencode(struct( ...
    "sourceId", string(sourceId), ...
    "imageSize", imageSize, ...
    "temperatureRange", double(range(:).'))));
end
