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
                writer = fullfile(appFolder, "+" + slug, "+debug", "writeSamplePack.m");

                if ~isfile(runner)
                    missing(end + 1, 1) = appFile + " missing package-root run.m";
                    continue;
                end
                if ~isfile(writer)
                    missing(end + 1, 1) = appFile + " missing +debug/writeSamplePack.m";
                    continue;
                end

                body = string(fileread(char(runner)));
                directCall = slug + ".debug.writeAndLogSamplePack(debugLog";
                setupCall = slug + ".debug.writeSamplePack(debugLog)";
                if ~(contains(body, directCall) || ...
                        (contains(body, "setupDebugSamples()") && contains(body, setupCall)))
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
