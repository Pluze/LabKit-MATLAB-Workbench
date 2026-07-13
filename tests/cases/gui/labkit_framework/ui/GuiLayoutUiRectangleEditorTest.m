classdef GuiLayoutUiRectangleEditorTest < matlab.unittest.TestCase
    %GUILAYOUTUIRECTANGLEEDITORTEST Verify the base-MATLAB rectangle editor.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function rectangleEditorOwnsMovableGraphics(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = uifigure('Visible', 'off', ...
                'Name', 'labkit_rectangle_editor_probe');
            figureCleanup = onCleanup(@() delete(fig));
            ax = uiaxes(fig);
            background = image(ax, zeros(40, 60, 3, 'uint8'));
            axis(ax, 'image');
            runtime = labkit.ui.interaction.runtime(ax, struct('figure', fig));
            editor = labkit.ui.interaction.rectangleEditor(runtime, ...
                [40 60 3], [10 8 20 12], struct('fixedAspectRatio', true));
            editorCleanup = onCleanup(@() editor.delete());
            editor.setBackground(background);

            assert(editor.isValid(), ...
                'Rectangle editor should create base-MATLAB graphics.');
            graphics = editor.graphics();
            assert(numel(graphics) == 5 && all(arrayfun( ...
                @(handle) strcmp(get(handle, 'HitTest'), 'on'), graphics)), ...
                'Resizable editor should expose one box and four interactive corners.');

            editor.setPosition([-5 -3 100 30]);
            position = editor.getPosition();
            assert(position(1) >= 1 && position(2) >= 1 && ...
                position(1) + position(3) <= 60 && ...
                position(2) + position(4) <= 40, ...
                'Rectangle editor should constrain geometry to image bounds.');
            assert(abs(position(3) ./ position(4) - 20 ./ 12) < 1e-12, ...
                'Fixed-aspect editor should preserve its initial aspect ratio.');

            editor.setBounds([5 45 7 37]);
            editor.setPosition([1 1 10 6]);
            position = editor.getPosition();
            assert(position(1) >= 5 && position(2) >= 7, ...
                'Explicit coordinate bounds should constrain offset previews.');

            fixedSize = labkit.ui.interaction.rectangleEditor(runtime, ...
                [40 60], [12 10 18 14], struct('resizable', false));
            fixedCleanup = onCleanup(@() fixedSize.delete());
            assert(numel(fixedSize.graphics()) == 1, ...
                'Non-resizable editor should expose only the draggable box.');
            fixedSize.setActive(false);
            fixedGraphics = fixedSize.graphics();
            assert(strcmp(fixedGraphics.HitTest, 'off'), ...
                'Inactive rectangle graphics should not intercept pointer events.');

            clear fixedCleanup editorCleanup figureCleanup cleanup
        end
    end
end
