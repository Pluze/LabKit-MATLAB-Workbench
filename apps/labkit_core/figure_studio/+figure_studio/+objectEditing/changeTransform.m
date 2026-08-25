%CHANGETRANSFORM Update one transient object-transform value.
function state = changeTransform(state, name, value, ~)
value = double(value);
if ~isscalar(value) || ~isfinite(value), return; end
state.session.editor.transformDraft.(char(name)) = value;
end
