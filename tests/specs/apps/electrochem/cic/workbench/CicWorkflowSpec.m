classdef CicWorkflowSpec < matlab.unittest.TestCase
    %CICWORKFLOWSPEC Verify the CIC layout wiring that headless specs cannot prove.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsRecomputesExportsAndRestoresAChronoSession(testCase)
            first = testfixtures.dta.file( ...
                'chrono_chronopot_current_pulse_0p2ms.DTA');
            second = testfixtures.dta.file( ...
                'chrono_chronopot_current_pulse_1ms.DTA');
            unsupported = testfixtures.dta.file( ...
                'eis_potentiostatic_zcurve.DTA');
            folder = string(tempname);
            mkdir(folder);
            cleanupFolder = onCleanup(@() removeFolder(folder));
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice( ...
                    fullfile(folder, "cic_results.csv")), ...
                "alert", @(~, ~) []);
            definition = cic.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanupRuntime = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            verifySemanticLayout(testCase, figure);
            testCase.verifyEqual(string( ...
                findall(figure, "Tag", "files").Multiselect), "on");
            runtime.applyFileSelection("files", string(first), 1);
            results = findall(figure, "Tag", "results");
            testCase.verifyEqual(size(results.Data), [1, 8]);
            testCase.verifyNotEmpty(findall(figure, "Tag", "plotAxes.top").Children);
            testCase.verifyNotEmpty(findall(figure, "Tag", "plotAxes.bottom").Children);
            testCase.verifyTrue(contains(string( ...
                findall(figure, "Tag", "detect").Value), "metadata-current"));

            runtime.applyFileSelection("files", ...
                [string(first), string(second), string(unsupported)], 1:3);
            before = results.Data;
            runtime.applyControlValue("areaOverride", "2");
            after = results.Data;
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 2);
            for row = 1:2
                testCase.verifyEqual(after{row, 7}, 0.5 * before{row, 7}, ...
                    "RelTol", 1e-12);
            end

            runtime.invokeAction("exportResults");
            testCase.verifyTrue(isfile(fullfile(folder, "cic_results.csv")));
            testCase.verifyGreaterThan( ...
                height(readtable(fullfile(folder, "cic_results.csv"))), 0);

            clear cleanupRuntime cleanupFolder
        end
    end
end

function verifySemanticLayout(testCase, figure)
    ids = ["files", "preset", "cathLimit", "anodLimit", "delayUs", ...
        "areaOverride", "pulseMode", "cicMode", "cicUnit", ...
        "useMeasuredCurrent", "results", "exportResults", ...
        "plotAxes.top", "plotAxes.bottom"];
    for id = ids
        testCase.verifyNumElements(findall(figure, "Tag", id), 1, ...
            "Missing CIC semantic target: " + id);
    end
end

function removeFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end
