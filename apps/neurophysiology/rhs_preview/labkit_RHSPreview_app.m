function varargout = labkit_RHSPreview_app(varargin)
%LABKIT_RHSPREVIEW_APP Launch the RHS Preview app.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @rhs_preview.definition, @rhs_preview.requirements, ...
        @rhs_preview.version, varargin{:});
end
