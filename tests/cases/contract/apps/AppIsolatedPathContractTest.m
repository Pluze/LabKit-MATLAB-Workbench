classdef AppIsolatedPathContractTest < matlab.unittest.TestCase
    %APPISOLATEDPATHCONTRACTTEST Exercise every App without sibling App paths.

    methods (Test, TestTags = {'Integration'})
        function publicAppsLoadContractsAndDebugSamplesOnOwningPath(testCase)
            root = labkitRepoRoot();
            apps = publicApps(root);
            testCase.assertNotEmpty(apps, ...
                "The isolated-path contract should discover public Apps.");

            previousPath = path;
            pathCleanup = onCleanup(@() path(previousPath));
            scratchRoot = tempname;
            mkdir(scratchRoot);
            scratchCleanup = onCleanup(@() removeFolder(scratchRoot));
            for k = 1:numel(apps)
                restoredefaultpath;
                addpath(root);
                addpath(apps(k).root);
                rehash path

                assertOnlyOwningAppIsOnPath(testCase, apps, k);
                definitionFactory = str2func( ...
                    apps(k).slug + ".definition");
                definition = definitionFactory();

                testCase.verifyEqual(definition.Entrypoint, apps(k).command);
                testCase.verifyEqual(definition.AppId, apps(k).slug);
                testCase.verifyNotEmpty(regexp(definition.AppVersion, ...
                    '^\d+\.\d+\.\d+$', "once"));
                report = labkit.contract.checkRequirements( ...
                    definition.Requirements);
                testCase.verifyTrue(report.ok, ...
                    apps(k).command + ": " + report.message);
                testCase.verifyClass(definition.BuildDebugSample, ...
                    "function_handle");

                writer = definition.BuildDebugSample;
                sampleContext = labkit.app.diagnostic.SampleContext( ...
                    fullfile(scratchRoot, apps(k).slug));
                pack = writer(sampleContext);
                testCase.verifyClass(pack, ...
                    "labkit.app.diagnostic.SamplePack", ...
                    apps(k).command + ...
                    " DebugSample must return a typed SamplePack.");
                testCase.verifyTrue(isscalar(pack));
            end
            clear scratchCleanup pathCleanup
        end
    end
end

function removeFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end

function assertOnlyOwningAppIsOnPath(testCase, apps, ownerIndex)
    entries = string(strsplit(path, pathsep));
    siblingRoots = [apps.root];
    siblingRoots(ownerIndex) = [];
    testCase.verifyFalse(any(ismember(entries, siblingRoots)), ...
        apps(ownerIndex).command + ...
        " isolated path unexpectedly contains a sibling App root.");
end

function apps = publicApps(root)
    entries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
    [~, order] = sort(string(fullfile({entries.folder}, {entries.name})));
    entries = entries(order);
    apps = repmat(struct( ...
        "root", "", "slug", "", "command", ""), 1, numel(entries));
    for k = 1:numel(entries)
        [~, slug] = fileparts(entries(k).folder);
        [~, command] = fileparts(entries(k).name);
        apps(k) = struct( ...
            "root", string(entries(k).folder), ...
            "slug", string(slug), ...
            "command", string(command));
    end
end
