-------------------------------------------------------------------------------
wa_treehugger_data = {

  trees = {
     -- mage quarter
      {y=-9025.9, x=875.1}, {y=-9027.3, x=854.9}, {y=-9022.1, x=841.1},
      {y=-9006.3, x=836.1}, {y=-9000.0, x=855.0}, {y=-8959.5, x=825.2},
      {y=-8973.1, x=834.8}, {y=-8968.3, x=845.2}, {y=-8990.5, x=866.5},
      {y=-8978.9, x=895.1}, {y=-9014.8, x=898.1}, {y=-9020.6, x=895.2}, 
      {y=-9005.5, x=920.0}, {y=-8987.3, x=969.7}, {y=-8955.7, x=979.6}, 
      {y=-8932.8, x=983.2}, {y=-8901.4, x=961.8}, {y=-8945.5, x=941.0},
      {y=-8898.6, x=932.4}, {y=-8914.4, x=910.0}, {y=-8936.2, x=920.5}, 
      {y=-8895.3, x=893.8}, {y=-8880.6, x=867.5}, {y=-8883.1, x=818.5},
      {y=-8920.8, x=812.0}, {y=-8959.3, x=793.3}, {y=-8952.1, x=762.4},
	  {y=-8926.2, x=784.3},
      {y=-8959.3, x=879.9, e=1}, {y=-8967.8, x=888.0, e=1},
      {y=-8878.6, x=890.2, e=1}, {y=-8897.8, x=877.8, e=1},
      {y=-8990.9, x=877.7, e=1}, {y=-8958.7, x=963.1, e=1},
      {y=-8942.3, x=964.7, e=1}, {y=-8913.6, x=967.5, e=1},
      {y=-8928.9, x=944.9, e=1}, {y=-8909.5, x=856.5, e=1},
	  
	  -- canal
	  {y=-8899.2, x=743.3}, {y=-8906.4, x=698.9}, {y=-8873.2, x=701.3},
	  {y=-8818.8, x=747.8},
	  {y=-8853.5, x=763.9, e=1},
   
	  -- cathedral square
	  {y=-8631.4, x=719.4}, {y=-8678.0, x=761.0}, {y=-8650.4, x=765.0},
	  {y=-8621.8, x=762.0}, {y=-8643.8, x=787.9}, {y=-8624.3, x=808.3},
	  {y=-8646.6, x=813.1}, {y=-8658.3, x=834.3}, {y=-8645.4, x=845.3},
	  {y=-8632.5, x=834.0}, {y=-8615.5, x=847.5}, {y=-8590.6, x=765.7},
	  {y=-8580.1, x=748.6}, {y=-8584.1, x=718.0}, {y=-8539.8, x=791.2},
	  {y=-8462.1, x=787.8}, {y=-8494.7, x=800.1}, {y=-8497.0, x=857.8},
	  {y=-8473.2, x=873.6}, {y=-8491.7, x=877.7}, {y=-8554.2, x=885.7},
	  {y=-8583.3, x=897.0}, {y=-8579.5, x=932.2}, {y=-8564.4, x=858.3},
	  {y=-8649.3, x=725.5, e=1}, {y=-8639.8, x=748.3, e=1},
	  {y=-8635.0, x=778.9, e=1}, {y=-8652.3, x=820.9, e=1},
	  {y=-8585.9, x=867.8, e=1}
	  
  },

  targets = {nil,nil,nil},
  on = false,
  
  scale = 0.1
}

-------------------------------------------------------------------------------
function wa_treehugger_data.TurnOff()
	local data = wa_treehugger_data
	
	if not data.on then return end
	
	data.on = false
	WeakAuras.ScanEvents( "WA_TREEHUGGER_TOGGLED", false )
end

-------------------------------------------------------------------------------
function wa_treehugger_data.TurnOn()
	local data = wa_treehugger_data
	
	if data.on then return end
	
	data.on = true
	WeakAuras.ScanEvents( "WA_TREEHUGGER_TOGGLED", true )
end

-------------------------------------------------------------------------------
function wa_treehugger_data.AddTree( info ) 
	
end
 
-------------------------------------------------------------------------------
function wa_treehugger_data.Update()
	local data = wa_treehugger_data
	
	
	data.targets = {nil,nil,nil}
	
	local y,x = UnitPosition( "player" )
	
	for _,v in pairs( data.trees ) do
		local dist = (v.x - x)^2 + (v.y - y)^2
		
		for i = 1,3 do
			if data.targets[i] == nil then
				data.targets[i] = { x = v.x, y = v.y, d = dist, e = v.e or false }
				break
			elseif dist < data.targets[i].d then
				if i < 3 then
					data.targets[i+1] = data.targets[i]
				end
				data.targets[i] = { x = v.x, y = v.y, d = dist, e = v.e or false }
				break
			end
		end
	end
	
	data.TurnOn()
end

-------------------------------------------------------------------------------
function wa_treehugger_data.on_translate( sx, sy, index )
	 local f = GetPlayerFacing("player") 
    
    local py,px = UnitPosition( "player" )
    local data = wa_treehugger_data.targets[index]
	
    if data == nil then return end
      
    local xt,yt = px - data.x, py - data.y
    
    -- rotate
    local x = xt * math.cos(f) - yt * math.sin(f)
    local y = xt * math.sin(f) + yt * math.cos(f)
    
    y = -y
    
    x = x * wa_treehugger_data.scale 
    y = y * wa_treehugger_data.scale 
    
    -- normalize
    local d = math.sqrt((x*x)+(y*y))
    if d > 1 then
        
        
        x = x / d
        y = y / d
    end
    
    -- safety clamp
    x = math.min( 1, math.max( -1, x ))
    y = math.min( 1, math.max( -1, y ))
    
    return sx + 32*x, sy + 32*y
end