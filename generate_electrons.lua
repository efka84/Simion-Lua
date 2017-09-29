--[[
(c) FK 13 Jul 2016
the code simulates electrons of energy  specified by the loop and writes their ion number and time of flight
or other properties if desired into a file according to their initial kinetic energy
-number of electrons are still defined in the simion gui at register particles!
]]

simion.workbench_program()

local energy
local farbe
--SUGGESTIONS OF DAVID MANURA ARE ABBREVIATED AS DM
--DM local fh

local function set_ke(ke)
  local speed = math.sqrt(ion_vx_mm^2 + ion_vy_mm^2 + ion_vz_mm^2)
  assert(speed ~= 0)
  local new_speed = ke_to_speed(ke, ion_mass)
  local scale = new_speed/speed
  ion_vx_mm = ion_vx_mm * scale
  ion_vy_mm = ion_vy_mm * scale
  ion_vz_mm = ion_vz_mm * scale
end
-- see Workbench Program Extensions in SIMION 8.1 in Help menu of SIMION 8.1
--really funny way to define a loop
-- the func segment.flym() is executed the for loop starts here but runs till the end of line file

function segment.flym()
    for i = 15,40 do
    energy = i
    farbe = i
--DM fh = assert(io.open( tostring(energy).. "eV.txt", "a"),"invalid")
--dont forget to inactivate the above command inside the segment.terminate()
    fh = assert(io.open( tostring(energy).. "eV.dat", "w"),"invalid")
    run()
    fh:close()
--DM fh:close()
--dont forget to inactivate the above command inside the segment.terminate()
    end
end
--the for loop is still active
function segment.initialize()
set_ke(energy)
ion_color = farbe
end
--the for loop is active in the segment.terminate()
function segment.terminate()
    if ion_px_mm > 444 then
        fh:write(ion_number, "\t", ion_time_of_flight,"\n") --write ion_number tab write time_of_flight new line
    end
end
