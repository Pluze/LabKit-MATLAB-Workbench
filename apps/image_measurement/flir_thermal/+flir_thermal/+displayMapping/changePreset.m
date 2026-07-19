function state=changePreset(state,preset,context)
if string(preset)=="Auto",state=flir_thermal.displayMapping.autoRange(state,context);end
end
