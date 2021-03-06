-- status: correct
-- teardown_command: rm -rf PI_Controller-lua.log PI_Controller-lua_tmp/ PI_Controller_*.dot PI_Controller-lua.mat
-- linux: yes
-- mingw: no

function exitOnError (status)
  print("info:    status code: " .. status)
  if 0 ~= status then
    os.exit(0)
  end
end

oms2_setLoggingLevel(0)
status = 0;

oms2_setLogFile("PI_Controller-lua.log")
status = oms2_setTempDirectory("./PI_Controller-lua_tmp")
exitOnError(status)

status = oms2_newFMIModel("PI_Controller")
exitOnError(status)

-- instantiate FMUs
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Math.Add.fmu", "addP")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Math.Gain.fmu", "P")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Math.Add3.fmu", "addI")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Continuous.Integrator.fmu", "I")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Math.Add.fmu", "addPI")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Math.Gain.fmu", "gainPI")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Nonlinear.Limiter.fmu", "limiter")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Math.Add.fmu", "addSat")
status = status + oms2_addFMU("PI_Controller", "../FMUs/Modelica.Blocks.Math.Gain.fmu", "gainTrack")
exitOnError(status)

-- add connections
status = status + oms2_addConnection("PI_Controller", "addP:y", "P:u")
status = status + oms2_addConnection("PI_Controller", "addI:y", "I:u")
status = status + oms2_addConnection("PI_Controller", "P:y", "addPI:u1")
status = status + oms2_addConnection("PI_Controller", "I:y", "addPI:u2")
status = status + oms2_addConnection("PI_Controller", "addPI:y", "gainPI:u")
status = status + oms2_addConnection("PI_Controller", "gainPI:y", "limiter:u")
status = status + oms2_addConnection("PI_Controller", "gainPI:y", "addSat:u2")
status = status + oms2_addConnection("PI_Controller", "limiter:y", "addSat:u1")
status = status + oms2_addConnection("PI_Controller", "addSat:y", "gainTrack:u")
status = status + oms2_addConnection("PI_Controller", "gainTrack:y", "addI:u3")
exitOnError(status)

-- define parameters
k = 100.0
yMax = 12.0
yMin = -yMax
wp = 1.0
Ni = 0.1
xi_start = 0.0

-- set parameters
status = status + oms2_setRealParameter("PI_Controller.addP:k1", wp)
status = status + oms2_setRealParameter("PI_Controller.addP:k2", -1.0)
status = status + oms2_setRealParameter("PI_Controller.addI:k2", -1.0)
status = status + oms2_setRealParameter("PI_Controller.I:y_start", xi_start)
status = status + oms2_setRealParameter("PI_Controller.gainPI:k", k)
status = status + oms2_setRealParameter("PI_Controller.limiter:uMax", yMax)
status = status + oms2_setRealParameter("PI_Controller.addSat:k2", -1.0)
status = status + oms2_setRealParameter("PI_Controller.gainTrack:k", 1.0/(k*Ni))
exitOnError(status)

-- simulation settings
status = status + oms2_setStartTime("PI_Controller", 0.0)
status = status + oms2_setStopTime("PI_Controller", 4.0)
status = status + oms2_setCommunicationInterval("PI_Controller", 1e-4)
status = status + oms2_setResultFile("PI_Controller", "PI_Controller-lua.mat")
exitOnError(status)

-- instantiate lookup table
status = status + oms2_addTable("PI_Controller", "setpoint.csv", "setpoint")
status = status + oms2_addTable("PI_Controller", "drivetrain.csv", "driveTrain")
exitOnError(status)

-- add connections
status = status + oms2_addConnection("PI_Controller", "setpoint:speed", "addP:u1")
status = status + oms2_addConnection("PI_Controller", "setpoint:speed", "addI:u1")
status = status + oms2_addConnection("PI_Controller", "driveTrain:w", "addP:u2")
status = status + oms2_addConnection("PI_Controller", "driveTrain:w", "addI:u2")
exitOnError(status)

status = status + oms2_exportCompositeStructure("PI_Controller", "PI_Controller_CompositeStructure.dot")
exitOnError(status)
--os.execute("dot -Gsplines=none PI_Controller_CompositeStructure.dot | neato -n -Gsplines=ortho -Tpdf -oPI_Controller_CompositeStructure.pdf")

-- initialize
print("info:    Initialization")
status = status + oms2_initialize("PI_Controller")
print("info:      limiter.u: " .. oms2_getReal("PI_Controller.limiter:u"))
print("info:      limiter.y: " .. oms2_getReal("PI_Controller.limiter:y"))
exitOnError(status)

status = status + oms2_exportDependencyGraphs("PI_Controller", "PI_Controller_initialUnknowns.dot", "PI_Controller_outputs.dot")
exitOnError(status)
--os.execute("gvpr -c \"N[$.degree==0]{delete(root, $)}\" PI_Controller_initialUnknowns.dot | dot -Tpdf -o PI_Controller_initialUnknowns.pdf")
--os.execute("gvpr -c \"N[$.degree==0]{delete(root, $)}\" PI_Controller_outputs.dot | dot -Tpdf -o PI_Controller_outputs.pdf")

-- simulate
print("info:    Simulation")
status = status + oms2_simulate("PI_Controller")
print("info:      limiter.u: " .. oms2_getReal("PI_Controller.limiter:u"))
print("info:      limiter.y: " .. oms2_getReal("PI_Controller.limiter:y"))
exitOnError(status)

status = oms2_unloadModel("PI_Controller")
exitOnError(status)

vars = {"limiter.u", "limiter.y"}
for _,var in ipairs(vars) do
  if 1 == oms2_compareSimulationResults("PI_Controller-lua.mat", "../ReferenceFiles/PI_Controller.mat", var, 1e-2, 1e-4) then
    print("info:    " .. var .. " is equal")
  else
    print("error:   " .. var .. " is not equal")
  end
end

-- Result:
-- info:    status code: 0
-- info:    status code: 0
-- info:    status code: 0
-- info:    status code: 0
-- info:    status code: 0
-- info:    status code: 0
-- info:    status code: 0
-- info:    status code: 0
-- info:    status code: 0
-- info:    Initialization
-- info:      limiter.u: 0.0
-- info:      limiter.y: 0.0
-- info:    status code: 0
-- info:    status code: 0
-- info:    Simulation
-- info:      limiter.u: -10.014508893657
-- info:      limiter.y: -10.014508893657
-- info:    status code: 0
-- info:    status code: 0
-- info:    limiter.u is equal
-- info:    limiter.y is equal
-- info:    Logging information has been saved to "PI_Controller-lua.log"
-- info:    9 warnings
-- info:    0 errors
-- endResult
