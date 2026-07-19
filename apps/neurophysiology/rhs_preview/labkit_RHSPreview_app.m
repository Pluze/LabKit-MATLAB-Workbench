function varargout = labkit_RHSPreview_app(varargin)
%LABKIT_RHSPREVIEW_APP Launch the RHS Preview app.

    [varargout{1:nargout}] = rhs_preview.definition().launch(varargin{:});
end
