## status: correct
## teardown_command: rm HelloWorld_cs_Fit_py.log HelloWorld_cs_Fit_res.mat

from OMSimulator import OMSimulator
from OMSysIdent import OMSysIdent
import numpy as np

session = OMSimulator()

version = session.getVersion()

session.setLogFile("HelloWorld_cs_Fit_py.log")
session.setTempDirectory(".")
model = "HelloWorld_cs_Fit"
session.newFMIModel(model)
# session.setTolerance(model, 1e-5) # 2018-04-25 Not yet supported in oms2 API

# add FMU
session.addFMU(model, "../FMUs/HelloWorld_cs.fmu", "HelloWorld")

# add solver
session.addSolver(model, "solver1", "internal")
session.addConnection(model, "HelloWorld", "solver1")

# create simodel for model
simodel = OMSysIdent(model)
# simodel.describe()

# Data generated from simulating HelloWorld.mo for 1.0s with Euler and 0.1s step size
kNumSeries = 1
kNumObservations = 11
data_time = np.array([0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1])
inputvars = []
measurementvars = ["HelloWorld:x"]
data_x = np.array([1, 0.9, 0.8100000000000001, 0.7290000000000001, 0.6561, 0.5904900000000001, 0.5314410000000001, 0.4782969000000001, 0.43046721, 0.387420489, 0.3486784401])

simodel.initialize(kNumSeries, data_time, inputvars, measurementvars)
# simodel.describe()

simodel.addParameter("HelloWorld:x_start", 0.5)
simodel.addParameter("HelloWorld:a", -0.5)
simodel.addMeasurement(0, "HelloWorld:x", data_x)
# simodel.describe()

simodel.setOptions_max_num_iterations(25)
simodel.solve("")

status, state = simodel.getState()
# print('status: {0}; state: {1}').format(OMSysIdent.oms_status_str(status), OMSysIdent.omsi_simodelstate_str(state))

status, startvalue1, estimatedvalue1 = simodel.getParameter("HelloWorld:a")
status, startvalue2, estimatedvalue2 = simodel.getParameter("HelloWorld:x_start")
# print('HelloWorld.a startvalue1: {0}; estimatedvalue1: {1}'.format(startvalue1, estimatedvalue1))
# print('HelloWorld.x_start startvalue2: {0}; estimatedvalue2: {1}'.format(startvalue2, estimatedvalue2))
is_OK1 = estimatedvalue1 > -1.1 and estimatedvalue1 < -0.9
is_OK2 = estimatedvalue2 > 0.9 and estimatedvalue2 < 1.1
print('HelloWorld.a estimation is OK: {0}'.format(is_OK1))
print('HelloWorld.x_start estimation is OK: {0}'.format(is_OK2))

# del simodel
session.unloadModel(model)

## Result:
## HelloWorld.a estimation is OK: True
## HelloWorld.x_start estimation is OK: True
## info:    Logging information has been saved to "HelloWorld_cs_Fit_py.log"
## endResult
