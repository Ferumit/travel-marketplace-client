plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false
}

allprojects {
    repositories {
        // Local offline repository for vendored artifacts
        maven { url = uri("$rootDir/local_repo") }
        
        google()
        mavenCentral()
        
        // Alternative reliable mirrors to bypass Maven Central SSL bad_record_mac error
        maven { url = uri("https://mirrors.tencent.com/nexus/repository/maven-public/") }
        maven { url = uri("https://repo.huaweicloud.com/repository/maven/") }
        maven { url = uri("https://jitpack.io") }
        
        // Alibaba Cloud mirrors
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
    }

    buildscript {
        repositories {
            google()
            mavenCentral()
            maven { url = uri("https://mirrors.tencent.com/nexus/repository/maven-public/") }
            maven { url = uri("https://repo.huaweicloud.com/repository/maven/") }
            maven { url = uri("https://jitpack.io") }
            maven { url = uri("https://maven.aliyun.com/repository/google") }
            maven { url = uri("https://maven.aliyun.com/repository/central") }
            maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
