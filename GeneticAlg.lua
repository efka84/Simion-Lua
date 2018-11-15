--[[ original author TH
	improved by FK
The code implements a genetic algorithm to improve the transmission of the spectrometer MDTOF_LANGand puts the results in a text file

	---------------	TO DO ---------------------
	1. first lines should be  the initial energy of the electrons
	2. initial voltages of the electrodes
]]

simion.workbench_program()

--write the current date into the file  'Log_Genetic_Algorithm.txt'
file =io.open("Log_Genetic_Algorithm.txt","a")
file:write(os.date(),"\n")
file:close()
-- end of date writing

		--adjustables
adjustable number_of_generations		= 20
adjustable detector_position			= 445	-- detector distance
adjustable detector_radius				= 40
adjustable number_of_individuals		= 30	 -- number of individuals
-- sets the maximal genetic aberation after one generation (absolute)
adjustable maximal_genetic_aberration	= 30
-- The first generation is determined by the first voltage settings
-- choose a radius (in %: 0.x oder in Volts: > 1) for this first generation
-- i.e. V1 = 100, first_generation_radius = 0.5, the first generation will consists of V1  [50;150] V
adjustable first_generation_radius 		= 0.75
adjustable total_number_ions			= 500	-- how many ions are flying?
-- optimization weights
adjustable opimization_weight_hits			= 5
adjustable opimization_weight_tof			= 3
adjustable opimization_weight_tof_stddev	= 3
adjustable opimization_weight_collimation	= 2

current_generation						= 0
current_child							= 1
number_of_voltages						= 6
start_voltages							= {}
-- Tables for the optimization data
fitness									= {}
parents									= {}
children								= {}
-- Environment variables
init									= 0
terminated								= 0
finish									= 0
current_ion								= 0
current_ion_coll						= 0
current_ion_coll_y						= 0
hits_collimation						= 0
hits_count 								= 0
hits									= {}


function segment.init_p_values()
	-- Initialize System. init is already set to zero! so the following statement makes sure that the System
	--gets Initialized!
	if init == 0 then
		-- Saving starting Voltages. defined above: start_voltages={}
		start_voltages[1] = adj_elect01 --lua arrays start at 1 instead of zero like other prog languages
		start_voltages[2] = adj_elect02
		start_voltages[3] = adj_elect03
		start_voltages[4] = adj_elect04
		start_voltages[5] = adj_elect05
		start_voltages[6] = adj_elect06
		start_voltages[7] = adj_elect07
		-- Creating the first generation
		fiat_lux()
		repopulate()
		-- saving init value
		init = 1
	end
	-- Setting the individuals voltages.  defined above children= {}
	adj_elect01		= children[current_child][1]
	adj_elect02		= children[current_child][2]
	adj_elect03		= children[current_child][3]
	adj_elect04		= children[current_child][4]
	adj_elect05		= children[current_child][5]
	adj_elect06		= children[current_child][6]

	terminated 			= 0
	current_ion 		= 0
	hits_coll_factor	= 0
	kill				= 0
	hits				= {}
end

-- Calculating how good the settings are
	function segment.other_actions()
		-- save collimation
		if 	ion_px_mm > detector_position / 3 and ion_px_mm < (detector_position+1) / 3 and ion_py_mm > -detector_radius and ion_py_mm < detector_radius then
			current_ion_coll = ion_number
			current_ion_coll_y = ion_py_mm
			ion_color = 1;
			mark() --mark() is an internal defined function, which marks the ion location
	   end
		if ion_px_mm < 8 then
				kill = 1
				ion_color = 10;
	 	end
			-- ions hits the diode's surface
		 if 	(ion_px_mm > detector_position and abs(ion_py_mm) < detector_radius  )
			and ion_number > current_ion then
			current_ion 	= ion_number
			ion_color = 2
			-- calculating collimation factor
			if current_ion_coll == ion_number  then
				if ion_py_mm*current_ion_coll_y > 0 then
					hits_coll_factor = hits_coll_factor + 1
					ion_color = 6
					else
						hits_coll_factor = hits_coll_factor + 0.5
						ion_color = 7
			  end
		  end
			-- counting hits an marking ion
			hits[current_ion]	= { tof = ion_time_of_flight }
			mark()
	   end
	end

-- ----------------------------- function segment.terminate () --------------------------
	function segment.terminate()
			-- alle ions are through
		if ion_number > total_number_ions*0.925 and terminated == 0 then
		-- getting the count of hits and the average tof
		local sum_hits	= 0
		local avg_tof 	= 0
		for i,v in pairs(hits) do
			avg_tof 	= avg_tof + v.tof
			sum_hits 	= sum_hits +1
		end

		if sum_hits > 30 then
			avg_tof = avg_tof / sum_hits
		else
			kill = 1
		end
		-- getting the standard deviation
		local std_dev_tof = 1e-6

		if kill == 0 then
			std_dev_tof = 0

			for i,v in pairs(hits) do
				std_dev_tof = 1 / sum_hits * (avg_tof - v.tof)^2 + std_dev_tof
			end
			std_dev_tof = math.sqrt(std_dev_tof)
		end

		-- calculating the fitness_scores
		local fitness_score = ceil(10000/(opimization_weight_hits + opimization_weight_tof + opimization_weight_tof_stddev + opimization_weight_collimation) * ( 0

			-- adding score-points for hits
				+
				5 * opimization_weight_hits * sum_hits / ion_number
			-- adding score-points for a long TOF
				+
				opimization_weight_tof * avg_tof
			        -- adding score points for low tof standard deviation (making factor 0.002 ideal)
				+
				opimization_weight_tof_stddev * 0.0005 / std_dev_tof
			-- adding score points for good collimation
				+
				opimization_weight_collimation * hits_collimation / sum_hits
			))
			--
		--print(kill, sum_hits / ion_number,avg_tof, std_dev_tof, hits_collimation / sum_hits)

		if  kill == 1 then
			fitness_score = 0
		end

		fitness[current_child] = {child = current_child, fit = fitness_score, tof = avg_tof, stddev = std_dev_tof, hits = sum_hits}
		--print(children[current_child][1],children[current_child][2],children[current_child][3],children[current_child][4],children[current_child][5],children[current_child][6],fitness[current_child].fit )
		-- rise current_child
		current_child		= current_child + 1
		terminated 	= 1

		-- current_individualed through all individuals?
		if current_child > number_of_individuals then
			current_child = 1
			surviving_of_the_fittest()
		end

		-- current_individualed throup all generations?
		if current_generation > number_of_generations then

			--data = data..result
			--save_file("report.txt",data)
			print("Finished")
			file =io.open("Log_Genetic_Algorithm.txt","a")
			file:write("F I N I S H E D " )
			file:close()

         -- Stop reruns
			sim_rerun_flym = 0
			else
			-- Continue flym
			sim_rerun_flym = 1
		end
	end
end
--------------------------- end of function segment.terminate() ----------------------
 ---------------------------- function fiat_lux () --------------------------------------
-- creates the first generation, which is, for example, a 15x7 Matrix
function fiat_lux()
	print("Creating the first generation")
	for n=1,ceil(number_of_individuals/2) do
		parents[n] = {} --parents= {}  array defined already
			for m=1,number_of_voltages do
			parents[n][m] = ceil(start_voltages[m] * ( 1 + math.random(-1,1) * math.random() * first_generation_radius ))
		end
	end
end
-----------------------end of function fiat_lux () ----------------------------
------------------------- function repopulate ()--------------------------------
-- creates the next generation
function repopulate()
	local parent1, parent2

	current_generation = current_generation + 1 	-- increasing generation

	if(current_generation <= number_of_generations) then
		print("Current Generation: " ..current_generation)
		file =io.open("Log_Genetic_Algorithm.txt","a")
		file:write("\n","Current Generation:" ..current_generation,"\n")
		file:close()
	end --end of the above if then command
	-- creating children
	for n=1,number_of_individuals do
			-- take the parents (strongest survivors) to the next generation
			if n <= ceil(number_of_individuals/3) then
			children[n] = parents[n]
					-- and some new children
					else
					-- new child is born *
						children[n] 		= {}
					-- getting the chromosoms of his parents
							parent1 		= math.random(1,ceil(number_of_individuals/2))
							parent2 		= math.random(1,ceil(number_of_individuals/2))
							exchange_factor	= math.random(1,number_of_voltages-1)
					for m=1,number_of_voltages do
						if( m > exchange_factor) then
							children[n][m] = parents[parent1][m]+math.random(-1,1)*math.random()*maximal_genetic_aberration/current_generation
						else
								children[n][m] = parents[parent2][m]+math.random(-1,1)*math.random()*maximal_genetic_aberration/current_generation
				   end
						children[n][m] = floor(children[n][m])
			end
		end
	end
end

function surviving_of_the_fittest()

	local fittest 		= {}
	local n 			= 1
	local sum_fitness 	= 0

	table.sort(fitness,function(a,b) return a.fit>b.fit end)

	for i, v in ipairs(fitness) do

	  if n == 1 then
		print("Strongest Child:", children[n][1],children[n][2],children[n][3],children[n][4],children[n][5],children[n][6],start_voltages[7],"("..v.hits.." Treffer, "..ceil(v.tof*1000).." ns +- "..ceil(v.stddev*1000*1000).."ps, "..v.fit.." points)")
		--open the file to write
		file =io.open("Log_Genetic_Algorithm.txt","a")
		file:write("Strongest Child:", children[n][1],"\t", children[n][2],"\t",children[n][3],"\t",children[n][4],"\t",children[n][5],"\t",children[n][6],"\t",start_voltages[7],"\t","("..v.hits.." Treffer, "..ceil(v.tof*1000).." ns +- "..ceil(v.stddev*1000*1000).."ps, "..v.fit.." points)","\n")
		file:close()
	 end

	  if n <= ceil(number_of_individuals/2)  then
		fittest[n] = children[v.child]
	  end

	  n = n + 1
	  sum_fitness = sum_fitness + v.fit
    end

	n = n -1
	print("Average fitness in this generation: "..ceil(sum_fitness/n))
	file = io.open("Log_Genetic_Algorithm.txt","a")
	file:write("Average fitness in this generation: "..ceil(sum_fitness/n), "\n") --something wrong here, because the number is not written into file
	file:close()

	parents = fittest

	repopulate()
end


function save_file(name,content)
	local file

	file = io.open(name,"w")
	file:write ( content )
	file:close()

	return 1
end
