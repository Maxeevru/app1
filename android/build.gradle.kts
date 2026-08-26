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

// ВЫСТАВИЛИ АКТУАЛЬНУЮ ВЕРСИЮ 35 ДЛЯ ВСЕХ ПЛАГИНОВ:
subprojects {
    plugins.withId("com.android.application") {
        configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(35)
            defaultConfig { targetSdk = 35 }
            if (namespace == null) {
                namespace = "com.example.${project.name}"
            }
        }
    }
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.BaseExtension> {
            compileSdkVersion(35)
            defaultConfig { targetSdk = 35 }
            if (namespace == null) {
                namespace = "com.example.${project.name}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
