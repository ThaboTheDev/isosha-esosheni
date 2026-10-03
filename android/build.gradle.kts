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

// Keep this in sync with android/gradle/wrapper/gradle-wrapper.properties.
// Gradle 9.3.1 is the version paired with AGP 9.1.0 by Flutter 3.47, and the lowest
// version the Flutter Gradle plugin's dependency check accepts for AGP 9.1.
tasks.named<org.gradle.api.tasks.wrapper.Wrapper>("wrapper") {
    gradleVersion = "9.3.1"
    distributionType = org.gradle.api.tasks.wrapper.Wrapper.DistributionType.ALL
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
