classdef NeurophysiologyWorkflowSpecTest < matlab.unittest.TestCase
    %NEUROPHYSIOLOGYWORKFLOWSPECTEST Verify RHS app-family workflow specs.

    methods (Test, TestTags = {'Unit'})
        function previewOwnsProtocolDraftingSurface(testCase)
            setupLabKitTestPath();

            spec = rhs_preview.ui.buildSpec(struct());

            testCase.verifyEqual(tabTitles(spec), ...
                ["Setup", "Protocol", "Filter", "Review", "Log"]);
            testCase.verifyTrue(any(sectionTitles(spec) == ...
                "Protocol Channel Roles"));
            testCase.verifyTrue(any(sectionTitles(spec) == "File Filter"));
            testCase.verifyTrue(any(actionLabels(spec) == ...
                "Save Protocol Draft"));
            testCase.verifyTrue(any(actionLabels(spec) == ...
                "Save Filter Record"));
            testCase.verifyTrue(any(actionLabels(spec) == "Zoom to ROI"));
        end

        function screenCommandIsRetiredIntoPreview(testCase)
            setupLabKitTestPath();

            testCase.verifyEqual(exist("labkit_RHSScreen_app", "file"), 0);
            testCase.verifyEqual(exist("rhs_screen.ui.buildSpec", "file"), 0);
        end

        function analysisWorkflowKeepsHeavyAnalyzeExplicit(testCase)
            setupLabKitTestPath();

            spec = nerve_response_analysis.ui.buildSpec(struct());

            testCase.verifyEqual(tabTitles(spec), ...
                ["Setup", "Protocol", "Review", "Export", "Log"]);
            testCase.verifyTrue(any(sectionTitles(spec) == ...
                "Filter Record"));
            testCase.verifyTrue(any(sectionTitles(spec) == ...
                "Protocol (recommended)"));
            testCase.verifyTrue(any(actionLabels(spec) == ...
                "Analyze Filtered Files"));
            testCase.verifyTrue(any(actionLabels(spec) == ...
                "Export Analysis"));
        end

        function statsWorkflowAutoLoadHasRefreshAndExport(testCase)
            setupLabKitTestPath();

            spec = response_review_stats.ui.buildSpec(struct());

            testCase.verifyEqual(tabTitles(spec), ...
                ["Setup", "Review", "Export", "Log"]);
            testCase.verifyTrue(any(actionLabels(spec) == ...
                "Refresh Metrics"));
            testCase.verifyTrue(any(actionLabels(spec) == ...
                "Export Metrics"));
        end
    end
end

function titles = tabTitles(spec)
    tabs = spec.props.controlTabs;
    titles = strings(1, numel(tabs));
    for k = 1:numel(tabs)
        titles(k) = string(tabs{k}.props.title);
    end
end

function titles = sectionTitles(spec)
    flat = flattenSpec(spec);
    titles = strings(1, 0);
    for k = 1:numel(flat)
        if strcmp(flat(k).kind, "section") && isfield(flat(k).props, "title")
            titles(end + 1) = string(flat(k).props.title);
        end
    end
end

function labels = actionLabels(spec)
    flat = flattenSpec(spec);
    labels = strings(1, 0);
    for k = 1:numel(flat)
        if strcmp(flat(k).kind, "action") && isfield(flat(k).props, "label")
            labels(end + 1) = string(flat(k).props.label);
        end
    end
end

function flat = flattenSpec(spec)
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
    parts = cell(1, numel(childSpecs) + 1);
    parts{1} = spec;
    for k = 1:numel(childSpecs)
        parts{k + 1} = flattenSpec(childSpecs{k});
    end
    flat = [parts{:}];
end
