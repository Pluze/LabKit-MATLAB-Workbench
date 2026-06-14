classdef ProjectGovernanceScaffoldSourceTest < matlab.unittest.TestCase
    %PROJECTGOVERNANCESCAFFOLDSOURCETEST Verify private scaffold source helpers.

    methods (Test, TestTags = {'Unit'})
        function summaryRowsReflectScaffoldState(testCase)
            root = setupLabKitTestPath();
            addScaffoldSourcePath(testCase, root);

            S = struct( ...
                'inputNames', ["a.csv"; "b.csv"], ...
                'outputFolder', "out", ...
                'sampleName', "Specimen A", ...
                'repeatCount', 3, ...
                'threshold', 0.75, ...
                'primaryValue', 7.25, ...
                'mode', "Review", ...
                'enabled', false, ...
                'lastAction', "Updated settings");

            data = scaffold_app.view.summaryTableData(S);

            testCase.verifyEqual(data(:, 1), { ...
                'Inputs selected'; ...
                'Output folder'; ...
                'Sample name'; ...
                'Repeat count'; ...
                'Threshold'; ...
                'Primary value'; ...
                'Mode'; ...
                'Run enabled'; ...
                'Last action'});
            testCase.verifyEqual(data{1, 2}, '2');
            testCase.verifyEqual(data{2, 2}, 'out');
            testCase.verifyEqual(data{3, 2}, 'Specimen A');
            testCase.verifyEqual(data{4, 2}, '3');
            testCase.verifyEqual(data{5, 2}, '0.75');
            testCase.verifyEqual(data{6, 2}, '7.25');
            testCase.verifyEqual(data{7, 2}, 'Review');
            testCase.verifyEqual(data{8, 2}, 'off');
            testCase.verifyEqual(data{9, 2}, 'Updated settings');
        end

        function detailLinesRenderDefaultState(testCase)
            root = setupLabKitTestPath();
            addScaffoldSourcePath(testCase, root);

            lines = scaffold_app.view.detailLines(struct());

            testCase.verifyTrue(iscell(lines));
            testCase.verifyTrue(any(contains(string(lines), ...
                'Scaffold app is ready.')));
            testCase.verifyTrue(any(contains(string(lines), ...
                'Mode: Preview')));
        end

        function buildSpecShowsCommonUiSurface(testCase)
            root = setupLabKitTestPath();
            addScaffoldSourcePath(testCase, root);

            spec = scaffold_app.ui.buildSpec(struct());
            flat = flattenSpec(spec);
            kinds = string({flat.kind});
            ids = string({flat.id});
            fieldKinds = collectFieldKinds(flat);

            testCase.verifyTrue(all(ismember(["app", "tab", "section", ...
                "pathPanel", "field", "rangeField", "actionGroup", ...
                "action", "resultTable", "statusPanel", "logPanel", ...
                "workspace", "previewArea"], kinds)));
            testCase.verifyTrue(all(ismember(["text", "spinner", ...
                "number", "slider", "dropdown", "checkbox", "readonly"], ...
                fieldKinds)));
            testCase.verifyTrue(all(ismember(["inputs", "outputFolder", ...
                "summaryTable", "details", "logPanel", "preview"], ids)));
        end
    end
end

function addScaffoldSourcePath(testCase, root)
    scaffoldPath = fullfile(root, "apps", "project", "governance", ...
        "scaffold", "generated_app");
    addpath(scaffoldPath);
    testCase.addTeardown(@() removePathIfPresent(scaffoldPath));
end

function removePathIfPresent(folder)
    paths = strsplit(path, pathsep);
    if any(strcmp(paths, folder))
        rmpath(folder);
    end
end

function flat = flattenSpec(spec)
    flat = spec;
    childSpecs = {};
    if isfield(spec, "children") && iscell(spec.children)
        childSpecs = [childSpecs, spec.children];
    end
    if isfield(spec, "props") && isstruct(spec.props) && ...
            isfield(spec.props, "controlTabs") && iscell(spec.props.controlTabs)
        childSpecs = [childSpecs, spec.props.controlTabs];
    end
    if isfield(spec, "props") && isstruct(spec.props) && ...
            isfield(spec.props, "workspace") && isstruct(spec.props.workspace)
        childSpecs{end + 1} = spec.props.workspace;
    end
    if isfield(spec, "slots") && isstruct(spec.slots)
        slotNames = fieldnames(spec.slots);
        for k = 1:numel(slotNames)
            slotValue = spec.slots.(slotNames{k});
            if isstruct(slotValue)
                childSpecs{end + 1} = slotValue;
            end
        end
    end
    for k = 1:numel(childSpecs)
        flat = [flat, flattenSpec(childSpecs{k})];
    end
end

function kinds = collectFieldKinds(flat)
    kinds = strings(1, 0);
    for k = 1:numel(flat)
        if strcmp(flat(k).kind, "field") && isfield(flat(k).props, "kind")
            kinds(end + 1) = string(flat(k).props.kind);
        end
    end
end
