-- Procedurally generate water (old script tho haha)
-- Script : Miisan

if not app.activeSprite then
  app.alert("No sprite is active!")
  return
end

if not app.activeSprite.selection.isEmpty then
  local sprite = app.activeSprite
  local bounds = sprite.selection.bounds
  local currentFrame = app.activeFrame.frameNumber

  local dlg = Dialog{
    title="Water Generator Settings"
  }
  dlg:color{ id="waterColor", label="Water Color:", color=Color{ r=64, g=158, b=255, a=180 } }
  dlg:color{ id="outlineColor", label="Outline Color:", color=Color{ r=44, g=123, b=211, a=255 } }
  dlg:slider{ id="waveHeight", label="Wave Height:", min=1, max=10, value=3 }
  dlg:slider{ id="animSpeed", label="Animation Speed:", min=1, max=24, value=12 }
  dlg:number{ id="numBubbles", label="Number of Bubbles:", text="3", decimals=0 }
  dlg:slider{ id="shineIntensity", label="Shine Intensity:", min=0, max=100, value=50 }
  dlg:button{ id="ok", text="OK" }
  dlg:button{ id="cancel", text="Cancel" }
  dlg:show()

  if not dlg.data.ok then return end

  local waterLayer = sprite:newLayer()
  waterLayer.name = "Water Body"
  local outlineLayer = sprite:newLayer()
  outlineLayer.name = "Water Outline"
  local effectsLayer = sprite:newLayer()
  effectsLayer.name = "Water Effects"

  for f = 0, 11 do
    if f > 0 then
      sprite:newFrame()
    end
    
    local phase = f * (2 * math.pi / 12)
    local outlineCel = sprite:newCel(outlineLayer, currentFrame + f)
    local outlineImg = Image(bounds.width, bounds.height, sprite.colorMode)
    outlineImg:clear(Color{ r=0, g=0, b=0, a=0 })
    
    local waveHeights = {}
    
    for x = 0, bounds.width - 1 do
      local waveY = math.floor(
        math.sin(x * 0.1 + phase) * dlg.data.waveHeight + 
        math.sin(x * 0.05 + phase * 1.5) * (dlg.data.waveHeight * 0.5)
      )
      
      local topY = math.floor(bounds.height * 0.2) + waveY
      if topY >= 0 and topY < bounds.height then
        outlineImg:drawPixel(x, topY, dlg.data.outlineColor)
        outlineImg:drawPixel(x, topY + 1, dlg.data.outlineColor)
      end
      waveHeights[x] = topY
    end
    
    outlineCel.image = outlineImg
    outlineCel.position = Point(bounds.x, bounds.y)
    
    local waterCel = sprite:newCel(waterLayer, currentFrame + f)
    local waterImg = Image(bounds.width, bounds.height, sprite.colorMode)
    waterImg:clear(Color{ r=0, g=0, b=0, a=0 })
    
    for x = 0, bounds.width - 1 do
      local topY = waveHeights[x]
      if topY then
        for y = topY + 2, bounds.height - 1 do
          waterImg:drawPixel(x, y, dlg.data.waterColor)
        end
      end
    end
    
    waterCel.image = waterImg
    waterCel.position = Point(bounds.x, bounds.y)
    
    local effectsCel = sprite:newCel(effectsLayer, currentFrame + f)
    local effectsImg = Image(bounds.width, bounds.height, sprite.colorMode)
    effectsImg:clear(Color{ r=0, g=0, b=0, a=0 })
    
    for x = 0, bounds.width - 1 do
      local topY = waveHeights[x]
      if topY then
        local shineColor = Color{ 
          r=255, 
          g=255, 
          b=255, 
          a=math.floor((dlg.data.shineIntensity / 100) * 128)
        }
        effectsImg:drawPixel(x, topY, shineColor)
      end
    end
    
    for b = 1, dlg.data.numBubbles do
      local bubblePhase = (f * 2 * math.pi / 12) + (b * 2 * math.pi / dlg.data.numBubbles)
      local bubbleX = math.floor(bounds.width * (b - 0.5) / dlg.data.numBubbles)
      local bubbleY = math.floor(bounds.height * 0.6 + math.sin(bubblePhase) * 10)
      
      local bubbleColor = Color{ r=255, g=255, b=255, a=128 }
      effectsImg:drawPixel(bubbleX, bubbleY, bubbleColor)
      effectsImg:drawPixel(bubbleX + 1, bubbleY, bubbleColor)
      effectsImg:drawPixel(bubbleX, bubbleY + 1, bubbleColor)
      effectsImg:drawPixel(bubbleX + 1, bubbleY + 1, bubbleColor)
    end
    
    effectsCel.image = effectsImg
    effectsCel.position = Point(bounds.x, bounds.y)
  end

  for i = currentFrame, currentFrame + 11 do
    sprite.frames[i].duration = 1/dlg.data.animSpeed
  end

  app.refresh()
else
  app.alert("Please make a selection first!")
end