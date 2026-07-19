function context = debugSampleContext(root)
%DEBUGSAMPLECONTEXT Minimal filesystem context for App debug-sample tests.

    root = string(root);
    sampleFolder = fullfile(root, "samples");
    outputFolder = fullfile(root, "outputs");
    if ~isfolder(sampleFolder)
        mkdir(sampleFolder);
    end
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    context = struct( ...
        "artifactFolder", root, ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", string(outputFolder), ...
        "manifestFile", string(fullfile(root, "manifest.json")), ...
        "recordArtifacts", @(manifest) writeManifest( ...
            fullfile(root, "manifest.json"), manifest));
end

function writeManifest(filepath, manifest)
    text = jsonencode(manifest, PrettyPrint=true);
    [fileId, message] = fopen(filepath, "w");
    if fileId < 0
        error("labkit:tests:DebugManifestWriteFailed", "%s", message);
    end
    cleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, "%s\n", text);
    clear cleanup
end
