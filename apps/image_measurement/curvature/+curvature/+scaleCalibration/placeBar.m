function state = placeBar(state, context)
if isempty(state.session.cache.image) || ~state.project.annotations.calibration.isCalibrated
    context.alert("Measure a scale reference before placing a scale bar.", "Calibration required"); return
end
p = state.project.parameters;
state.session.view.scaleBar = labkit.app.interaction.scaleBarGeometry( ...
    size(state.session.cache.image), state.project.annotations.calibration, ...
    p.scaleBarLength, p.scaleBarPosition, p.scaleBarColor);
end
