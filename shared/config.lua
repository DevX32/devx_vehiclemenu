return {
    keyBind = 'F5',
    speedUnit = 'mph', -- kmph / mph
    
    -- UI Settings
    ui = {
        fadeTime = 500,
        iconSize = { 
            width = '1vw', 
            height = '2vh' 
        },
        engineIconSize = {
            width = '1.5vw', 
            height = '2.5vh'
        },
        colors = {
            primary = '#ffffff',
            hover = '#cccccc',
            shadow = 'rgba(0, 0, 0, 0.8)'
        }
    },
    
    -- Vehicle Settings
    vehicle = {
        detectionRadius = 5.0,
        updateInterval = 100,
        iconOffset = 0.35
    },
    
    -- Controls
    controls = {
        enableArrowKeys = true,
        enableMouseControl = true
    }
}