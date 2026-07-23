classdef DebugSamplePackCoverageTest < matlab.unittest.TestCase
    %DEBUGSAMPLEPACKCOVERAGETEST Guard debug sample-pack coverage.

    methods (Test, TestTags = {'Unit'})
        function everySupportedAppDefinesDebugSampleWriter(testCase)
            setupLabKitTestPath();
            root = string(labkitRepoRoot());
            appFiles = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
            testCase.assertNotEmpty(appFiles, ...
                "Expected supported app entrypoints under apps/.");

            missing = strings(0, 1);
            for k = 1:numel(appFiles)
                appFile = string(fullfile(appFiles(k).folder, appFiles(k).name));
                appFolder = string(appFiles(k).folder);
                slug = appSlugFromEntrypoint(appFile);
                definition = fullfile(appFolder, "+" + slug, "definition.m");
                writer = fullfile(appFolder, "+" + slug, "+debug", "writeSamplePack.m");

                if ~isfile(definition)
                    missing(end + 1, 1) = appFile + ...
                        " missing definition.m runtime contract";
                    continue;
                end
                if ~isfile(writer)
                    missing(end + 1, 1) = appFile + " missing +debug/writeSamplePack.m";
                    continue;
                end

                body = string(fileread(definition));
                samplePackHandle = "@" + slug + ".debug.writeSamplePack";
                if ~contains(body, samplePackHandle)
                    missing(end + 1, 1) = appFile + ...
                        " does not define its app-owned DebugSample writer";
                end
            end

            testCase.verifyEmpty(missing, strjoin(missing, newline));
        end
    end
end

function slug = appSlugFromEntrypoint(appFile)
    appFolder = string(fileparts(char(appFile)));
    [~, slug] = fileparts(char(appFolder));
    slug = string(slug);
end
