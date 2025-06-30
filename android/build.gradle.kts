buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2") // ✅ Correct syntax
    }

    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    layout.buildDirectory.set(newSubprojectBuildDir)

    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
