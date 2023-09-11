package patches.buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.DotnetBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.dotnetBuild
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.ui.*

/*
This patch script was generated by TeamCity on settings change in UI.
To apply the patch, change the buildType with id = 'Build'
accordingly, and delete the patch script.
*/
changeBuildType(RelativeId("Build")) {
    check(name == "Build") {
        "Unexpected name: '$name'"
    }
    name = "Build tidybee-hub"

    check(publishArtifacts == PublishMode.NORMALLY_FINISHED) {
        "Unexpected option value: publishArtifacts = $publishArtifacts"
    }
    publishArtifacts = PublishMode.SUCCESSFUL

    vcs {
        expectEntry(DslContext.settingsRoot.id!!)
        root(DslContext.settingsRoot.id!!, "+:hub => .")
    }

    expectSteps {
        dotnetBuild {
            name = "Build"
            projects = """
                functionnalTests/*.csproj
                unitaryTests/*.csproj
            """.trimIndent()
            logging = DotnetBuildStep.Verbosity.Normal
            dockerImage = "mcr.microsoft.com/dotnet/sdk:7.0"
            param("dotNetCoverage.dotCover.home.path", "%teamcity.tool.JetBrains.dotCover.CommandLineTools.DEFAULT%")
        }
        script {
            name = "Tests"
            scriptContent = """
                cd functionnalTests
                dotnet publish -o out
                dotnet vstest out/TidyUpSoftware.xUnitTests.dll
                cd ..
                dotnet publish -o out
                dotnet vstest out/TidyUpSoftware.nUnitTests.dll
            """.trimIndent()
        }
    }
    steps {
        update<DotnetBuildStep>(0) {
            name = "build tidybee-hub"
            clearConditions()
            projects = "hub/tidybee-hub.csproj"
        }
        insert(1) {
            dockerCommand {
                commandType = build {
                    source = file {
                        path = "agent/Dockerfile"
                    }
                }
            }
        }
        items.removeAt(2)
    }
}
