classdef UiSpecTest < matlab.unittest.TestCase
    %UISPECTEST Verify LabKit UI 2.0 declarative spec contracts.

    methods (Test, TestTags = {'Unit'})
        function test_uiSpec(testCase)
            setupLabKitTestPath();
            verify_uiSpec();
        end
    end
end

function verify_uiSpec()
%TEST_UISPEC Verify UI 2.0 spec grammar and GUI-free validation.

    checkCommonSpecShape();
    checkChildrenMustBeCellRows();
    checkFieldKindWhitelist();
    checkPathPanelModes();
    checkPreviewAreaValidation();
    checkCustomBuilderValidation();
    checkDuplicateIdsFailBeforeGuiConstruction();
end

function checkCommonSpecShape()
    field = labkit.ui.spec.field('gain', 'Gain', ...
        'kind', 'spinner', 'value', 2);
    section = labkit.ui.spec.section('settings', 'Settings', {field});
    tab = labkit.ui.spec.tab('setup', 'Setup', {section});
    workspace = labkit.ui.spec.workspace('workspace', 'Preview', { ...
        labkit.ui.spec.previewArea('preview', 'Preview')});
    app = labkit.ui.spec.app('probeApp', 'Probe App', ...
        'controlTabs', {tab}, 'workspace', workspace);

    assert(strcmp(app.kind, 'app'), 'App spec should preserve kind.');
    assert(strcmp(app.id, 'probeApp'), 'App spec should preserve id.');
    assert(isstruct(app.props) && iscell(app.children) && isstruct(app.slots), ...
        'Spec should use the common kind/id/props/children/slots shape.');
    assert(iscell(app.props.controlTabs) && isrow(app.props.controlTabs), ...
        'controlTabs should stay a cell row vector for heterogeneous children.');
    assert(strcmp(section.children{1}.id, 'gain'), ...
        'Section children should preserve child specs.');
end

function checkChildrenMustBeCellRows()
    child = labkit.ui.spec.field('probe', 'Probe');
    assertThrows(@() labkit.ui.spec.section('bad', 'Bad', [child child]), ...
        'labkit:ui:spec:InvalidChildren', ...
        'Struct-array children should be rejected.');
    assertThrows(@() labkit.ui.spec.tab('badTab', 'Bad', {child; child}), ...
        'labkit:ui:spec:InvalidChildren', ...
        'Column-cell children should be rejected.');
end

function checkFieldKindWhitelist()
    allowed = {'text', 'number', 'spinner', 'dropdown', 'slider', ...
        'checkbox', 'readonly'};
    for k = 1:numel(allowed)
        spec = labkit.ui.spec.field(['field' num2str(k)], 'Field', ...
            'kind', allowed{k});
        assert(strcmpi(spec.props.kind, allowed{k}), ...
            'Allowed field kind should be preserved.');
    end
    assertThrows(@() labkit.ui.spec.field('radio', 'Radio', ...
        'kind', 'radioGroup'), 'labkit:ui:spec:InvalidFieldKind', ...
        'Primitive or unproven field kinds should stay out of UI 2.0.');
end

function checkPathPanelModes()
    modes = {'singleFile', 'multiFile', 'folder', 'multiFolder', 'outputFolder'};
    for k = 1:numel(modes)
        spec = labkit.ui.spec.pathPanel(['paths' num2str(k)], 'Paths', ...
            'mode', modes{k});
        assert(strcmp(spec.props.mode, modes{k}), ...
            'Allowed pathPanel mode should be preserved.');
    end
    singleSelection = labkit.ui.spec.pathPanel('singleSelectPaths', 'Paths', ...
        'mode', 'multiFile', 'selectionMode', 'single');
    assert(strcmp(singleSelection.props.selectionMode, 'single'), ...
        'pathPanel selectionMode should be configurable independently of chooser mode.');
    assertThrows(@() labkit.ui.spec.pathPanel('badPaths', 'Paths', ...
        'mode', 'database'), 'labkit:ui:spec:InvalidPathPanelMode', ...
        'Unsupported pathPanel modes should fail validation.');
    assertThrows(@() labkit.ui.spec.pathPanel('badSelection', 'Paths', ...
        'selectionMode', 'range'), ...
        'labkit:ui:spec:InvalidPathPanelSelectionMode', ...
        'Unsupported pathPanel selectionMode should fail validation.');
end

function checkPreviewAreaValidation()
    pair = labkit.ui.spec.previewArea('pairPreview', 'Pair', ...
        'layout', 'pair', 'axisIds', {'input', 'output'});
    assert(strcmp(pair.props.layout, 'pair'), ...
        'Allowed preview layout should be preserved.');
    stack = labkit.ui.spec.previewArea('waveforms', 'Waveforms', ...
        'layout', 'stack', 'count', 4);
    assert(stack.props.count == 4, ...
        'Stacked preview areas should support axis count.');
    modes = labkit.ui.spec.previewArea('modePreview', 'Mode Preview', ...
        'viewModes', {'Input', 'Output'}, 'onModeChange', @uiSpecModeProbe);
    assert(isequal(modes.props.viewModes, {'Input', 'Output'}), ...
        'previewArea should preserve declared viewModes.');
    assertThrows(@() labkit.ui.spec.previewArea('badPreview', 'Bad', ...
        'layout', 'grid'), 'labkit:ui:spec:InvalidPreviewLayout', ...
        'Unsupported preview layouts should fail validation.');
end

function checkCustomBuilderValidation()
    spec = labkit.ui.spec.custom('customProbe', @uiSpecCustomProbe);
    assert(strcmp(spec.kind, 'custom'), ...
        'Named custom builder should produce a custom spec.');
    assertThrows(@() labkit.ui.spec.custom('badCustom', @(varargin) []), ...
        'labkit:ui:spec:InvalidCustomBuilder', ...
        'Anonymous custom builders should be rejected.');
end

function checkDuplicateIdsFailBeforeGuiConstruction()
    tab = labkit.ui.spec.tab('setup', 'Setup', { ...
        labkit.ui.spec.section('sectionOne', 'One', { ...
            labkit.ui.spec.field('dup', 'First'), ...
            labkit.ui.spec.field('dup', 'Second')})});
    workspace = labkit.ui.spec.workspace('workspace', 'Workspace', {});
    spec = labkit.ui.spec.app('probeApp', 'Probe App', ...
        'controlTabs', {tab}, 'workspace', workspace);
    assertThrows(@() labkit.ui.app.create(spec), ...
        'labkit:ui:app:DuplicateId', ...
        'Duplicate ids should fail before GUI construction.');
end

function assertThrows(fn, expectedIdentifier, label)
    try
        fn();
    catch ME
        assert(strcmp(ME.identifier, expectedIdentifier), ...
            '%s Expected %s but caught %s.', label, expectedIdentifier, ME.identifier);
        return;
    end
    error('%s Expected an error with identifier %s.', label, expectedIdentifier);
end

function uiSpecModeProbe(varargin)
end
