classdef ProfileToolSpec < matlab.unittest.TestCase
    %PROFILETOOLSPEC Safe target resolution contracts for the profiling tool.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function rejectsArbitraryCommandStrings(testCase)
            root = labkittest.setup();
            cleanup = addToolPath(root);
            output = fullfile(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder, ...
                "profile.html");

            testCase.verifyError(@() profileLabKitTarget( ...
                "setappdata(groot,'unsafeProfileCommand',true)", output, ...
                "WaitForGuiClose", false), ...
                "profileLabKitTarget:UnresolvedTarget");
            testCase.verifyFalse(isappdata(groot, "unsafeProfileCommand"));
            delete(cleanup)
        end

        function profilesOnlyTheResolvedFunctionFile(testCase)
            root = labkittest.setup();
            cleanup = addToolPath(root);
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            functionFile = fullfile(folder, "labkitProfileProbe.m");
            writeText(functionFile, strjoin([ ...
                "function labkitProfileProbe"
                "setappdata(groot, 'labkitProfileProbeRan', true);"
                "end"], newline));
            stateCleanup = onCleanup(@() clearProbeState());
            output = fullfile(folder, "profile.html");

            [htmlFile, artifacts] = profileLabKitTarget(functionFile, output, ...
                "WaitForGuiClose", false, "OpenReport", false, ...
                "PrintSummary", false, "RethrowError", true);

            testCase.verifyTrue(isappdata(groot, "labkitProfileProbeRan"));
            testCase.verifyTrue(isfile(htmlFile));
            testCase.verifyTrue(isfile(artifacts.jsonFile));
            delete(stateCleanup); delete(cleanup)
        end
    end
end

function cleanup = addToolPath(root)
folder = fullfile(root, "tools", "profiling");
addpath(folder, "-begin");
cleanup = onCleanup(@() rmpath(folder));
end

function clearProbeState()
if isappdata(groot, "labkitProfileProbeRan")
    rmappdata(groot, "labkitProfileProbeRan");
end
if isappdata(groot, "unsafeProfileCommand")
    rmappdata(groot, "unsafeProfileCommand");
end
clear labkitProfileProbe
end

function writeText(filepath, content)
file = fopen(filepath, "w");
assert(file >= 0, "Could not create profiling fixture.");
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s", content);
clear cleanup
end
