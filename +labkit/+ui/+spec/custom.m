function spec = custom(id, builder, varargin)
%CUSTOM Create a custom tool/layout escape-hatch spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.custom(id, builder, opts...)
%
% Inputs:
%   id - globally unique custom control id.
%   builder - named function handle in its own .m file. It is called by the
%       framework with parent, id, context, and props.
%   opts - app-neutral options for that custom builder.
%
% Output:
%   spec - scalar data-only UI spec struct.

    validateBuilder(builder);
    props = optionStruct(varargin);
    props.builder = builder;
    spec = makeSpec('custom', id, props, {}, struct());
end

function validateBuilder(builder)
    if ~isa(builder, 'function_handle')
        error('labkit:ui:spec:InvalidCustomBuilder', ...
            'custom builder must be a function handle.');
    end

    info = functions(builder);
    if ismember(info.type, {'anonymous', 'nested', 'scopedfunction'})
        error('labkit:ui:spec:InvalidCustomBuilder', ...
            'custom builder must be a named function in its own .m file.');
    end

    builderFile = which(info.function);
    if isempty(builderFile) || ~endsWith(builderFile, '.m')
        error('labkit:ui:spec:InvalidCustomBuilder', ...
            'custom builder "%s" must resolve to an .m file.', info.function);
    end
end
