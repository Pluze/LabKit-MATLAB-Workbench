classdef QualityScanScopeGuardrailTest < matlab.unittest.TestCase
    %QUALITYSCANSCOPEGUARDRAILTEST Guard private app opt-in scan scope.

    methods (Test, TestTags = {'Integration', 'Style'})
        function privateAppGuardrailScopeRequiresSentinel(testCase)
            root = setupLabKitTestPath();
            privateRoot = createPrivateQualityProbe(testCase);
            cleanupPrivate = setEnvForTest("LABKIT_PRIVATE_APP_ROOTS", privateRoot);
            cleanupForce = setEnvForTest("LABKIT_GUARD_PRIVATE_APPS", "");

            scope = labkitQualityScanScope(root);

            testCase.verifyFalse(any(contains(scope.appMFiles, ...
                "labkit_PrivateQualityProbe_app.m")), ...
                "Private app roots should not enter project quality guardrails without an opt-in sentinel.");
            clear cleanupPrivate cleanupForce;
        end

        function privateAppGuardrailScopeIncludesAcceptedRoots(testCase)
            root = setupLabKitTestPath();
            privateRoot = createPrivateQualityProbe(testCase);
            writeText(fullfile(privateRoot, ".labkit-accept-main-guardrails"), ...
                "accept main guardrails" + newline);
            cleanupPrivate = setEnvForTest("LABKIT_PRIVATE_APP_ROOTS", privateRoot);
            cleanupForce = setEnvForTest("LABKIT_GUARD_PRIVATE_APPS", "");

            scope = labkitQualityScanScope(root);

            testCase.verifyTrue(any(contains(scope.appMFiles, ...
                "labkit_PrivateQualityProbe_app.m")), ...
                "Accepted private app roots should enter project quality guardrails.");
            clear cleanupPrivate cleanupForce;
        end
    end
end

function root = createPrivateQualityProbe(testCase)
    root = string(tempname);
    appFolder = fullfile(root, "apps", "private_family", "private_probe");
    mkdir(appFolder);
    writeText(fullfile(appFolder, "labkit_PrivateQualityProbe_app.m"), ...
        "function labkit_PrivateQualityProbe_app" + newline + ...
        "end" + newline);
    testCase.addTeardown(@() removeFolderIfPresent(root));
end

function cleanup = setEnvForTest(name, value)
    previous = getenv(char(name));
    setenv(char(name), char(value));
    cleanup = onCleanup(@() setenv(char(name), previous));
end

function writeText(filepath, text)
    fid = fopen(filepath, "w");
    assert(fid > 0, "Could not write test file: %s", filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
