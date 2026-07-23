function verifyAppIsolatedPathContract(testCase, relativeAppFolder)
%VERIFYAPPISOLATEDPATHCONTRACT Prove one App is runnable without siblings.
% Expected caller: one App-owned isolated-path contract test.
% Inputs: testCase and an apps/<family>/<slug> relative folder.
% Side effects: temporarily resets MATLAB paths and writes a synthetic sample.

    root = labkitRepoRoot();
    appRoot = fullfile(root, "apps", char(relativeAppFolder));
    [~, slug] = fileparts(appRoot);
    previousPath = path;
    pathCleanup = onCleanup(@() path(previousPath));
    scratchRoot = string(tempname);
    mkdir(scratchRoot);
    scratchCleanup = onCleanup(@() removeFolder(scratchRoot));
    restoredefaultpath;
    addpath(root);
    addpath(appRoot);
    rehash path

    definition = feval(slug + ".definition");
    testCase.verifyEqual(string(definition.AppId), string(slug));
    testCase.verifyNotEmpty(regexp(definition.AppVersion, '^\d+\.\d+\.\d+$', "once"));
    testCase.verifyTrue(labkit.contract.checkRequirements( ...
        definition.Requirements).ok);
    pack = definition.BuildDebugSample(labkit.app.diagnostic.SampleContext( ...
        fullfile(scratchRoot, slug)));
    testCase.verifyClass(pack, "labkit.app.diagnostic.SamplePack");
    clear scratchCleanup pathCleanup
end

function removeFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end
