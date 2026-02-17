-- Procedural Tree Generator 
-- Script: Miisan

local sprite = app.activeSprite
if not sprite then
  app.alert("No active sprite!")
  return
end

local previewLayer = nil

local function generateTree(config, isPreview)
  local function randomFloat(min, max)
    return min + math.random() * (max - min)
  end

  local function randomInt(min, max)
    return math.random(min, max)
  end

  local function varyColor(baseColor, variation)
    if not variation then return baseColor end
    return Color{
      r=math.max(0, math.min(255, baseColor.red + randomInt(-20, 20))),
      g=math.max(0, math.min(255, baseColor.green + randomInt(-20, 20))),
      b=math.max(0, math.min(255, baseColor.blue + randomInt(-20, 20))),
      a=baseColor.alpha
    }
  end

  math.randomseed(config.seed)

  local canvas = {}
  local canvasWidth = 200
  local canvasHeight = 200
  local centerX = canvasWidth / 2
  local startY = canvasHeight - 10

  for y = 0, canvasHeight - 1 do
    canvas[y] = {}
    for x = 0, canvasWidth - 1 do
      canvas[y][x] = 0
    end
  end

  local function setPixel(x, y, color)
    x = math.floor(x)
    y = math.floor(y)
    if x >= 0 and x < canvasWidth and y >= 0 and y < canvasHeight then
      canvas[y][x] = color
    end
  end

  local function darkenColor(color, amount)
    return Color{
      r=math.max(0, color.red - amount),
      g=math.max(0, color.green - amount),
      b=math.max(0, color.blue - amount),
      a=color.alpha
    }
  end

  local function lightenColor(color, amount)
    return Color{
      r=math.min(255, color.red + amount),
      g=math.min(255, color.green + amount),
      b=math.min(255, color.blue + amount),
      a=color.alpha
    }
  end

  local function drawLine(x1, y1, x2, y2, thickness, color)
    local dx = x2 - x1
    local dy = y2 - y1
    local steps = math.max(math.abs(dx), math.abs(dy))

    if steps == 0 then return end

    local xInc = dx / steps
    local yInc = dy / steps
    local halfThick = thickness / 2

    for i = 0, steps do
      local x = x1 + xInc * i
      local y = y1 + yInc * i

      for tx = -halfThick, halfThick do
        for ty = -halfThick, halfThick do
          if tx*tx + ty*ty <= halfThick*halfThick then
            local shadedColor = color
            local dist = math.sqrt(tx*tx + ty*ty) / halfThick

            if tx < 0 then
              shadedColor = darkenColor(color, math.floor(15 * (1 - dist)))
            elseif tx > 0 then
              shadedColor = lightenColor(color, math.floor(10 * (1 - dist)))
            end

            setPixel(x + tx, y + ty, shadedColor)
          end
        end
      end
    end
  end

  local function drawCircle(cx, cy, radius, color)
    for y = -radius, radius do
      for x = -radius, radius do
        if x*x + y*y <= radius*radius then
          setPixel(cx + x, cy + y, color)
        end
      end
    end
  end

  local function drawSquare(cx, cy, size, color)
    for y = -size, size do
      for x = -size, size do
        setPixel(cx + x, cy + y, color)
      end
    end
  end

  local branches = {}

  local function drawBranch(x, y, angle, length, thickness, depth, maxDepth)
    if depth > maxDepth or length < 2 then return end

    local endX = x + math.cos(angle) * length
    local endY = y + math.sin(angle) * length

    drawLine(x, y, endX, endY, thickness, config.trunkColor)
    table.insert(branches, {x=endX, y=endY, depth=depth})

    if depth < maxDepth then
      local branchAngleSpread = 0.8
      local branchLengthRatio = 0.9
      local branchThicknessRatio = 0.7

      local numBranches = randomInt(2, 3)

      for i = 1, numBranches do
        local newAngle = angle + randomFloat(-branchAngleSpread, branchAngleSpread)
        local newLength = length * (branchLengthRatio + randomFloat(-0.1, 0.1))
        local newThickness = math.max(1, thickness * branchThicknessRatio)

        drawBranch(endX, endY, newAngle, newLength, newThickness, depth + 1, maxDepth)
      end
    end
  end

  local maxDepth = math.floor(config.branchCount / 2) + 2
  local trunkHeight = config.treeHeight * 0.6
  local initialAngle = -math.pi / 2

  drawLine(centerX, startY, centerX, startY - trunkHeight, config.trunkWidth, config.trunkColor)

  for i = 1, config.branchCount do
    local branchY = startY - trunkHeight * (0.3 + (i / config.branchCount) * 0.7)
    local branchAngle = (i % 2 == 0) and -math.pi/3 or -2*math.pi/3
    local branchLength = config.treeHeight * 0.3

    drawBranch(centerX, branchY, branchAngle, branchLength, config.trunkWidth * 0.7, 1, maxDepth)
  end

  drawBranch(centerX, startY - trunkHeight, initialAngle, config.treeHeight * 0.4, config.trunkWidth * 0.7, 1, maxDepth)

  if config.leafDensity > 0 then
    for _, branch in ipairs(branches) do
      if branch.depth >= maxDepth - 1 then
        local leafRadius = randomInt(2, 4)

        for i = 1, config.leafDensity do
          local lx = branch.x + randomInt(-leafRadius*2, leafRadius*2)
          local ly = branch.y + randomInt(-leafRadius*2, leafRadius*2)
          local leafCol = varyColor(config.leafColor, config.leafVariation)

          if config.leafShape == "Circle" then
            drawCircle(lx, ly, randomInt(1, leafRadius), leafCol)
          else
            drawSquare(lx, ly, randomInt(1, leafRadius), leafCol)
          end
        end
      end
    end
  end

  if config.outline then
    local outlined = {}
    for y = 0, canvasHeight - 1 do
      outlined[y] = {}
      for x = 0, canvasWidth - 1 do
        outlined[y][x] = canvas[y][x]
      end
    end

    local thickness = config.outlineThickness or 1
    local maxCheck = thickness + 1

    for y = maxCheck, canvasHeight - maxCheck - 1 do
      for x = maxCheck, canvasWidth - maxCheck - 1 do
        if canvas[y][x] ~= 0 then
          for dy = -thickness, thickness do
            for dx = -thickness, thickness do
              local ny, nx = y + dy, x + dx
              if ny >= 0 and ny < canvasHeight and nx >= 0 and nx < canvasWidth then
                if canvas[ny][nx] == 0 then
                  outlined[ny][nx] = config.outlineColor
                end
              end
            end
          end
        end
      end
    end

    canvas = outlined
  end

  app.transaction(function()
    local layer
    if isPreview then
      if not previewLayer or not previewLayer.sprite then
        previewLayer = sprite:newLayer()
        previewLayer.name = "PREVIEW"
      end
      layer = previewLayer
      for _, cel in ipairs(layer.cels) do
        sprite:deleteCel(cel)
      end
    else
      layer = sprite:newLayer()
      layer.name = "Tree"
      if previewLayer and previewLayer.sprite then
        sprite:deleteLayer(previewLayer)
        previewLayer = nil
      end
    end

    local minX, maxX = canvasWidth, 0
    local minY, maxY = canvasHeight, 0

    for y = 0, canvasHeight - 1 do
      for x = 0, canvasWidth - 1 do
        if canvas[y][x] ~= 0 then
          minX = math.min(minX, x)
          maxX = math.max(maxX, x)
          minY = math.min(minY, y)
          maxY = math.max(maxY, y)
        end
      end
    end

    local cropWidth = maxX - minX + 1
    local cropHeight = maxY - minY + 1

    local img = Image(cropWidth, cropHeight, sprite.colorMode)
    img:clear()

    for y = minY, maxY do
      for x = minX, maxX do
        if canvas[y][x] ~= 0 then
          img:drawPixel(x - minX, y - minY, canvas[y][x])
        end
      end
    end

    local cel = sprite:newCel(layer, app.activeFrame.frameNumber)
    cel.image = img
    cel.position = Point(
      math.floor(sprite.width / 2 - cropWidth / 2),
      math.floor(sprite.height - cropHeight - 5)
    )
  end)

  app.refresh()
end

local dlg = Dialog{title="Procedural Tree Generator"}

dlg:separator{text="Size & Complexity"}

dlg:slider{
  id="treeHeight",
  label="Height:",
  min=10,
  max=100,
  value=40,
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:slider{
  id="trunkWidth",
  label="Trunk Width:",
  min=1,
  max=10,
  value=3,
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:slider{
  id="branchCount",
  label="Branch Density:",
  min=1,
  max=10,
  value=5,
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:slider{
  id="leafDensity",
  label="Leaf Density:",
  min=0,
  max=10,
  value=6,
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:separator{text="Leaf Style"}

dlg:combobox{
  id="leafShape",
  label="Leaf Shape:",
  option="Circle",
  options={"Circle", "Square"},
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:separator{text="Colors"}

dlg:color{
  id="trunkColor",
  label="Trunk Color:",
  color=Color{r=62, g=39, b=49},
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:color{
  id="leafColor",
  label="Leaf Color:",
  color=Color{r=25, g=60, b=62},
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:check{
  id="leafVariation",
  label="Leaf Color Variation:",
  selected=true
}

dlg:separator{text="Outline"}

dlg:check{
  id="outline",
  label="Add Outline:",
  selected=true
}

dlg:slider{
  id="outlineThickness",
  label="Outline Thickness:",
  min=1,
  max=3,
  value=1,
  onchange=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, true)
  end
}

dlg:color{
  id="outlineColor",
  label="Outline Color:",
  color=Color{r=0, g=0, b=0}
}

dlg:separator{text="Options"}

dlg:number{
  id="seed",
  label="Random Seed:",
  text=tostring(os.time()),
  decimals=0
}

dlg:separator()

dlg:button{
  text="Save Tree",
  onclick=function()
    generateTree({
      treeHeight=dlg.data.treeHeight,
      trunkWidth=dlg.data.trunkWidth,
      branchCount=dlg.data.branchCount,
      leafDensity=dlg.data.leafDensity,
      leafShape=dlg.data.leafShape,
      trunkColor=dlg.data.trunkColor,
      leafColor=dlg.data.leafColor,
      leafVariation=dlg.data.leafVariation,
      outline=dlg.data.outline,
      outlineColor=dlg.data.outlineColor,
      outlineThickness=dlg.data.outlineThickness,
      seed=dlg.data.seed
    }, false)
    dlg:modify{id="seed", text=tostring(dlg.data.seed + 1)}
  end
}

dlg:button{
  text="Close",
  onclick=function()
    if previewLayer and previewLayer.sprite then
      app.transaction(function()
        sprite:deleteLayer(previewLayer)
      end)
      app.refresh()
    end
    dlg:close()
  end
}

dlg:show{wait=false}

generateTree({
  treeHeight=40,
  trunkWidth=3,
  branchCount=5,
  leafDensity=6,
  leafShape="Circle",
  trunkColor=Color{r=62, g=39, b=49},
  leafColor=Color{r=25, g=60, b=62},
  leafVariation=true,
  outline=true,
  outlineColor=Color{r=0, g=0, b=0},
  outlineThickness=1,
  seed=os.time()
}, true)
