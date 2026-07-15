classdef DebugSamplePackCoverageTest < matlab.unittest.TestCase
    %DEBUGSAMPLEPACKCOVERAGETEST Guard debug sample-pack coverage.

    methods (Test, TestTags = {'Unit'})
        function every_supported_app_has_debug_sample_writer_and_wiring(testCase)
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
                runner = fullfile(appFolder, "+" + slug, "run.m");
                definition = fullfile(appFolder, "+" + slug, "definition.m");
                definitionActions = fullfile(appFolder, "+" + slug, ...
                    "definitionActions.m");
                startup = fullfile(appFolder, "+" + slug, "startup.m");
                actions = fullfile(appFolder, "+" + slug, "+actions", "table.m");
                writer = fullfile(appFolder, "+" + slug, "+debug", "writeSamplePack.m");

                wiringFiles = [runner, definition, definitionActions, startup, actions];
                wiringFiles = wiringFiles(isfile(wiringFiles));
                if isempty(wiringFiles)
                    missing(end + 1, 1) = appFile + ...
                        " missing runtime wiring source for debug samples";
                    continue;
                end
                if ~isfile(writer)
                    missing(end + 1, 1) = appFile + " missing +debug/writeSamplePack.m";
                    continue;
                end

                body = "";
                for iFile = 1:numel(wiringFiles)
                    body = body + newline + string(fileread(wiringFiles(iFile)));
                end
                directCall = slug + ".debug.writeAndLogSamplePack(";
                samplePackCall = slug + ".debug.writeSamplePack(";
                samplePackHandle = "@" + slug + ".debug.writeSamplePack";
                if ~(contains(body, directCall) || ...
                        contains(body, samplePackCall) || ...
                        contains(body, samplePackHandle))
                    missing(end + 1, 1) = appFile + " does not call app-owned debug sample writer";
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
