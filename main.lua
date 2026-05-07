-- Variables
BackgroundColor = {255, 255, 255}
PauseOverlayColor = {0, 0, 0, 0.2} -- white with 50% opacity
GamePaused = false
TimeToDrawDot = 0.02
ComicRelief = love.graphics.newFont("assets/fonts/ComicRelief-Regular.ttf", 24)
DotSize = 4
DotColor = {0, 0, 0}

Drawing = {} -- this contains all of the dots placed around the screen, it is used to render them in the draw function, and updated in the update function

-- Game load
function love.load()
   -- allow resizing
   love.window.setTitle("Love2D testing")
   love.graphics.setBackgroundColor(BackgroundColor)
    love.filesystem.setIdentity("drawing_app_test")
end

-- Game update
function love.update(dt)
   if GamePaused then
      return
   end
   CreateDots()
end

-- Handle inputs
function love.keypressed(key)
   HandleInput(key)
end

-- Game render
function love.draw()
   ShowDrawing()
   RenderPauseScreen() -- Love2D only allows graphics calls in the draw function, outside it won't work apparently
end

function love.focus(f)
  if not f then
      GamePaused = true
  else
      GamePaused = false
  end
end

function HandleInput(key)
   if key == "escape" then
      GamePaused = not GamePaused
   elseif key == "s" then
      SaveScreenshot()
   elseif key == "r" then
      ResetEverything()
   elseif key == "o" then
      love.system.openURL(love.filesystem.getSaveDirectory())
   end
end

function RenderPauseScreen()
   if GamePaused then
      -- draw overlay gradient
      love.graphics.setColor(PauseOverlayColor)
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
      
      -- set font scaled by screen size and color
      love.graphics.setFont(ComicRelief)
      love.graphics.setColor(0, 0, 0)
      love.graphics.printf("PAUSED - press Escape to continue", 0, love.graphics.getHeight() / 2 - ComicRelief:getHeight() / 2, love.graphics.getWidth(), "center")
      love.graphics.printf("Press S to save a screenshot of your drawing, R to reset everything", 0, love.graphics.getHeight() / 2 + ComicRelief:getHeight(), love.graphics.getWidth(), "center")
      love.graphics.printf("Press O to open the folder where screenshots are saved (if any)", 0, love.graphics.getHeight() / 2 + ComicRelief:getHeight() * 2, love.graphics.getWidth(), "center")
   end
end

function ResetEverything()
   Drawing = {}
   -- place the dot randomly on the screen to start with, so it doesn't start in the same place every time
   Drawing[#Drawing + 1] = {
      size = DotSize,
      color = DotColor,
      x = love.math.random(0, love.graphics.getWidth()),
      y = love.math.random(0, love.graphics.getHeight())
   }
end


--[[ Each dot in the drawing is a table with the following properties:
   - size: the size of the dot
   - color: the color of the dot
   - x: the x position of the dot
   - y: the y position of the dot
   - lastX: the last x position of the dot, used for smooth movement
   - lastY: the last y position of the dot, used for smooth movement
]]--
function CreateDots()
   --[[
   Create a new dot every X seconds, and place it randomly around the last placed dot to create a smooth line effect, 
   if there is no last placed dot, place it randomly on the screen, every now and them, we randomly move the dot a bit more to create more varied shapes, 
   we also try to avoid placing the dot outside of the screen or too close to other dots by using the dot size as radius
   ]]--
   
   -- add a new dot to the drawing every X seconds
   if not GamePaused then
      if not Drawing.lastDotTime then
         Drawing.lastDotTime = love.timer.getTime()
      end

      -- if the last dot was placed more than X seconds ago, we place a new one
      if love.timer.getTime() - Drawing.lastDotTime > TimeToDrawDot then
         -- we get the last dot if it exists, otherwise we create a new one next to it to simulate a smooth line, and we add it to the drawing
         local dot = {
            size = DotSize,
            color = DotColor,
            -- get the position of the last dot if it exists, otherwise use random
            lastX = Drawing[#Drawing] and Drawing[#Drawing].x or love.math.random(0, love.graphics.getWidth()),
            lastY = Drawing[#Drawing] and Drawing[#Drawing].y or love.math.random(0, love.graphics.getHeight()),
            -- then we place the new dot randomly around the last one, within a radius of the DotSize, tried to create a smooth line effect but it sucks
            x = (Drawing[#Drawing] and Drawing[#Drawing].x or love.math.random(0, love.graphics.getWidth())) + love.math.random(-DotSize, DotSize),
            y = (Drawing[#Drawing] and Drawing[#Drawing].y or love.math.random(0, love.graphics.getHeight())) + love.math.random(-DotSize, DotSize)
         }
         table.insert(Drawing, dot)
         Drawing.lastDotTime = love.timer.getTime()
      end
   end
end

function ShowDrawing()
   for _, dot in ipairs(Drawing) do
      love.graphics.setColor(dot.color)
      love.graphics.circle("fill", dot.x, dot.y, dot.size)
   end
end

function SaveScreenshot()
   local WasGamePaused = GamePaused
   -- unpause to not save the pause screen too lmao
   GamePaused = false

   -- check if screenshot already exists, if it does, we add a number to the end of the file name to avoid overwriting it
   local fileName = os.date("%Y-%m-%d_%H-%M-%S") .. "_drawing.png"
   local fileExists = love.filesystem.getInfo(fileName)
   local counter = 1

   while fileExists do
      fileName = os.date("%Y-%m-%d_%H-%M-%S") .. "_drawing_" .. counter .. ".png"
      fileExists = love.filesystem.getInfo(fileName)
      counter = counter + 1
   end

   -- save screenshot
   local screenshotData = love.graphics.captureScreenshot(fileName)

   -- restore game paused state
   GamePaused = WasGamePaused
end