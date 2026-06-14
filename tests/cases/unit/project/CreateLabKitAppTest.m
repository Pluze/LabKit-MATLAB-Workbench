classdef CreateLabKitAppTest < matlab.unittest.TestCase
    %CREATELABKITAPPTEST Verify the app scaffold generator.

    methods (Test, TestTags = {'Unit'})
        function generatorCopiesStarterShapeWithoutRegistry(testCase)
            root = setupLabKitTestPath();

            tempRoot = tempname;
            cleaner = onCleanup(@() removeFolderIfPresent(tempRoot));

            created = project_governance.ops.createLabKitApp( ...
                "Root", tempRoot, ...
                "Family", "bench_tools", ...
                "Slug", "surface_scan", ...
                "EntryPoint", "labkit_SurfaceScan_app", ...
                "Label", "Surface Scan");

            appFolder = fullfile(tempRoot, "apps", "bench_tools", "surface_scan");
            testCase.verifyEqual(created.AppFolder, string(appFolder));
            testCase.verifyTrue(isfile(fullfile(appFolder, "labkit_SurfaceScan_app.m")));
            testCase.verifyTrue(isfolder(fullfile(appFolder, "+surface_scan")));
            testCase.verifyTrue(isfile(fullfile(appFolder, "+surface_scan", "run.m")));
            testCase.verifyTrue(isfile(fullfile(appFolder, "+surface_scan", "+ui", "buildSpec.m")));
            testCase.verifyTrue(isfile(fullfile(appFolder, "+surface_scan", "+view", "detailLines.m")));
            testCase.verifyTrue(isfile(fullfile(tempRoot, "tests", "cases", ...
                "unit", "apps", "bench_tools", "SurfaceScanScaffoldTest.m")));

            entryText = string(fileread(fullfile(appFolder, "labkit_SurfaceScan_app.m")));
            testCase.verifyTrue(contains(entryText, "surface_scan.run"));
            testCase.verifyFalse(contains(entryText, "scaffold_app"));
            testCase.verifyFalse(contains(entryText, "scaffold_App_app"));

            specText = string(fileread(fullfile(appFolder, "+surface_scan", "+ui", "buildSpec.m")));
            testCase.verifyTrue(contains(specText, "Surface Scan"));
            testCase.verifyFalse(contains(specText, "scaffoldApp"));
        end
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
