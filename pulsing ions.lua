
-- Pulsed voltage of ion TOF
--

simion.workbench_program()

--
-- Define adjustable variables
--

-- Voltage of the pulse in [V]
adjustable pulse_voltage = -300

-- Pulse width [us]
adjustable pulse_width = 2

-- Offset-time [us]
adjustable pulse_offset_time = 78

-- Potential energy display update period [us]
adjustable pe_update_each_usec = 2

--
-- Set initial values
--

-- Last potential energy surface update time [us]
local last_pe_update = 0.0

--
-- Define pulse shape (rectangular)
--
function pulse(t)
 if (t >= 0) and (t <= pulse_width) then
  return pulse_voltage
 else
  return 0
 end
end

--
-- Adjust electrode voltage with pulse
--
function segment.fast_adjust()
 local p = pulse(ion_time_of_flight - pulse_offset_time)

 adj_elect03 = p
end

--
-- Ionization process and
-- refresh of potential energy view
--
function segment.other_actions()
 -- Iionization process
 if ion_time_of_flight > pulse_offset_time then
  if ion_number >= 500 then
   ion_charge = 2
  else
   ion_charge = 1
  end
 end

 if abs(ion_time_of_flight - last_pe_update)
     >= pe_update_each_usec then

  last_pe_update = ion_time_of_flight

  -- Request a PE surface display update.
  sim_update_pe_surface = 1
 end
end
