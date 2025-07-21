plugins {
    id("com.android.application") version "8.7.0" apply false
    // Hapus jika ada library plugin yang tidak ditemukan
    id("com.google.gms.google-services") version "4.3.15" apply false
}

 android {
        ndkVersion = "27.0.12077973"
        ...
    }

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
