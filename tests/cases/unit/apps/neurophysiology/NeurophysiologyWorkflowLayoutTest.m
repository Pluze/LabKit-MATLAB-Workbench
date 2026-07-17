classdef NeurophysiologyWorkflowLayoutTest < matlab.unittest.TestCase
    %NEUROPHYSIOLOGYWORKFLOWLAYOUTTEST Verify RHS app-family workflow layouts.

    methods (Test, TestTags = {'Unit'})
        function previewOwnsProtocolDraftingSurface(testCase)
            setupLabKitTestPath();

            layout = rhs_preview.userInterface.buildWorkbenchLayout( ...
                appCallbacks(rhs_preview.definitionActions()));

            testCase.verifyEqual(tabTitles(layout), ...
                ["Setup", "Protocol", "Filter", "Review", "Log"]);
            testCase.verifyTrue(any(sectionTitles(layout) == ...
                "Protocol Channel Roles"));
            testCase.verifyTrue(any(sectionTitles(layout) == "File Filter"));
            testCase.verifyTrue(any(actionLabels(layout) == ...
                "Save Protocol Draft"));
            testCase.verifyTrue(any(actionLabels(layout) == ...
                "Save Filter Record"));
            testCase.verifyTrue(any(actionLabels(layout) == "Zoom to ROI"));
        end

        function analysisWorkflowKeepsHeavyAnalyzeExplicit(testCase)
            setupLabKitTestPath();

            layout = nerve_response_analysis.userInterface.buildWorkbenchLayout( ...
                appCallbacks(nerve_response_analysis.definitionActions()));

            testCase.verifyEqual(tabTitles(layout), ...
                ["Setup", "Protocol", "Review", "Export", "Log"]);
            testCase.verifyTrue(any(sectionTitles(layout) == ...
                "Filter Record"));
            testCase.verifyTrue(any(sectionTitles(layout) == ...
                "Protocol (recommended)"));
            testCase.verifyTrue(any(actionLabels(layout) == ...
                "Analyze Filtered Files"));
            testCase.verifyTrue(any(actionLabels(layout) == ...
                "Export Analysis"));
        end

        function statsWorkflowAutoLoadHasRefreshAndExport(testCase)
            setupLabKitTestPath();

            layout = response_review_stats.userInterface.buildWorkbenchLayout( ...
                appCallbacks(response_review_stats.definitionActions()));

            testCase.verifyEqual(tabTitles(layout), ...
                ["Setup", "Review", "Export", "Log"]);
            testCase.verifyTrue(any(actionLabels(layout) == ...
                "Refresh Metrics"));
            testCase.verifyTrue(any(actionLabels(layout) == ...
                "Export Metrics"));
        end
    end
end

function callbacks = appCallbacks(actions)
    callbacks = struct();
    ids = fieldnames(actions);
    for k = 1:numel(ids)
        callbacks.(ids{k}) = @(varargin) [];
    end
end

function titles = tabTitles(layout)
    tabs = layout.props.controlTabs;
    titles = strings(1, numel(tabs));
    for k = 1:numel(tabs)
        titles(k) = string(tabs{k}.props.title);
    end
end

function titles = sectionTitles(layout)
    flat = flattenLayout(layout);
    titles = strings(1, numel(flat));
    count = 0;
    for k = 1:numel(flat)
        if strcmp(flat(k).kind, "section") && isfield(flat(k).props, "title")
            count = count + 1;
            titles(count) = string(flat(k).props.title);
        end
    end
    titles = titles(1:count);
end

function labels = actionLabels(layout)
    flat = flattenLayout(layout);
    labels = strings(1, numel(flat));
    count = 0;
    for k = 1:numel(flat)
        if strcmp(flat(k).kind, "action") && isfield(flat(k).props, "label")
            count = count + 1;
            labels(count) = string(flat(k).props.label);
        end
    end
    labels = labels(1:count);
end

function flat = flattenLayout(layout)
    childLayouts = {};
    if isfield(layout, "children") && iscell(layout.children)
        childLayouts = [childLayouts, layout.children];
    end
    if isfield(layout, "props") && isstruct(layout.props) && ...
            isfield(layout.props, "controlTabs") && iscell(layout.props.controlTabs)
        childLayouts = [childLayouts, layout.props.controlTabs];
    end
    if isfield(layout, "props") && isstruct(layout.props) && ...
            isfield(layout.props, "workspace") && isstruct(layout.props.workspace)
        childLayouts{end + 1} = layout.props.workspace;
    end
    if isfield(layout, "slots") && isstruct(layout.slots)
        slotNames = fieldnames(layout.slots);
        slotValues = cell(1, numel(slotNames));
        for k = 1:numel(slotNames)
            slotValues{k} = layout.slots.(slotNames{k});
        end
        childLayouts = [childLayouts, ...
            slotValues(cellfun(@isstruct, slotValues))];
    end
    parts = cell(1, numel(childLayouts) + 1);
    parts{1} = layout;
    for k = 1:numel(childLayouts)
        parts{k + 1} = flattenLayout(childLayouts{k});
    end
    flat = [parts{:}];
end
