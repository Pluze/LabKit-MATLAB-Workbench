classdef GaitWorkflowSpec < matlab.unittest.TestCase
    %GAITWORKFLOWSPEC Specify Video Marker input, analysis, export, restore.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function analyzesNavigatesExportsAndRestoresSyntheticPose(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = gaitWorkflowProject(string(folder));
            posePath = project.inputs.sources(1).path;
            backend = struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            definition = gait_analysis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
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
            sourceTab = oneHandle(figureValue, "source");
            stepDetails = oneHandle(figureValue, "stepDetails");
            testCase.verifyEqual(string(sourceTab.Title), ...
                "Source + Step Review");
            testCase.verifyTrue(isDescendantOf(stepDetails, sourceTab));
            detailsText = join(string(stepDetails.Value), newline);
            testCase.verifyTrue(contains(detailsText, "Swing"));
            testCase.verifyTrue(contains(detailsText, "ROM"));
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
            testCase.verifyEmpty(findobj( ...
                skeletonAxes.Children, "Type", "text"));
            labels = string(skeletonAxes.Legend.String);
            testCase.verifyFalse(any(startsWith(labels, "data")));
            [~, stem] = fileparts(posePath);
            testCase.verifyTrue(isfile(fullfile(folder, stem + "_summary.csv")));
            clear cleanup
        end
    end
end

function tf = isDescendantOf(component, expectedAncestor)
tf = false;
current = component.Parent;
while ~isempty(current)
    if current == expectedAncestor
        tf = true;
        return
    end
    current = current.Parent;
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
testCase.verifyEqual(string(ax.DataAspectRatioMode), "manual");
testCase.verifyEqual(ax.DataAspectRatio(1), ...
    ax.DataAspectRatio(2), "RelTol", 1e-10);
end
