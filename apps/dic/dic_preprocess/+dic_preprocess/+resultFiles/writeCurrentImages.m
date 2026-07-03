% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current reference/moving images and output folder. Output is a struct of
% written paths. Side effects: writes two PNG image files.

function outputs = writeCurrentImages(referenceImage, movingImage, folder)
%WRITECURRENTIMAGES Write the current DIC preprocess pair as PNG files.

    outputs = struct( ...
        'referencePath', fullfile(folder, 'current_reference.png'), ...
        'movingPath', fullfile(folder, 'current_moving.png'));
    imwrite(referenceImage, outputs.referencePath);
    imwrite(movingImage, outputs.movingPath);
end
