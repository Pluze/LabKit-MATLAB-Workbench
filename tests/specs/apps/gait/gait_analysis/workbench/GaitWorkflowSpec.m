classdef GaitWorkflowSpec < matlab.unittest.TestCase
    %GAITWORKFLOWSPEC Specify Video Marker input, analysis, export, restore.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function analyzesNavigatesExportsAndRestoresSyntheticPose(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = gait_analysis.syntheticInputs.writeSamplePack(context);
            posePath = pack.InitialProject.inputs.sources(1).reference.originalPath;
            backend = struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            definition = gait_analysis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("poseFile", posePath, 1);
            skeletonAxes = oneHandle( ...
                figureValue, "gaitStepAxes.skeleton");
            overviewAxes = oneHandle( ...
                figureValue, "gaitContextAxes.overview");
            verifyVisibleLineData(testCase, skeletonAxes);
            verifyVisibleLineData(testCase, overviewAxes);
            runtime.applyControlValue("originAtFirstFrameFirstPoint", true);
            runtime.invokeAction("runAnalysis");
            result = runtime.State.project.results.analysis;
            if height(result.stepTable) > 1
                runtime.applyTableSelection("stepTable", [2 1]);
                runtime.invokeAction("previousStep");
                runtime.invokeAction("nextStep");
            end
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportResults");

            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyTrue(result.ok);
            testCase.verifyGreaterThan(height(result.frameTable), 0);
            testCase.verifyGreaterThan(height(result.stepTable), 0);
            anglesAxes = oneHandle(figureValue, "gaitStepAxes.angles");
            segmentsAxes = oneHandle( ...
                figureValue, "gaitContextAxes.segments");
            verifyVisibleLineData(testCase, skeletonAxes);
            verifyVisibleLineData(testCase, anglesAxes);
            verifyVisibleLineData(testCase, segmentsAxes);
            verifyVisibleLineData(testCase, overviewAxes);
            verifyEqualDataUnits(testCase, skeletonAxes);
            verifyEqualDataUnits(testCase, overviewAxes);
            labels = string(skeletonAxes.Legend.String);
            testCase.verifyFalse(any(startsWith(labels, "data")));
            [~, stem] = fileparts(posePath);
            testCase.verifyTrue(isfile(fullfile(folder, stem + "_summary.csv")));
            testCase.verifyTrue(isfile(fullfile(folder, stem + "_gait.labkit.json")));
            saved = fullfile(folder, "gait-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.applyFileSelection("poseFile", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(saved);
            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyTrue(runtime.State.project.results.analysis.ok);
            clear cleanup
        end
    end
end

function handle = oneHandle(parent, tag)
handle = findall(parent, "Tag", tag);
if numel(handle) ~= 1
    error("GaitWorkflowSpec:UnexpectedHandleCount", ...
        "Expected one handle tagged %s.", tag);
end
end

function verifyVisibleLineData(testCase, ax)
lines = findobj(ax, "Type", "line");
x = cell2mat(arrayfun(@(line) ...
    double(line.XData(:)), lines, UniformOutput=false));
y = cell2mat(arrayfun(@(line) ...
    double(line.YData(:)), lines, UniformOutput=false));
x = x(isfinite(x));
y = y(isfinite(y));
testCase.verifyNotEmpty(x);
testCase.verifyNotEmpty(y);
testCase.verifyLessThanOrEqual(min(x), ax.XLim(2));
testCase.verifyGreaterThanOrEqual(max(x), ax.XLim(1));
testCase.verifyLessThanOrEqual(min(y), ax.YLim(2));
testCase.verifyGreaterThanOrEqual(max(y), ax.YLim(1));
end

function verifyEqualDataUnits(testCase, ax)
position = getpixelposition(ax, true);
xUnitsPerPixel = diff(double(ax.XLim)) / position(3);
yUnitsPerPixel = diff(double(ax.YLim)) / position(4);
testCase.verifyEqual( ...
    xUnitsPerPixel, yUnitsPerPixel, "RelTol", 1e-10);
end
