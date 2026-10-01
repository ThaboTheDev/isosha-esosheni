allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.named<org.gradle.api.tasks.wrapper.Wrapper>("wrapper") {
    gradleVersion = "8.11.1"
    distributionType = org.gradle.api.tasks.wrapper.Wrapper.DistributionType.ALL
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
