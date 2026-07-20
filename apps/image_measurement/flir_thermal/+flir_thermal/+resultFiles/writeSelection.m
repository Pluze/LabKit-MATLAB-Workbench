% App-owned implementation for flir_thermal.resultFiles.writeSelection within the flir_thermal product workflow.
function [payload, manifestPath, ok] = writeSelection( ...
        sources, annotations, parameters, callbackContext)
%WRITESELECTION Decode, export, and register one FLIR result package.
payload = [];
manifestPath = "";
ok = false;
folder = string(parameters.outputFolder);
if strlength(folder) == 0
    callbackContext.alert( ...
        "Choose an output folder before exporting.", ...
        "Output folder required");
    return
end
try
    paths = callbackContext.resolveSourcePaths(sources);
    items = flir_thermal.sourceFiles.readImages( ...
        paths, struct("SkipInvalid", false));
    items = applyAnnotations(items, sources, annotations);
    options = struct( ...
        "outputFolder", folder, ...
        "format", parameters.exportFormat, ...
        "palette", parameters.palette, ...
        "colorMapping", parameters.colorMapping, ...
        "gammaValue", parameters.gammaValue, ...
        "range", []);
    payload = flir_thermal.resultFiles.writeOutputs(items, options);
    outputs = resultFiles(payload);
    package = labkit.app.result.Package( ...
        Outputs=outputs, ...
        Inputs=struct("sources", sources), ...
        Parameters=parameters, ...
        Summary=struct( ...
            "imageCount", numel(items), ...
            "savedCount", sum(string({payload.results.status}) == "saved"), ...
            "failedCount", sum(string({payload.results.status}) == "failed")), ...
        ManifestName="flir_thermal.labkit.json");
    written = callbackContext.writeResultPackage(folder, package);
catch ME
    callbackContext.reportError("Export FLIR thermal results", ME);
    callbackContext.alert(ME.message, "Could not export FLIR images");
    return
end
manifestPath = string(written.Value);
ok = true;
end

function items = applyAnnotations(items, sources, annotations)
for k = 1:numel(items)
    match = find(string({annotations.sourceId}) == ...
        string(sources(k).id), 1);
    if ~isempty(match)
        items(k) = flir_thermal.thermalAnnotations.apply( ...
            items(k), annotations(match));
    end
end
end

function outputs = resultFiles(payload)
outputs = cell(1, 3 * numel(payload.results) + 1);
cursor = 0;
fields = ["thermalImagePath", "colorbarPath", "temperatureCsvPath"];
roles = ["thermal-image", "temperature-colorbar", "temperature-csv"];
for k = 1:numel(payload.results)
    status = "failed";
    if string(payload.results(k).status) == "saved"
        status = "success";
    end
    for n = 1:numel(fields)
        cursor = cursor + 1;
        path = string(payload.results(k).(fields(n)));
        [~, name, extension] = fileparts(path);
        relativePath = string(name) + string(extension);
        if strlength(relativePath) == 0
            relativePath = "failed_" + roles(n) + "_" + string(k) + ".dat";
        end
        outputs{cursor} = labkit.app.result.File( ...
            roles(n) + "-" + string(k), roles(n), relativePath, ...
            MediaType=mediaType(extension), Status=status, ...
            Message=string(payload.results(k).message));
    end
end
cursor = cursor + 1;
[~, name, extension] = fileparts(payload.manifestPath);
outputs{cursor} = labkit.app.result.File( ...
    "thermal-manifest", "summary", ...
    string(name) + string(extension), MediaType="text/csv");
end

function value = mediaType(extension)
extension = lower(string(extension));
if extension == ".csv"
    value = "text/csv";
elseif any(extension == [".jpg", ".jpeg"])
    value = "image/jpeg";
elseif any(extension == [".tif", ".tiff"])
    value = "image/tiff";
else
    value = "image/png";
end
end
