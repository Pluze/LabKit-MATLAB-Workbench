classdef EisWorkflowSpec < matlab.unittest.TestCase
    %EISWORKFLOWSPEC Specify EIS file loading, plot materialization, and export.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function importsRecommendedWindowAndRestoresItAfterFullRange(testCase)
            % Oracle: an elevated-boundary arc has a 10 Hz valley and dominant tail;
            % import must crop automatically and both range actions must work.
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            f = logspace(5,-1,19).';
            y = [10 10 11 12 13 15 16 15 12 10 8 6 5 6 9 25 60 80 100].';
            path = fullfile(folder, "spectrum.DTA");
            lines = strings(numel(f)+4, 1);
            lines(1:4) = ["EXPLAIN"; "ZCURVE" + char(9) + "TABLE"; ...
                join(["Pt","Time","Freq","Zreal","Zimag","Zmod","Zphz"], char(9)); ...
                join(["#","s","Hz","ohm","ohm","ohm","deg"], char(9))];
            for k = 1:numel(f)
                lines(k+4) = string(sprintf('%d\t%d\t%.15g\t%g\t%g\t%g\t%g', ...
                    k-1,k,f(k),k,-y(k),hypot(k,y(k)),-atand(y(k)/k)));
            end
            writelines(lines, path);
            definition = eis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection("files", string(path), 1);
            testCase.verifyEqual(runtime.State.session.nyquist.lower, 1, AbsTol=1e-12);
            ax = findall(runtime.figureHandle(), "Tag", "nyquistOverview.nyquist");
            frequency = findall(runtime.figureHandle(), "Tag", "frequencySection");
            label = findall(runtime.figureHandle(), "Tag", "nyquistMinimum.label");
            testCase.verifyEqual(string(label.Text), "Min · 10 Hz");
            testCase.verifyEqual(string(frequency.BorderType), "none");
            plotPanel = findall(runtime.figureHandle(), "Tag", "nyquistOverview");
            fitButton = findall(runtime.figureHandle(), "Tag", "fitOverviewAxes");
            testCase.verifyEqual(ancestor(fitButton, "uipanel"), frequency);
            testCase.verifyEqual(frequency.Parent, plotPanel.Parent);
            testCase.verifyLessThan(frequency.Layout.Row, plotPanel.Layout.Row);
            testCase.verifyEqual(frequency.Layout.Column, plotPanel.Layout.Column);
            testCase.verifyEqual(string(ancestor(frequency, "uitab").Title), "Nyquist + Bode");
            curve = findall(ax, "Type", "line");
            testCase.verifyEqual(sum(isfinite(curve.XData)), 13);
            testCase.verifyEqual(string(ax.Title.String), "Nyquist (10 Hz – 100 kHz)");
            testCase.verifyEmpty(plotPanel.Title);
            testCase.verifyEqual(string(plotPanel.BorderType), "none");
            maximumLabel = findall(runtime.figureHandle(), "Tag", "nyquistMaximum.label");
            testCase.verifyEqual(string(maximumLabel.Text), "Max · 100 kHz");
            runtime.invokeAction("resetFrequency");
            curve = findall(ax, "Type", "line");
            testCase.verifyEqual(sum(isfinite(curve.XData)), 19);
            testCase.verifyEqual(string(ax.Title.String), "Nyquist (0.1 Hz – 100 kHz)");
            runtime.invokeAction("recommendFrequency");
            curve = findall(ax, "Type", "line");
            testCase.verifyEqual(sum(isfinite(curve.XData)), 13);
            testCase.verifyEqual(string(ax.Title.String), "Nyquist (10 Hz – 100 kHz)");
            testCase.verifyEqual(runtime.State.session.cache.items.negZimag_ohm(:), y);
            capture = labkittest.nativeGraphicsCapability("interface-capture");
            if capture.Available
                fig = runtime.figureHandle();
                path = fullfile(folder, "overview.png");
                exportapp(fig, path);
                % Hidden capture settles web-grid geometry without delivering
                % native resize events; exercise the installed panel callback.
                plotPanel.SizeChangedFcn(plotPanel, []);
                verifyFilledViewport(testCase, ax);
                center = [mean(ax.XLim), mean(ax.YLim)];
                fig.Position(3:4) = fig.Position(3:4) + [160 -80];
                drawnow;
                exportapp(fig, path);
                % Hidden capture settles web-grid geometry without delivering
                % native resize events; exercise the installed panel callback.
                plotPanel.SizeChangedFcn(plotPanel, []);
                verifyFilledViewport(testCase, ax);
                testCase.verifyEqual([mean(ax.XLim), mean(ax.YLim)], center, AbsTol=1e-9);
            end
            clear cleanup
        end

        function linksOverviewFrequencyWithoutChangingCustomOrSource(testCase)
            % Oracle: plotted coordinates match the exact selected source
            % frequencies in all overview axes; custom data/view and source stay fixed.
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = eis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime(definition, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection("files", ...
                testfixtures.dta.file("eis_potentiostatic_zcurve.DTA"), 1);
            original = runtime.State.session.cache.items;
            figureValue = runtime.figureHandle();
            nyquist = findall(figureValue, "Tag", "nyquistOverview.nyquist");
            bode = findall(figureValue, "Tag", "bodeOverview.magnitude");
            custom = findall(figureValue, "Tag", "plot.main");
            [~, customViewport] = inspectViewport(custom);
            limits = runtime.State.session.nyquist.limits;
            cutoff = mean(limits);
            runtime.applyControlValue("nyquistMinimum", cutoff);
            curve = findall(nyquist, "Type", "line");
            expected = original.Zreal_ohm(:).' / 1000;
            expected(log10(original.freq_Hz) < cutoff) = NaN;
            testCase.verifyEqual(curve.XData, expected);
            verifyViewport(testCase, custom, customViewport);
            bodeLine = findall(bode, "Type", "line");
            expectedFrequency = original.freq_Hz(:).';
            expectedFrequency(log10(expectedFrequency) < cutoff) = NaN;
            testCase.verifyEqual(bodeLine.XData, expectedFrequency);
            testCase.verifyEqual(bode.XLim, 10.^[cutoff limits(2)], RelTol=1e-12);
            phase = findall(figureValue, "Tag", "bodeOverview.phase");
            phaseLine = findall(phase, "Type", "line");
            testCase.verifyEqual(phaseLine.XData, expectedFrequency);
            testCase.verifyEqual(phase.XLim, bode.XLim, RelTol=1e-12);
            testCase.verifyEqual(runtime.State.session.cache.items, original);
            % Custom coordinates do not invalidate either overview renderer.
            runtime.applyControlValue("xAxis", "Freq (Hz)");
            runtime.applyControlValue("logX", true);
            testCase.verifyTrue(isgraphics(curve) && isgraphics(bodeLine));
            testCase.verifyEqual(curve.XData, expected);
            [~, inspected] = inspectViewport(nyquist);
            runtime.applyControlValue("showMarkers", false);
            verifyViewport(testCase, nyquist, inspected);
            runtime.applyControlValue("nyquistMaximum", limits(1));
            testCase.verifyEqual(runtime.State.session.nyquist.lower, limits(1));
            runtime.applyControlValue("nyquistMinimum", limits(2));
            testCase.verifyEqual(runtime.State.session.nyquist.upper, limits(2));
            runtime.invokeAction("resetFrequency");
            testCase.verifyEqual(runtime.State.session.nyquist.lower, limits(1));
            testCase.verifyEqual(runtime.State.session.nyquist.upper, limits(2));
            runtime.applyFileSelection("files", strings(1,0), zeros(1,0));
            testCase.verifyFalse(runtime.State.session.nyquist.available);
            clear cleanup
        end

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
            % Draft names have no plotted meaning; replacing the errorbar
            % would discard native graphics state for an unrelated text edit.
            runtime.applyControlValue("groupName", "Draft name");
            testCase.verifyTrue(isgraphics(bars));
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

function verifyFilledViewport(testCase, ax)
% A fixed equal-unit plot fills its inner box only when these ratios agree.
position = getpixelposition(ax);
allocation = ax.Position;
inner = ax.InnerPosition;
pixels = inner(3:4) .* position(3:4) ./ allocation(3:4);
testCase.verifyEqual(diff(ax.XLim)/diff(ax.YLim), pixels(1)/pixels(2), RelTol=.02);
testCase.verifyEqual(ax.DataAspectRatio(1), ax.DataAspectRatio(2), AbsTol=1e-12);
end
