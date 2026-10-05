classdef EisWorkflowSpec < matlab.unittest.TestCase
    %EISWORKFLOWSPEC Specify EIS file loading, plot materialization, and export.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function recognizesThreeSamplesAndKeepsManualAssignments(testCase)
            % Oracle: exact suffix prefixes produce three groups of three;
            % a manual reassignment survives subsequent auto-recognition.
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = testfixtures.dta.file("eis_potentiostatic_zcurve.DTA");
            names = ["Sample-A-1", "Sample-A-2", "Sample-A-3", ...
                "Sample-B-1", "Sample-B-2", "Sample-B-3", ...
                "Sample-C-1", "Sample-C-2", "Sample-C-3", "unmatched"];
            paths = fullfile(string(folder), names + ".DTA");
            for path = paths, copyfile(source, path); end
            backend = struct("choose", @(varargin) labkit.app.dialog.Choice("Auto-group files"), ...
                "alert", @(~, ~) [], "inform", @(~, ~) []);
            definition = eis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection("files", paths, 1:10);
            groupTab = findall(runtime.figureHandle(), "Type", "uitab", "Title", "Groups");
            groupTab.Parent.SelectedTab = groupTab;
            drawnow;
            runtime.applyControlValue("groupingEnabled", true);
            groups = runtime.State.project.groups;
            testCase.verifyEqual(string({groups.name}), ["Sample-A", "Sample-B", "Sample-C"]);
            testCase.verifyEqual(arrayfun(@(g) numel(g.sourceIds), groups), [3 3 3]);
            capture = labkittest.nativeGraphicsCapability("interface-capture");
            if capture.Available
                exportapp(runtime.figureHandle(), labkittest.visualEvidencePath("eis-group-manager", ".png"));
            end
            runtime.applyControlValue("selectedGroup", "Sample-B");
            runtime.applyFilePanelSelection("files", 1);
            runtime.invokeAction("assignGroup");
            runtime.invokeAction("autoGroup");
            testCase.verifyEqual(arrayfun(@(g) numel(g.sourceIds), runtime.State.project.groups), [2 4 3]);
            runtime.applyControlValue("groupingEnabled", false);
            runtime.applyControlValue("groupingEnabled", true);
            testCase.verifyEqual(arrayfun(@(g) numel(g.sourceIds), runtime.State.project.groups), [2 4 3]);
            runtime.invokeAction("deleteGroup");
            testCase.verifyEqual(string({runtime.State.project.groups.name}), ["Sample-A", "Sample-C"]);
            testCase.verifyNumElements(runtime.State.project.inputs.sources, 10);
            clear cleanup
        end

        function groupsSelectedScansAndRestoresRawView(testCase)
            % Oracle: two assigned copies yield N=2, SD=0; a third stays out.
            % This catches inert controls, selection loss, and stale groups.
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = testfixtures.dta.file("eis_potentiostatic_zcurve.DTA");
            paths = fullfile(string(folder), ["scan-a.DTA","scan-b.DTA","scan-c.DTA"]);
            for path = paths, copyfile(source, path); end
            output = fullfile(folder, "groups.csv");
            backend = struct("choose", @(varargin) labkit.app.dialog.Choice("Group manually"), ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            definition = eis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection("files", paths, 1:3);
            testCase.verifyFalse(runtime.State.project.parameters.groupingEnabled);
            runtime.applyControlValue("groupingEnabled", true);
            runtime.applyFilePanelSelection("files", [1 2]);
            runtime.applyControlValue("groupName", "Sample A");
            runtime.invokeAction("addGroup");
            runtime.invokeAction("assignGroup");
            testCase.verifyNumElements(runtime.State.project.groups, 1);
            testCase.verifyNumElements(runtime.State.project.groups(1).sourceIds, 2);
            ax = findall(runtime.figureHandle(), "Tag", "plot.main");
            bars = findall(ax, "Type", "errorbar");
            testCase.assertNumElements(bars, 1);
            testCase.verifyEqual(bars.YPositiveDelta, zeros(size(bars.YData)));
            capture = labkittest.nativeGraphicsCapability("interface-capture");
            if capture.Available
                exportapp(runtime.figureHandle(), labkittest.visualEvidencePath("eis-groups", ".png"));
            end
            runtime.invokeAction("exportPlot");
            result = readtable(output, TextType="string");
            testCase.verifyTrue(all(result.N == 2));
            testCase.verifyEqual(unique(result.Group), "Sample A");
            runtime.applyControlValue("groupingEnabled", false);
            testCase.verifyNumElements(findall(ax, "Type", "line"), 3);
            runtime.applyControlValue("groupingEnabled", true);
            runtime.applyFilePanelSelection("files", 2);
            runtime.applyControlValue("groupName", "Sample B");
            runtime.invokeAction("addGroup");
            runtime.applyControlValue("selectedGroup", "Sample B");
            runtime.invokeAction("assignGroup");
            testCase.verifyNumElements(runtime.State.project.groups, 2);
            runtime.invokeAction("ungroupFiles");
            testCase.verifyEmpty(runtime.State.project.groups(2).sourceIds);
            runtime.invokeAction("deleteGroup");
            testCase.verifyNumElements(runtime.State.project.groups, 1);
            testCase.verifyEqual(string(runtime.State.project.groups(1).name), "Sample A");
            runtime.applyFileSelection("files", paths([1 3]), 1:2);
            testCase.verifyNumElements(runtime.State.project.groups(1).sourceIds, 1);
            runtime.applyFileSelection("files", paths(3), 1);
            testCase.verifyEmpty(runtime.State.project.groups(1).sourceIds);
            runtime.invokeAction("deleteGroup");
            testCase.verifyEmpty(runtime.State.project.groups);
            testCase.verifyEmpty(findall(ax, "Type", "errorbar"));
            clear cleanup
        end

        function loadsPlotsExportsAndRestoresAnEisFile(testCase)
            source = testfixtures.dta.file("eis_potentiostatic_zcurve.DTA");
            unsupported = testfixtures.dta.file( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            output = fullfile(folder, "eis.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            definition = eis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("files", [source, unsupported], 1:2);
            axesValue = findall(figureValue, "Tag", "plot.main");
            units = eis.impedanceDisplay.catalog();
            [fitted, inspected] = inspectViewport(axesValue);
            runtime.applyControlValue("showMarkers", false);
            verifyViewport(testCase, axesValue, inspected);
            runtime.invokeAction("fitAxes");
            verifyViewport(testCase, axesValue, fitted);
            runtime.invokeAction("equalAxes");
            testCase.verifyEqual(axesValue.DataAspectRatio(1), ...
                axesValue.DataAspectRatio(2), AbsTol=1e-12);
            runtime.applyControlValue("impedanceUnit", units.choices(4));
            expected = fitted ./ 1000;
            verifyViewport(testCase, axesValue, expected);
            runtime.invokeAction("exportPlot");

            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNumElements(runtime.State.project.inputs.sources, 1);
            testCase.verifyNotEmpty(axesValue.Children);
            testCase.verifySubstring(string(axesValue.XLabel.String), ...
                units.choices(4));
            for tag = ["nyquistOverview.nyquist" "bodeOverview.magnitude" "bodeOverview.phase"]
                overviewAxes = findall(figureValue, "Tag", tag);
                testCase.verifyNotEmpty(findall(overviewAxes, "Type", "line"));
                [overviewFitted, overviewInspected] = inspectViewport(overviewAxes);
                verifyViewport(testCase, overviewAxes, overviewInspected);
                overviewLimits.(extractAfter(tag, ".")) = overviewFitted;
            end
            runtime.invokeAction("fitOverviewAxes");
            for tag = ["nyquistOverview.nyquist" "bodeOverview.magnitude" "bodeOverview.phase"]
                overviewAxes = findall(figureValue, "Tag", tag);
                verifyViewport(testCase, overviewAxes, ...
                    overviewLimits.(extractAfter(tag, ".")));
            end
            capture = labkittest.nativeGraphicsCapability("interface-capture");
            evidencePath = labkittest.visualEvidencePath("eis-overview", ".png");
            if capture.Available
                exportapp(figureValue, evidencePath);
                testCase.verifyTrue(isfile(evidencePath));
            else
                testCase.verifyError(@() exportapp(figureValue, evidencePath), capture.ErrorIdentifier);
                testCase.verifyFalse(isfile(evidencePath));
            end
            testCase.verifyTrue(isfile(output));
            clear cleanup
        end
    end
end

function [fitted, inspected] = inspectViewport(ax)
fitted = [ax.XLim, ax.YLim];
inspected = [innerLimits(fitted(1:2)), innerLimits(fitted(3:4))];
ax.XLim = inspected(1:2);
ax.YLim = inspected(3:4);
end

function limits = innerLimits(limits)
limits = limits + [0.2, -0.2] .* diff(limits);
end

function verifyViewport(testCase, ax, expected)
actual = [ax.XLim, ax.YLim];
tolerance = max(1, max(abs(expected))) * 1e-9;
testCase.verifyEqual(actual, expected, AbsTol=tolerance);
end
