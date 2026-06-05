% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function strain = loadNcorrStrain(matFile)
    data = load(matFile, 'data_dic_save');
    if ~isfield(data, 'data_dic_save') || ~isfield(data.data_dic_save, 'strains')
        error('MAT file must contain data_dic_save.strains.');
    end

    strains = data.data_dic_save.strains;
    required = {'plot_exx_ref_formatted', 'plot_eyy_ref_formatted'};
    for i = 1:numel(required)
        if ~isfield(strains, required{i})
            error('Missing data_dic_save.strains.%s.', required{i});
        end
    end

    strain = struct();
    strain.exx = strains.plot_exx_ref_formatted;
    strain.eyy = strains.plot_eyy_ref_formatted;
    strain.roiMask = [];
    if isfield(strains, 'roi_ref_formatted') && ...
            isfield(strains.roi_ref_formatted, 'mask')
        strain.roiMask = logical(strains.roi_ref_formatted.mask);
    end
end
