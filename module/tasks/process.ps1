task Deploy CheckParameters,
            EnsureDataverseEnvironment,
            EnsureDataverseSolution,
            ConnectDataverse,
            DeployDataverseTables

task DeployNoPacCli SetSkipPacCli,
                    CheckParameters,
                    ConnectDataverse,
                    DeployDataverseTables