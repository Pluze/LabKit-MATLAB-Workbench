classdef AppSessionRestoreFailureTest < matlab.unittest.TestCase
    %APPSESSIONRESTOREFAILURETEST Protect cross-App session restore semantics.

    methods (Test, TestTags = {'Integration'})
        function existingCorruptSourcesAbortEveryAffectedFactory(testCase)
            setupLabKitTestPath();
            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() rmdir(folder, 's'));
            cases = restoreCases();

            for k = 1:numel(cases)
                item = cases(k);
                filepath = fullfile(folder, item.filename);
                writeBytes(filepath, uint8([13 37 0 255]));
                definition = str2func(item.package + ".definition");
                def = definition();
                project = def.project.Create();
                project.inputs.sources = labkit.ui.runtime.sourceRecord( ...
                    item.id, item.role, filepath, item.required);

                caught = [];
                try
                    def.createSession(project);
                catch ME
                    caught = ME;
                end
                testCase.verifyClass(caught, 'MException', ...
                    item.package + ...
                    " must reject an existing corrupt project source.");
            end
            clear cleanup
        end
    end
end

function cases = restoreCases()
    cases = [ ...
        restoreCase("figure_studio", "figure1", "matlab-figure", ...
            "corrupt.fig", true), ...
        restoreCase("focus_stack", "image1", "focus-image", ...
            "corrupt-focus.png", true), ...
        restoreCase("image_match", "reference", "reference-image", ...
            "corrupt-reference.png", true), ...
        restoreCase("image_enhance", "image1", "source-image", ...
            "corrupt-enhance.png", true), ...
        restoreCase("flir_thermal", "thermal1", "thermal-image", ...
            "corrupt-thermal.jpg", true), ...
        restoreCase("nerve_response_analysis", "filterRecord", ...
            "filterRecord", "corrupt-filter.json", true)];
end

function value = restoreCase(package, id, role, filename, required)
    value = struct( ...
        "package", package, ...
        "id", id, ...
        "role", role, ...
        "filename", filename, ...
        "required", required);
end

function writeBytes(filepath, bytes)
    [fileId, message] = fopen(filepath, 'w');
    assert(fileId >= 0, message);
    cleanup = onCleanup(@() fclose(fileId));
    fwrite(fileId, bytes, 'uint8');
    clear cleanup
end
